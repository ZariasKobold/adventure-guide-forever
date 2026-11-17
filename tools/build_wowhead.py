"""Build AdventureGuideForever/Data/Generated/Wowhead.lua from tools/wowhead/snapshot.json.

Usage:  python tools/build_wowhead.py

The snapshot comes from tools/wowhead/extract.js. Everything that needs judgment (which
zone is which instance, which wing a boss belongs to, which NPCs are trash, which NPCs
form one encounter) lives in the tables below, so it can be reviewed in one place.
"""

from __future__ import annotations

import json
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lua_writer import lua_value  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
SNAPSHOT = ROOT / "tools" / "wowhead" / "snapshot.json"
NPC_DATA = ROOT / "tools" / "wowhead" / "npcs.json"          # optional, from extract_npcs.js
NPC_EXTRACTOR = ROOT / "tools" / "wowhead" / "extract_npcs.js"
OUTPUT = ROOT / "AdventureGuideForever" / "Data" / "Generated" / "Wowhead.lua"

# Spells every creature has; not worth listing as boss abilities.
NOISE_SPELLS = {"Dazed", "Attack", "Auto Shot", "Shoot", "Throw", "Shoot Bow", "Shoot Gun",
                "Shoot Crossbow", "Generic Bonus Damage", "Stealth Detection"}

# ---------------------------------------------------------------------------
# Instance mapping
# ---------------------------------------------------------------------------

# Single-instance zones: Wowhead zone ID -> instance key (Data/Instances.lua).
ZONE_TO_INSTANCE = {
    16919: "hallofthanes", 2437: "ragefire", 16611: "ruinslordaeron", 1581: "deadmines",
    718: "wailing", 209: "shadowfang", 16732: "excavation", 719: "blackfathom",
    717: "stockade", 491: "razorfenkraul", 721: "gnomeregan", 16550: "drownedcity",
    722: "razorfendowns", 1337: "uldaman", 1176: "zulfarrak", 16620: "alcaz",
    2100: "maraudon", 1477: "sunkentemple", 1584: "brd", 16554: "blackmaw",
    2057: "scholomance", 2017: "stratholme",
}

# Zones Wowhead files as one zone but the guide splits into wings: NPC ID -> instance key.
WINGS = {
    796: {  # Scarlet Monastery
        3983: "smgraveyard", 4543: "smgraveyard", 6488: "smgraveyard", 6489: "smgraveyard",
        6490: "smgraveyard",
        3974: "smlibrary", 6487: "smlibrary",
        3975: "smarmory",
        4542: "smcathedral", 3976: "smcathedral", 3977: "smcathedral",
    },
    2557: {  # Dire Maul
        14354: "dmeast", 11490: "dmeast", 13280: "dmeast", 14327: "dmeast", 11492: "dmeast",
        16097: "dmeast",
        11489: "dmwest", 11488: "dmwest", 11487: "dmwest", 11496: "dmwest", 11486: "dmwest",
        11467: "dmwest", 14506: "dmwest", 14349: "dmwest",
        14326: "dmnorth", 14322: "dmnorth", 14321: "dmnorth", 14323: "dmnorth",
        14325: "dmnorth", 14324: "dmnorth", 11501: "dmnorth",
    },
    1583: {  # Blackrock Spire
        9196: "lbrs", 9236: "lbrs", 9237: "lbrs", 10596: "lbrs", 10584: "lbrs", 9736: "lbrs",
        10220: "lbrs", 10268: "lbrs", 9568: "lbrs", 9596: "lbrs", 9718: "lbrs", 9217: "lbrs",
        9218: "lbrs", 9219: "lbrs", 10376: "lbrs", 10263: "lbrs",
        9816: "ubrs", 10264: "ubrs", 10429: "ubrs", 10339: "ubrs", 10430: "ubrs",
        10363: "ubrs", 10509: "ubrs", 10899: "ubrs", 16042: "ubrs", 16080: "ubrs",
    },
}

# Drop sources that are trash or event adds, not bosses.
TRASH = {4301, 5259, 5708, 8920, 10318, 10391, 10422, 10426, 10469, 10499, 11459, 14308}

# NPCs that make up one encounter: member NPC ID -> (lead NPC ID, encounter name).
ENCOUNTER_GROUPS = {
    642: (642, "Sneed's Shredder"), 643: (642, "Sneed's Shredder"),
    6906: (6906, "The Lost Dwarves"), 6907: (6906, "The Lost Dwarves"),
    6908: (6906, "The Lost Dwarves"),
    7267: (7267, "Chief Ukorz Sandscalp"), 7797: (7267, "Chief Ukorz Sandscalp"),
    9027: (9027, "Ring of Law"), 9028: (9027, "Ring of Law"), 9029: (9027, "Ring of Law"),
    9030: (9027, "Ring of Law"), 9031: (9027, "Ring of Law"), 9032: (9027, "Ring of Law"),
    10429: (10429, "Warchief Rend Blackhand"), 10339: (10429, "Warchief Rend Blackhand"),
    10813: (10813, "Balnazzar"), 10812: (10813, "Balnazzar"),
}

# Rares, summons, and side bosses: shown as "(optional)".
OPTIONAL = {
    3586, 5912, 1720, 4425, 4842, 7354, 7356, 6488, 6489, 6490, 6228, 4542, 10080, 10081,
    10082, 7273, 8443, 12876, 12902, 8923, 9217, 9218, 9219, 9596, 9718, 10263, 10376,
    10509, 10899, 16042, 16080, 10393, 10809, 10558, 11143, 11032, 11058, 11120, 11121,
    14516, 16118, 11467, 14349, 14506, 16097, 255699, 260468, 264172, 264177, 269104,
    269111, 250034,
}

# ---------------------------------------------------------------------------
# Item labels
# ---------------------------------------------------------------------------

INVENTORY_SLOT = {
    1: "Head", 2: "Neck", 3: "Shoulder", 4: "Shirt", 5: "Chest", 6: "Waist", 7: "Legs",
    8: "Feet", 9: "Wrist", 10: "Hands", 11: "Finger", 12: "Trinket", 13: "One-Hand",
    14: "Off Hand", 15: "Ranged", 16: "Back", 17: "Two-Hand", 18: "Bag", 19: "Tabard",
    20: "Chest", 21: "Main Hand", 22: "Off Hand", 23: "Held In Off-hand", 24: "Ammo",
    25: "Thrown", 26: "Ranged", 28: "Relic",
}
ARMOR_TYPE = {1: "Cloth", 2: "Leather", 3: "Mail", 4: "Plate"}
ARMOR_SPECIAL = {6: "Shield", 7: "Libram", 8: "Idol", 9: "Totem"}
WEAPON_TYPE = {
    0: "Axe", 1: "Axe", 2: "Bow", 3: "Gun", 4: "Mace", 5: "Mace", 6: "Polearm", 7: "Sword",
    8: "Sword", 10: "Staff", 13: "Fist Weapon", 15: "Dagger", 16: "Thrown", 18: "Crossbow",
    19: "Wand", 20: "Fishing Pole",
}
TWO_HANDED = {1, 5, 8}
STANDALONE_WEAPONS = {2, 3, 6, 10, 16, 18, 19, 20}
CLASS_LABEL = {0: "Consumable", 1: "Bag", 6: "Ammo", 9: "Recipe", 11: "Quiver", 15: "Miscellaneous"}
EXCLUDED_CLASSES = {12, 13}  # quest items, keys

ITEM_CLASS_WEAPON, ITEM_CLASS_ARMOR = 2, 4


def item_label(inv_type: int, item_class: int, subclass: int) -> str:
    slot = INVENTORY_SLOT.get(inv_type, "")
    if item_class == ITEM_CLASS_ARMOR:
        if subclass in ARMOR_TYPE:
            return f"{ARMOR_TYPE[subclass]} {slot}".strip()
        return ARMOR_SPECIAL.get(subclass, slot or "Armor")
    if item_class == ITEM_CLASS_WEAPON:
        kind = WEAPON_TYPE.get(subclass, "Weapon")
        if subclass in TWO_HANDED:
            return f"Two-Hand {kind}"
        if subclass in STANDALONE_WEAPONS:
            return kind
        return f"{slot} {kind}".strip()
    return CLASS_LABEL.get(item_class, "Miscellaneous")


# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

def instance_for(zone_id: int, npc_id: int) -> str | None:
    if zone_id in WINGS:
        return WINGS[zone_id].get(npc_id)
    return ZONE_TO_INSTANCE.get(zone_id)


def build(snapshot: dict) -> tuple[dict, list[str]]:
    """Returns ({instKey: {"bosses": [...]}}, warnings)."""
    names = {int(k): v for k, v in snapshot["npcNames"].items()}
    instances: dict[str, dict[int, dict]] = defaultdict(dict)
    warnings: list[str] = []
    seen_items: set[tuple[str, int]] = set()

    for zone_id_str, zone in snapshot["zones"].items():
        zone_id = int(zone_id_str)
        if zone_id not in ZONE_TO_INSTANCE and zone_id not in WINGS:
            continue  # duplicate or empty zone listing
        for item_id, name, quality, inv_type, item_class, subclass, _req, npc_id in zone["drops"]:
            if npc_id in TRASH or item_class in EXCLUDED_CLASSES:
                continue
            inst = instance_for(zone_id, npc_id)
            if not inst:
                warnings.append(f"zone {zone_id}: no wing for NPC {npc_id} {names.get(npc_id)!r}")
                continue
            lead, boss_name = ENCOUNTER_GROUPS.get(npc_id, (npc_id, names[npc_id]))
            boss = instances[inst].setdefault(lead, {
                "npcID": lead, "name": boss_name, "optional": lead in OPTIONAL or None,
                "loot": [], "_minLevel": 999, "_members": [],
            })
            if npc_id not in boss["_members"]:
                boss["_members"].append(npc_id)
            if (inst, item_id) in seen_items:
                continue  # some items list several sources; first boss wins
            seen_items.add((inst, item_id))
            boss["loot"].append({
                "itemID": item_id, "name": name, "quality": quality,
                "slot": item_label(inv_type, item_class, subclass),
            })
            if _req:
                boss["_minLevel"] = min(boss["_minLevel"], _req)

    out = {}
    for inst, bosses in instances.items():
        ordered = sorted(bosses.values(), key=lambda b: (b["_minLevel"], b["name"]))
        for b in ordered:
            del b["_minLevel"]
            b["loot"].sort(key=lambda i: (-i["quality"], i["slot"] == "Recipe", i["name"]))
        out[inst] = {"bosses": ordered}
    return dict(sorted(out.items())), sorted(set(warnings))


def all_boss_npc_ids(data: dict) -> list[int]:
    """Every NPC that makes up a boss encounter, for the NPC extractor to read."""
    return sorted({npc for inst in data.values() for b in inst["bosses"] for npc in b["_members"]})


def apply_npc_data(data: dict, npcs: dict) -> int:
    """Adds display IDs and abilities from npcs.json. Returns how many bosses it enriched.

    For multi-NPC encounters the lead NPC's model is used, and the abilities of every
    member are listed together (each spell once).
    """
    enriched = 0
    for inst in data.values():
        for boss in inst["bosses"]:
            records = [npcs[str(m)] for m in boss["_members"] if str(m) in npcs]
            if not records:
                continue
            enriched += 1
            lead = npcs.get(str(boss["npcID"]), {})
            display = lead.get("displayID") or next((r["displayID"] for r in records if r.get("displayID")), 0)
            boss["displayID"] = display or None
            abilities, seen = [], set()
            for record in records:
                for spell_id, name in record.get("abilities", []):
                    if name in NOISE_SPELLS or spell_id in seen or name in {a["name"] for a in abilities}:
                        continue
                    seen.add(spell_id)
                    abilities.append({"spellID": spell_id, "name": name})
            boss["abilities"] = abilities or None
    return enriched


def strip_internal(data: dict) -> None:
    for inst in data.values():
        for boss in inst["bosses"]:
            boss.pop("_members", None)


def write_npc_id_list(ids: list[int]) -> None:
    """Keeps the NPC list inside extract_npcs.js in step with the current snapshot."""
    text = NPC_EXTRACTOR.read_text(encoding="utf-8")
    begin = text.index("// BEGIN NPC_IDS")
    begin = text.index("\n", begin) + 1
    end = text.index("// END NPC_IDS")
    rows = [", ".join(str(i) for i in ids[n:n + 12]) for n in range(0, len(ids), 12)]
    block = "const NPC_IDS = [\n" + "".join(f"  {r},\n" for r in rows) + "];\n"
    NPC_EXTRACTOR.write_text(text[:begin] + block + text[end:], encoding="utf-8", newline="\n")


BOSS_KEYS = ["npcID", "name", "displayID", "optional", "abilities", "loot"]
ITEM_KEYS = ["itemID", "name", "quality", "slot"]


ABILITY_KEYS = ["spellID", "name"]


def render(data: dict, snapshot: dict, npc_meta: dict | None) -> str:
    lines = [
        "-- GENERATED FILE. Do not edit by hand.",
        "-- Built by tools/build_wowhead.py from tools/wowhead/snapshot.json"
        + (" and npcs.json" if npc_meta else ""),
        f"-- Loot and NPC IDs: {snapshot['source']}, fetched {snapshot['fetched']}.",
    ]
    if npc_meta:
        lines.append(f"-- Abilities and models: {npc_meta['source']}, fetched {npc_meta['fetched']}.")
    lines += [
        "-- Hand-written guide text lives in Data/Content.",
        "",
        "local _, AG = ...",
        "",
    ]
    for inst, payload in data.items():
        body = lua_value(payload, 0, BOSS_KEYS + ITEM_KEYS + ABILITY_KEYS + ["bosses"])
        lines.append(f'AG:RegisterGenerated("{inst}", {body})')
        lines.append("")
    return "\n".join(lines)


def main() -> int:
    snapshot = json.loads(SNAPSHOT.read_text(encoding="utf-8"))
    data, warnings = build(snapshot)

    npc_ids = all_boss_npc_ids(data)
    write_npc_id_list(npc_ids)
    npc_meta = None
    if NPC_DATA.exists():
        npc_meta = json.loads(NPC_DATA.read_text(encoding="utf-8"))
        enriched = apply_npc_data(data, npc_meta["npcs"])
        missing = [i for i in npc_ids if str(i) not in npc_meta["npcs"]]
        print(f"npcs.json: abilities/models for {enriched} bosses; {len(missing)} NPCs not read yet")
        for npc_id, record in sorted(npc_meta["npcs"].items(), key=lambda kv: int(kv[0])):
            if record.get("error"):
                print(f"  warning: NPC {npc_id} abilities unreadable: {record['error']}")
    strip_internal(data)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(render(data, snapshot, npc_meta), encoding="utf-8", newline="\n")
    bosses = sum(len(v["bosses"]) for v in data.values())
    items = sum(len(b["loot"]) for v in data.values() for b in v["bosses"])
    print(f"Wrote {OUTPUT.relative_to(ROOT)}: {len(data)} instances, {bosses} bosses, {items} items")
    print(f"Updated {NPC_EXTRACTOR.relative_to(ROOT)} with {len(npc_ids)} NPC IDs")
    for w in warnings:
        print("  warning:", w)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
