---
name: shopify-store-pulse
description: Weekly business health check for Lbass Original from Shopify data — visitor-to-buyer funnel, orders and cancellations, traffic sources, ageing stock, and (once there are enough sales) what sells fastest by brand, size, type, condition and price. Use when asked how the store is doing, why sales are low, what to discount, what stock to buy, or for a weekly business report.
---

# Store Pulse

Read-only analysis of the Lbass Original Shopify store (prices in MAD). Uses the claude.ai **Shopify** connector: `run-analytics-query` (ShopifyQL) and `graphql_query` (Admin API). Never call `graphql_mutation`, `update-product`, `create-discount` or any write tool from this skill — recommend, do not change.

## How the catalogue is recorded

Every product is one-of-one (`totalInventory` 1, tag `One of One`). Use these fields rather than parsing titles:

| Dimension | Source |
|-----------|--------|
| Brand | `vendor` |
| Type | `productType` (Shoes, Jackets, …) and tags `type:*` |
| Size | option `Size` (also tag `Size …`) |
| Condition | tag `condition:new` / `condition:excellent` / `condition:very-good` / … |
| Gender | tag `gender:*` |
| Listed on | `publishedAt` (fall back to `createdAt`) |
| Price | `priceRangeV2.minVariantPrice.amount` |

## Steps

Default window: last 28 days, compared with the previous 28. Use 90 days if the user asks or if the 28-day numbers are too small to read.

### 1. Funnel (always)

```
FROM sessions SHOW sessions, sessions_with_cart_additions, sessions_that_reached_checkout, sessions_that_completed_checkout, conversion_rate SINCE -28d UNTIL today COMPARE TO previous_period
```

Report each step as a count and as % of the step before. Name the single biggest drop. Rough e-commerce reference points, for context only: add-to-cart 5–10 % of sessions, conversion 1–3 %.

### 2. Where visitors come from

```
FROM sessions SHOW sessions GROUP BY referrer_source SINCE -28d UNTIL today ORDER BY sessions DESC
FROM sessions SHOW sessions GROUP BY session_device_type SINCE -28d UNTIL today
FROM sales SHOW orders, total_sales GROUP BY order_referrer_source, order_referrer_name SINCE -90d UNTIL today
```

Note: Instagram and WhatsApp in-app browsers often hide the referrer, so much of `direct` is likely social. Say so; do not present `direct` as "people typing the URL".

### 3. Orders and cancellations

GraphQL, paginate with `pageInfo` until done. Filter `query: "created_at:>=YYYY-MM-DD"`:

```graphql
query Orders($first: Int!, $after: String, $q: String!) {
  orders(first: $first, after: $after, query: $q, sortKey: CREATED_AT, reverse: true) {
    nodes {
      name createdAt cancelledAt cancelReason test tags
      displayFinancialStatus displayFulfillmentStatus paymentGatewayNames
      shippingAddress { city }
      lineItems(first: 10) { nodes {
        title quantity
        originalUnitPriceSet { shopMoney { amount } }
        discountedUnitPriceAfterAllDiscountsSet { shopMoney { amount } }
        product { id vendor productType tags createdAt publishedAt }
      } }
    }
    pageInfo { hasNextPage endCursor }
  }
}
```

Exclude `test: true` and any order tagged `test` (the owner places real test orders and tags them). If such orders exist in the window, subtract them from the funnel's checkout counts too and say how many were removed. Report: orders, completed vs cancelled, cancel rate, `cancelReason`, minutes from order to cancellation, payment method (Cash on Delivery vs other), cities. Flag repeated orders for the same product and any order shipping outside Morocco.

### 4. Ageing stock

```graphql
query Active($first: Int!, $after: String) {
  products(first: $first, after: $after, query: "status:active inventory_total:>0", sortKey: CREATED_AT) {
    nodes { title vendor productType tags createdAt publishedAt options { name values }
            priceRangeV2 { minVariantPrice { amount } } }
    pageInfo { hasNextPage endCursor }
  }
}
```

Bucket by days listed: 0–14, 15–30, 31–60, 60+. For 60+ items list brand, type, size, price. Also flag data problems that hurt search and filtering, e.g. a size in the title that differs from the `Size` option.

### 5. What sells (only with enough data)

Join completed (not cancelled) order line items to their product. Days to sell = order `createdAt` − product `publishedAt`. Group by brand, type, size, condition, and price band (<300, 300–499, 500–699, 700+ MAD).

**Sample-size rule:** if there are fewer than 30 completed items in the window, do not report rankings or "best sellers". Say how many sales there are, list them, and state that patterns are not yet reliable. Never draw a conclusion from a group with fewer than 5 sales.

## Output

1. **Headline** — one sentence: the single biggest problem this period, with its number.
2. **Funnel table** — step | count | % of previous | change vs previous period.
3. **Orders** — completed, cancelled, cancel rate, notable patterns.
4. **Traffic** — sources and devices, with the `direct` caveat.
5. **Stock** — ageing buckets, 60+ list, data problems found.
6. **What sells** — or the sample-size notice.
7. **Top 3 actions** — ranked by expected impact on completed orders, each tied to a number above. Prefer fixes to the biggest funnel drop. Do not suggest a discount on items listed under 30 days.

Keep the brand rules in `CLAUDE.md` in mind when suggesting site changes (Arabic RTL, real photos only, do not change tracking hooks or structured data silently).
