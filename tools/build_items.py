"""Item levels and stats for every item the guide lists, for gear search and suggestions.

    python tools/build_items.py

1. Collects every item ID the built guide knows (boss loot and quest rewards) and writes
   them, grouped into ID ranges, into tools/wowhead/extract_items.js.
2. If tools/wowhead/items.json exists (run extract_items.js in a browser to make it),
   writes AdventureGuideForever/Data/Generated/Items.lua: each item's item level, required
   level, class restriction, armor, weapon damage, and stats.

Item stats are game data (numbers), so items.json and Items.lua are committed.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from addon_env import ROOT, load_addon, to_py  # noqa: E402
from lua_writer import lua_value  # noqa: E402

EXTRACTOR = ROOT / "tools" / "wowhead" / "extract_items.js"
ITEMS_JSON = ROOT / "tools" / "wowhead" / "items.json"
OUTPUT = ROOT / "AdventureGuideForever" / "Data" / "Generated" / "Items.lua"
RANGE_SPAN = 900  # IDs per page, safely under Wowhead's 1,000-item list limit

# Wowhead listview fields -> our names. Everything else numeric is a stat.
META = {"level": "itemLevel", "reqlevel": "reqLevel", "classs": "class", "subclass": "subclass",
        "slot": "slot", "armor": "armor", "dps": "dps", "speed": "speed", "reqclass": "classes",
        "quality": "quality"}
IGNORE = {"id", "name", "slotbak", "classes", "nsockets", "dura", "maxcount", "reqskill",
          "reqskillrank", "reqrep", "reqfaction", "side", "nslots", "dmgtype1", "dmgmin1",
          "dmgmax1", "mledmgmin", "mledmgmax", "mlespeed", "mledps", "rgddmgmin", "rgddmgmax",
          "rgdspeed", "rgddps", "dmgrange", "races", "reqrace", "itemset", "bonding", "durability",
          # prices, flags, and situational bonuses that don't decide what to wear
          "buyprice", "avgbuyout", "flags5", "reqspell", "sheathtype", "skill", "subsubclass",
          "health", "atkpwrvsbeast", "atkpwrvsdemon", "atkpwrvsdragonkin", "atkpwrvselemental",
          "atkpwrvshumanoid", "atkpwrvsundead", "spldmgvsdragonkin", "spldmgvselemental",
          "spldmgvsundead"}
# Wowhead's stat keys -> our short names (what Data/Generated/Items.lua uses).
STATS = {"str": "str", "agi": "agi", "sta": "sta", "int": "int", "spi": "spi",
         "atkpwr": "ap", "rgdatkpwr": "rap", "feratkpwr": "feral", "splpwr": "sp", "healpwr": "heal",
         "spldmg": "sp", "critstrkrtng": "crit", "hitrtng": "hit", "hastertng": "haste",
         "defrtng": "def", "dodgertng": "dodge", "parryrtng": "parry", "blockrtng": "block",
         "block": "blockValue", "manargn": "mp5", "healthrgn": "hp5", "splpen": "spellPen",
         "firres": "fireRes", "frores": "frostRes", "natres": "natureRes", "shares": "shadowRes",
         "arcres": "arcaneRes", "holres": "holyRes", "armorbonus": "bonusArmor",
         "splheal": "heal", "blockamount": "blockValue", "exprtng": "expertise",
         "mlecritstrkpct": "critPct", "rgdcritstrkpct": "rangedCritPct", "splcritstrkpct": "spellCritPct",
         "mlehitpct": "hitPct", "rgdhitpct": "rangedHitPct", "rgdhastepct": "rangedHastePct",
         "firsplpwr": "fireSp", "frosplpwr": "frostSp", "natsplpwr": "natureSp",
         "shasplpwr": "shadowSp", "arcsplpwr": "arcaneSp", "holsplpwr": "holySp",
         "skilldaggers": "daggerSkill", "skillunarmed": "unarmedSkill", "skillferalcombat": "feralSkill"}
ITEM_KEYS = ["itemID", "itemLevel", "reqLevel", "quality", "class", "subclass", "slot", "classes",
             "armor", "dps", "speed", "stats", "items"]


def guide_item_ids() -> list[int]:
    _, ag = load_addon()
    ag.BuildGuides(ag)
    ids = set()
    for guide in to_py(ag.Guides).values():
        for boss in guide.get("bosses") or []:
            for item in boss.get("loot") or []:
                if item.get("itemID"):
                    ids.add(item["itemID"])
    for quests in to_py(ag.Quests).values():
        for q in quests or []:
            for r in q.get("rewards") or []:
                ids.add(r["itemID"])
    return sorted(ids)


def id_ranges(ids: list[int], span: int = RANGE_SPAN) -> list[list[int]]:
    ranges: list[list[int]] = []
    for i in ids:
        if ranges and i - ranges[-1][0] <= span:
            ranges[-1][1] = i
        else:
            ranges.append([i, i])
    return ranges


def write_extractor(ids: list[int]) -> None:
    text = EXTRACTOR.read_text(encoding="utf-8")
    begin = text.index("\n", text.index("// BEGIN ITEM_RANGES")) + 1
    end = text.index("// END ITEM_RANGES")
    ranges = id_ranges(ids)
    rrows = [", ".join(f"[{a}, {b}]" for a, b in ranges[n:n + 6]) for n in range(0, len(ranges), 6)]
    irows = [", ".join(str(i) for i in ids[n:n + 12]) for n in range(0, len(ids), 12)]
    block = ("const ITEM_RANGES = [\n" + "".join(f"  {r},\n" for r in rrows) + "];\n"
             + "const ITEM_IDS = [\n" + "".join(f"  {r},\n" for r in irows) + "];\n")
    EXTRACTOR.write_text(text[:begin] + block + text[end:], encoding="utf-8", newline="\n")


def item_record(item_id: int, raw: dict) -> dict:
    rec: dict = {"itemID": item_id}
    stats: dict[str, float] = {}
    for key, value in raw.items():
        if key in META:
            if value not in (None, 0, ""):
                rec[META[key]] = value
        elif key in STATS and isinstance(value, (int, float)) and value:
            name = STATS[key]
            stats[name] = stats.get(name, 0) + value
    if "dps" in rec:
        rec["dps"] = round(rec["dps"], 1)
    if stats:
        rec["stats"] = dict(sorted(stats.items()))
    return rec


def render(items: dict, ids: list[int]) -> str:
    records = [item_record(i, items[str(i)]) for i in ids if str(i) in items]
    return ("-- GENERATED FILE. Do not edit by hand.\n"
            "-- Built by tools/build_items.py from tools/wowhead/items.json: item level, required\n"
            "-- level, armor, damage, and stats for every item the guide lists, from Wowhead's\n"
            "-- WoW Forever database (wowhead.com/forever). Stat names: see AG.STAT_LABELS.\n"
            "\nlocal _, AG = ...\n\n"
            f"AG:RegisterItems({lua_value({'items': records}, 0, ITEM_KEYS)})\n")


def main() -> int:
    ids = guide_item_ids()
    write_extractor(ids)
    print(f"{len(ids)} items in {len(id_ranges(ids))} ID ranges -> {EXTRACTOR.relative_to(ROOT)}")
    if not ITEMS_JSON.exists():
        print(f"No {ITEMS_JSON.relative_to(ROOT)} yet: run extract_items.js in a browser (see its header).")
        return 0
    data = json.loads(ITEMS_JSON.read_text(encoding="utf-8"))
    OUTPUT.write_text(render(data["items"], ids), encoding="utf-8", newline="\n")
    found = sum(1 for i in ids if str(i) in data["items"])
    print(f"Wrote {OUTPUT.relative_to(ROOT)}: {found} of {len(ids)} items have Wowhead data.")
    unknown = sorted({k for rec in data["items"].values() for k, v in rec.items()
                      if isinstance(v, (int, float)) and k not in META and k not in STATS and k not in IGNORE})
    if unknown:
        print("Fields not used (add to STATS or IGNORE):", ", ".join(unknown))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
