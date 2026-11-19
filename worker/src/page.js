// The share page itself: one paste box and a Send button.

function escapeHtml(s) {
  return String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
}

export function renderPage(env = {}) {
  const siteKey = escapeHtml(env.TURNSTILE_SITE_KEY || "");
  const repo = escapeHtml(env.REPO || "");
  const turnstile = siteKey
    ? `<script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>`
    : "";
  const widget = siteKey ? `<div class="cf-turnstile" data-sitekey="${siteKey}" data-theme="dark"></div>` : "";
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Share with Adventure Guide Forever</title>
<meta name="description" content="Send what Adventure Guide Forever's learning mode found, so the guide grows for everyone.">
${turnstile}
<style>
  :root {
    --bg: #17120d; --panel: #221a12; --border: #5a4630; --text: #eee3cf; --muted: #b6a68c;
    --gold: #f2c14e; --accent: #8c1d18; --accent-hover: #a8241e; --ok: #7fd17f; --bad: #ff8a7a;
  }
  * { box-sizing: border-box; }
  body {
    margin: 0; background: var(--bg); color: var(--text);
    font: 16px/1.5 system-ui, -apple-system, "Segoe UI", sans-serif;
  }
  main { max-width: 720px; margin: 0 auto; padding: 32px 16px 48px; }
  h1 { color: var(--gold); font-size: 1.6rem; margin: 0 0 4px; }
  .lede { color: var(--muted); margin: 0 0 24px; }
  ol { padding-left: 1.3em; margin: 0 0 16px; }
  li { margin: 4px 0; }
  kbd {
    background: #00000055; border: 1px solid var(--border); border-radius: 4px;
    padding: 0 5px; font: 0.9em ui-monospace, Consolas, monospace;
  }
  label { display: block; font-weight: 600; margin: 16px 0 6px; }
  textarea {
    width: 100%; background: #0e0b08; color: var(--text); border: 1px solid var(--border);
    border-radius: 6px; padding: 10px; font: 13px/1.4 ui-monospace, Consolas, monospace; resize: vertical;
  }
  textarea:focus { outline: 2px solid var(--gold); outline-offset: 1px; }
  #data { min-height: 220px; }
  #notes { min-height: 70px; font-family: inherit; font-size: 15px; }
  .row { display: flex; flex-wrap: wrap; gap: 16px; align-items: center; margin-top: 18px; }
  button {
    background: var(--accent); color: #fff; border: 1px solid #c9a34a; border-radius: 6px;
    padding: 10px 26px; font-size: 1rem; font-weight: 600; cursor: pointer;
  }
  button:hover:not(:disabled) { background: var(--accent-hover); }
  button:disabled { opacity: 0.6; cursor: default; }
  #status { min-height: 1.5em; margin-top: 14px; }
  #status.ok { color: var(--ok); } #status.bad { color: var(--bad); }
  #status a { color: var(--gold); }
  .fine { color: var(--muted); font-size: 0.85rem; margin-top: 32px; border-top: 1px solid var(--border); padding-top: 14px; }
  .fine a { color: var(--muted); }
</style>
</head>
<body>
<main>
  <h1>Share what you learned</h1>
  <p class="lede">Help Adventure Guide Forever grow: send the loot, abilities, and boss details your learning mode found. No account needed.</p>
  <ol>
    <li>In game, type <kbd>/ag share</kbd> (or click Share in the reminder).</li>
    <li>Click the big box in the Share window and press <kbd>Ctrl</kbd>+<kbd>C</kbd>.</li>
    <li>Paste it below with <kbd>Ctrl</kbd>+<kbd>V</kbd> and click <b>Send</b>.</li>
  </ol>
  <form id="form">
    <label for="data">What the Share window shows</label>
    <textarea id="data" name="data" spellcheck="false" autocomplete="off" required
      placeholder="AGF1 version=... id=...&#10;B ...&#10;END ..."></textarea>
    <label for="notes">Anything else? <span style="font-weight:400;color:var(--muted)">(optional)</span></label>
    <textarea id="notes" name="notes" maxlength="1000"
      placeholder="Notes about the fights, or things that seemed different from the guide."></textarea>
    <div class="row">
      ${widget}
      <button id="send" type="submit">Send</button>
    </div>
    <div id="status" role="status" aria-live="polite"></div>
  </form>
  <p class="fine">
    What you send holds only boss, item, and spell IDs, kill counts, and a random ID (so a newer share
    from you replaces your older one). No character names. It's posted publicly as an issue on
    ${repo ? `<a href="https://github.com/${repo}" rel="noopener">the addon's GitHub page</a>` : "the addon's GitHub page"},
    and a maintainer reviews it before it joins the next release.
  </p>
</main>
<script>
  const form = document.getElementById("form");
  const status = document.getElementById("status");
  const send = document.getElementById("send");
  function show(text, kind, link) {
    status.className = kind || "";
    status.textContent = text;
    if (link) {
      const a = document.createElement("a");
      a.href = link; a.rel = "noopener"; a.textContent = "See it on GitHub";
      status.append(" ", a);
    }
  }
  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const data = document.getElementById("data").value;
    if (!data.trim()) { show("Paste what the Share window shows first.", "bad"); return; }
    const tokenField = form.querySelector('[name="cf-turnstile-response"]');
    send.disabled = true;
    show("Sending...");
    try {
      const res = await fetch("/share", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ data, notes: document.getElementById("notes").value, turnstile: tokenField ? tokenField.value : "" }),
      });
      const result = await res.json().catch(() => ({ ok: false, error: "Something went wrong. Please try again." }));
      if (result.ok) {
        const n = result.bosses === 1 ? "1 boss" : result.bosses + " bosses";
        show("Thank you! Your data on " + n + " is on its way into the guide.", "ok", result.url);
        form.reset();
      } else {
        show(result.error || "Something went wrong. Please try again.", "bad");
      }
    } catch {
      show("Couldn't reach the share page. Check your connection and try again.", "bad");
    } finally {
      send.disabled = false;
      if (window.turnstile) window.turnstile.reset();
    }
  });
</script>
</body>
</html>`;
}
