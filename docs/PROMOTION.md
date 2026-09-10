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

## Deployed

| | |
|---|---|
| Staging theme | `STAGING — promo 2nd item + shared card 20260909` · `OnlineStoreTheme/207582658891` · prefix `/t/99` · **UNPUBLISHED** |
| Preview | `https://www.lbassoriginal.com/?preview_theme_id=207582658891` |
| Files | 9, each **MD5-verified byte-identical** to commit `8a7172d` |

```
config/settings_schema.json          snippets/lbass-promo.liquid
templates/collection.liquid          snippets/lbass-price.liquid
templates/search.liquid              snippets/lbass-promo-badge.liquid
templates/product.liquid             snippets/lbass-promo-css.liquid
                                     snippets/lbass-product-card.liquid
```

`layout/theme.liquid` and `templates/index.liquid` were verified **unchanged
from the live theme** (`6ee793c8…` / `76c41057…`) — the stylesheet moved to the
card templates, so neither needed touching and neither was touched.

### Publishing is a manual step, on purpose

The Shopify MCP blocks writes to the live/MAIN theme, and blocks theme
publishing outright. That is the right constraint here anyway: **cart and
checkout have never been exercised**. Preview the staging theme, run the 2-item
cart test below, then publish from Shopify Admin → Themes.

### One transcription failure worth knowing about

Five files went up as hand-copied base64. Four were byte-perfect; `search.liquid`
came out the **same size but a different MD5** — one character had flipped in
transit. It was caught only because every file was checksummed against the repo
afterwards, and fixed by having Shopify fetch the raw bytes from GitHub instead.
If you ever push theme files this way, verify checksums; the upload response
reports success either way.

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

## APPLIED 2026-09-10 — genuine −10% markdown on 31 pieces

`compare_at_price` set to each piece's existing price, price reduced 10%,
rounded to whole dirhams. **Live now, store-wide** (prices are not theme-scoped).

| | |
|---|---|
| Pieces | **31** — available AND not vetoed by `lbass.promo_eligible` |
| Excluded | 16 sold out · 17 vetoed by `promo_eligible=false` |
| Catalogue value | 13,100 DH → **11,787 DH** |
| Margin given up | **1,313 DH** |
| Badge on every one | reads exactly **−10%**, verified against the theme's own rounding |

Verified by reading all 64 products back: 31 carry a `compareAtPrice`, 33 are
`null`. The mutation response was not trusted on its own.

**This is compliant.** The struck price is the price genuinely charged for
months — a real former price, which is what a reference price is supposed to be.
It is the 28.57% inflation, not the strikethrough, that was the problem.

**Rollback:** `docs/ROLLBACK-markdown-20260910.md` restores all 31 prices and
clears every `compare_at_price` in two paste-able GraphQL documents.

**Plan of record:** `test/render/markdown_plan_20260910.py` — the eligibility
rule in code, plus the exact before/after for each piece.

### ⚠ Ordering caveat this was applied under

The theme fix that RENDERS strikethroughs is on the staging theme only. Until
that theme is published, the collection grid shows the new lower price with **no
discount indicator at all** — the markdown is invisible and the margin is simply
gone. Publishing was requested immediately after this was applied.

## What "promo prices" costs

The campaign shows **no struck-through price**, because no item's price changes.
If the goal is the reference-screenshot look — struck price, percentage,
«وفّر …» on every card — that requires a genuine markdown, and
`snippets/lbass-price.liquid` already renders it the moment `compare_at_price`
is set. Measured on real store prices:

| piece | now | −10% | −20% | −30% |
|---|--:|--:|--:|--:|
| Vans Old Skool Black | 349 | 314 | 279 | 244 |
| Zara Khaki Jacket | 449 | 404 | 359 | 314 |
| Nike Air Max Black/Green | 599 | 539 | 479 | 419 |
| The North Face Puffer | 749 | 674 | 599 | 524 |
| HOKA Red Running | 999 | 899 | 799 | 699 |
| Adidas Originals Shorts | 230 | 207 | 184 | 161 |
| **margin given up** | **3375** | **338** | **675** | **1012** |

Setting `compare_at_price` to today's actual price is **fully compliant** — that
price has genuinely been charged for months, which is exactly what a reference
price is supposed to be. The 28.57% inflation was the only part that was not.

So the choice is real and it is a business one, not an engineering one:

- **−30% struck prices** → costs a true 30%
- **−10% struck prices** → costs 10%, badge reads −10%
- **−30% headline at ~10% cost** → the 2nd-item campaign, no struck prices

There is no fourth option. A −30% struck price at 10% cost requires a fake
reference, which is where this started.

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
