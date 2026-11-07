# Lbass Original — Shopify theme

Source of truth for the Lbass Original storefront (https://www.lbassoriginal.com).

## Contents

Snapshot of the live theme `LIVE — Lbass 20260904 (filters + newsletter)`
(`OnlineStoreTheme/207249506635`, role `MAIN`), pulled 2026-09-09 via the
Shopify Admin GraphQL API and verified byte-identical by MD5 (74/75 text files;
`config/settings_data.json` differs only by an auto-generated header the API adds).

```
assets/      theme assets (images, svg, mp4, llms.txt) — no .css or .js
config/      settings_schema.json (theme_info only), settings_data.json
layout/      theme.liquid, password.liquid
locales/     en.default.json, fr.json
sections/    lbass-hero, lbass-collection-hero  (the only {% schema %} files)
snippets/    48 snippets
templates/   18 .liquid templates (Vintage architecture — no JSON templates)
docs/        ARCHITECTURE-AUDIT.md
```

## Architecture in one line

Bespoke Vintage-architecture theme: no OS 2.0 JSON templates, no external CSS/JS
assets (everything inline), no merchant-editable theme settings, and two templates
(`index`, `page.vault`) that bypass the layout entirely with `{% layout none %}`.

See **[docs/ARCHITECTURE-AUDIT.md](docs/ARCHITECTURE-AUDIT.md)** before changing anything.

## Working on this repo

This snapshot is not connected to the store. Changes here do not deploy.
To sync, use the Shopify CLI (`shopify theme pull/push --theme 207249506635`)
or the Admin API, and re-verify checksums after any pull.

## SEO / GEO tooling for Claude Code

Committed so every Claude Code session on this repo can use them. Each MCP server asks for approval the first time a session starts it.

- **Google Search Console MCP** (`.mcp.json`, server `gsc`, from `AminForou/mcp-gsc`): set `GSC_CREDENTIALS_PATH` to a service-account JSON that has been added as a user on the Search Console property. The OAuth browser flow does not work in cloud sessions. Companion skills: `.claude/skills/gsc-*`.
- **GEO Optimizer** (`.claude/skills/geo-optimizer` + MCP server `geo-optimizer`, from `Auriti-Labs/geo-optimizer-skill`): AI-search visibility audits. The skill lists the constraints that apply to the live WordPress site. Cloud sessions need `www.lbassoriginal.com` allowed in the environment's network policy to audit the live site.

Both run through `uvx`; nothing is added to the theme itself. Day-to-day usage: `docs/SEO-ROUTINE.md`.

**WooCommerce Store Pulse** (`.claude/skills/woocommerce-store-pulse`): weekly orders, stock and funnel check. Needs a read-only WooCommerce REST API key (WordPress admin → WooCommerce → Settings → Advanced → REST API → Add key, permission **Read**). On the Mac, export it as `WC_CONSUMER_KEY` and `WC_CONSUMER_SECRET` in `~/.zshrc`; in cloud sessions, save it as a network secret for `www.lbassoriginal.com`. The funnel part reads GA4 through the claude.ai Supermetrics connector.
