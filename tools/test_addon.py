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
                if kind != "image":
                    self.assertIsInstance(file_id, int, f"{key}.{kind}")

    def test_bundled_art_files_exist(self):
        addon = Path(__file__).resolve().parent.parent / "AdventureGuideForever"
        prefix = "Interface\\AddOns\\AdventureGuideForever\\"
        for key, art in to_py(self.ag.Art).items():
            if "image" not in art:
                continue
            path = art["image"]
            self.assertTrue(path.startswith(prefix), f"{key}: {path}")
            rel = path[len(prefix):].replace("\\", "/") + ".tga"
            self.assertTrue((addon / rel).is_file(), f"{key}: missing {rel}")

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


class FeatureTests(unittest.TestCase):
    """Drops-from index, community data, party sync messages, and /ag share exports."""

    def setUp(self):
        self.lua, self.ag = load_built()
        self.lua.execute("function __db(t) return t end")

    def set_db(self, lua_src):
        self.ag.db = self.lua.eval(f"(function() return {lua_src} end)()")

    def test_pedometer_combat_rules(self):
        pace = lambda speed, **s: self.ag.JourneyPace(speed, self.lua.table_from(s))
        # Out of combat the speed counts as is, even fast mounts.
        self.assertEqual(pace(30, combat=False), 30)
        self.assertEqual(pace(None, combat=False, moving=True), 0)
        # A charge counts like running, not a 40-yard stride.
        self.assertEqual(pace(40, combat=True, moving=True, lastPace=7), 14)
        self.assertEqual(pace(7, combat=True, moving=True, lastPace=7), 7)
        # A hidden speed counts as your last pace while you move, nothing while you stand.
        self.assertEqual(pace(None, combat=True, moving=True, lastPace=8), 8)
        self.assertEqual(pace(None, combat=True, moving=False, lastPace=8), 0)
        # Knockbacks: flung through the air without pressing a key counts nothing.
        self.assertEqual(pace(25, combat=True, airborne=True, moving=False, lastPace=7), 0)
        self.assertEqual(pace(25, combat=True, airborne=True, moving=True, lastPace=7), 7)

    def test_travel_counts_this_session_and_all_time(self):
        rec = self.lua.eval("{ distance = { foot = 100 }, combat = 0 }")  # an old record, no session yet
        self.ag.AddTravel(self.ag, rec, "foot", 17, False)
        self.ag.AddTravel(self.ag, rec, "mounted", 50, True)
        rec = to_py(rec)
        self.assertEqual(rec["distance"]["foot"], 117)
        self.assertEqual(rec["session"]["distance"]["foot"], 17)
        self.assertEqual(rec["session"]["distance"]["mounted"], 50)
        self.assertEqual((rec["combat"], rec["session"]["combat"]), (50, 50))
        self.assertEqual(self.ag.TotalYards(self.ag, self.lua.table_from(rec["session"]["distance"])), 67)

    def test_number_formatting(self):
        ui = self.ag.UI
        self.assertEqual(ui.Commas(1234567.8), "1,234,567")
        self.assertEqual(ui.Commas(999), "999")
        self.assertEqual(ui.Distance(50), "50 yards")
        self.assertEqual(ui.Distance(1760 * 2.5), "2.50 miles")
        self.assertEqual(ui.Distance(1760 * 31), "31.0 miles")

    def test_item_sources_find_guide_loot(self):
        guides = to_py(self.ag.Guides)
        boss = next(b for b in guides["deadmines"]["bosses"] if b.get("loot"))
        item = boss["loot"][0]
        sources = to_py(self.ag.ItemSources(self.ag, item["itemID"]))
        self.assertIn(("deadmines", boss["key"]), [(s["instKey"], s["bossKey"]) for s in sources])

    def test_item_sources_include_own_learned_drops(self):
        self.set_db("{ learned = { kroldok = { bosses = { mugg = { name = 'Mugg', kills = 10, "
                    "loot = { [999001] = 4 }, spells = {} } } } } }")
        sources = to_py(self.ag.ItemSources(self.ag, 999001))
        self.assertEqual(len(sources), 1)
        self.assertEqual(sources[0]["bossName"], "Mugg")
        self.assertAlmostEqual(sources[0]["dropChance"], 40.0)

    def test_community_joins_learned_data(self):
        self.ag.Community = self.lua.table()
        self.lua.eval("""function(ag) ag:RegisterCommunity("kroldok", { bosses = {
            { key = "mugg", name = "Mugg", npcID = 5, kills = 8, reports = 2,
              loot = { { itemID = 77, count = 3 } }, spells = { { spellID = 88, count = 20 } } } } }) end""")(self.ag)
        self.ag.BuildGuides(self.ag)
        self.set_db("{ learned = { kroldok = { bosses = { mugg = { kills = 2, loot = { [77] = 5 }, spells = {} } } } } }")
        rec = to_py(self.ag.GetLearnedBosses(self.ag, "kroldok"))["mugg"]
        self.assertEqual(rec["kills"], 8)              # larger of yours and the community's
        self.assertEqual(rec["loot"], {77: 5})
        self.assertEqual(rec["spells"], {88: 20})
        self.assertEqual(rec["npcID"], 5)
        self.assertTrue(rec["community"])
        sources = to_py(self.ag.ItemSources(self.ag, 77))
        self.assertEqual(sources[0]["bossKey"], "mugg")

    def test_sync_messages_round_trip(self):
        self.set_db("{ learned = {} }")
        loot = ", ".join(f"[{100000 + i}] = {i + 1}" for i in range(60))   # forces several chunks
        rec = self.lua.eval(f"{{ name = 'Overlord^Mugg', kills = 3, npcID = 12, displayID = 34, "
                            f"loot = {{ {loot} }}, spells = {{ [555] = 9 }} }}")
        msgs = to_py(self.ag.Sync.Encode("kroldok", "overlordmugg", rec))
        self.assertGreater(len(msgs), 3)
        self.assertTrue(all(len(m) <= 255 for m in msgs))
        for m in msgs:
            inst, boss, data = self.ag.Sync.Decode(m)
            self.assertEqual((inst, boss), ("kroldok", "overlordmugg"))
            self.ag.MergeLearned(self.ag, inst, boss, data)
        got = to_py(self.ag.db.learned)["kroldok"]["bosses"]["overlordmugg"]
        self.assertEqual(got["name"], "OverlordMugg")    # separator stripped
        self.assertEqual(got["kills"], 3)
        self.assertEqual(len(got["loot"]), 60)
        self.assertEqual(got["spells"], {555: 9})

    def test_sync_rejects_bad_messages(self):
        bad = ["2^B^kroldok^mugg^1^0^0^x", "1^B^nowhere^mugg^1^0^0^x", "1^B^kroldok^bad key^1^0^0^x",
               "1^L^kroldok^mugg^1:999999999999", "1^L^kroldok^mugg^", "1^X^kroldok^mugg^1", "x" * 300]
        for m in bad:
            self.assertIsNone(self.ag.Sync.Decode(m), m)

    def test_sync_merge_keeps_larger_counts(self):
        self.set_db("{ learned = { kroldok = { bosses = { mugg = { kills = 5, loot = { [1] = 4 }, spells = {} } } } } }")
        changed = self.ag.MergeLearned(self.ag, "kroldok", "mugg", self.lua.eval("{ kills = 3, loot = { [1] = 2, [2] = 1 } }"))
        self.assertTrue(changed)
        got = to_py(self.ag.db.learned)["kroldok"]["bosses"]["mugg"]
        self.assertEqual(got["kills"], 5)
        self.assertEqual(got["loot"], [4, 1])   # to_py turns item IDs 1 and 2 into a list

    def test_export_is_read_by_intake(self):
        import learned_intake as li
        self.set_db("{ learned = { kroldok = { bosses = { overlordmugg = { name = 'Overlord Mugg', kills = 3, "
                    "npcID = 12, loot = { [500] = 2, [7] = 1 }, spells = { [9] = 4 } } } }, "
                    "nowhere = { bosses = { x = { kills = 1, loot = {}, spells = {} } } } }, unshared = 2 }")
        self.ag.version = "0.5.0"
        text, bosses = self.ag.BuildExport(self.ag)
        self.assertEqual(bosses, 1)                       # unknown instances are left out
        sub = li.parse_export("Some notes\n```text\n" + text + "\n```\n", {"kroldok"})
        rec = sub["bosses"]["kroldok/overlordmugg"]
        self.assertEqual(sub["version"], "0.5.0")
        self.assertEqual((rec["kills"], rec["npcID"], rec["displayID"], rec["name"]), (3, 12, None, "Overlord Mugg"))
        self.assertEqual(rec["loot"], {"7": 1, "500": 2})
        self.assertEqual(rec["spells"], {"9": 4})


class GuideCompareTests(unittest.TestCase):
    """Reading Wowhead's guide markup (tools/compare_guides.py)."""

    MARKUP = (
        "[toc]\r\n[zone=2437] is in Orgrimmar.\r\n"
        '[h2 type=bar toc="Overview"]Ragefire Chasm Overview[/h2]\r\n'
        "The recommended level for Ragefire Chasm is 13-18. It's short.\r\n"
        '[h2 type=bar toc="Quests"]Every Quest[/h2]\r\n'
        "[table][tr background=black][td][b]Quest[/b][/td][td]Level[/td][td]Side[/td][td]Effort[/td]"
        "[td]Share?[/td][td]Starts[/td][/tr]"
        "[tr][td][quest=5728][/td][td align=center]9 [/td][td][span class=icon-horde][/span][/td][td][/td]"
        "[td][b][color=q5]Pre[/color][/b][/td][td][b]Orgrimmar[/b], Valley of Wisdom - [npc=4949] /way 31 37\r\n"
        "[i]Prerequisite: Complete 3 quests, starting with [quest=5726][/i][/td][/tr]"
        "[tr][td][quest=5761][/td][td]9[/td][td]-[/td][td][/td][td][span class=\"fa fa-check\"][/span][/td]"
        "[td]Inside RFC - [item=14381] drop[/td][/tr][/table]\r\n"
        '[h2 type=bar toc="Trash"]Noteworthy Trash Mobs[/h2]\r\n'
        "Ragefire Shamans ([npc=11319]) cast [spell=547].\r\n"
        '[h2 type=bar toc="Bosses"]Bosses[/h2]\r\n'
        '[box-highlight name="Taragaman the Hungerer"]\r\n'
        "[b]Strategy[/b] [npc=11520] uses [spell=18072] near the edge.[pad]\r\n"
        "[table][tr][td][b]Abilities[/b][/td][/tr][tr][td] [spell=11970] [spell=18072] [/td][/tr][/table]\r\n"
        "[/box-highlight]\r\n"
        '[h2 type=bar toc="Loot"]Loot[/h2]\r\n[item=14149]\r\n'
    )
    NAMES = {"quest": {"5728": {"name": "Hidden Enemies"}, "5761": {"name": "Slaying the Beast"},
                       "5726": {"name": "Hidden Enemies"}},
             "spell": {"11970": {"name": "Fire Nova"}, "18072": {"name": "Uppercut"}, "547": {"name": "Healing Wave"}},
             "npc": {"11319": {"name": "Ragefire Shaman"}, "11520": {"name": "Taragaman the Hungerer"},
                     "4949": {"name": "Thrall"}},
             "item": {"14381": {"name": "Grimtotem Satchel"}}}

    def setUp(self):
        import compare_guides
        self.cg = compare_guides

    def test_reads_levels_bosses_quests_and_trash(self):
        facts = self.cg.parse_guide({"title": "Ragefire Chasm Dungeon Overview Guide: Quests &amp; More",
                                     "markup": self.MARKUP, "names": self.NAMES})
        self.assertEqual(facts["title"], "Ragefire Chasm Dungeon Overview Guide: Quests & More")
        self.assertEqual(tuple(facts["levels"]), (13, 18))
        boss = facts["bosses"][0]
        self.assertEqual((boss["name"], boss["npcIDs"], boss["abilities"]),
                         ("Taragaman the Hungerer", [11520], [11970, 18072]))
        self.assertEqual(boss["abilityNames"], ["Fire Nova", "Uppercut"])
        self.assertEqual([(q["questID"], q["level"], q["name"]) for q in facts["quests"]],
                         [(5728, 9, "Hidden Enemies"), (5761, 9, "Slaying the Beast")])
        first, second = facts["quests"]
        self.assertEqual((first["side"], first["start"], first["x"], first["y"], first["chain"], first["shareable"]),
                         ("Horde", "Orgrimmar, Valley of Wisdom - Thrall", 31.0, 37.0, 5726, False))
        self.assertEqual((second["side"], second["start"], second["x"], second["chain"], second["shareable"]),
                         (None, "Inside RFC - Grimtotem Satchel drop", None, None, True))
        self.assertEqual(facts["trash"]["names"], ["Ragefire Shaman"])

    def test_quests_file_is_up_to_date(self):
        facts = json.loads(self.cg.FACTS.read_text(encoding="utf-8"))["instances"]
        self.assertEqual(self.cg.QUESTS.read_text(encoding="utf-8"), self.cg.render_quests(facts),
                         "Data/Generated/Quests.lua is stale: run tools/compare_guides.py --quests")

    def test_quests_by_faction(self):
        lua, ag = load_built()
        ag.Quests = lua.table()
        lua.eval("""function(ag) ag:RegisterQuests("ragefire", { quests = {
            { questID = 1, name = "B", level = 9, side = "Horde" },
            { questID = 2, name = "A", level = 9 },
            { questID = 3, name = "C", level = 8, side = "Alliance" } } }) end""")(ag)
        horde, other = ag.GetQuests(ag, "ragefire", "Horde")
        self.assertEqual(([q["questID"] for q in to_py(horde)], other), ([2, 1], 1))
        everyone, _ = ag.GetQuests(ag, "ragefire")
        self.assertEqual([q["questID"] for q in to_py(everyone)], [3, 2, 1])

    def test_quest_list_on_the_instance_page(self):
        lua, ag = load_built()
        lua.execute("""
            UnitFactionGroup = function() return "Horde" end
            C_QuestLog = {
                IsQuestFlaggedCompleted = function(id) return id == 1 end,
                GetLogIndexForQuestID = function(id) if id == 2 then return 4 end end,
            }
            agf_rows, agf_paras = {}, {}
            agf_doc = {
                Heading = function(self, t) agf_heading = t end,
                Row = function(self, icon, title, body, note, opts) table.insert(agf_rows, { title = title, note = note, body = body, q = opts.questID }) end,
                Paragraph = function(self, t) table.insert(agf_paras, t) end,
            }""")
        ag.Quests = lua.table()
        lua.eval("""function(ag) ag:RegisterQuests("ragefire", { quests = {
            { questID = 1, name = "Done one", level = 9, side = "Horde", start = "Orgrimmar", x = 49, y = 50 },
            { questID = 2, name = "Taken", level = 10, chain = 1, chainName = "Done one" },
            { questID = 3, name = "Open", level = 11 },
            { questID = 4, name = "Theirs", level = 9, side = "Alliance" } } }) end""")(ag)
        quests, other, open = ag.QuestsFor(ag, "ragefire")
        self.assertEqual((len(to_py(quests)), other, open), (3, 1, 2))
        ag.RenderQuestList(ag, lua.globals().agf_doc, "ragefire")
        rows = to_py(lua.globals().agf_rows)
        self.assertEqual([r["q"] for r in rows], [1, 2, 3])
        self.assertIn("Done", rows[0]["note"])
        self.assertIn("In your log", rows[1]["note"])
        self.assertIn("Orgrimmar", rows[0]["body"])
        self.assertIn("starts with", rows[1]["body"])
        self.assertIn("(3, 2 not done)", lua.globals().agf_heading)
        self.assertIn("for the Alliance", to_py(lua.globals().agf_paras)[0])

    def test_reads_h3_boss_boxes_and_between_levels(self):
        markup = ('[h2 toc="Overview"]O[/h2]The recommended level for Hall of Thanes is between 13 and 18.'
                  '[h2 toc="Bosses"]B[/h2][div][box][h3 type=bar] Faldrim Anvilmar [/h3]'
                  "[npc=261306] patrols.[b]Abilities[/b] [spell=26048] [/box][/div]"
                  "[div][box][h3 type=bar]Magmatus[/h3][npc=261316][b]Abilities[/b][spell=1293228][/box][/div]")
        facts = self.cg.parse_guide({"title": "The Hall of Thanes", "markup": markup, "names": {}})
        self.assertEqual(tuple(facts["levels"]), (13, 18))
        self.assertEqual([(b["name"], b["npcIDs"], b["abilities"]) for b in facts["bosses"]],
                         [("Faldrim Anvilmar", [261306], [26048]), ("Magmatus", [261316], [1293228])])

    def test_hub_lookup_is_loose(self):
        n = self.cg.normalize
        hub = {n("Temple of Atal'Hakkar (Sunken Temple)"): (50, 60), n("Dire Maul"): (58, 60)}
        self.assertEqual(self.cg.hub_lookup(hub, ["Temple of Atal'Hakkar"]), (50, 60))
        self.assertEqual(self.cg.hub_lookup(hub, ["Warpwood Quarter", "Dire Maul East"]), (58, 60))

    def test_matches_titles_to_instances(self):
        _, ag = load_addon(re.compile(r"^Data/Instances\.lua$"))
        instances = to_py(ag.Instances)
        match = lambda t: self.cg.match_instance(t, instances)  # noqa: E731
        self.assertEqual(match("Ragefire Chasm Dungeon Overview Guide"), "ragefire")
        self.assertEqual(match("The Deadmines Dungeon Overview Guide"), "deadmines")
        self.assertEqual(match("Scarlet Monastery: Library Dungeon Guide"), "smlibrary")
        self.assertEqual(match("Dire Maul: East Dungeon Guide"), "dmeast")
        self.assertIsNone(match("Some Unrelated Guide"))

    def test_hub_level_table(self):
        hub = self.cg.hub_levels("[tr][td][b]Dungeon[/b][/td][td]Lower[/td][td]Upper[/td][/tr]"
                                 "[tr][td]The Hall of Thanes[/td][td]13[/td][td]18[/td][td]New[/td][/tr]")
        self.assertEqual(hub, {self.cg.normalize("The Hall of Thanes"): (13, 18)})


class IntakeTests(unittest.TestCase):
    """tools/learned_intake.py: validating shares and merging them into Community.lua."""

    HEADER = "AGF1 version=0.5.0 id=abcdef0123456789"

    def setUp(self):
        import learned_intake
        self.li = learned_intake
        self.instances = {"kroldok", "deadmines"}

    def export(self, *lines):
        return "\n".join([self.HEADER, *lines, f"END {len(lines)}"])

    def test_rejects_bad_exports(self):
        bad = [
            "hello",
            self.export("B nowhere x kills=1 npc=0 display=0 name=X"),
            self.export("B kroldok bad-key kills=1 npc=0 display=0 name=X"),
            self.export("L kroldok mugg 0:1"),
            self.export("L kroldok mugg 1:9999999999"),
            self.export("rm -rf /"),
            self.HEADER + "\nB kroldok mugg kills=1 npc=0 display=0 name=X\nEND 5",   # cut off
            self.HEADER + "\nB kroldok mugg kills=1 npc=0 display=0 name=X",          # no END
            "AGF1 version=0.5.0 id=NOT-HEX\nEND 0",
        ]
        for text in bad:
            with self.assertRaises(self.li.SubmissionError, msg=text):
                self.li.parse_export(text, self.instances)

    def test_names_are_cleaned(self):
        sub = self.li.parse_export(self.export('B kroldok mugg kills=1 npc=0 display=0 name=Mu|cffgg"\x07 ' + "x" * 80),
                                   self.instances)
        name = sub["bosses"]["kroldok/mugg"]["name"]
        self.assertNotIn("|", name)
        self.assertNotIn("\x07", name)
        self.assertLessEqual(len(name), self.li.MAX_NAME)

    def test_newer_share_replaces_older_and_players_add_up(self):
        db = {"submitters": {}}
        a1 = self.li.parse_export(self.export("B kroldok mugg kills=2 npc=5 display=0 name=Mugg",
                                              "L kroldok mugg 77:1"), self.instances)
        a2 = self.li.parse_export(self.export("B kroldok mugg kills=4 npc=5 display=0 name=Mugg",
                                              "L kroldok mugg 77:2"), self.instances)
        b = self.li.parse_export(self.export("B kroldok mugg kills=3 npc=5 display=9 name=Mugg",
                                             "L kroldok mugg 77:1 78:1").replace("abcdef0123456789", "0000aaaa"),
                                 self.instances)
        self.assertTrue(self.li.merge_submission(db, a1, 1, "2026-11-17"))
        self.assertTrue(self.li.merge_submission(db, a2, 2, "2026-11-18"))
        self.assertFalse(self.li.merge_submission(db, a2, 3, "2026-11-18"))   # same data again
        self.li.merge_submission(db, b, 4, "2026-11-18")
        boss = self.li.aggregate(db)["kroldok"][0]
        self.assertEqual(boss["kills"], 7)                   # 4 (latest of player A) + 3 (player B)
        self.assertEqual(boss["reports"], 2)
        self.assertEqual(boss["displayID"], 9)
        self.assertEqual(boss["loot"], [{"itemID": 77, "count": 3}, {"itemID": 78, "count": 1}])

    def test_rendered_lua_loads(self):
        db = {"submitters": {}}
        sub = self.li.parse_export(self.export("B kroldok mugg kills=6 npc=5 display=0 name=Overlord \"Mugg\"",
                                               "L kroldok mugg 77:3", "S kroldok mugg 88:10"), self.instances)
        self.li.merge_submission(db, sub, None, "2026-11-17")
        src = self.li.render(self.li.aggregate(db), 1)
        lua, ag = load_addon(re.compile(r"^Data/(Instances|Registry)\.lua$"))
        lua.eval("function(src, ns) assert(loadstring(src))('AdventureGuideForever', ns) end")(src, ag)
        ag.BuildGuides(ag)
        rec = to_py(ag.CommunityLearned)["kroldok"]["mugg"]
        self.assertEqual(rec["name"], 'Overlord "Mugg"')
        self.assertEqual(rec["loot"], {77: 3})
        self.assertEqual(rec["spells"], {88: 10})

    def test_community_lua_is_up_to_date(self):
        db = self.li.load_db()
        self.assertEqual(self.li.OUTPUT.read_text(encoding="utf-8"),
                         self.li.render(self.li.aggregate(db), len(db["submitters"])),
                         "run tools/learned_intake.py --build")


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
