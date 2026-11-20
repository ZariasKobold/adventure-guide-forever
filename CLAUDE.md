# CLAUDE.md: Adventure Guide Forever

A World of Warcraft: Forever addon that rebuilds the retail **Adventure Guide** (dungeon and raid journal), which Forever ships without. Vault hub note: `Projects/Adventure Guide Forever/Adventure Guide Forever.md`.

## Layout

| Path | What it is |
|---|---|
| `AdventureGuideForever/` | **The addon** (the folder players install). Version lives in its TOC. |
| `AdventureGuideForever/Data/Content/<instance>.lua` | Hand-written guide text: instance intro, lore, route, tips; per boss: overview, lore, strategy (summary/tank/healer/dps), abilities with role alerts. **Edit these** (or merge drafts with `tools/apply_writing.py`). |
| `AdventureGuideForever/Data/Generated/Wowhead.lua` | Generated from Wowhead. **Never edit by hand**; run `tools/build_wowhead.py`. |
| `AdventureGuideForever/Data/Registry.lua` | Merges Content + Generated into `AG.Guides` at load. Its header documents both schemas and the merge rules. |
| `AdventureGuideForever/Data/Instances.lua` | All 37 Forever instances (key, name, zone, levels). |
| `AdventureGuideForever/Data/Art.lua` | Blizzard art file IDs per instance (journal button, lore, loading screen, finder), found with `/agprobe art`. |
| `AdventureGuideForever/Art/` | Bundled 1024x512 TGA loading-screen art for the 9 Forever-new instances (sources in its README). |
| `AdventureGuideForever/Data/Generated/Items.lua` | Item level, required level, armor, damage, and stats for every guide item (boss drops and quest rewards). **Never edit by hand**; built by `tools/build_items.py` from `tools/wowhead/items.json`. |
| `AdventureGuideForever/Data/Generated/Quests.lua` | Each dungeon's quests (level, faction, where it starts, chain, rewards). **Never edit by hand**; built by `tools/compare_guides.py` from `tools/wowhead/guide_facts.json`. |
| `AdventureGuideForever/Gear.lua` | Gear filtering for the Gear tab: slot and type groups, what each class can wear and wield (mail/plate at 40), class-restricted items, stat sorting, and the dungeon filter (`AG:SourceIn`; ranked by spec score when weights are given). |
| `AdventureGuideForever/Suggest.lua` | Suggested gear: stat weights per spec (`AG.SPECS`), spec detection, item scoring, best pick per slot, and comparison with what you're wearing. |
| `AdventureGuideForever/Search.lua` | Search index over dungeons, bosses, items (drops and quest rewards), quests, and abilities. `UI/SearchPage` shows results. |
| `AdventureGuideForever/Quests.lua` | Quest status (done, in your log) and your faction's quests per instance, for the instance page and the dungeon card. |
| `AdventureGuideForever/Wishlist.lua` | The wishlist, with drop alerts. |
| `AdventureGuideForever/UI/` | `MainFrame` (window, tabs), `InstanceList` (art card grid), `InstanceOverview` (instance page), `InstancePage` (overview + boss list), `BossPage` (bestiary layout), `GearPage` (Gear tab filters and results), `SuggestPage` (Suggested Gear tab), `WishlistPage`, `Options` (a page in Esc > Options > AddOns, with the key that opens the guide), `Briefing` (dungeon card on arrival, boss card on target), `Tooltips` ("Drops from"), `SearchPage` (search box and results), `Document` (shared scrolling layout), `Widgets`. |
| `AdventureForeverPedometer/` | **A second addon:** Adventure Forever Pedometer, split out of the guide. Distance traveled (by position in the open world, by speed in dungeons, with combat rules), this session vs all time, the step badge by the minimap, places visited (dungeons, raids, zones), and a `/pedometer` window. On first login it imports what the guide counted (`AdventureGuideForeverDB.journey[*]`: distance, and visits with the `instanceNames` the guide adds in `AG:RetireOldData`). **Its own git repo** (https://github.com/ZariasKobold/adventure-forever-pedometer, gitignored here) with its own version, CLAUDE.md, and tests (`python -m unittest discover tests` from that folder). |
| `AdventureGuideProbe/` | Diagnostic addon (`/agprobe`, `/agprobe art`, `/agprobe maps`, `/agprobe deep`). Not shipped. |
| `tools/` | Python dev tooling: build, tests, Wowhead extractors. See `tools/README.md`. |

## Commands

The tooling needs Python 3.10+ and `lupa` (embedded Lua 5.1): `python -m venv .venv` then `.venv\Scripts\pip install -r tools\requirements.txt`.

```
.venv\Scripts\python tools\build_wowhead.py           # regenerate Data/Generated/Wowhead.lua
.venv\Scripts\python -m unittest tools\test_addon.py  # run all tests (must pass before any change is done)
.venv\Scripts\python tools\test_addon.py --report     # coverage: bosses missing text or loot
```

Tests load the real addon files in Lua 5.1. When you add a Lua file, add it to **both** TOCs (`AdventureGuideForever_Forever.toc` and the fallback `AdventureGuideForever.toc`); a test checks they match.

## Forever platform facts (verified in game, Nov 2026)

- Client 1.60.1, **Interface 16001**, TOC suffix `_Forever.toc`. Runs the **modern Midnight (12.x) UI and API**, not Classic's.
- `Blizzard_EncounterJournal` ships but refuses to load (`WRONG_GAME_TYPE`), and all EJ_* data is empty. So the addon supplies its own data.
- Shift+J is still bound to `TOGGLEENCOUNTERJOURNAL` but opens Guild & Communities, so we claim it with `SetOverrideBindingClick`. `EJMicroButton` exists but is not on the menu bar, so `UI/MicroButton.lua` adds our own after Collections: the Dragonflight `UI-HUD-MicroMenu-AdventureGuide-*` icon atlas exists, and the frame is copied from the neighbour's `Background`/`PushedBackground` (verified Nov 17, 2026).
- `PlayerModel:SetDisplayInfo` works.
- Specs: `GetSpecialization` returns a placeholder named after the class (Druid, id 1484), and there's no `GetTalentTabInfo`. Talents live in a modern loadout (`C_ClassTalents.GetActiveConfigID`, `C_Traits`): one tree holding the three classic trees as columns. `AG:LoadoutTrees` counts points per column; `/ag spec` shows it (verified Nov 18, 2026).
- Install path: `World of Warcraft\_forever_\Interface\AddOns\`.

## Coding rules

Rules from `https://wowforeverguides.com/addons/developers` (beta-era; its claims are marked Confirmed, Reported, or Unverified), enforced by tests where possible:
- **Lua 5.1 only.** No `require`, `io`, `os`, `goto`, or bitwise operators.
- **Namespace everything.** Every file starts `local _, AG = ...`. Allowed globals are listed at the top of `Core.lua`, and a test fails on any new one.
- **Secret values:** check API returns with `AG:Readable(x)` / `AG:IsUsable(x)` before comparing or truth-testing them (`UnitExists`, `UnitLevel`, `UnitName`, loot quality...). There's no combat log; use `ENCOUNTER_*`, `UNIT_SPELLCAST_*`, and loot events.
- **Async data:** get items and spells through `UI.ItemInfo` / `UI.SpellInfo`. They request the load and call back on `ITEM_/SPELL_DATA_LOAD_RESULT`.
- One event frame per module, with a handler table keyed by event. No idle `OnUpdate`. Use `PlaySound(SOUNDKIT.*)`.
- Touch saved variables (`AdventureGuideForeverDB`) only from `ADDON_LOADED` on.
- **Data style:** content files use named fields only (no positional tables). Generated output goes through `tools/lua_writer.py`.

## Data pipeline

All guide data comes from Wowhead's Forever database and guides, through the tools below, plus hand-written content. Learning mode (recording loot, spells, and models from play), party sync, and `/ag share` were removed in v0.9.0: Wowhead covers the same ground, and Forever's encounter events produced phantom bosses. Nothing the addon keeps leaves the player's computer.

`tools/wowhead/extract.js` (zone pages: loot and NPC IDs) and `extract_npcs.js` (boss pages: spells and models) run in a normal browser on wowhead.com, slowly. **Never automate past Wowhead's human verification.** Fast bursts trip it; the NPC extractor waits 8 seconds per page and saves its progress so it can resume. Outputs: `tools/wowhead/snapshot.json` and `npcs.json` (fetched Nov 16 to 17, 2026). Wing assignments, trash filters, and multi-NPC encounters are explicit tables in `build_wowhead.py`.

## Status (Nov 20, 2026)

- **v0.9.0** (not released yet, with Pedometer v1.1.0; not yet tested in game): learning mode, party sync, `/ag share`, the share page (`worker/`), and the GitHub share pipeline removed (old saved data is cleared by `AG:RetireOldData`; the deployed Cloudflare Worker and its GitHub token still need deleting by hand). Visit counts and the Journey tab moved to the pedometer (its Places page). Options moved into Esc > Options > AddOns, with a button that sets the guide's key (the game's `TOGGLEENCOUNTERJOURNAL` binding). Gear tab: Dungeon filter ("Where I am now" follows you in) ranked for your spec with upgrade notes. The X closes the window in combat (it no longer goes through `HideUIPanel`). Dropdown menus wrap into columns past 20 entries.
- **v0.8.0** (with Pedometer v1.0.0, released Nov 18, 2026): the pedometer and step badge split out into their own addon, `AdventureForeverPedometer/` (not yet tested in game; it imports the guide's old distance on first login). The guide keeps visit counts in the Journey tab and points to the pedometer.
- **v0.7.1**: share page (`worker/`, live at agf-share.draconicdesigns.workers.dev; verified with a real share, issue #1 → PR #2), gentler share reminder with an Options toggle, learning mode spell capture made robust to hidden values (`/ag learn status`; not yet tested in a dungeon). **v0.7.0** (tested in game Nov 18, 2026): search, Gear tab with filters, Suggested Gear tab (best pick per slot for your level and spec, quest rewards included, Auto spec from the talent loadout), item stats for every guide item, pedometer counts flight paths and swimming, step badge shows this session. **v0.6.0** (quests verified in game Nov 18, 2026): dungeon quests on every instance page (238 quests, 27 dungeons, from `Data/Generated/Quests.lua`), with done / in-log status and an open-quest count on the dungeon card. **v0.5.1**: dungeon advice checked against Wowhead's Forever guides (`tools/compare_guides.py`): the 7 Forever-new dungeons rewritten with full strategies, classic level ranges corrected, missing encounters and abilities added. **v0.5.0** (not yet tested in game): drops-from tooltips, wishlist with drop alerts, optional dungeon and boss briefing cards, Journey tab (pedometer with combat rules, this session vs all time, visit counts), step counter by the minimap calendar, party sync, and `/ag share` → GitHub issue → pull request for community learned data. **v0.4.2**: Adventure Guide button on the menu bar, MIT license. **v0.4.1**: drop chances on 1047 items, bundled art for all 9 Forever-new instances. **v0.4.0**: art card grid, instance overview pages, bestiary-style boss pages, lore and strategy for all 37 instances (252 of 286 bosses have strategy), drop chances supported. Tested in game Nov 17, 2026: card grid, overview and boss pages all work.
- Forever has **no dungeon maps** (`/agprobe maps`: only 60 world and zone maps), so the overview uses a written route instead of a map.
- Forever-new dungeons have no Blizzard art file IDs, so their loading-screen art is bundled in `Art/`. Verified Nov 17, 2026: `/agprobe newart` and `/agprobe lfg` found no client art for them (their Dungeon Finder entries, IDs 3267-3275, carry no texture, and none of 624 path guesses exist). Dalaran, Krol'dok, Shaper's Terrace, and the Hyjal raids (open Dec 9) have no boss mechanics published; add them from Wowhead once they're documented.
- Drop chances are filled from `npcs.json` (extract_npcs.js v2, Nov 17, 2026).

## Git and versioning

- Public repo: https://github.com/ZariasKobold/adventure-guide-forever (branch `main`).
- Conventional commits (`feat:`, `fix:`, `docs:`, `chore:`). Run the tests before committing.
- The version lives only in the TOCs' `## Version:` line (both TOCs). For a release, bump it there, commit, then tag `vX.Y.Z` and push the tag. `AG.version` reads it at runtime.
- Release zips go on GitHub Releases, not in the repo (`*.zip` is ignored). Build one with
  `git archive --format=zip --prefix=AdventureGuideForever/ -o AdventureGuideForever-vX.Y.Z.zip vX.Y.Z:AdventureGuideForever`.
- `.gitattributes` keeps LF line endings everywhere.
