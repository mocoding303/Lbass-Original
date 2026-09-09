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
