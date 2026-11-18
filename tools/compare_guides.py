"""Check our guide against Wowhead's Forever dungeon and raid guides.

Reads tools/wowhead/guides.json (from tools/wowhead/extract_guides.js) and the built addon,
then writes:

  tools/wowhead/guide_facts.json   Facts pulled from each guide: level range, bosses with
                                   their NPC and ability spell IDs, quests, notable trash.
                                   IDs and names only, no Wowhead prose, so it can be
                                   committed and used by the build.
  tools/wowhead/guide_report.md    Where we disagree: missing bosses, abilities we don't
                                   mention, level ranges that differ, quests and trash to
                                   add. Regenerate any time; it isn't committed.

    python tools/compare_guides.py

guides.json itself holds Wowhead's guide text and is git-ignored: it's a local reference
for the writing pass. Everything players read is written in our own words, and the
addon credits Wowhead as a source.
"""

from __future__ import annotations

import html
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from addon_env import ROOT, load_addon, to_py  # noqa: E402
from lua_writer import lua_value  # noqa: E402
from build_wowhead import NOISE_SPELLS  # noqa: E402

# Passives that aren't worth a line in the guide, on top of the build's own list.
PASSIVES = NOISE_SPELLS | {"Dual Wield", "Parry", "Block", "Dodge"}

GUIDES = ROOT / "tools" / "wowhead" / "guides.json"
FACTS = ROOT / "tools" / "wowhead" / "guide_facts.json"
REPORT = ROOT / "tools" / "wowhead" / "guide_report.md"
QUESTS = ROOT / "AdventureGuideForever" / "Data" / "Generated" / "Quests.lua"
QUEST_KEYS = ["questID", "name", "level", "reqLevel", "side", "start", "x", "y", "chain",
              "chainName", "shareable", "choose", "rewards", "itemID", "quality", "quests"]

# Names Wowhead's guide titles use that differ from ours.
TITLE_ALIASES = {
    "smgraveyard": ["Scarlet Monastery: Graveyard", "Scarlet Monastery Graveyard"],
    "smlibrary": ["Scarlet Monastery: Library", "Scarlet Monastery Library"],
    "smarmory": ["Scarlet Monastery: Armory", "Scarlet Monastery Armory"],
    "smcathedral": ["Scarlet Monastery: Cathedral", "Scarlet Monastery Cathedral"],
    "stockade": ["The Stockade", "Stormwind Stockade"],
    "dmeast": ["Dire Maul: East", "Dire Maul East", "Warpwood Quarter"],
    "dmwest": ["Dire Maul: West", "Dire Maul West", "Capital Gardens"],
    "dmnorth": ["Dire Maul: North", "Dire Maul North", "Gordok Commons"],
    "sunkentemple": ["Sunken Temple", "Temple of Atal'Hakkar"],
    "dalaran": ["City of Dalaran", "Dalaran"],
    "excavation": ["Excavation Site: Wetlands", "Excavation Site"],
}

TAG = re.compile(r"\[(npc|spell|quest|item|zone)=(\d+)[^\]]*\]")


def normalize(text: str) -> str:
    return re.sub(r"[^a-z0-9]", "", html.unescape(text).lower().replace("the ", ""))


# ---------------------------------------------------------------------------
# Reading Wowhead markup
# ---------------------------------------------------------------------------

def sections(markup: str) -> list[tuple[str, str]]:
    """Split a guide at its [h2] headings: [(toc label or heading, body), ...]."""
    parts = re.split(r"\[h2([^\]]*)\](.*?)\[/h2\]", markup)
    out = [("Intro", parts[0])]
    for i in range(1, len(parts) - 2, 3):
        attrs, heading, body = parts[i], parts[i + 1], parts[i + 2]
        toc = re.search(r'toc="([^"]*)"', attrs)
        out.append(((toc.group(1) if toc else heading).strip(), body))
    return out


def ids(text: str, kind: str) -> list[int]:
    seen: list[int] = []
    for k, n in TAG.findall(text):
        if k == kind and int(n) not in seen:
            seen.append(int(n))
    return seen


def plain(text: str, names: dict) -> str:
    """Markup to readable text, with [npc=1] etc. replaced by names (for the report)."""
    def name(m):
        return names.get(m.group(1), {}).get(m.group(2), {}).get("name") or f"{m.group(1)} {m.group(2)}"
    text = TAG.sub(name, text)
    text = re.sub(r"\[[^\]]*\]", " ", text)
    return re.sub(r"\s+", " ", html.unescape(text)).strip()


def level_range(text: str) -> tuple[int, int] | None:
    m = re.search(r"recommended level[^.]{0,80}?(\d{1,2})\s*(?:-|–|to|and)\s*(\d{1,2})", text, re.I)
    return (int(m.group(1)), int(m.group(2))) if m else None


def boss_boxes(body: str) -> list[tuple[str, str]]:
    """Each boss's (name, markup). Guides use [box-highlight name=...] or [h3]Name[/h3] boxes."""
    boxes = re.findall(r'\[box-highlight name="([^"]*)"\](.*?)\[/box-highlight\]', body, re.S)
    if not boxes:
        parts = re.split(r"\[h3[^\]]*\](.*?)\[/h3\]", body)
        boxes = [(parts[i], parts[i + 1]) for i in range(1, len(parts) - 1, 2)]
    return [(re.sub(r"\[[^\]]*\]", "", html.unescape(n)).strip(), b) for n, b in boxes]


def parse_bosses(body: str) -> list[dict]:
    bosses = []
    for name, box in boss_boxes(body):
        split = re.split(r"\[b\]\s*Abilities\s*\[/b\]", box, maxsplit=1, flags=re.I)
        abilities = ids(split[1], "spell") if len(split) > 1 else ids(box, "spell")
        bosses.append({"name": name, "npcIDs": ids(box, "npc"), "abilities": abilities,
                       "mentioned": [s for s in ids(split[0], "spell") if s not in abilities]})
    return bosses


SIDES = {"horde": "Horde", "alliance": "Alliance"}


def parse_quests(body: str, names: dict) -> list[dict]:
    """The guide's quest table (Quest | Level | Side | Effort | Share? | Starts), one record
    per quest: level, faction (None for both), where it starts and its /way coordinates,
    the quest its chain starts with, and whether it can be shared."""
    quests = []
    for row in re.findall(r"\[tr[^\]]*\](.*?)\[/tr\]", body, re.S):
        cells = re.findall(r"\[td[^\]]*\](.*?)\[/td\]", row, re.S)
        if len(cells) < 6 or not re.match(r"\s*\[quest=\d+\]", cells[0]):
            continue
        qid = ids(cells[0], "quest")[0]
        level = re.search(r"\d{1,2}", re.sub(r"\[[^\]]*\]", "", cells[1]))
        side_cell = cells[2].lower()
        sides = [v for k, v in SIDES.items() if k in side_cell]
        starts = cells[5]
        way = re.search(r"/way\s+(\d+(?:\.\d+)?)\s*,?\s+(\d+(?:\.\d+)?)", starts)
        chain = next((q for q in ids(starts, "quest") if q != qid), None)
        where = plain(re.split(r"\[i\]|Prerequisite", starts)[0], names)
        where = re.sub(r"\s+,", ",", re.sub(r"/way.*$", "", where)).strip(" .,-")
        quests.append({
            "questID": qid,
            "level": int(level.group(0)) if level else None,
            "side": sides[0] if len(sides) == 1 else None,
            "start": where[:100] or None,
            "x": float(way.group(1)) if way else None,
            "y": float(way.group(2)) if way else None,
            "chain": chain,
            "shareable": "fa-check" in cells[4],
        })
    return quests


def parse_quest_details(body: str) -> dict[str, dict]:
    """The guide's per-quest tabs: {normalized quest name: {reqLevel, rewards, choose}}.
    Rewards are the [item=] tags between "Reward(s)...:" and the end of that box."""
    out = {}
    for m in re.finditer(r'\[tab name="([^"]*)"[^\]]*\](.*?)(?=\[tab name=|\[/tabs\]|\Z)', body, re.S):
        name, tab = html.unescape(m.group(1)), m.group(2)
        req = re.search(r"Level Required:\s*(?:\[b\])?\s*(\d{1,2})", tab)
        reward = re.search(r"Rewards?\s*(\(choose one\))?\s*:(.*?)(?:\[/box\]|\[/center\]|\Z)", tab, re.S | re.I)
        out[normalize(name)] = {
            "reqLevel": int(req.group(1)) if req else None,
            "rewards": ids(reward.group(2), "item") if reward else [],
            "choose": bool(reward and reward.group(1)),
        }
    return out


def parse_guide(guide: dict) -> dict:
    markup, names = guide["markup"], guide.get("names", {})
    facts = {"title": html.unescape(guide["title"]), "updated": guide.get("updated"),
             "levels": None, "bosses": [], "quests": [], "trash": {"npcIDs": [], "spells": []}}
    details: dict[str, dict] = {}
    for label, body in sections(markup):
        low = label.lower()
        if "quest" in low:
            details.update(parse_quest_details(body))
        if facts["levels"] is None:
            facts["levels"] = level_range(plain(body, names))
        if "boss" in low or "encounter" in low:
            facts["bosses"] += parse_bosses(body)
        elif "quest" in low:
            seen = {x["questID"] for x in facts["quests"]}
            facts["quests"] += [q for q in parse_quests(body, names) if q["questID"] not in seen]
        elif "trash" in low or "mobs" in low:
            facts["trash"]["npcIDs"] += ids(body, "npc")
            facts["trash"]["spells"] += ids(body, "spell")
    for q in facts["quests"]:
        q["name"] = names.get("quest", {}).get(str(q["questID"]), {}).get("name")
        if q["chain"]:
            q["chainName"] = names.get("quest", {}).get(str(q["chain"]), {}).get("name")
        d = details.get(normalize(q["name"] or ""))
        if d:
            q["reqLevel"] = d["reqLevel"]
            q["choose"] = d["choose"] and len(d["rewards"]) > 1
            q["rewards"] = [{"itemID": i,
                             "name": names.get("item", {}).get(str(i), {}).get("name"),
                             "quality": names.get("item", {}).get(str(i), {}).get("quality")}
                            for i in d["rewards"]]
    for b in facts["bosses"]:
        b["abilityNames"] = [names.get("spell", {}).get(str(s), {}).get("name") for s in b["abilities"]]
    facts["trash"]["names"] = [names.get("npc", {}).get(str(n), {}).get("name") for n in facts["trash"]["npcIDs"]]
    return facts


def hub_levels(markup: str) -> dict[str, tuple[int, int]]:
    """The hub page's level table: {normalized name: (low, high)}."""
    out = {}
    for row in re.findall(r"\[tr\](.*?)\[/tr\]", markup, re.S):
        cells = [re.sub(r"\[[^\]]*\]", "", c).strip() for c in re.findall(r"\[td[^\]]*\](.*?)\[/td\]", row, re.S)]
        if len(cells) >= 3 and cells[1].isdigit() and cells[2].isdigit():
            out[normalize(cells[0])] = (int(cells[1]), int(cells[2]))
    return out


# ---------------------------------------------------------------------------
# Matching and comparing
# ---------------------------------------------------------------------------

def hub_lookup(hub: dict, names: list[str]) -> tuple[int, int] | None:
    """Hub rows are named loosely ("Temple of Atal'Hakkar (Sunken Temple)", "Dire Maul",
    one row per Maraudon wing): exact name first, then the first row either name starts."""
    keys = [normalize(n) for n in names]
    for k in keys:
        if k in hub:
            return hub[k]
    for k in keys:
        for row, rng in hub.items():
            if len(k) >= 6 and len(row) >= 6 and (row.startswith(k) or k.startswith(row)):
                return rng
    return None


def instance_names(inst: dict) -> list[str]:
    return [inst["name"], *(inst.get("aliases") or []), *TITLE_ALIASES.get(inst["key"], [])]


def match_instance(title: str, instances: list[dict]) -> str | None:
    t = normalize(title)
    best = None
    for inst in instances:
        for name in instance_names(inst):
            n = normalize(name)
            if n and t.startswith(n) and (best is None or len(n) > best[1]):
                best = (inst["key"], len(n))
    return best[0] if best else None


# Wowhead boxes named for the event or room rather than the boss.
BOSS_ALIASES = {"dirgendirgehammer": "durgendirgehammer",
                "chestofseven": "seven", "fatherflame": "solakarflamewreath",
                "fireofakumaievent": "firesofakumai"}


def boss_name_keys(name: str) -> list[str]:
    """Ways to match a Wowhead box title: whole, without "(Rare)", and each side of
    "X and Y", "X / Y", or "Room - Boss"."""
    name = re.sub(r"\(rare\)|<[^>]*>", "", html.unescape(name), flags=re.I)
    parts = [name] + re.split(r"\s+and\s+|\s*/\s*|\s+-\s+", name)
    keys = [normalize(p) for p in parts if normalize(p)]
    return [BOSS_ALIASES.get(k, k) for k in keys]


def match_boss(gb: dict, by_name: dict, by_npc: dict) -> dict | None:
    """Our boss for a Wowhead box: by name first (a box can mention other bosses' NPCs),
    then by the NPCs it tags."""
    for k in boss_name_keys(gb["name"]):
        if k in by_name:
            return by_name[k]
    return next((by_npc[n] for n in gb["npcIDs"] if n in by_npc), None)


def compare(key: str, inst: dict, guide: dict, facts: dict, hub: dict) -> list[str]:
    names = guide.get("names", {})
    spell_name = lambda s: names.get("spell", {}).get(str(s), {}).get("name") or f"spell {s}"  # noqa: E731
    out = [f"## {inst['name']} (`{key}`)", "", f"Source: {facts['url']} (updated {facts['updated']})", ""]

    ours = (inst["minLevel"], inst["maxLevel"])
    hub_range = hub_lookup(hub, instance_names(inst))
    level_notes = []
    for label, rng in (("guide text", facts["levels"]), ("hub table", hub_range)):
        if rng and tuple(rng) != ours:
            level_notes.append(f"{label} says {rng[0]}-{rng[1]}")
    if level_notes:
        out.append(f"- **Levels:** we say {ours[0]}-{ours[1]}; " + "; ".join(level_notes) + ".")

    our_bosses = inst["guide"].get("bosses", [])
    by_npc = {b.get("npcID"): b for b in our_bosses if b.get("npcID")}
    by_name = {normalize(b["name"]): b for b in our_bosses}
    for b in our_bosses:
        for alias in b.get("alsoNamed") or []:
            by_name.setdefault(normalize(alias), b)
    matched = set()
    for gb in facts["bosses"]:
        ob = match_boss(gb, by_name, by_npc)
        if not ob:
            out.append(f"- **Boss missing from our guide:** {gb['name']} (NPC {', '.join(map(str, gb['npcIDs'])) or '?'}).")
            continue
        matched.add(ob["name"])
        have_ids = {a.get("spellID") for a in ob.get("abilities") or [] if a.get("spellID")}
        have_names = {normalize(a["name"]) for a in ob.get("abilities") or []}
        missing = [s for s in gb["abilities"] if s not in have_ids and spell_name(s) not in PASSIVES
                   and normalize(spell_name(s)) not in have_names]
        if missing:
            out.append(f"- **{ob['name']}:** abilities we don't list: "
                       + ", ".join(f"{spell_name(s)} ({s})" for s in missing) + ".")
        if not (ob.get("strategy") or {}).get("summary"):
            out.append(f"- **{ob['name']}:** we have no strategy; Wowhead's guide has one.")
    extra = [b["name"] for b in our_bosses if b["name"] not in matched and not b.get("optional")]
    if extra and facts["bosses"]:
        out.append(f"- **Ours but not in Wowhead's guide:** {', '.join(extra)} (check they're real Forever bosses).")
    unnamed = [q["questID"] for q in facts["quests"] if not q.get("name")]
    if unnamed:
        out.append(f"- **Quests with no name in the guide's data:** {', '.join(map(str, unnamed))}.")
    if facts["trash"]["names"]:
        out.append(f"- **Notable trash:** {', '.join(n for n in facts['trash']['names'] if n)}.")
    if len(out) == 4:
        out.append("- Everything checked matches.")
    out.append("")
    return out


def render_quests(instances: dict[str, dict]) -> str:
    """Data/Generated/Quests.lua from guide_facts.json's instances."""
    lines = [
        "-- GENERATED FILE. Do not edit by hand.",
        "-- Built by tools/compare_guides.py from tools/wowhead/guide_facts.json: each dungeon's",
        "-- quests from Wowhead's WoW Forever dungeon guides (wowhead.com/forever).",
        "",
        "local _, AG = ...",
        "",
    ]
    for key in sorted(instances):
        quests = []
        for q in instances[key]["quests"]:
            rec = {k: q.get(k) for k in QUEST_KEYS[:-1] if q.get(k) not in (None, False, "", [])}
            if "rewards" in rec:
                rec["rewards"] = [{k: v for k, v in r.items() if v is not None} for r in rec["rewards"]]
            for k in ("x", "y"):
                if k in rec:
                    rec[k] = round(rec[k], 1)
            quests.append(rec)
        if quests:
            lines.append(f'AG:RegisterQuests("{key}", {lua_value({"quests": quests}, 0, QUEST_KEYS)})')
            lines.append("")
    return "\n".join(lines).rstrip("\n") + "\n"


def build_quests() -> None:
    facts = json.loads(FACTS.read_text(encoding="utf-8"))["instances"]
    QUESTS.write_text(render_quests(facts), encoding="utf-8", newline="\n")


def main() -> int:
    if "--quests" in sys.argv:
        build_quests()
        print(f"Rebuilt {QUESTS.relative_to(ROOT)} from {FACTS.relative_to(ROOT)}")
        return 0
    if not GUIDES.exists():
        print(f"No {GUIDES.relative_to(ROOT)} yet: run tools/wowhead/extract_guides.js first (see its header).")
        return 1
    data = json.loads(GUIDES.read_text(encoding="utf-8"))
    lua, ag = load_addon()
    ag.BuildGuides(ag)
    instances = to_py(ag.Instances)
    guides_rt = to_py(ag.Guides)
    for inst in instances:
        inst["guide"] = guides_rt.get(inst["key"], {})

    hub = {}
    facts_by_inst: dict[str, dict] = {}
    unmatched = []
    for url, guide in data["guides"].items():
        if "overview-hub" in url or "dungeons-overview-locations" in url:
            hub.update(hub_levels(guide["markup"]))
            continue
        key = match_instance(guide["title"], instances)
        if not key:
            unmatched.append(guide["title"])
            continue
        facts = parse_guide(guide)
        facts["url"] = url
        if key not in facts_by_inst or len(facts["bosses"]) > len(facts_by_inst[key]["bosses"]):
            facts_by_inst[key] = facts

    FACTS.write_text(json.dumps({
        "source": "Wowhead Forever dungeon and raid guides (facts only: IDs, names, levels)",
        "fetched": data.get("fetched"),
        "instances": {k: facts_by_inst[k] for k in sorted(facts_by_inst)},
    }, indent=1, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
    build_quests()

    report = ["# Our guide vs Wowhead's", "",
              f"Generated by `tools/compare_guides.py` from guides fetched {data.get('fetched')}.", ""]
    missing = [i["name"] for i in instances if i["key"] not in facts_by_inst]
    if missing:
        report += [f"**No Wowhead guide found for:** {', '.join(missing)}.", ""]
    if unmatched:
        report += [f"**Guides that matched no instance:** {'; '.join(unmatched)}.", ""]
    guide_by_url = data["guides"]
    for inst in instances:
        if inst["key"] in facts_by_inst:
            f = facts_by_inst[inst["key"]]
            report += compare(inst["key"], inst, guide_by_url[f["url"]], f, hub)
    REPORT.write_text("\n".join(report) + "\n", encoding="utf-8", newline="\n")

    bosses = sum(len(f["bosses"]) for f in facts_by_inst.values())
    quests = sum(len(f["quests"]) for f in facts_by_inst.values())
    print(f"{len(facts_by_inst)} of {len(instances)} instances have a Wowhead guide: "
          f"{bosses} bosses, {quests} quests. Wrote {FACTS.relative_to(ROOT)}, "
          f"{QUESTS.relative_to(ROOT)}, and {REPORT.relative_to(ROOT)}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
