# The share page

A small [Cloudflare Worker](https://developers.cloudflare.com/workers/) that lets players send
what learning mode found **without a GitHub account**:

1. In game, `/ag share` shows the export and this page's link.
2. The player pastes the export on the page and clicks **Send**.
3. The Worker checks it (`src/share.js`, the same rules as `tools/learned_intake.py`) and files
   it as an issue on the repo, shaped like the "Share learned data" issue form.
4. The existing **Learned data intake** Action turns the issue into a pull request.

Junk, spam, and anything that isn't a share is turned away before it reaches GitHub.
[Turnstile](https://developers.cloudflare.com/turnstile/) (Cloudflare's bot check, usually
invisible) keeps bots out. Player notes are quoted and can't @mention anyone.

| File | What it is |
|---|---|
| `src/index.js` | The Worker: serves the page (`GET /`) and takes shares (`POST /share`). |
| `src/share.js` | Checks a share and builds the GitHub issue. |
| `src/page.js` | The page itself. |
| `test/share.test.mjs` | Tests: `node --test worker/test/` (no packages needed). |
| `wrangler.toml` | Worker name, repo, and the Turnstile site key. |

`tools/test_addon.py` also checks that a real export from the addon passes the Worker and
that the issue it writes passes the intake script.

## Setup (one time, about 15 minutes)

You need Node.js (already installed for the tests) and:

### 1. A Cloudflare account

Free: <https://dash.cloudflare.com/sign-up>. The free Workers plan allows 100,000 requests a day.

### 2. Deploy the Worker

```powershell
cd worker
npx wrangler@4 login
npx wrangler@4 deploy
```

`login` opens your browser to approve Wrangler. `deploy` prints the page's address, something
like `https://agf-share.<your-subdomain>.workers.dev`. It works right away, but answers "isn't set
up yet" until it has a GitHub token (next step).

### 3. A GitHub token that can only file issues

At <https://github.com/settings/personal-access-tokens/new> (fine-grained token):

- **Token name:** `agf-share page`
- **Expiration:** up to a year. Put a reminder in your calendar to renew it.
- **Repository access:** Only select repositories, then `adventure-guide-forever`
- **Permissions:** Repository permissions, then **Issues: Read and write**. Nothing else.
  (Metadata: Read is added automatically.)

Generate it, copy it, and hand it straight to Cloudflare. It's stored encrypted there and
never goes in the repo:

```powershell
npx wrangler@4 secret put GITHUB_TOKEN
```

Issues the page files show up under your GitHub account, labeled "Sent from the share page".

### 4. Turnstile (the bot check)

In the Cloudflare dashboard, open **Turnstile**, then **Add widget**:

- **Widget name:** `agf-share`
- **Hostname:** the `agf-share.<your-subdomain>.workers.dev` address from step 2
- **Widget mode:** Managed

Put the **site key** in `wrangler.toml` (`TURNSTILE_SITE_KEY = "..."`; it's public, so it's fine
in the repo). Then store the **secret key** and deploy again:

```powershell
npx wrangler@4 secret put TURNSTILE_SECRET
npx wrangler@4 deploy
```

### 5. Point the addon at it

Set `AG.SHARE_PAGE_URL` in `AdventureGuideForever/Share.lua` to the page's address. The Share
window then shows that link with "No account needed" wording, instead of the GitHub form.

### 6. Try it

Open the page, paste a real `/ag share` export, and click **Send**. The page links to the
new issue, and the Action should open a pull request within a minute or two.

## Changing it later

- Edit `src/`, run `node --test worker/test/`, then `npx wrangler@4 deploy` from `worker/`.
- `npx wrangler@4 tail` shows live logs. The Worker logs only GitHub errors, never shares or IPs.
- To see it locally: `npx wrangler@4 dev` (Turnstile is skipped while its keys are empty;
  put `GITHUB_TOKEN=...` in `worker/.dev.vars` to file real issues, which is gitignored).
