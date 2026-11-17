# CLAUDE.md: Adventure Guide Forever

A World of Warcraft: Forever addon that rebuilds the retail **Adventure Guide** (dungeon and raid journal), which Forever ships without. Vault hub note: `Projects/Adventure Guide Forever/Adventure Guide Forever.md`.

## Layout

| Path | What it is |
|---|---|
| `AdventureGuideForever/` | **The addon** (the folder players install). Version lives in its TOC. |
| `AdventureGuideForever/Data/Content/<instance>.lua` | Hand-written guide text: intros, boss overviews, abilities with role alerts. **Edit these.** |
| `AdventureGuideForever/Data/Generated/Wowhead.lua` | Generated from Wowhead. **Never edit by hand**; run `tools/build_wowhead.py`. |
| `AdventureGuideForever/Data/Registry.lua` | Merges Content + Generated into `AG.Guides` at load. Its header documents the merge rules. |
| `AdventureGuideForever/Data/Instances.lua` | All 37 Forever instances (key, name, zone, levels). |
| `AdventureGuideForever/Learn.lua` | Learning mode: records loot, models, and boss spells from play. |
| `AdventureGuideForever/UI/` | Window, instance list, instance page, boss page, shared widgets. |
| `AdventureGuideProbe/` | Throwaway diagnostic addon (`/agprobe`). Not shipped. |
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
- Shift+J is still bound to `TOGGLEENCOUNTERJOURNAL` but opens Guild & Communities, so we claim it with `SetOverrideBindingClick`. `EJMicroButton` exists and is shown.
- `PlayerModel:SetDisplayInfo` works.
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

`tools/wowhead/extract.js` (zone pages: loot and NPC IDs) and `extract_npcs.js` (boss pages: spells and models) run in a normal browser on wowhead.com, slowly. **Never automate past Wowhead's human verification.** Fast bursts trip it; the NPC extractor waits 8 seconds per page and saves its progress so it can resume. Outputs: `tools/wowhead/snapshot.json` and `npcs.json` (fetched Nov 16 to 17, 2026). Wing assignments, trash filters, and multi-NPC encounters are explicit tables in `build_wowhead.py`.

## Status (Nov 17, 2026)

- **v0.3.0**, built but **not yet tested in game**. All 24 tests pass.
- 31 of 37 instances have Wowhead data (234 bosses, 1,049 items, 234 models, 868 spells). There's no data for Dalaran, Shaper's Terrace, Onyxia, or the Hyjal raids (which open Dec 9). Krol'dok uses its wiki loot list.
- Next: in-game test, then add luacheck and do a UI code review pass.

## Git and versioning

- Private repo: https://github.com/ZariasKobold/adventure-guide-forever (branch `main`).
- Conventional commits (`feat:`, `fix:`, `docs:`, `chore:`). Run the tests before committing.
- The version lives only in the TOCs' `## Version:` line (both TOCs). For a release, bump it there, commit, then tag `vX.Y.Z` and push the tag. `AG.version` reads it at runtime.
- Release zips go on GitHub Releases, not in the repo (`*.zip` is ignored). Build one with
  `git archive --format=zip --prefix=AdventureGuideForever/ -o AdventureGuideForever-vX.Y.Z.zip vX.Y.Z:AdventureGuideForever`.
- `.gitattributes` keeps LF line endings everywhere.
