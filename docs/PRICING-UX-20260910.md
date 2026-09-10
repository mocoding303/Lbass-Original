# Promotional price presentation — 2026-09-10

Makes the sale price the first thing a shopper sees, on every surface that
prints a price, and stops those surfaces from disagreeing with each other.

## Staged, not live

| | |
|---|---|
| Theme | `207633219915` — **STAGING — sale price hierarchy 20260910** |
| Role | `UNPUBLISHED` |
| Preview | `https://www.lbassoriginal.com/?preview_theme_id=207633219915` |
| Publish | Shopify Admin → Online Store → Themes → **Publish** |
| Commit | `ca90c45` on `claude/lbass-theme-audit-vgmu56` |

Eight files, each MD5-verified byte-identical to the repo after upload:

```
sections/lbass-collection-hero.liquid   92ee782693b0947247ab885eb2b47473
snippets/lbass-markdown-badge.liquid    cc2941f79163a81337a28249a3fe7ccb
snippets/lbass-price.liquid             c8e72b43d5ca3e7207107a0d235cc824
snippets/lbass-product-card.liquid      c7ecdeb086764970e0dea4fcbb58d288
snippets/lbass-promo-css.liquid         c7ab1b797ebecc6f8839a712bee86f9a
snippets/lbass-sale.liquid              9af000f678b98a1b944d57b088c4d9d4
templates/index.liquid                  44fe97e21a2922f01a6365f68476b808
templates/product.liquid                9e6d44a3e3d292e2bf3848218e87de04
```

**`themeFilesUpsert` lies.** It returned an empty `upsertedThemeFiles` AND an
empty `userErrors` for a batch of seven files, of which three had not been
written. Always re-read `checksumMd5` afterwards and compare; a clean response
is not evidence. Two of the three needed an individual retry.

## What a shopper sees

```
                        ┌─────────────┐
  image                 │  ‑33%       │  ink badge, bottom-right
                        └─────────────┘
  brand
  title
  299 DH                                 26px, leads the card
  449 DH   (‑33%)                        14px struck + red pill
  وفّر 150 DH                             red, aligned with the prices
```

Measured ratio of sale price to struck price: **1.6–1.9×** across 360px, 390px
and 1280px, RTL and LTR.

## Decisions worth knowing

**The sale price is not red.** The 1/1 stamp, the percentage pill and the
savings line are already red; a red price would be the fourth red element on one
card, which is what makes a card look cheap. Size and weight carry the
hierarchy. One commented line in `lbass-promo-css.liquid` flips it.

**The markdown badge is ink, the campaign ribbon is red, and they sit in
different corners.** They mean different things — this item is reduced 33%, vs
a *second* item would be 30% off — and merging them visually rebuilds the
confusion removed on 2026-09-09. Do not "unify" them.

**Both positions were measured, not eyeballed.** A logical `inset-inline-end`
put the badge bottom-left in RTL, on top of the 1/1 stamp, because the stamp
declares `direction:ltr` on itself and therefore never mirrors.
`inset-block-start` put it under the campaign ribbon in LTR once the ribbon
wrapped to two lines. Bottom-right is the only corner both leave free, so it is
pinned physically rather than logically.

**A card that carries both a markdown and the campaign shows two percentages.**
That is inherent to running a 2nd-item campaign alongside per-item markdowns.
Colour, corner and the ribbon's own «على الثانية» keep them apart. If it still
reads as clutter, the fix is a merchandising decision — suppress the campaign
ribbon on cards that have their own markdown — not a styling one.

## Bugs fixed along the way

1. **Two surfaces, two percentages.** `templates/product.liquid` used a plain
   `divided_by`, which floors, while the card rounded half-up. On a 300 → 193
   markdown that is 35% on the product page against 36% on the grid. Both now
   read `snippets/lbass-sale.liquid`, which is the only place the arithmetic
   lives. Latent at −10%, where both roundings agree; wrong at other depths.
2. **`‑0%` could reach the page.** A genuine 1 DH markdown on 1000 DH rounds to
   zero. The strikethrough and the saving stay — the reduction is real — but the
   percentage is suppressed.
3. **Switching size left a stale discount.** The handler repriced the headline
   only, so the strikethrough, percentage and saving described the *previous*
   variant. All four now move together. Latent while every product is
   one-of-one.
4. **The homepage hid discounts.** The "Real" rail rendered the price and
   nothing else, so a marked-down piece looked full price there and reduced
   everywhere else. The "Drop" rail had a strikethrough but no percentage or
   saving. Both fixed.
5. **The savings line flushed the wrong way.** `lbass-stamp` locks the price row
   to `direction:ltr`, so a `text-align:start` saving flushed right under
   left-flushed prices and the block zig-zagged.
6. **No accessible labels.** `<s>` is not announced, so a screen reader read two
   bare numbers with no way to tell which one the shopper pays.
7. **The product page's price block** depended on an assignment 550 lines above
   it and rendered an empty price when lifted out of that context.

## Coverage

| Surface | Price | Struck | % | Saving | Badge on image |
|---|---|---|---|---|---|
| Collection grid | ✅ | ✅ | ✅ | ✅ | ✅ |
| Search | ✅ | ✅ | ✅ | ✅ | ✅ |
| Product page | ✅ | ✅ | ✅ | ✅ | — (no card image) |
| Homepage — Drop rail | ✅ | ✅ | ✅ | ✅ | — |
| Homepage — Real rail | ✅ | ✅ | ✅ | ✅ | — |
| Homepage — JS card | ✅ | ✅ | ✅ | ❌ | — |

The JS-rendered card in `cardHTML()` needed no percentage fix — its
`Math.round` already matches the Liquid — but it does not print the dirham
saving. It is a client-side path the Liquid harness cannot execute, so it was
left alone rather than changed unverified.

`templates/page.vault.liquid` also has its own price markup and was not touched.

## Price accuracy

`compare_at_price` is **display only**. What Shopify charges is `variant.price`,
which is what the cart and checkout use, so no presentation change here can move
the amount a customer pays. The markdowns themselves are genuine former prices —
see `docs/PROMOTION.md` and `docs/ROLLBACK-markdown-20260910.md`.

## Tests

```
NODE_PATH=<path-to-playwright> ./test/render/run_all.sh
```

Ten suites. The four that cover this work:

| Suite | Asserts |
|---|---|
| `test_sale_presentation.rb` | 11 price pairs across the rounding boundary; badge and pill equal on every one; `‑0%` scanned for on all inputs; no-promotion cases emit no promotional markup |
| `test_pdp_price.rb` | slices the price block out of the live template, executes it, and matches it against the card |
| `test_home_rails.rb` | slices both homepage rails out of the live template and matches them against the card |
| `test_variant_switch.js` | extracts the real `applySale()` and drives it in Chromium across marked-down and full-price sizes |
| `measure_sale.js` | the QA matrix at 360/390/1280px in RTL and LTR: size ratio, badge containment, no overlap with stamp or ribbon, no overflow |

`run_all.sh` checks exit codes directly. Piping to `grep` made `$?` report
grep's status, which briefly showed two Chromium suites as PASS while they were
failing to load at all.
