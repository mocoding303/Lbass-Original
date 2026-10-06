# SEO routine: Search Console + GEO

How to use the `gsc` (Google Search Console) and `geo-optimizer` tools set up in `.mcp.json`. Setup details are in `README.md`.

**Two things to keep in mind**

- These tools only work in Claude Code **on the Mac, started from Terminal**. They do not work in the Claude phone app or in web/cloud sessions. The Search Console key lives only on the Mac.
- Nothing reaches the live store automatically. This repo is a copy of the theme. A fix made here must be copied into Shopify (Online Store → Themes → Edit code). Run **Duplicate theme** first so there is a backup.

## Start a session

1. Open **Terminal**.
2. Run:
   ```bash
   cd ~/Lbass-Original && git pull && claude
   ```
3. Type requests in plain English inside Claude's box (the one with `>`), not at the `%` prompt.

## What to run, and when

End every request with **"and tell me the top 3 actions"**. Add **"don't edit files, just recommend"** when you only want advice: Claude runs in Auto mode and can edit files without asking.

| When | Type this | What you get |
|------|-----------|--------------|
| Weekly | `run the gsc-seo-weekly-report for lbassoriginal.com` | Clicks, impressions, top pages, change vs last week |
| Monthly | `run gsc-content-opportunities` | Pages seen in Google but rarely clicked. Rewrite their title and description |
| Monthly | `run gsc-indexing-audit` | Product pages Google has not indexed. This matters most for one-of-one stock |
| Monthly | `run gsc-cannibalization-check` | Two pages competing for the same search |
| Weekly | `run shopify-store-pulse` | Visitor-to-buyer funnel, cancellations, traffic sources, ageing stock. Uses the claude.ai Shopify connector, so it also works in web sessions |
| Every 2–3 months, or after big site changes | `run a GEO audit on https://www.lbassoriginal.com and give me the top 5 fixes` | Visibility to ChatGPT, Perplexity, Gemini |

Plain questions also work, for example:

- `which search terms bring visitors from Morocco this month?`
- `compare the last 28 days to the previous 28`
- `why did traffic drop on <date>?`

## Applying a fix

1. Ask Claude to explain the change first, then to make it in the repo.
2. In Shopify, **Duplicate theme** (backup).
3. Copy the changed file into the theme code editor and save.
4. Check the live page on a phone.

GEO-specific rules for this theme (no `geo fix --apply`, edit the existing `assets/llms.txt` and `templates/robots.txt.liquid`, no silent JSON-LD changes) are in `.claude/skills/geo-optimizer/SKILL.md`.

## Maintenance

- **Key file:** stays in `~/.config/gsc/service-account.json`. Never move it into the repo folder and never send it to anyone. If the Mac is lost or the key leaks: Google Cloud → IAM & Admin → Service Accounts → Keys → delete it, then create a new one.
- **A server shows ✘ in `/mcp`:** select it → Enter → **Reconnect**. If it still fails, press Enter on it to read the error.
- **`claude: command not found`:** run `source ~/.local/bin/env`, then `claude`.
- **Shell vs Claude:** a line ending in `%` is the Mac shell (commands only). The box with `>` under the Claude logo is Claude (plain English).
