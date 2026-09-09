# Summer Sale — «−30% على القطعة الثانية»

Operational runbook. Read `docs/ARCHITECTURE-AUDIT.md` first for theme context.

---

## What this campaign is

A real Shopify **automatic Buy-X-Get-Y discount**. Buy two eligible pieces, the
discount takes 30% off one of them at checkout. Shopify applies the money; the
theme only announces it.

**No item's own price changes, and no compare-at price is fabricated.**

### Why it was built this way

The original brief asked for a different mechanism: inflate each price by
28.57%, call that the compare-at, then show "−30%" so the customer pays ~90% of
the original. That was declined and the reasoning is worth keeping:

- **No price history exists.** `compareAtPrice` was `null` on all 64 products
  (checked 2026-09-09). The 128.57 DH would have been created and struck through
  the same day, on a one-of-one piece that has only ever had one price.
- **The Google & YouTube channel is live** (`Publication/359324156235`). Google's
  Misrepresentation policy covers fabricated discounts, and sale-price
  annotations require a genuinely established former price. Suspensions there hit
  the whole account.
- **The theme already forbade it.** `templates/product.liquid` (NEW-RETAIL
  REFERENCE note) states that a figure which was never our price is
  misrepresentation and risks the Merchant listings.
- Moroccan consumer law (Loi 31-08) regulates price-reduction advertising on the
  principle that the reference must be a price actually practised. **Not legal
  advice — confirm with a Moroccan avocat before any reference-price campaign.**

The 2nd-item mechanism reaches the same commercial goal honestly. Measured
against real store prices, the blended give-back on two-item baskets is
**5.0%–13.9%, mean 9.9%** — the brief's ~10% target — with a truthful −30%
headline. Single-item baskets cost nothing.

---

## The three things that must agree

The badge and the checkout price must cover **identical products**, or the page
promises something checkout will not honour. One tag drives all three:

```
        tag  summer-sale
          │
          ├─ smart collection  summer-sale        (auto, tag rule)
          │      └─ automatic discount is scoped to THIS collection
          │
          └─ snippets/lbass-promo.liquid          (product.tags contains …)
                 └─ every badge in the theme asks this file and nothing else
```

Change the tag in the theme editor and you must change the collection's rule to
match. They are two halves of one switch.

---

## Shopify objects (already created)

| Object | ID | State |
|---|---|---|
| Smart collection `summer-sale` | `gid://shopify/Collection/702851252555` | Live, **0 products** |
| Automatic discount | `gid://shopify/DiscountAutomaticNode/2268443050315` | **SCHEDULED** — starts 2026-10-01 |

Discount config: buy 1 from the collection → get 1 from the collection at 30%
off, `usesPerOrderLimit: 1` (one discounted item per order, matching the promise
"the second item"), combines with shipping discounts so the 499 DH free-shipping
offer still applies.

Nothing can fire today: the collection is empty **and** the discount is scheduled.

---

## Going live — in this order

1. **Tag the pieces** you want in the campaign with `summer-sale`.
   Membership updates automatically. Sold-out pieces are filtered out by the
   theme regardless — a one-of-one that has sold can never be anyone's second item.
2. **Test a real 2-item cart** before anything is announced:
   - add two eligible pieces of **different prices**
   - confirm the discount line appears in cart and at checkout
   - **note which line Shopify discounts** — see the open question below
   - confirm a single-item cart gets nothing
   - confirm an untagged piece is excluded
3. **Start the discount** — Shopify Admin → Discounts → set the start date to now.
4. **Turn on the theme setting** — Theme editor → Promotion → 2nd item →
   *Campaign is running* ✅, and check *Discount on 2nd item* reads the same
   percentage as the Shopify discount.

Turning off is step 4 then step 3 in reverse. Leave the tag alone; it costs
nothing while the campaign is off.

---

## Verification status

Executed against Shopify's own Liquid engine (gem 5.13.0) and rendered in
Chromium. See `test/render/`.

| Verified | How |
|---|---|
| 9 eligibility cases | tag / availability / editorial veto / case-insensitivity / substring / whitespace |
| Price across 6 price points | percentages derived and self-consistent, half-up rounded |
| Card in 6 states | campaign, markdown, both, sold out, veto, plain |
| Off switch | no promotional markup leaks; untagged product renders byte-identically on/off |
| **Refactor is behaviour-preserving** | new component diffed against the pre-refactor inline markup (commit `e1be0c4`) on vendor, title, stamp, href, chips, price, microdata, data-attributes, alt text, quick-add — **identical in all 4 scenarios** |
| RTL | ribbon measured 10px from the **right** edge of its own image on every campaign card; `direction: rtl` confirmed on body |
| Mobile 390px / desktop 1280px | no horizontal page overflow, no child overflowing any card, ribbon contained |
| Design tokens | price `--lb-ink`, struck `--lb-ink-3`, savings/percent `--lb-red`, ribbon `--lb-red-deep` — all resolved |

Three real bugs were caught this way and fixed:

1. **Filters in an `if` condition** (`{% if x | strip == '1' %}`) — invalid Liquid.
   Shopify would have rejected the theme upload.
2. **Tag normalisation applied to the accumulator, not each tag**, so a tag stored
   with surrounding whitespace never matched.
3. **Two competing percentages on one card.** A piece with a genuine markdown showed
   «−25%» and «−30%» as near-identical red pills meaning different things. The
   campaign line was removed from the card body; the ribbon already carries it.

### Still NOT verified

- **Cart and checkout.** No order was placed. The discount is scheduled and the
  collection is empty, so nothing could be tested end to end.
- **Real product imagery.** The preview used flat colour placeholders.
- **Which item Shopify discounts** — see below.

## The one open question

**Which of the two items does Shopify discount?**

[Likely] the lower-priced eligible line, but the Admin API reference does not
state it and the storefront was unreachable from the build environment
(egress-blocked), so it is **unverified**. Because of that, no customer-facing
string claims which item. The shipped copy says only what is true either way:
applies automatically, no code, one item per order.

Once you have observed it in a real cart (step 2 above), you may tighten
*Product page — small print* in the theme editor. It is a setting, not code.

---

## Percentage sync — the one manual coupling

Liquid cannot read an automatic discount. `settings.promo_second_pct` is a
**copy** of the rate in Shopify Admin → Discounts.

**If they disagree, the site advertises a rate the customer does not get.**
Change both in the same sitting. The money always comes from Shopify; the
setting only controls what the page claims.

---

## Wording rules

The discount lands on the *second* item, not the one on screen. Every label
keeps its object:

| | |
|---|---|
| ✅ | «−30% على الثانية» |
| ✅ | «زيد قطعة ثانية وخد التخفيض» |
| ❌ | «−30%» alone, in a circle or anywhere else |
| ❌ | any struck-through price sourced from this campaign |

Drop «على الثانية» and the badge becomes a claim that the piece on screen is 30%
off. It is not, and the page stops matching checkout.

A struck-through price may only come from a genuine Shopify `compare_at_price`.
`snippets/lbass-price.liquid` renders that automatically, independently of this
campaign, with the saving and the percentage derived from the two real prices.

---

## Files

| File | Role |
|---|---|
| `snippets/lbass-promo.liquid` | **Single source of truth** — echoes `1`/`0` for campaign membership |
| `snippets/lbass-promo-badge.liquid` | Badge markup — `format: 'ribbon' \| 'line' \| 'pdp'` |
| `snippets/lbass-price.liquid` | Price + genuine compare-at + derived saving |
| `snippets/lbass-product-card.liquid` | **The** product card — replaced ~7 copies |
| `snippets/lbass-promo-css.liquid` | Styles. Render once, **after** `lbass-stamp` |
| `config/settings_schema.json` | Campaign settings (first merchant-editable controls in this theme) |
| `test/render/` | Liquid render + Chromium layout tests. Run these before any change to the card or price components. |

Wired into: `templates/collection.liquid`, `templates/search.liquid`,
`templates/product.liquid` (PDP block), `layout/theme.liquid` + `templates/index.liquid`
(stylesheet, both HTML shells — see the audit on why there are two).

### Still on the old inline markup

`templates/index.liquid` (3 card spots), `templates/page.vault.liquid`,
`page.pseo`, `page.start-here`, `page.newsletter-confirmation`. They render
correctly and are unaffected by the campaign — they simply will not show the
badge until they are moved onto `lbass-product-card` too. `index.liquid` is a
247 KB monolith and was left for a separate, reviewable change.
