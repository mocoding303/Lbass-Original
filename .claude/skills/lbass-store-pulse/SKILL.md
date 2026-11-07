---
name: lbass-store-pulse
description: Weekly business health check for Lbass Original — orders (WhatsApp, LB-… numbers stored in Cloudflare), stock from the Google Sheet, ageing pieces, newsletter growth, and visits. Use when asked how the store is doing, why sales are low, what to discount, what stock to buy, or for a weekly business report.
---

# Store Pulse

Read-only analysis of Lbass Original. **Never write**: no `wrangler deploy`, no `kv key put/delete`, no D1 statement other than `SELECT`, no edits to the Google Sheet, no running `update.sh`. Recommend; the owner applies changes.

## Where the data is

| Data | Location | How to read it |
|------|----------|----------------|
| Site code, config | `~/Lbass/static-site` on the owner's Mac | Read files |
| Products, prices, stock | Owner's Google Sheet (`update.sh` builds the site from it) | Google Drive connector (`read_file_content`), or the sheet/CSV URL found in `update.sh` |
| Orders (`LB-…`) | Cloudflare storage bound to the Worker `lbass-site` | `npx wrangler` read commands |
| Newsletter sign-ups | Cloudflare storage bound to the same Worker | `npx wrangler` read commands |
| Search visits | Google Search Console | the `gsc` MCP server |
| All visits | Cloudflare Web Analytics or GA4, if enabled | Ask the owner which is on; GA4 through the Supermetrics connector |

This skill needs the Mac (wrangler is logged in there). In a cloud session without the site folder, run only the Sheet and Search Console parts and say what was skipped.

## Step 0: learn the setup (every run; it is quick)

1. Read `~/Lbass/static-site/wrangler.toml` (or `wrangler.json`/`wrangler.jsonc`) and note the storage bindings: `kv_namespaces`, `d1_databases`, `r2_buckets`.
2. Read the Worker source (path in `main`) and find:
   - how an order is saved: binding, key format (e.g. `order:LB-…`), and the fields stored (date, items, prices, city, phone, status…);
   - how newsletter sign-ups are saved;
   - whether an order has any status field (confirmed, delivered, refused, cancelled).
3. Read `update.sh` to find the Google Sheet and its columns (name, brand, size, condition, price, stock, date added…).

State the setup in two lines in the report so the owner can correct it.

## Read commands (only these)

```bash
cd ~/Lbass/static-site
# KV
npx wrangler kv key list --binding=<BINDING> --remote --prefix=<order prefix>
npx wrangler kv key get <key> --binding=<BINDING> --remote
# D1
npx wrangler d1 execute <DB> --remote --command "SELECT ... "
```

Use `--remote` (live data, not local dev). Never print customers' phone numbers or full names in the report; aggregate them.

## Steps

Default window: last 28 days vs the previous 28; 90 days if asked or if numbers are too small.

### 1. Orders

Count `LB-…` orders by day, product, size, price, city (if stored). **These are orders started on WhatsApp, not confirmed sales.** If a status field exists, split them: confirmed, delivered, refused/cancelled, no outcome recorded. If none exists, say so in the headline and recommend recording one.

**Test orders:** exclude order numbers listed in `~/.config/lbass/test-orders.txt` (one `LB-…` per line) if the file exists, and say how many were excluded. If an order looks like a test (owner's own number, repeated within minutes), ask rather than guess.

### 2. Stock (from the Sheet)

- Pieces in stock, total value at listed price.
- Ageing: if the Sheet has a date-added column, bucket 0–14, 15–30, 31–60, 60+ days and list the 60+ pieces (name, brand, size, price). Without a date column, say so and recommend adding one.
- Data problems: missing size, price or photo; size in the name that differs from the size column; duplicate rows.

### 3. Visits

Search Console (`gsc`): clicks, impressions, top pages and queries. If Cloudflare Web Analytics or GA4 is available, add total visits, sources and devices. Orders ÷ visits = order rate; say which visit source was used.

### 4. Newsletter

New sign-ups in the window vs the previous one. Never list email addresses.

### 5. What sells (only with enough data)

Days to sell = order date − date added (needs the Sheet's date column). Group by brand, type, size, condition, price band (<300, 300–499, 500–699, 700+ MAD).

**Sample-size rule:** fewer than 30 orders in the window → no rankings. List the orders and say patterns are not yet reliable. No conclusion from a group with fewer than 5 orders.

## Output

1. **Setup seen:** two lines (bindings, order fields, sheet columns).
2. **Headline:** the single biggest problem, with its number.
3. **Orders:** started, outcomes (or "no outcome recorded"), tests excluded.
4. **Visits:** and order rate, with the source named.
5. **Stock:** ageing, 60+ list, data problems.
6. **Newsletter:** sign-ups and change.
7. **What sells:** or the sample-size notice.
8. **Top 3 actions:** ranked by expected impact on delivered orders, each tied to a number above.
