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
| `migrate_content.py` | One-time conversion of the old `Data/Guides` files into `Data/Content`. Kept for the record. |
| `test_addon.py` | Test suite: TOC integrity, data shape, and the registry's merge rules. |
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
