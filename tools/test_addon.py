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

    def test_no_unknown_string_escapes(self):
        # Lua 5.1 silently drops an unknown escape: "Interface\Icons\X" loses its backslashes
        # and the texture path breaks. Paths need doubled backslashes.
        string = re.compile(r'"((?:[^"\\\n]|\\.)*)"')
        for path in toc_files():
            for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                code = "" if line.lstrip().startswith("--") else line
                for m in string.finditer(code):
                    for e in re.finditer(r"\\(.)", m.group(1)):
                        self.assertIn(e.group(1), 'abfnrtv\\"\'0123456789',
                                      f"{path.name}:{n}: unknown escape in {m.group(0)}")

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
    """Drops-from index, search, and the options page."""

    def setUp(self):
        self.lua, self.ag = load_built()
        self.lua.execute("function __db(t) return t end")

    def set_db(self, lua_src):
        self.ag.db = self.lua.eval(f"(function() return {lua_src} end)()")

    def test_number_formatting(self):
        ui = self.ag.UI
        self.assertEqual(ui.Commas(1234567.8), "1,234,567")
        self.assertEqual(ui.Commas(999), "999")

    def test_search_groups_and_ranks(self):
        groups = {g["key"]: g for g in to_py(self.ag.Search(self.ag, "mugg"))}
        self.assertEqual(groups["boss"]["results"][0]["name"], "Overlord Mugg")
        self.assertIn("ability", groups)
        self.assertFalse(to_py(self.ag.Search(self.ag, "m")))  # too short
        self.assertFalse(to_py(self.ag.Search(self.ag, "zzzz nothing")))
        # Punctuation and spaces don't matter, and abbreviations find dungeons.
        self.assertEqual(to_py(self.ag.Search(self.ag, "zul farrak"))[0]["results"][0]["instKey"], "zulfarrak")
        self.assertEqual(to_py(self.ag.Search(self.ag, "RFC"))[0]["results"][0]["instKey"], "ragefire")
        # An exact name beats a longer one containing it.
        names = [e["name"] for e in to_py(self.ag.Search(self.ag, "fire nova"))[0]["results"]]
        self.assertEqual(names[0], "Fire Nova")

    def test_quest_rewards_are_items_too(self):
        quests = to_py(self.ag.Quests["ragefire"])
        quest = next(q for q in quests if q.get("rewards"))
        reward = quest["rewards"][0]
        sources = to_py(self.ag.ItemSources(self.ag, reward["itemID"]))
        self.assertIn(quest["questID"], [s.get("questID") for s in sources])
        found = to_py(self.ag.Search(self.ag, reward["name"]))
        self.assertIn(reward["itemID"], [e.get("itemID") for g in found for e in g["results"]])

    def test_item_sources_find_guide_loot(self):
        guides = to_py(self.ag.Guides)
        boss = next(b for b in guides["deadmines"]["bosses"] if b.get("loot"))
        item = boss["loot"][0]
        sources = to_py(self.ag.ItemSources(self.ag, item["itemID"]))
        self.assertIn(("deadmines", boss["key"]), [(s["instKey"], s["bossKey"]) for s in sources])

    def test_old_data_is_retired(self):
        # Learning mode, sharing, and party sync are gone; visits stay for the pedometer,
        # with the instances' names added (it doesn't know the guide's keys).
        self.set_db("{ learn = true, learned = { deadmines = {} }, unshared = 4, shareID = 'abc', "
                    "lastShareNudge = 1, options = { sync = true, shareReminder = true, tooltips = true }, "
                    "journey = { ['Me-Realm'] = { instances = { deadmines = { visits = 3 } }, zones = {} } } }")
        self.ag.RetireOldData(self.ag, self.ag.db)
        db = to_py(self.ag.db)
        for gone in ("learn", "learned", "unshared", "shareID", "lastShareNudge"):
            self.assertNotIn(gone, db)
        self.assertEqual(db["options"], {"tooltips": True})
        rec = db["journey"]["Me-Realm"]
        self.assertEqual(rec["instances"]["deadmines"]["visits"], 3)
        self.assertEqual(rec["instanceNames"], {"deadmines": "Deadmines"})

    def test_binding_names(self):
        name = self.ag.BindingName
        self.assertEqual(name("J", False, False, True), "SHIFT-J")
        self.assertEqual(name("F5", True, True, True), "ALT-CTRL-SHIFT-F5")
        self.assertEqual(name("G", False, True, False), "CTRL-G")

    def test_dungeon_card_once_per_trip(self):
        self.lua.execute("""
            agf_where = { "The Deadmines", "party" }
            GetInstanceInfo = function() return agf_where[1], agf_where[2] end
            UnitName = function() return "Me" end
            GetRealmName = function() return "Realm" end""")
        self.set_db("{ options = { zoneCard = true } }")
        shown = []
        self.ag.ShowZoneCard = lambda ag, key: shown.append(key)
        arrive = self.ag.BriefingArrive
        arrive()
        arrive()                                         # a reload inside: no second card
        self.lua.execute("agf_where = { 'Westfall', 'none' }")
        arrive()
        self.lua.execute("agf_where = { 'The Deadmines', 'party' }")
        arrive()                                         # back in: a new trip
        self.assertEqual(shown, ["deadmines", "deadmines"])

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


class ItemDataTests(unittest.TestCase):
    """Item levels and stats (tools/build_items.py -> Data/Generated/Items.lua)."""

    def setUp(self):
        import build_items
        self.bi = build_items

    def test_item_record_maps_wowhead_fields(self):
        rec = self.bi.item_record(14147, {"level": 18, "reqlevel": 13, "classs": 4, "subclass": 3, "slot": 9,
                                          "armor": 78, "quality": 3, "str": 2, "spi": 3, "name": "x",
                                          "splpwr": 0, "dps": 12.1666})
        self.assertEqual(rec, {"itemID": 14147, "itemLevel": 18, "reqLevel": 13, "class": 4, "subclass": 3,
                               "slot": 9, "armor": 78, "quality": 3, "dps": 12.2, "stats": {"spi": 3, "str": 2}})

    def test_id_ranges_stay_under_the_page_limit(self):
        ranges = self.bi.id_ranges([1, 5, 900, 902, 5000, 5001])
        self.assertEqual(ranges, [[1, 900], [902, 902], [5000, 5001]])
        self.assertTrue(all(b - a <= self.bi.RANGE_SPAN for a, b in ranges))

    def test_items_file_is_up_to_date(self):
        if not self.bi.ITEMS_JSON.exists():
            self.skipTest("no items.json yet")
        data = json.loads(self.bi.ITEMS_JSON.read_text(encoding="utf-8"))
        self.assertEqual(self.bi.OUTPUT.read_text(encoding="utf-8"),
                         self.bi.render(data["items"], self.bi.guide_item_ids()),
                         "Data/Generated/Items.lua is stale: run tools/build_items.py")

    def test_class_can_use(self):
        lua, ag = load_built()
        can = lambda item, cls, lvl=60: ag.CanUse(ag, lua.table_from(item), cls, lvl)  # noqa: E731
        plate = {"class": 4, "subclass": 4, "slot": 5}
        mail = {"class": 4, "subclass": 3, "slot": 5}
        self.assertTrue(can(plate, 1, 40))      # warriors wear plate from 40
        self.assertFalse(can(plate, 1, 39))
        self.assertFalse(can(plate, 8))         # mages never
        self.assertFalse(can(mail, 3, 30))      # hunters wear mail from 40
        self.assertTrue(can(mail, 7, 45))       # shamans too
        self.assertTrue(can({"class": 2, "subclass": 19, "slot": 26}, 5))   # priests use wands
        self.assertFalse(can({"class": 2, "subclass": 4, "slot": 17}, 5))   # but not two-hand maces
        self.assertTrue(can({"class": 2, "subclass": 4, "slot": 13}, 5))    # one-hand maces are fine
        # Class-restricted items: the bitmask lists who may use it (bit = classID).
        paladin_only = {"class": 4, "subclass": 1, "slot": 5, "classes": 2}
        self.assertTrue(can(paladin_only, 2))
        self.assertFalse(can(paladin_only, 5))

    def test_filter_gear(self):
        lua, ag = load_built()
        f = lambda **kw: to_py(ag.FilterGear(ag, lua.table_from(kw)))  # noqa: E731
        everything = f()
        self.assertGreater(len(everything), 1000)
        wrists = f(slot="wrist", stat="str", maxLevel=20)
        self.assertTrue(wrists)
        values = [g["statValue"] for g in wrists]
        self.assertEqual(values, sorted(values, reverse=True))
        self.assertTrue(all(g["item"]["slot"] == 9 for g in wrists))
        self.assertTrue(all(g["item"].get("reqLevel", 1) <= 20 for g in wrists))
        cloth = f(type="cloth", usable=True, classID=1, level=60)
        self.assertTrue(cloth)
        self.assertFalse(f(type="plate", usable=True, classID=8, level=60))

    def test_gear_page_renders(self):
        lua, ag = load_built()
        lua.execute("""
            UnitClass = function() return "Warrior", "WARRIOR", 1 end
            UnitLevel = function() return 20 end
            agf_rows = {}
            agf_doc = {
                Row = function(self, icon, title, body, note, opts) table.insert(agf_rows, { body = body, note = note, id = opts.itemID }) end,
                Paragraph = function() end,
            }""")
        ag.db = lua.eval("{ gear = { usable = true, minQuality = 2, slot = 'wrist' } }")
        ag.frame = lua.eval("{ header = { SetText = function() end } }")
        ag.RenderGear(ag, lua.globals().agf_doc)
        rows = to_py(lua.globals().agf_rows)
        self.assertTrue(rows)
        self.assertTrue(all("Wrist" in r["body"] for r in rows))
        self.assertTrue(all("Level" in r["note"] for r in rows))

    def test_suggested_gear(self):
        lua, ag = load_built()
        plan, weights = ag.SuggestGear(ag, 1, "fury", 30, lua.eval("{ faction = 'Horde' }"))
        plan, weights = to_py(plan), to_py(weights)
        by_slot = {s["slot"]: s for s in plan}
        self.assertEqual(len(by_slot["finger"]["picks"]), 2)        # two rings
        for slot in plan:
            for pick in slot["picks"]:
                item = pick["item"]
                self.assertLessEqual(item.get("reqLevel", 1), 30)
                self.assertNotEqual(item.get("subclass"), 4 if item.get("class") == 4 else -1)  # no plate before 40
                if slot["alternatives"]:
                    self.assertGreaterEqual(pick["score"], slot["alternatives"][0]["score"])
        # Leaving quest rewards out never picks one.
        no_quests = to_py(ag.SuggestGear(ag, 1, "fury", 30, lua.eval("{ quests = false }"))[0])
        self.assertFalse([p for s in no_quests for p in s["picks"] if p["source"].get("questID")])
        # Scores follow the weights: Strength counts for Fury, not for a Holy priest.
        item = lua.eval("{ stats = { str = 10 } }")
        self.assertEqual(ag.ScoreItem(ag, item, lua.table_from(weights)), 10)
        holy = ag.GetSpec(ag, 5, "holy").w
        self.assertEqual(ag.ScoreItem(ag, item, holy), 0)

    def test_compare_to_equipped(self):
        lua, ag = load_built()
        lua.execute("""
            agf_worn = { [11] = 999001, [12] = 999002 }
            GetInventoryItemID = function(unit, slot) return agf_worn[slot] end
            GetInventoryItemLink = function(unit, slot) return agf_worn[slot] and ("item:" .. agf_worn[slot]) end
            C_Item = { GetItemStats = function(link)
                if link == "item:999001" then return { ITEM_MOD_STRENGTH_SHORT = 4 } end
                return { ITEM_MOD_STRENGTH_SHORT = 9 } end,
                GetItemInfoInstant = function() return nil, nil, nil, "INVTYPE_FINGER", nil, 4 end }""")
        w = lua.eval("{ str = 1 }")
        pick = lua.eval("{ itemID = 5, score = 7 }")
        slots = lua.eval("{ 11, 12 }")
        self.assertEqual(ag.CompareToEquipped(ag, pick, slots, w), 3)   # beats the weaker ring (4) by 3
        self.assertEqual(ag.CompareToEquipped(ag, lua.eval("{ itemID = 999002, score = 9 }"), slots, w), "equipped")
        self.assertIsNone(ag.CompareToEquipped(ag, pick, lua.eval("{ 1 }"), w))  # nothing worn there

    def test_detect_spec(self):
        lua, ag = load_built()
        lua.execute("""GetSpecialization = function() return 2 end
            GetSpecializationInfo = function(i) return 72, "Fury" end""")
        self.assertEqual(ag.DetectSpec(ag, 1), "fury")
        lua.execute("""GetSpecialization = nil
            GetNumTalentTabs = function() return 3 end
            GetTalentTabInfo = function(tab) return "x", nil, ({ 5, 0, 31 })[tab] end""")
        self.assertEqual(ag.DetectSpec(ag, 8), "frost")
        # Classic druids have three trees (no Guardian), matched by name, not position.
        lua.execute("""GetTalentTabInfo = function(tab)
                return ({ "Balance", "Feral Combat", "Restoration" })[tab], nil, ({ 0, 14, 0 })[tab] end""")
        self.assertEqual(ag.DetectSpec(ag, 11), "feral")
        lua.execute("""GetTalentTabInfo = function(tab)
                return tab, ({ "Balance", "Feral Combat", "Restoration" })[tab], "", nil, ({ 0, 0, 12 })[tab] end""")
        self.assertEqual(ag.DetectSpec(ag, 11), "restoration")
        # No talent points spent: the game's specialization, by ID when the name differs.
        lua.execute("""GetTalentTabInfo = function(tab) return "x", nil, 0 end
            GetSpecialization = function() return 2 end
            GetSpecializationInfo = function(i) return 260, "Outlaw" end""")
        self.assertEqual(ag.DetectSpec(ag, 4), "combat")
        self.assertEqual(ag.MatchSpec(ag, 3, "Beast Mastery"), "beastmastery")
        self.assertIsNone(ag.MatchSpec(ag, 3, "Frost"))
        # Forever: placeholder spec "Druid" (1484), no talent tabs, a modern loadout whose
        # one tree holds the three classic trees side by side.
        lua.execute("""GetNumTalentTabs = nil; GetTalentTabInfo = nil
            GetSpecialization = function() return 1 end
            GetSpecializationInfo = function() return 1484, "Druid" end
            local nodes = {}
            for col, xs in ipairs({ { 100, 160, 220 }, { 500, 560, 620 }, { 900, 960, 1020 } }) do
                for _, x in ipairs(xs) do
                    nodes[#nodes + 1] = { ID = #nodes + 1, posX = x, ranksPurchased = col == 2 and 3 or (x == 100 and 1 or 0) }
                end
            end
            C_ClassTalents = { GetActiveConfigID = function() return 5727048 end }
            C_Traits = {
                GetConfigInfo = function() return { treeIDs = { 77 } } end,
                GetTreeNodes = function() local ids = {} for i = 1, #nodes do ids[i] = i end return ids end,
                GetNodeInfo = function(_, id) return nodes[id] end,
            }""")
        self.assertEqual(ag.DetectSpec(ag, 11), "feral")
        # Named sub-trees win when the game has them.
        lua.execute("""local named = { { ID = 1, posX = 0, ranksPurchased = 5, subTreeID = 9 },
                { ID = 2, posX = 0, ranksPurchased = 2, subTreeID = 8 } }
            C_Traits.GetTreeNodes = function() return { 1, 2 } end
            C_Traits.GetNodeInfo = function(_, id) return named[id] end
            C_Traits.GetSubTreeInfo = function(_, id) return { name = id == 9 and "Restoration" or "Balance" } end""")
        self.assertEqual(ag.DetectSpec(ag, 11), "restoration")
        lua.execute("""C_Traits = nil; C_ClassTalents = nil""")
        lua.execute("""UnitLevel = function() return 21 end
            UnitClass = function() return "Rogue", "ROGUE", 4 end""")
        lines = ag.SpecReport(ag)
        self.assertTrue(len(list(lines.values())) >= 3)

    def test_plan_page_renders(self):
        lua, ag = load_built()
        lua.execute("""
            UnitClass = function() return "Mage", "MAGE", 8 end
            UnitLevel = function() return 40 end
            UnitFactionGroup = function() return "Alliance" end
            agf_rows = {}
            agf_doc = {
                Row = function(self, icon, title, body, note, opts) table.insert(agf_rows, { title = title, note = note }) end,
                Paragraph = function() end,
            }""")
        ag.db = lua.eval("{ plan = { quests = true }, wishlist = {} }")
        ag.frame = lua.eval("{ header = { SetText = function() end } }")
        ag.RenderPlan(ag, lua.globals().agf_doc)
        rows = to_py(lua.globals().agf_rows)
        self.assertGreater(len(rows), 10)
        self.assertTrue(any("New slot" in (r["note"] or "") for r in rows))

    def test_filter_gear_by_dungeon(self):
        lua, ag = load_built()
        f = lambda **kw: to_py(ag.FilterGear(ag, lua.table_from(kw)))  # noqa: E731
        weights = ag.GetSpec(ag, 1, "fury").w
        here = f(instance="deadmines", faction="Horde", weights=weights, usable=True, classID=1, level=20)
        self.assertTrue(here)
        self.assertTrue(all(g["source"]["instKey"] == "deadmines" for g in here))
        self.assertTrue(all(g["source"].get("side") in (None, "Horde") for g in here))   # no Alliance quests
        scores = [g["score"] for g in here]
        self.assertEqual(scores, sorted(scores, reverse=True))                              # best for Fury first
        everywhere = f(usable=True, classID=1, level=20)
        self.assertLess(len(here), len(everywhere))

    def test_gear_page_where_i_am(self):
        lua, ag = load_built()
        lua.execute("""
            UnitClass = function() return "Warrior", "WARRIOR", 1 end
            UnitLevel = function() return 20 end
            UnitFactionGroup = function() return "Alliance" end
            agf_where = { "The Deadmines", "party" }
            GetInstanceInfo = function() return agf_where[1], agf_where[2] end
            agf_rows, agf_text = {}, {}
            agf_doc = {
                Row = function(self, icon, title, body, note, opts) table.insert(agf_rows, { body = body, note = note }) end,
                Paragraph = function(self, text) table.insert(agf_text, text) end,
            }""")
        ag.db = lua.eval("{ gear = { usable = true, minQuality = 2, instance = 'here' }, plan = {} }")
        ag.frame = lua.eval("{ header = { SetText = function() end } }")
        ag.RenderGear(ag, lua.globals().agf_doc)
        rows = to_py(lua.globals().agf_rows)
        self.assertTrue(rows)
        self.assertTrue(all("Deadmines" in r["body"] for r in rows))
        self.assertIn("best for your", to_py(lua.globals().agf_text)[0])
        self.assertTrue(any("New slot" in r["note"] for r in rows))      # compared with what you wear
        # Outside a dungeon, "Where I am now" says so instead of listing everything.
        lua.execute("agf_where = { 'Elwynn Forest', 'none' }; agf_rows, agf_text = {}, {}")
        ag.RenderGear(ag, lua.globals().agf_doc)
        self.assertFalse(to_py(lua.globals().agf_rows))
        self.assertIn("not in a dungeon", to_py(lua.globals().agf_text)[0])

    def test_registered_items_load(self):
        lua, ag = load_built()
        ag.RegisterItems(ag, lua.eval("{ items = { { itemID = 77, itemLevel = 20, stats = { sta = 4 } } } }"))
        self.assertEqual(to_py(ag.GetItem(ag, 77))["stats"], {"sta": 4})
        self.assertIsNone(ag.GetItem(ag, 78))


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
