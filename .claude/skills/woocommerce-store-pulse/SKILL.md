---
name: woocommerce-store-pulse
description: Weekly business health check for Lbass Original on WooCommerce — orders and cancellations, ageing stock, what sells fastest (once there are enough sales), and the visitor-to-buyer funnel from Google Analytics 4. Use when asked how the store is doing, why sales are low, what to discount, what stock to buy, or for a weekly business report.
---

# Store Pulse (WooCommerce)

Read-only analysis of the Lbass Original store at `https://www.lbassoriginal.com` (WordPress + WooCommerce, prices in MAD). Recommend; never change orders, products or prices from this skill. Use only `GET` requests.

## Access

Orders and products come from the WooCommerce REST API (`/wp-json/wc/v3/`), using a **Read**-only API key.

- **On the owner's Mac:** the key is in the shell as `WC_CONSUMER_KEY` and `WC_CONSUMER_SECRET`. Call:
  ```bash
  curl -s -u "$WC_CONSUMER_KEY:$WC_CONSUMER_SECRET" "https://www.lbassoriginal.com/wp-json/wc/v3/<endpoint>"
  ```
- **In a cloud session:** the key is saved as a network secret for `www.lbassoriginal.com` and added by the proxy. Call the same URL with `curl -s` and no `-u`.

If neither works (401/403), stop and say the API key is missing; do not guess figures.

Paginate with `per_page=100&page=N`; the `X-WP-TotalPages` response header (use `curl -s -D -`) gives the page count.

## Before the first analysis: learn how products are recorded

Fetch 5 recent products (`products?per_page=5&orderby=date&order=desc`) and check where brand, size and condition live: `categories`, `tags`, `attributes` (e.g. `pa_size`), or a `brands` field. Use what the data shows; do not assume. Note anything inconsistent (e.g. a size in the name that differs from the size attribute).

## Steps

Default window: last 28 days, compared with the previous 28. Use 90 days if asked or if the numbers are too small to read. Dates go in ISO 8601 (`2026-10-01T00:00:00`).

### 1. Orders and cancellations

```
orders?after=<start>&before=<end>&status=any&per_page=100&page=N
```

Fields to use: `number`, `status`, `date_created`, `date_completed`, `payment_method_title`, `shipping.city` (fall back to `billing.city`), `line_items[].product_id|name|quantity|total`.

- **Completed sales** = status `completed` or `processing`.
- **Lost** = `cancelled`, `refunded`, `failed`. Report each separately.
- Ignore `pending` and `checkout-draft` older than 24 h as abandoned checkouts; count them on their own line.
- **Test orders:** the owner places real test orders. Exclude any order whose `customer_note` or a `meta_data` value contains `test`, and say how many were excluded. (Owner: put the word "test" in the order note, or move test orders to the Bin.)

Report: completed orders and revenue, lost orders by status, rate of each, payment method (cash on delivery vs other), cities, and repeat orders for the same product.

### 2. Funnel: from Google Analytics 4 (via the Supermetrics connector)

Find the GA4 data source with `data_source_discovery`, its account with `accounts_discovery`, and field ids with `field_discovery`. Query for the same window: sessions, add-to-carts, checkouts, ecommerce purchases, and sessions by source/medium and by device.

Report each funnel step as a count and as % of the step before, and name the biggest drop. Reference points, for context only: add-to-cart 5–10 % of sessions, conversion 1–3 %.

If GA4 is not connected, or it has sessions but no ecommerce events, skip this step and say exactly that: the funnel needs GA4 with WooCommerce ecommerce tracking (e.g. the Google for WooCommerce or GTM4WP plugin). Do not estimate the funnel from orders alone.

### 3. Ageing stock

```
products?status=publish&stock_status=instock&per_page=100&page=N
```

Days listed = today − `date_created`. Bucket: 0–14, 15–30, 31–60, 60+. For 60+ items list name, brand, type, size and `price`.

### 4. What sells (only with enough data)

Join completed orders' line items to products by `product_id` (fetch `products/<id>` for items no longer in stock). Days to sell = order `date_created` − product `date_created`. Group by brand, type, size, condition, and price band (<300, 300–499, 500–699, 700+ MAD).

**Sample-size rule:** fewer than 30 completed items in the window → no rankings or "best sellers". Say how many sales there are, list them, and state that patterns are not yet reliable. Never draw a conclusion from a group with fewer than 5 sales.

## Output

1. **Headline:** one sentence: the single biggest problem this period, with its number.
2. **Orders:** completed, lost by status, abandoned checkouts, test orders excluded.
3. **Funnel:** step | count | % of previous | change vs previous period. Or the GA4 notice.
4. **Traffic:** sources and devices (from GA4).
5. **Stock:** ageing buckets, the 60+ list, data problems found.
6. **What sells:** or the sample-size notice.
7. **Top 3 actions:** ranked by expected impact on completed orders, each tied to a number above. Do not suggest a discount on items listed under 30 days.

Site rules still apply to any suggested change: Arabic RTL copy, real product photos only, and no silent changes to tracking or structured data.
