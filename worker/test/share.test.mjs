// Run with: node --test worker/test/   (no packages needed)
import { test } from "node:test";
import assert from "node:assert/strict";
import { checkShare, cleanNotes, buildIssue } from "../src/share.js";
import worker, { handleShare } from "../src/index.js";
import { renderPage } from "../src/page.js";

const GOOD = [
  "AGF1 version=0.7.0 id=0123abcd4567ef89",
  "B deadmines vancleef kills=3 npc=639 display=2029 name=Edwin VanCleef",
  "L deadmines vancleef 5191:2 5193:1",
  "S deadmines vancleef 6713:4",
  "END 3",
].join("\n");

test("a real export passes, cleaned to just its lines", () => {
  const pasted = "Here you go!\r\n```text\r\n" + GOOD.replace(/\n/g, "\r\n") + "\r\n```\r\nthanks";
  const r = checkShare(pasted);
  assert.equal(r.ok, true);
  assert.equal(r.text, GOOD);
  assert.equal(r.bosses, 1);
  assert.equal(r.shareId, "0123abcd4567ef89");
});

test("broken or hostile pastes are turned away with a reason", () => {
  const bad = {
    empty: "",
    notAShare: "hello there",
    badHeader: GOOD.replace("id=0123abcd4567ef89", "id=NOT-HEX"),
    cutOff: GOOD.split("\n").slice(0, 3).join("\n"),
    wrongCount: GOOD.replace("END 3", "END 7"),
    strayLine: GOOD.replace("END 3", "<script>alert(1)</script>\nEND 4"),
    badKey: GOOD.replace("B deadmines vancleef", "B dead-mines vancleef"),
    zeroId: GOOD.replace("5191:2", "0:2"),
    hugeId: GOOD.replace("5191:2", "999999999999:2"),
    noBosses: "AGF1 version=0.7.0 id=0123abcd4567ef89\nEND 0",
    tooLong: GOOD + "x".repeat(300_000),
  };
  for (const [name, text] of Object.entries(bad)) {
    const r = checkShare(text);
    assert.equal(r.ok, false, name);
    assert.ok(r.error.length > 10, name);
  }
});

test("notes can't mention people or break out of the quote", () => {
  const notes = cleanNotes("Hi @someone\n```\nAGF1 version=9 id=ffffffff\n```");
  assert.ok(!/@[a-z]/i.test(notes));
  assert.ok(!notes.includes("`"));
  assert.ok(notes.split("\n").every((ln) => ln.startsWith("> ")));
  assert.equal(cleanNotes("   "), "");
  assert.equal(cleanNotes(42), "");
});

test("the issue matches the issue form's shape", () => {
  const issue = buildIssue(checkShare(GOOD), "Fun fight");
  assert.match(issue.title, /^\[Learned\] Data from the game \(1 boss\)$/);
  assert.ok(issue.body.startsWith("### Learned data\n\n```text\nAGF1 version=0.7.0"));
  assert.ok(issue.body.includes("> Fun fight"));
  assert.ok(buildIssue(checkShare(GOOD), "").body.includes("_No response_"));
});

function post(body, headers = {}) {
  return new Request("https://agf-share.example.workers.dev/share", {
    method: "POST",
    headers: { "Content-Type": "application/json", Origin: "https://agf-share.example.workers.dev", ...headers },
    body: JSON.stringify(body),
  });
}

const ENV = { REPO: "owner/repo", GITHUB_TOKEN: "test-token", TURNSTILE_SECRET: "test-secret" };

async function withFetch(fake, fn) {
  const real = globalThis.fetch;
  globalThis.fetch = fake;
  try { return await fn(); } finally { globalThis.fetch = real; }
}

test("a good share becomes a GitHub issue", async () => {
  const calls = [];
  const res = await withFetch(async (url, init) => {
    calls.push({ url: String(url), init });
    if (String(url).includes("turnstile")) return Response.json({ success: true });
    return Response.json({ html_url: "https://github.com/owner/repo/issues/7" }, { status: 201 });
  }, () => handleShare(post({ data: GOOD, notes: "hi", turnstile: "tok" }), ENV));
  const out = await res.json();
  assert.equal(res.status, 200);
  assert.deepEqual(out, { ok: true, url: "https://github.com/owner/repo/issues/7", bosses: 1 });
  const gh = calls.find((c) => c.url.includes("api.github.com"));
  assert.equal(gh.url, "https://api.github.com/repos/owner/repo/issues");
  assert.equal(gh.init.headers.Authorization, "Bearer test-token");
  assert.ok(JSON.parse(gh.init.body).body.includes("AGF1 version=0.7.0"));
});

test("bots, other sites, and junk never reach GitHub", async () => {
  let github = 0;
  const fake = async (url) => {
    if (String(url).includes("turnstile")) return Response.json({ success: false });
    github += 1;
    return Response.json({}, { status: 201 });
  };
  await withFetch(fake, async () => {
    assert.equal((await handleShare(post({ data: GOOD, turnstile: "bad" }), ENV)).status, 403);
    assert.equal((await handleShare(post({ data: GOOD }, { Origin: "https://evil.example" }), ENV)).status, 403);
    const noBot = { ...ENV, TURNSTILE_SECRET: undefined };
    assert.equal((await handleShare(post({ data: "nope" }), noBot)).status, 400);
    const broken = new Request("https://agf-share.example.workers.dev/share", { method: "POST", body: "{not json" });
    assert.equal((await handleShare(broken, noBot)).status, 400);
  });
  assert.equal(github, 0);
});

test("a GitHub outage gives the player a kind message", async () => {
  const env = { ...ENV, TURNSTILE_SECRET: undefined };
  const res = await withFetch(async () => new Response("down", { status: 500 }), () => handleShare(post({ data: GOOD }), env));
  assert.equal(res.status, 502);
  assert.match((await res.json()).error, /try again/);
});

test("the page renders and escapes its settings", async () => {
  const html = renderPage({ TURNSTILE_SITE_KEY: '"><script>x</script>', REPO: "owner/repo" });
  assert.ok(html.includes("Share what you learned"));
  assert.ok(!html.includes("<script>x</script>"));
  const res = await worker.fetch(new Request("https://agf-share.example.workers.dev/"), {});
  assert.equal(res.status, 200);
  assert.match(res.headers.get("Content-Type"), /text\/html/);
  assert.equal((await worker.fetch(new Request("https://agf-share.example.workers.dev/nope"), {})).status, 404);
});
