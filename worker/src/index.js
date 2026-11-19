// The share page for Adventure Guide Forever: players paste what /ag share shows, and this
// Worker checks it and files it as a GitHub issue, so nobody needs a GitHub account. The
// repo's "Learned data intake" Action then turns the issue into a pull request as usual.
//
// GET  /       the page
// POST /share  { data, notes, turnstile } -> { ok, url } or { ok: false, error }
//
// Settings (wrangler.toml [vars]): REPO, TURNSTILE_SITE_KEY.
// Secrets (wrangler secret put): GITHUB_TOKEN (fine-grained, this repo, Issues: write),
// TURNSTILE_SECRET. Turnstile is skipped when its keys aren't set (local testing).

import { checkShare, buildIssue, LIMITS } from "./share.js";
import { renderPage } from "./page.js";

const SECURITY_HEADERS = {
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "no-referrer",
  "X-Frame-Options": "DENY",
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store", ...SECURITY_HEADERS },
  });
}

async function verifyTurnstile(env, token, ip) {
  if (!env.TURNSTILE_SECRET) return true;
  if (typeof token !== "string" || !token) return false;
  const form = new FormData();
  form.append("secret", env.TURNSTILE_SECRET);
  form.append("response", token);
  if (ip) form.append("remoteip", ip);
  const res = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", { method: "POST", body: form });
  if (!res.ok) return false;
  const result = await res.json();
  return result.success === true;
}

async function createIssue(env, issue) {
  return fetch(`https://api.github.com/repos/${env.REPO}/issues`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.GITHUB_TOKEN}`,
      Accept: "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28",
      "User-Agent": "agf-share-page",
      "Content-Type": "application/json",
    },
    body: JSON.stringify(issue),
  });
}

export async function handleShare(request, env) {
  // Only this page may send shares.
  const origin = request.headers.get("Origin");
  if (origin && origin !== new URL(request.url).origin) return json({ ok: false, error: "Not allowed." }, 403);
  const size = Number(request.headers.get("Content-Length") || 0);
  if (size > LIMITS.maxChars + 10_000) return json({ ok: false, error: "That paste is far too long to be a share." }, 413);

  let payload;
  try {
    const raw = await request.text();
    if (raw.length > LIMITS.maxChars + 10_000) throw new Error("too long");
    payload = JSON.parse(raw);
  } catch {
    return json({ ok: false, error: "Something went wrong sending that. Please try again." }, 400);
  }

  const human = await verifyTurnstile(env, payload.turnstile, request.headers.get("CF-Connecting-IP"));
  if (!human) return json({ ok: false, error: "The page couldn't confirm you're not a bot. Reload it and try again." }, 403);

  const checked = checkShare(payload.data);
  if (!checked.ok) return json({ ok: false, error: checked.error }, 400);
  if (!env.GITHUB_TOKEN || !env.REPO) {
    return json({ ok: false, error: "The share page isn't set up yet. Please try again later." }, 503);
  }

  const res = await createIssue(env, buildIssue(checked, payload.notes));
  if (!res.ok) {
    console.log("GitHub said", res.status, (await res.text()).slice(0, 300));
    return json({ ok: false, error: "Couldn't hand it to GitHub just now. Please try again in a few minutes." }, 502);
  }
  const issue = await res.json();
  return json({ ok: true, url: issue.html_url, bosses: checked.bosses });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === "/" && (request.method === "GET" || request.method === "HEAD")) {
      return new Response(renderPage(env), {
        headers: { "Content-Type": "text/html; charset=utf-8", ...SECURITY_HEADERS },
      });
    }
    if (url.pathname === "/share" && request.method === "POST") return handleShare(request, env);
    return new Response("Not found", { status: 404, headers: SECURITY_HEADERS });
  },
};
