"""Merge new guide writing into Data/Content/<instance>.lua.

Usage:  python tools/apply_writing.py writing.json [more.json ...]

Each JSON file maps instance keys to text:

    {
      "deadmines": {
        "intro": "...", "lore": "...", "route": "...", "tips": ["...", "..."],
        "bosses": {
          "Edwin VanCleef": {
            "overview": "...", "lore": "...",
            "strategy": {"summary": "...", "tank": "...", "healer": "...", "dps": "..."}
          }
        }
      }
    }

Fields given replace the existing ones; fields left out are kept. Bosses match by name
(or alsoNamed) ignoring case and punctuation; unknown bosses are added. The JSON is input
only. The content files remain the single source of truth, so don't commit the drafts.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from addon_env import ADDON_DIR, load_addon, to_py  # noqa: E402
from lua_writer import lua_value  # noqa: E402

CONTENT_DIR = ADDON_DIR / "Data" / "Content"
# One order serves both levels: an instance reads intro, lore, route, tips, bosses; a boss
# reads name, optional, alsoNamed, npcID, displayID, overview, lore, strategy, abilities, loot.
KEY_ORDER = ["intro", "name", "optional", "alsoNamed", "npcID", "displayID", "overview", "lore",
             "route", "tips", "strategy", "summary", "tank", "healer", "dps", "abilities",
             "alerts", "text", "spellID", "loot", "itemID", "slot", "bosses"]
INSTANCE_FIELDS = ("intro", "lore", "route", "tips")
BOSS_FIELDS = ("overview", "lore", "strategy", "optional")


def normalize(name: str) -> str:
    return re.sub(r"[^a-z0-9]", "", re.sub(r"^the ", "", name.lower()))


def find_boss(bosses: list[dict], name: str) -> dict | None:
    target = normalize(name)
    for b in bosses:
        if normalize(b["name"]) == target or target in {normalize(n) for n in b.get("alsoNamed") or []}:
            return b
    return None


def write_content(inst: dict, content: dict) -> None:
    path = CONTENT_DIR / f"{inst['key']}.lua"
    body = lua_value(content, 0, KEY_ORDER)
    path.write_text(
        f"-- {inst['name']}: hand-written guide text.\n"
        f"-- NPC IDs and loot come from Data/Generated; see Data/Registry.lua for how they merge.\n"
        f"\nlocal _, AG = ...\n\nAG:RegisterContent(\"{inst['key']}\", {body})\n",
        encoding="utf-8", newline="\n")


def main(paths: list[str]) -> int:
    _, ag = load_addon(re.compile(r"^Data/(Instances|Registry|Content/)"))
    instances = {i["key"]: i for i in to_py(ag.Instances)}
    content = to_py(ag.Content)

    for path in paths:
        writing = json.loads(Path(path).read_text(encoding="utf-8"))
        for key, text in writing.items():
            if key not in instances:
                raise SystemExit(f"{path}: unknown instance {key!r}")
            entry = content.setdefault(key, {"bosses": []})
            entry.setdefault("bosses", [])
            for field in INSTANCE_FIELDS:
                if field in text:
                    entry[field] = text[field]
            added = 0
            for boss_name, boss_text in text.get("bosses", {}).items():
                boss = find_boss(entry["bosses"], boss_name)
                if boss is None:
                    boss = {"name": boss_name}
                    entry["bosses"].append(boss)
                    added += 1
                for field in BOSS_FIELDS:
                    if field in boss_text:
                        boss[field] = boss_text[field]
            write_content(instances[key], entry)
            print(f"{key:16} {len(text.get('bosses', {})):2} bosses written ({added} new)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
