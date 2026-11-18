# Adventure Guide: Forever, developer tools

These run on your computer, not in the game. They need Python 3.10+ and `lupa`, which
embeds Lua 5.1 (the same Lua version WoW uses), so the tools load the addon's real files
instead of guessing at them.

```
python -m venv .venv
.venv\Scripts\pip install -r tools\requirements.txt
```

## Data pipeline

```
Wowhead (Forever)  --extract.js-->  wowhead/snapshot.json  --build_wowhead.py-->  Data/Generated/Wowhead.lua
                                                                                          |
Data/Content/*.lua (hand-written text)  -------------------------------------------------+--> Data/Registry.lua --> AG.Guides
```

| File | What it does |
|---|---|
| `wowhead/extract.js` | Run in your browser's console on wowhead.com/forever. Reads each instance's zone page and outputs `snapshot.json`. It pauses between pages and stops if Wowhead asks for human verification. |
| `wowhead/snapshot.json` | Raw data: every boss drop (item ID, name, quality, slot, source NPC) per zone, plus NPC names. Fetched 2026-11-16. |
| `build_wowhead.py` | Turns the snapshot into `Data/Generated/Wowhead.lua`. The tables at the top decide which zone is which instance, which wing each boss belongs to, which NPCs are trash, and which NPCs form one encounter. |
| `wowhead/extract_guides.js` | Run in your browser's console on wowhead.com/forever. Reads Wowhead's dungeon and raid overview guides into `wowhead/guides.json` (git-ignored: it holds Wowhead's own text). |
| `compare_guides.py` | Reads `guides.json`, writes `wowhead/guide_facts.json` (IDs, names, levels, quests; committed) and `wowhead/guide_report.md` (where our guide disagrees; not committed). |
| `apply_writing.py` | Merges drafted guide writing (a JSON file of instance and boss text) into `Data/Content/*.lua`, keeping the standard format. Drafts are input only; don't commit them. |
| `migrate_content.py` | One-time conversion of the old `Data/Guides` files into `Data/Content`. Kept for the record. |
| `learned_intake.py` | Reads players' `/ag share` exports, merges them into `learned/community.json`, and writes `Data/Generated/Community.lua`. See below. |
| `test_addon.py` | Test suite: TOC integrity, data shape, the registry's merge rules, sync messages, and the share intake. |
| `addon_env.py`, `lua_writer.py` | Shared helpers: load the addon in Lua, and write tidy Lua tables. |

## Everyday commands

```
.venv\Scripts\python tools\build_wowhead.py          # regenerate Wowhead.lua
.venv\Scripts\python -m unittest tools\test_addon.py  # run the tests
.venv\Scripts\python tools\test_addon.py --report    # coverage: bosses missing text or loot
```

## Refreshing from Wowhead

1. Open https://www.wowhead.com/forever/zones/dungeons, open the console, paste
   `wowhead/extract.js`, run `copy(await whExtract())`, and save the clipboard over
   `wowhead/snapshot.json`.
2. Run `build_wowhead.py`. Any boss in a multi-wing zone (Scarlet Monastery, Dire Maul,
   Blackrock Spire) that isn't in `WINGS` is reported. Add it there and rebuild.
3. Run the tests.

## Boss abilities and models (extract_npcs.js)

Spell IDs and model display IDs live on each boss's NPC page (244 pages). Reading them in
a burst triggers Wowhead's human verification, so this extractor reads one page every 8
seconds (about 33 minutes) and saves its progress in the browser, so it can be stopped
and resumed. At 4 seconds the limit tripped about halfway through. If it does trip, save
what you have with `copy(whNpcsResult())`, open any NPC page directly to get the check,
or wait 20 to 30 minutes for the limit to reset.

1. Open https://www.wowhead.com/forever and its console (F12, then Console).
2. Paste all of `wowhead/extract_npcs.js`, press Enter, then run `await whNpcs()`.
3. If it stops for human verification: reload, complete the check, paste the file
   again, and run `await whNpcs()`. It continues where it left off.
4. When it prints "Done", run `copy(whNpcsResult())` and save the clipboard as
   `wowhead/npcs.json`.
5. Run `build_wowhead.py`, then the tests.

`build_wowhead.py` keeps the NPC list inside `extract_npcs.js` in step with the snapshot.
Multi-NPC encounters use the lead NPC's model and list every member's spells once.
Generic spells (Dazed, Attack, Shoot) are left out (`NOISE_SPELLS`).

## Wowhead's dungeon guides (extract_guides.js, compare_guides.py)

Wowhead has an overview guide for each Forever dungeon and raid (location, levels, quests,
notable trash, and each boss's strategy and abilities). We use them to check and improve
our guide, not to copy from: `guides.json` holds their text, so it stays on your computer
(git-ignored), and everything in `Data/Content` is written in our own words. The addon and
the READMEs credit Wowhead as a source.

1. Open https://www.wowhead.com/forever and its console (F12, then Console).
2. Paste all of `wowhead/extract_guides.js`, press Enter, then run `await whGuides()`.
   It finds the guides through each dungeon's zone page (falling back to guessing the
   address from the dungeon's name) and reads one page every 12 seconds. Like the NPC
   extractor, it saves progress and stops at Wowhead's human verification; reload,
   complete the check, paste again, and rerun to continue.
3. When it prints "Done", run `copy(whGuidesResult())` and save the clipboard as
   `wowhead/guides.json`.
4. Run `compare_guides.py`, then read `wowhead/guide_report.md`: missing bosses,
   abilities we don't mention, level ranges that differ, and quests and trash to add.
   Fix the content files (or draft with `apply_writing.py`), then run the tests.

## Learned data from players (learned_intake.py)

```
/ag share (in game)  --paste-->  GitHub issue form  --Action-->  learned_intake.py
    --> tools/learned/community.json  --> Data/Generated/Community.lua  --> pull request
```

- `.github/ISSUE_TEMPLATE/learned-data.yml` is the form players paste into.
- `.github/workflows/learned-data.yml` runs on each new issue that holds an export. It
  passes the issue text through an environment variable (never into a shell command),
  runs `learned_intake.py --from-env`, runs the tests, and opens a pull request that closes
  the issue. A rejected paste gets a comment explaining why. The repo setting "Allow GitHub
  Actions to create and approve pull requests" must be on.
- `learned_intake.py` validates every line (known instances, lowercase boss keys, numeric
  IDs and counts within limits, cleaned names). Each share has a random ID, so a player's
  newer share replaces their older one; different players' shares add up. Run
  `learned_intake.py --file export.txt` to try an export locally, or `--build` to rebuild
  `Community.lua` after editing `community.json` by hand (for example, to remove a bad share).
- Community data joins learning mode's data in the guide (`AG:GetLearnedBosses`), so new
  bosses, drops, spells, and models appear the same way your own learned data does.
