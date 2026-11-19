// Checks a pasted /ag share export before it becomes a public GitHub issue, and builds
// that issue. The rules mirror tools/learned_intake.py (the intake checks everything again
// in the GitHub Action; this just keeps junk and spam out of the repo).
//
// Export format (AdventureGuideForever/Share.lua):
//   AGF1 version=<addon version> id=<random share ID>
//   B <instKey> <bossKey> kills=<n> npc=<id> display=<id> name=<boss name>
//   L <instKey> <bossKey> <itemID>:<count> ...
//   S <instKey> <bossKey> <spellID>:<count> ...
//   END <number of B, L, and S lines>

export const LIMITS = {
  maxChars: 200_000, // the whole paste
  maxLines: 5000,
  maxId: 100_000_000,
  maxCount: 1_000_000,
  maxEntries: 500, // items or spells on one line
  maxNotes: 1000,
};

const KEY = /^[a-z0-9]{1,64}$/;
const SHARE_ID = /^[0-9a-f]{8,32}$/;
const VERSION = /^[0-9A-Za-z.\-]{1,20}$/;
const HEADER = /^AGF1 version=(\S+) id=(\S+)$/;
const BOSS = /^B (\S+) (\S+) kills=(\d+) npc=(\d+) display=(\d+) name=(.*)$/;
const LIST = /^([LS]) (\S+) (\S+) ((?:\d+:\d+ ?)+)$/;
const END = /^END (\d+)$/;

const CUT_OFF = "The paste looks cut off. In game, open the Share window again and copy everything in the big box.";

class ShareError extends Error {}

function number(text, limit) {
  const n = Number(text);
  if (!Number.isSafeInteger(n) || n < 0 || n > limit) throw new ShareError(`A number is out of range: ${text.slice(0, 20)}`);
  return n;
}

function keys(inst, boss) {
  if (!KEY.test(inst) || !KEY.test(boss)) throw new ShareError("A dungeon or boss name in the paste is damaged.");
}

// Returns { ok: true, text, shareId, version, bosses } with the export cleaned to just its
// lines, or { ok: false, error } with a message for the player.
export function checkShare(input) {
  try {
    if (typeof input !== "string" || !input.trim()) throw new ShareError("Paste what the Share window shows first.");
    if (input.length > LIMITS.maxChars) throw new ShareError("That paste is far too long to be a share.");
    const lines = input.replace(/\r/g, "").split("\n").map((ln) => ln.trim());
    const start = lines.findIndex((ln) => ln.startsWith("AGF1 "));
    if (start < 0) throw new ShareError("This isn't a share from the addon. It should start with a line beginning AGF1.");
    const header = HEADER.exec(lines[start]);
    if (!header || !VERSION.test(header[1]) || !SHARE_ID.test(header[2])) {
      throw new ShareError("The first line (AGF1 ...) is damaged. Copy it again from the Share window.");
    }
    const out = [lines[start]];
    const bosses = new Set();
    let records = 0;
    for (const ln of lines.slice(start + 1, start + 1 + LIMITS.maxLines)) {
      if (!ln || ln.startsWith("```")) continue;
      const end = END.exec(ln);
      if (end) {
        if (Number(end[1]) !== records) throw new ShareError(CUT_OFF);
        if (bosses.size === 0) throw new ShareError("This share is empty. Run a dungeon with learning mode on first.");
        out.push(ln);
        return { ok: true, text: out.join("\n"), shareId: header[2], version: header[1], bosses: bosses.size };
      }
      records += 1;
      let m;
      if ((m = BOSS.exec(ln))) {
        keys(m[1], m[2]);
        number(m[3], LIMITS.maxCount); // kills
        number(m[4], LIMITS.maxId); // NPC ID
        number(m[5], LIMITS.maxId); // display ID
        bosses.add(`${m[1]}/${m[2]}`);
      } else if ((m = LIST.exec(ln))) {
        keys(m[2], m[3]);
        const entries = m[4].trim().split(/\s+/);
        if (entries.length > LIMITS.maxEntries) throw new ShareError("One line of the paste has too many entries.");
        for (const entry of entries) {
          const [id, count] = entry.split(":");
          if (number(id, LIMITS.maxId) === 0) throw new ShareError("An ID of 0 isn't valid.");
          number(count, LIMITS.maxCount);
        }
        bosses.add(`${m[2]}/${m[3]}`);
      } else {
        throw new ShareError(`Couldn't read this line: ${ln.slice(0, 60)}`);
      }
      out.push(ln);
    }
    throw new ShareError(CUT_OFF);
  } catch (err) {
    if (err instanceof ShareError) return { ok: false, error: err.message };
    throw err;
  }
}

// Optional notes from the player, made safe for a public issue: plain text, short, quoted,
// and unable to @mention anyone.
export function cleanNotes(notes) {
  if (typeof notes !== "string") return "";
  const text = notes.replace(/[\u0000-\u0008\u000b-\u001f\u007f]/g, "").trim().slice(0, LIMITS.maxNotes);
  if (!text) return "";
  return text
    .replace(/@/g, "@​")
    .replace(/`/g, "'")
    .split("\n")
    .map((ln) => `> ${ln}`)
    .join("\n");
}

// The issue, in the same shape as the "Share learned data" issue form, so the existing
// GitHub Action (.github/workflows/learned-data.yml) picks it up unchanged.
export function buildIssue(checked, notes) {
  const quoted = cleanNotes(notes);
  const body = [
    "### Learned data",
    "",
    "```text",
    checked.text,
    "```",
    "",
    "### Anything else? (optional)",
    "",
    quoted || "_No response_",
    "",
    "<sub>Sent from the share page, so no GitHub account was needed.</sub>",
  ].join("\n");
  const count = checked.bosses === 1 ? "1 boss" : `${checked.bosses} bosses`;
  return { title: `[Learned] Data from the game (${count})`, body };
}
