"""Tests for the addon's data and merge logic, run in a real Lua 5.1 runtime.

Usage:  python -m unittest tools/test_addon.py -v
        python tools/test_addon.py --report      (coverage report, no assertions)
"""

from __future__ import annotations

import json
import re
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from addon_env import ADDON_DIR, TOC, load_addon, to_py, toc_files  # noqa: E402

# Instances with no published data anywhere yet; learning mode builds these from play.
KNOWN_EMPTY: set[str] = set()

VALID_ALERTS = {"tank", "healer", "dps", "deadly", "important", "interrupt", "magic",
                "curse", "poison", "disease", "enrage"}


def load_built():
    lua, ag = load_addon()
    ag.BuildGuides(ag)
    return lua, ag


class TocTests(unittest.TestCase):
    def test_every_listed_file_exists(self):
        missing = [str(p) for p in toc_files() if not p.exists()]
        self.assertEqual(missing, [])

    def test_every_data_file_is_listed(self):
        listed = {p.resolve() for p in toc_files()}
        on_disk = set((ADDON_DIR / "Data").rglob("*.lua"))
        self.assertEqual(sorted(str(p) for p in on_disk - listed), [])

    def test_fallback_toc_matches(self):
        fallback = ADDON_DIR / "AdventureGuideForever.toc"
        self.assertEqual(toc_files(fallback), toc_files(TOC))


class DataTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.lua, cls.ag = load_built()
        cls.instances = to_py(cls.ag.Instances)
        cls.guides = to_py(cls.ag.Guides)
        cls.alert_keys = set(to_py(cls.ag.UI.ALERTS).keys())

    def test_alert_list_matches_ui(self):
        self.assertEqual(self.alert_keys, VALID_ALERTS)

    def test_instance_keys_unique(self):
        keys = [i["key"] for i in self.instances]
        self.assertEqual(len(keys), len(set(keys)))

    def test_every_instance_has_a_guide(self):
        missing = {i["key"] for i in self.instances if i["key"] not in self.guides}
        self.assertEqual(missing, KNOWN_EMPTY)

    def test_boss_keys_unique_within_instance(self):
        for inst, guide in self.guides.items():
            keys = [b["key"] for b in guide["bosses"]]
            dupes = {k for k in keys if keys.count(k) > 1}
            self.assertFalse(dupes, f"{inst}: duplicate boss keys {dupes}")

    def test_bosses_well_formed(self):
        for inst, guide in self.guides.items():
            for boss in guide["bosses"]:
                where = f"{inst}/{boss.get('name')}"
                self.assertTrue(boss.get("name"), where)
                self.assertTrue(boss.get("key"), where)
                if "npcID" in boss:
                    self.assertIsInstance(boss["npcID"], int, where)
                for ab in boss.get("abilities") or []:
                    self.assertTrue(ab.get("name"), where)
                    unknown = set(ab.get("alerts") or []) - VALID_ALERTS
                    self.assertFalse(unknown, f"{where}: unknown alerts {unknown}")

    def test_loot_well_formed(self):
        for inst, guide in self.guides.items():
            for boss in guide["bosses"]:
                ids = []
                for item in boss.get("loot") or []:
                    where = f"{inst}/{boss['name']}/{item.get('name')}"
                    self.assertTrue(item.get("name"), where)
                    self.assertTrue(item.get("slot"), where)
                    if item.get("itemID") is not None:
                        self.assertIsInstance(item["itemID"], int, where)
                        self.assertGreater(item["itemID"], 0, where)
                        ids.append(item["itemID"])
                self.assertEqual(len(ids), len(set(ids)), f"{inst}/{boss['name']}: duplicate items")


class ContentTests(unittest.TestCase):
    """Shape of the hand-written guide text and the art table."""

    STRATEGY_KEYS = {"summary", "tank", "healer", "dps"}

    @classmethod
    def setUpClass(cls):
        cls.lua, cls.ag = load_built()
        cls.guides = to_py(cls.ag.Guides)
        cls.keys = {i["key"] for i in to_py(cls.ag.Instances)}

    def test_art_keys_are_instances(self):
        art_keys = set(to_py(self.ag.Art).keys())
        self.assertEqual(art_keys - self.keys, set())

    def test_art_ids_are_numbers(self):
        for key, art in to_py(self.ag.Art).items():
            for kind, file_id in art.items():
                self.assertIsInstance(file_id, int, f"{key}.{kind}")

    def test_instance_text_fields(self):
        for key, g in self.guides.items():
            for field in ("intro", "lore", "route"):
                if field in g:
                    self.assertIsInstance(g[field], str, f"{key}.{field}")
            for tip in g.get("tips") or []:
                self.assertIsInstance(tip, str, f"{key}.tips")

    def test_boss_strategy_shape(self):
        for key, g in self.guides.items():
            for b in g["bosses"]:
                s = b.get("strategy")
                if s is None:
                    continue
                where = f"{key}/{b['name']}"
                self.assertIsInstance(s, dict, where)
                self.assertFalse(set(s) - self.STRATEGY_KEYS, f"{where}: unknown strategy keys")
                for v in s.values():
                    self.assertIsInstance(v, str, where)


class RegistryTests(unittest.TestCase):
    """The merge rules documented in Data/Registry.lua, on small fixtures."""

    def setUp(self):
        import re
        self.lua, self.ag = load_addon(re.compile(r"^Data/(Instances|Registry)\.lua$"))
        self.ag.Content = self.lua.table()
        self.ag.Generated = self.lua.table()

    def register(self, kind, key, py):
        self.lua.globals()["__fixture"] = py
        table = self.lua.eval(f"(function() return {py} end)()")
        getattr(self.ag, f"Register{kind}")(self.ag, key, table)

    def build(self, key):
        self.ag.BuildGuides(self.ag)
        return to_py(self.ag.Guides[key])

    def test_content_and_generated_merge_by_name(self):
        self.register("Content", "deadmines", """{ intro = "Intro.", bosses = {
            { name = "Edwin VanCleef", overview = "Boss text.",
              abilities = { { name = "Thrash", alerts = { "tank" }, text = "Hits." } } } } }""")
        self.register("Generated", "deadmines", """{ bosses = {
            { npcID = 639, name = "Edwin VanCleef",
              abilities = { { spellID = 3391, name = "Thrash" }, { spellID = 99, name = "Extra" } },
              loot = { { itemID = 5191, name = "Cruel Barb", quality = 3, slot = "Sword" } } } } }""")
        guide = self.build("deadmines")
        boss = guide["bosses"][0]
        self.assertEqual(guide["intro"], "Intro.")
        self.assertEqual(boss["npcID"], 639)
        self.assertEqual(boss["overview"], "Boss text.")
        self.assertEqual(boss["abilities"][0]["spellID"], 3391)   # matched by name
        self.assertEqual(boss["abilities"][0]["alerts"], ["tank"])
        self.assertEqual(boss["abilities"][1]["name"], "Extra")   # generated-only appended
        self.assertEqual(boss["loot"][0]["itemID"], 5191)

    def test_generated_loot_replaces_content_loot(self):
        self.register("Content", "deadmines", """{ bosses = { { name = "Cookie",
            loot = { { name = "Old Classic Item", slot = "Wand" } } } } }""")
        self.register("Generated", "deadmines", """{ bosses = { { npcID = 645, name = "Cookie",
            loot = { { itemID = 5198, name = "Cookie's Stirring Rod", quality = 3, slot = "Wand" } } } } }""")
        loot = self.build("deadmines")["bosses"][0]["loot"]
        self.assertEqual([i["name"] for i in loot], ["Cookie's Stirring Rod"])

    def test_content_loot_used_when_generated_has_none(self):
        self.register("Content", "kroldok", """{ bosses = { { name = "Overlord Mugg",
            loot = { { name = "Mugg's Jabber", slot = "Fist Weapon" } } } } }""")
        loot = self.build("kroldok")["bosses"][0]["loot"]
        self.assertEqual([i["name"] for i in loot], ["Mugg's Jabber"])

    def test_alias_match_and_generated_name_wins(self):
        self.register("Content", "stratholme", """{ bosses = { { name = "Old Name",
            alsoNamed = { "Ezra Grimm" }, overview = "Text." } } }""")
        self.register("Generated", "stratholme", """{ bosses = { { npcID = 11058, name = "Ezra Grimm" } } }""")
        boss = self.build("stratholme")["bosses"][0]
        self.assertEqual(boss["name"], "Ezra Grimm")
        self.assertEqual(boss["overview"], "Text.")
        self.assertIn("Old Name", boss["alsoNamed"])

    def test_unmatched_generated_bosses_are_appended_in_order(self):
        self.register("Content", "deadmines", """{ bosses = { { name = "A" } } }""")
        self.register("Generated", "deadmines", """{ bosses = { { npcID = 1, name = "B" }, { npcID = 2, name = "C" } } }""")
        names = [b["name"] for b in self.build("deadmines")["bosses"]]
        self.assertEqual(names, ["A", "B", "C"])

    def test_unknown_instance_is_rejected(self):
        self.register("Content", "nowhere", "{ bosses = {} }")
        with self.assertRaises(Exception):
            self.ag.BuildGuides(self.ag)


class ForeverRulesTests(unittest.TestCase):
    """Addon rules for WoW Forever (Lua 5.1 sandbox, namespaced code, secret values)."""

    # Globals the addon may create when its files load; see the list at the top of Core.lua.
    ALLOWED_GLOBALS = {"SLASH_ADVENTUREGUIDEFOREVER1", "SLASH_ADVENTUREGUIDEFOREVER2",
                       "AdventureGuideForever_OnCompartmentClick"}
    FORBIDDEN = re.compile(r"\b(require|dofile|loadfile|io\.\w+|os\.\w+|setfenv|getfenv)\s*\(")

    def test_only_intended_globals(self):
        from lupa import lua51
        from addon_env import STUBS
        lua = lua51.LuaRuntime(unpack_returned_tuples=True)
        lua.execute(STUBS)
        before = set(lua.globals().keys())
        ns = lua.table()
        for path in toc_files():
            chunk = lua.eval("function(s, n) return assert(loadstring(s, '@' .. n)) end")(
                path.read_text(encoding="utf-8"), path.name)
            chunk("AdventureGuideForever", ns)
        created = set(lua.globals().keys()) - before
        self.assertEqual(created - self.ALLOWED_GLOBALS, set())

    def test_no_sandbox_forbidden_calls(self):
        for path in toc_files():
            for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                code = line.split("--", 1)[0]
                self.assertIsNone(self.FORBIDDEN.search(code), f"{path.name}:{n}: {line.strip()}")

    def test_every_file_starts_with_namespace(self):
        for path in toc_files():
            self.assertRegex(path.read_text(encoding="utf-8"), r"(?m)^local \w+, AG = \.\.\.$",
                             path.name)

    def test_compartment_function_exists(self):
        name = re.search(r"## AddonCompartmentFunc: (\w+)", TOC.read_text(encoding="utf-8")).group(1)
        lua, _ = load_addon()
        self.assertEqual(lua.eval(f"type({name})"), "function")

    def test_secret_values_are_unreadable(self):
        lua, ag = load_addon()
        lua.execute("SECRET = {}; issecretvalue = function(v) return v == SECRET end")
        secret = lua.eval("SECRET")
        self.assertIsNone(ag.Readable(ag, secret))
        self.assertFalse(ag.IsUsable(ag, secret))
        self.assertEqual(ag.Readable(ag, 5), 5)
        self.assertFalse(ag.Readable(ag, False))   # readable false stays false, not nil
        self.assertTrue(ag.IsUsable(ag, False))


class BuildToolTests(unittest.TestCase):
    """tools/build_wowhead.py: merging npcs.json into the generated data."""

    def setUp(self):
        import build_wowhead
        self.bw = build_wowhead

    def test_npc_data_merges_group_members(self):
        data = {"stratholme": {"bosses": [
            {"npcID": 10813, "name": "Balnazzar", "loot": [], "_members": [10813, 10812]},
        ]}}
        npcs = {
            "10813": {"displayID": 1000, "abilities": [[1, "Mind Blast"], [2, "Dazed"]]},
            "10812": {"displayID": 2000, "abilities": [[3, "Psychic Scream"], [1, "Mind Blast"]]},
        }
        self.assertEqual(self.bw.apply_npc_data(data, npcs), 1)
        boss = data["stratholme"]["bosses"][0]
        self.assertEqual(boss["displayID"], 1000)                       # lead's model
        self.assertEqual([a["name"] for a in boss["abilities"]], ["Mind Blast", "Psychic Scream"])

    def test_npc_data_falls_back_to_member_model(self):
        data = {"x": {"bosses": [{"npcID": 1, "name": "A", "loot": [], "_members": [1, 2]}]}}
        self.bw.apply_npc_data(data, {"1": {"displayID": 0, "abilities": []},
                                      "2": {"displayID": 77, "abilities": []}})
        self.assertEqual(data["x"]["bosses"][0]["displayID"], 77)

    def test_drop_chances_use_best_member(self):
        boss = {"loot": [{"itemID": 5, "name": "A"}, {"itemID": 6, "name": "B"}]}
        self.bw.apply_drop_chances(boss, [
            {"drops": [[5, 10, 100]]},
            {"drops": [[5, 30, 120], [9, 1, 2]]},   # item 9 isn't in the loot table
        ])
        self.assertEqual(boss["loot"][0]["dropChance"], 25.0)
        self.assertNotIn("dropChance", boss["loot"][1])

    def test_bosses_without_npc_data_are_untouched(self):
        data = {"x": {"bosses": [{"npcID": 1, "name": "A", "loot": [], "_members": [1]}]}}
        self.assertEqual(self.bw.apply_npc_data(data, {}), 0)
        self.assertNotIn("abilities", data["x"]["bosses"][0])

    def test_extractor_id_list_is_in_sync(self):
        snapshot = json.loads(self.bw.SNAPSHOT.read_text(encoding="utf-8"))
        data, _ = self.bw.build(snapshot)
        text = self.bw.NPC_EXTRACTOR.read_text(encoding="utf-8")
        block = text[text.index("const NPC_IDS = ["):text.index("// END NPC_IDS")]
        listed = [int(n) for n in re.findall(r"\d+", block)]
        self.assertEqual(listed, self.bw.all_boss_npc_ids(data))


def report() -> None:
    """Which hand-written bosses found no Wowhead match, and which Wowhead bosses have no text."""
    _, ag = load_built()
    content, generated = to_py(ag.Content), to_py(ag.Generated)
    for inst in to_py(ag.Instances):
        key = inst["key"]
        gen_names = {b["name"] for b in generated.get(key, {}).get("bosses", [])}
        if not gen_names:
            print(f"{key:16} no Wowhead data")
            continue
        guide = to_py(ag.Guides[key])
        no_text = [b["name"] for b in guide["bosses"] if not b.get("overview")]
        unmatched = [b["name"] for b in content.get(key, {}).get("bosses", [])
                     if b["name"] not in gen_names and not set(b.get("alsoNamed") or []) & gen_names]
        print(f"{key:16} bosses={len(guide['bosses']):2}  no overview: {no_text or '-'}")
        if unmatched:
            print(f"{'':16} content without Wowhead loot: {unmatched}")


if __name__ == "__main__":
    if "--report" in sys.argv:
        report()
    else:
        unittest.main()
