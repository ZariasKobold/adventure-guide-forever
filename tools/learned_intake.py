"""Merge players' learned data (pasted from /ag share) into the addon.

Players paste their export into the "Share learned data" issue form. The GitHub Action
in .github/workflows/learned-data.yml runs this script on the issue body:

    python tools/learned_intake.py --from-env            # reads ISSUE_BODY, ISSUE_NUMBER
    python tools/learned_intake.py --file export.txt     # same, from a file (for testing)
    python tools/learned_intake.py --build               # just rebuild Community.lua

It validates every line, stores the submission in tools/learned/community.json (one entry
per anonymous share ID, so a player's newer share replaces their older one), and rebuilds
AdventureGuideForever/Data/Generated/Community.lua from all submissions. A maintainer
reviews the pull request before anything reaches players.

The export format is documented at the top of AdventureGuideForever/Share.lua.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from addon_env import ROOT, load_addon, to_py  # noqa: E402
from lua_writer import lua_value  # noqa: E402

COMMUNITY_JSON = ROOT / "tools" / "learned" / "community.json"
OUTPUT = ROOT / "AdventureGuideForever" / "Data" / "Generated" / "Community.lua"

MAX_LINES = 5000
MAX_ID = 100_000_000
MAX_COUNT = 1_000_000
MAX_ENTRIES = 500          # items or spells on one line
MAX_NAME = 60

KEY = re.compile(r"^[a-z0-9]{1,64}$")
SHARE_ID = re.compile(r"^[0-9a-f]{8,32}$")
VERSION = re.compile(r"^[0-9A-Za-z.\-]{1,20}$")
HEADER = re.compile(r"^AGF1 version=(\S+) id=(\S+)$")
BOSS = re.compile(r"^B (\S+) (\S+) kills=(\d+) npc=(\d+) display=(\d+) name=(.*)$")
LIST = re.compile(r"^([LS]) (\S+) (\S+) ((?:\d+:\d+ ?)+)$")
END = re.compile(r"^END (\d+)$")


class SubmissionError(ValueError):
    """The pasted text isn't a valid export. The message is shown to the player."""


def instance_keys() -> set[str]:
    _, ag = load_addon(re.compile(r"^Data/Instances\.lua$"))
    return {i["key"] for i in to_py(ag.Instances)}


def _number(text: str, limit: int, what: str) -> int:
    n = int(text)
    if n < 0 or n > limit:
        raise SubmissionError(f"{what} out of range: {text}")
    return n


def _clean_name(name: str) -> str | None:
    name = re.sub(r"[\x00-\x1f\x7f|]", "", name).strip()[:MAX_NAME]
    return name or None


def parse_export(text: str, valid_instances: set[str]) -> dict:
    """Read an export. Returns {"version", "id", "bosses": {"inst/boss": record}}."""
    lines = [ln.strip() for ln in text.replace("\r", "").split("\n")]
    try:
        start = next(i for i, ln in enumerate(lines) if ln.startswith("AGF1 "))
    except StopIteration:
        raise SubmissionError("No export found. It should start with a line beginning AGF1.") from None
    header = HEADER.match(lines[start])
    if not header:
        raise SubmissionError("The first line (AGF1 ...) is damaged.")
    version, share_id = header.groups()
    if not VERSION.match(version) or not SHARE_ID.match(share_id):
        raise SubmissionError("The first line (AGF1 ...) is damaged.")

    bosses: dict[str, dict] = {}
    records = 0
    for ln in lines[start + 1:start + 1 + MAX_LINES]:
        if not ln or ln.startswith("```"):
            continue
        end = END.match(ln)
        if end:
            if int(end.group(1)) != records:
                raise SubmissionError("The export looks cut off. Copy all of it from the Share window.")
            return {"version": version, "id": share_id, "bosses": bosses}
        records += 1
        if m := BOSS.match(ln):
            inst, boss, kills, npc, display, name = m.groups()
            rec = _record(bosses, inst, boss, valid_instances)
            rec["kills"] = _number(kills, MAX_COUNT, "kills")
            rec["npcID"] = _number(npc, MAX_ID, "NPC ID") or None
            rec["displayID"] = _number(display, MAX_ID, "display ID") or None
            rec["name"] = _clean_name(name)
        elif m := LIST.match(ln):
            kind, inst, boss, pairs = m.groups()
            rec = _record(bosses, inst, boss, valid_instances)
            entries = pairs.split()
            if len(entries) > MAX_ENTRIES:
                raise SubmissionError(f"Too many entries on one line for {inst}/{boss}.")
            target = rec["loot" if kind == "L" else "spells"]
            for entry in entries:
                id_text, count_text = entry.split(":")
                item_id = _number(id_text, MAX_ID, "ID")
                if item_id == 0:
                    raise SubmissionError("An ID of 0 isn't valid.")
                target[str(item_id)] = _number(count_text, MAX_COUNT, "count")
        else:
            raise SubmissionError(f"Couldn't read this line: {ln[:80]}")
    raise SubmissionError("The export has no END line. Copy all of it from the Share window.")


def _record(bosses: dict, inst: str, boss: str, valid_instances: set[str]) -> dict:
    if inst not in valid_instances:
        raise SubmissionError(f"Unknown instance: {inst[:40]}")
    boss = boss.lower()
    if not KEY.match(boss):
        raise SubmissionError(f"Unknown boss key: {boss[:40]}")
    return bosses.setdefault(f"{inst}/{boss}", {
        "kills": 0, "npcID": None, "displayID": None, "name": None, "loot": {}, "spells": {}})


def merge_submission(db: dict, submission: dict, issue: int | None, date: str) -> bool:
    """Store a submission under its share ID. Returns False if nothing changed."""
    entry = {"version": submission["version"], "issue": issue, "date": date,
             "bosses": submission["bosses"]}
    old = db["submitters"].get(submission["id"])
    if old and old.get("bosses") == entry["bosses"]:
        return False
    db["submitters"][submission["id"]] = entry
    return True


def aggregate(db: dict) -> dict:
    """Add up every submitter's latest share: {inst: [boss records]}."""
    totals: dict[str, dict] = {}
    for share_id in sorted(db["submitters"]):
        for key, rec in db["submitters"][share_id]["bosses"].items():
            t = totals.setdefault(key, {"kills": 0, "reports": 0, "names": Counter(),
                                        "npcs": Counter(), "displays": Counter(),
                                        "loot": Counter(), "spells": Counter()})
            t["kills"] += rec.get("kills", 0)
            t["reports"] += 1
            for field, counter in (("name", "names"), ("npcID", "npcs"), ("displayID", "displays")):
                if rec.get(field):
                    t[counter][rec[field]] += 1
            for list_name in ("loot", "spells"):
                for id_text, n in rec.get(list_name, {}).items():
                    t[list_name][int(id_text)] += n

    out: dict[str, list] = {}
    for key in sorted(totals):
        inst, boss = key.split("/")
        t = totals[key]

        def top(counter):
            return min(counter.items(), key=lambda kv: (-kv[1], str(kv[0])))[0] if counter else None

        out.setdefault(inst, []).append({
            "key": boss, "name": top(t["names"]), "npcID": top(t["npcs"]),
            "displayID": top(t["displays"]), "kills": t["kills"], "reports": t["reports"],
            "loot": [{"itemID": i, "count": n} for i, n in sorted(t["loot"].items())],
            "spells": [{"spellID": i, "count": n} for i, n in sorted(t["spells"].items())],
        })
    return out


BOSS_KEYS = ["key", "name", "npcID", "displayID", "kills", "reports", "loot", "spells",
             "itemID", "spellID", "count", "bosses"]


def render(agg: dict, submitters: int) -> str:
    lines = [
        "-- GENERATED FILE. Do not edit by hand.",
        "-- Built by tools/learned_intake.py from tools/learned/community.json: what players'",
        "-- learning mode found and shared with /ag share."
        + (f" {submitters} player share{'s' if submitters != 1 else ''} merged." if submitters else " Nothing merged yet."),
        "",
        "local _, AG = ...",
        "",
    ]
    for inst, bosses in agg.items():
        lines.append(f'AG:RegisterCommunity("{inst}", {lua_value({"bosses": bosses}, 0, BOSS_KEYS)})')
        lines.append("")
    return "\n".join(lines).rstrip("\n") + "\n"


def load_db() -> dict:
    return json.loads(COMMUNITY_JSON.read_text(encoding="utf-8"))


def save_db(db: dict) -> None:
    COMMUNITY_JSON.write_text(json.dumps(db, indent=2, sort_keys=True) + "\n", encoding="utf-8", newline="\n")


def build(db: dict) -> None:
    OUTPUT.write_text(render(aggregate(db), len(db["submitters"])), encoding="utf-8", newline="\n")


def summarize(submission: dict, issue: int | None) -> str:
    bosses = submission["bosses"]
    items = sum(len(r["loot"]) for r in bosses.values())
    spells = sum(len(r["spells"]) for r in bosses.values())
    kills = sum(r["kills"] for r in bosses.values())
    lines = [
        f"Learned data shared from the game (addon v{submission['version']})"
        + (f", submitted in #{issue}." if issue else "."),
        "",
        f"- {len(bosses)} bosses, {kills} kills, {items} item drops, {spells} spells",
        "",
        "| Boss | Kills | Items | Spells |",
        "|---|---|---|---|",
    ]
    for key in sorted(bosses)[:60]:
        r = bosses[key]
        lines.append(f"| {key} ({r['name'] or '?'}) | {r['kills']} | {len(r['loot'])} | {len(r['spells'])} |")
    if len(bosses) > 60:
        lines.append(f"| ...and {len(bosses) - 60} more | | | |")
    if issue:
        lines += ["", f"Closes #{issue}"]
    return "\n".join(lines) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--from-env", action="store_true", help="read ISSUE_BODY and ISSUE_NUMBER")
    src.add_argument("--file", type=Path, help="read the export from a file")
    src.add_argument("--build", action="store_true", help="only rebuild Community.lua")
    ap.add_argument("--summary", type=Path, help="write a pull request description here")
    ap.add_argument("--error", type=Path, help="write the player-facing error message here")
    args = ap.parse_args()

    db = load_db()
    if args.build:
        build(db)
        print(f"Rebuilt {OUTPUT.relative_to(ROOT)} from {len(db['submitters'])} shares")
        return 0

    if args.from_env:
        text = os.environ.get("ISSUE_BODY", "")
        issue = int(os.environ["ISSUE_NUMBER"]) if os.environ.get("ISSUE_NUMBER", "").isdigit() else None
    else:
        text, issue = args.file.read_text(encoding="utf-8"), None

    try:
        submission = parse_export(text, instance_keys())
    except SubmissionError as e:
        print(f"Rejected: {e}")
        if args.error:
            # Shown in an issue comment: break up @mentions so a crafted paste can't ping anyone.
            args.error.write_text(str(e).replace("@", "@​") + "\n", encoding="utf-8")
        return 2

    changed = merge_submission(db, submission, issue, dt.date.today().isoformat())
    if changed:
        save_db(db)
        build(db)
    if args.summary:
        args.summary.write_text(summarize(submission, issue), encoding="utf-8")
    print(f"{'Merged' if changed else 'Nothing new in'} share {submission['id']}: "
          f"{len(submission['bosses'])} bosses")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
