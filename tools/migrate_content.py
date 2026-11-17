"""One-time migration: legacy Data/Guides/*.lua  ->  Data/Content/<instance>.lua.

The legacy files mixed hand-written text with guessed Classic IDs and loot. This splits
out only the hand-written parts, in the standard content format, and drops anything the
generated Wowhead data now supplies (NPC IDs and loot for bosses Wowhead covers).

Usage:  python tools/migrate_content.py     (run once; kept for the record)
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from addon_env import ADDON_DIR, load_addon, to_py  # noqa: E402
from lua_writer import lua_value  # noqa: E402

CONTENT_DIR = ADDON_DIR / "Data" / "Content"
GENERATED = ADDON_DIR / "Data" / "Generated" / "Wowhead.lua"

CONTENT_KEYS = ["intro", "bosses", "name", "optional", "alsoNamed", "npcID", "displayID",
                "overview", "abilities", "alerts", "text", "spellID", "loot", "itemID", "slot"]


def normalize(name: str) -> str:
    name = name.lower()
    name = re.sub(r"^the ", "", name)
    return re.sub(r"[^a-z0-9]", "", name)


def load_generated(lua) -> dict:
    collected = lua.table()
    lua.globals()["__collected"] = collected
    lua.execute("function __register(_, key, data) __collected[key] = data end")
    ns = lua.eval("{ RegisterGenerated = __register }")
    chunk = lua.eval("function(src) return assert(loadstring(src, '@Wowhead.lua')) end")(
        GENERATED.read_text(encoding="utf-8"))
    chunk("AdventureGuideForever", ns)
    return to_py(collected)


def match_generated(boss: dict, gen_bosses: list[dict]) -> dict | None:
    names = {normalize(boss["name"])} | {normalize(n) for n in boss.get("alsoNamed") or []}
    for gb in gen_bosses:
        if normalize(gb["name"]) in names:
            return gb
    for gb in gen_bosses:  # Forever renamed it: same NPC, new name
        if boss.get("npcID") and gb["npcID"] == boss["npcID"]:
            return gb
    return None


def migrate_boss(boss: dict, gen: dict | None, report: list[str]) -> dict:
    out = {"name": boss["name"], "optional": boss.get("optional"),
           "alsoNamed": boss.get("alsoNamed") or None, "overview": boss.get("overview")}
    if gen and normalize(gen["name"]) != normalize(boss["name"]) and not any(
            normalize(gen["name"]) == normalize(n) for n in boss.get("alsoNamed") or []):
        report.append(f"renamed {boss['name']!r} -> {gen['name']!r} (same NPC {gen['npcID']})")
        out["name"] = gen["name"]
    abilities = [
        {"name": a["name"], "alerts": a.get("alerts") or None, "text": a.get("text"),
         "spellID": a.get("spellID")}
        for a in boss.get("abilities") or []
    ]
    out["abilities"] = abilities or None
    if not gen:
        out["npcID"] = boss.get("npcID")
        out["displayID"] = boss.get("displayID")
    if not (gen and gen.get("loot")):
        loot = [{"name": i["name"], "itemID": i.get("itemID"), "slot": i.get("slot")}
                for i in boss.get("loot") or []]
        out["loot"] = loot or None
    return out


def write_content(inst: dict, guide: dict) -> Path:
    path = CONTENT_DIR / f"{inst['key']}.lua"
    body = lua_value(guide, 0, CONTENT_KEYS)
    path.write_text(
        f"-- {inst['name']}: hand-written guide text.\n"
        f"-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.\n"
        f"\nlocal _, AG = ...\n\nAG:RegisterContent(\"{inst['key']}\", {body})\n",
        encoding="utf-8", newline="\n")
    return path


def main() -> int:
    lua, ag = load_addon(re.compile(r"^Data/(Instances|Guides/)"))
    instances, legacy = to_py(ag.Instances), to_py(ag.Guides)
    generated = load_generated(lua)
    CONTENT_DIR.mkdir(parents=True, exist_ok=True)

    report: list[str] = []
    for inst in instances:
        guide = legacy.get(inst["key"])
        if not guide:
            continue
        gen_bosses = generated.get(inst["key"], {}).get("bosses", [])
        bosses = [migrate_boss(b, match_generated(b, gen_bosses), report) for b in guide["bosses"]]
        write_content(inst, {"intro": guide.get("intro"), "bosses": bosses})
    print(f"Wrote {len(list(CONTENT_DIR.glob('*.lua')))} content files to {CONTENT_DIR}")
    for line in report:
        print("  " + line)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
