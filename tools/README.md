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
| `wowhead/extract_items.js` | Run in your browser's console on wowhead.com/forever. Reads item stats from Wowhead's item lists, filtered to ID ranges that cover every guide item (31 pages), into `wowhead/items.json`. |
| `build_items.py` | Keeps the ID ranges in `extract_items.js` current, and turns `items.json` into `Data/Generated/Items.lua` (item level, required level, armor, damage, stats). Run it after loot or quests change. |
| `compare_guides.py` | Reads `guides.json`, writes `wowhead/guide_facts.json` (IDs, names, levels, quests; committed), `Data/Generated/Quests.lua` (each dungeon's quests; `--quests` rebuilds just this from the facts), and `wowhead/guide_report.md` (where our guide disagrees; not committed). |
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

## Item stats (extract_items.js, build_items.py)

For gear search and suggestions, every item the guide lists needs its item level,
required level, and stats. Wowhead's item list pages include those, so the extractor
reads them a range of item IDs at a time (each range under the 1,000-item page limit).

1. Run `build_items.py` so `extract_items.js` lists the current item IDs.
2. Open https://www.wowhead.com/forever and its console, paste all of
   `wowhead/extract_items.js`, and run `await whItems()` (one page every 12 seconds,
   about 6 minutes; it stops at human verification and resumes like the others).
3. Run `copy(whItemsResult())` and save the clipboard as `wowhead/items.json`.
4. Run `build_items.py` again to write `Data/Generated/Items.lua`, then the tests. It
   lists any Wowhead field it doesn't know yet; add it to `STATS` or `IGNORE`.

## Learned data from players (learned_intake.py)

```
/ag share (in game)  --paste-->  share page (worker/)  --issue-->  Action  --> learned_intake.py
    --> tools/learned/community.json  --> Data/Generated/Community.lua  --> pull request
```

- `worker/` is the share page players paste into, with no GitHub account needed: a
  Cloudflare Worker that checks the paste and files it as an issue. Setup and deploys are
  in `worker/README.md`; its tests run with `node --test worker/test/`.
- `.github/ISSUE_TEMPLATE/learned-data.yml` is the same thing as a GitHub issue form, for
  people with a GitHub account (and the fallback until the share page is set up).
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
