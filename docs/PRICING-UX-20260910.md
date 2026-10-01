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
| Commit | `85d55a9` on `claude/lbass-theme-audit-vgmu56` |

Eight files, each MD5-verified byte-identical to the repo after upload:

```
sections/lbass-collection-hero.liquid   92ee782693b0947247ab885eb2b47473
snippets/lbass-markdown-badge.liquid    cc2941f79163a81337a28249a3fe7ccb
snippets/lbass-price.liquid             17eb455def3e943d24f61c784fb2a3fc
snippets/lbass-product-card.liquid      c7ecdeb086764970e0dea4fcbb58d288
snippets/lbass-promo-css.liquid         484960bccc702dce2c507f5ac16866d8
snippets/lbass-sale.liquid              9af000f678b98a1b944d57b088c4d9d4
templates/index.liquid                  44fe97e21a2922f01a6365f68476b808
templates/product.liquid                b8bdaf9a275e053abdc83d49a2030fa1
```

**`themeFilesUpsert` lies.** It returned an empty `upsertedThemeFiles` AND an
empty `userErrors` for a batch of seven files, of which three had not been
written. Always re-read `checksumMd5` afterwards and compare; a clean response
is not evidence. Two of the three needed an individual retry.

## What a shopper sees

Collection card:

```
                        ┌──────────┐
  image                 │  ‑33%    │   ink block, bottom-right, 20px
                        └──────────┘
  brand
  title
  299 DH   449 DH   [‑33%]           price 26px · struck 14px grey
  وفّر 150 DH                          solid red pill 16px
```

Product page:

```
  السعر الحالي
  ┌────────┐
  │ ‑10%   │        solid clay block, 21px desktop / 19px mobile
  └────────┘
  674 DH  749 DH    price clamp(22–30px) · struck 15px
  وفّر 75 DH          14px clay
```

## The hierarchy, and where it is enforced

    price  >  discount  >  strikethrough  >  saving

| | phone ≤400px | phone | desktop |
|---|---|---|---|
| price | 21px | 23px | 26px |
| discount pill | 14px | 15px | 16px |
| strikethrough | 13px | 13px | 14px |
| saving | 11.5px | 11.5px | 12px |

Product page: discount 19px → 21px, price 22px → 30px, struck 14px → 15px.

This is **asserted, not intended**. `measure_sale.js` checks every relationship
in a real browser at 360/390/1280px in RTL and LTR, and on the product page at
390/1280px. It caught a tie on the first attempt — the pill was set to 14px
while the strikethrough steps up to 14px on desktop, so on desktop there was no
hierarchy at all.

**Why the discount got its own line on the product page.** Not only size:
`.pdp-prices` is `align-items:baseline`, and a badge large enough to notice
cannot share a baseline with a `clamp(22px,3vw,30px)` price without one of them
looking misaligned. That row also wraps on a phone, where a *trailing* badge is
the element that wraps off — the promotion being the first thing to vanish on
the surface that matters most.

**`display:inline-flex` defeats `hidden`.** `.pdp-save[hidden]{display:none}` is
restated for that reason. Without it, choosing a full-price size leaves an empty
clay block on the page.

**The bigger image badge does not fit beside a SOLD stamp.** Measured at 360px:
image 156px, SOLD stamp 75px (vs 52px for 1/1), badge 67px — 162px of content in
156px. It shrinks on sold cards only, where the discount is information rather
than a live offer, instead of shrinking on every phone card to accommodate the
one that is already unbuyable.

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


---

## The reference price (crossed-out), 2026-09-10 rev 2

Two of the requested changes were measurable defects, not preferences.

### Contrast — the product page strikethrough failed AA

| | colour | on ground | ratio | |
|---|---|---|---|---|
| PDP reference **was** | `--txt3` `#5E5A55` | `--ink` | **2.89:1** | fails AA |
| PDP reference **now** | `--txt2` `#97928A` | `--ink` | 6.40:1 | AA |
| PDP saving **was** | `--clay` `#B4502A` | `--ink` | **3.88:1** | fails AA |
| PDP saving **now** | `--clay2` `#D4683E` | `--ink` | 5.51:1 | AA |
| card reference **was** | `--lb-ink-3` `#6B6B6E` | bone | 5.31:1 | AA, tertiary |
| card reference **now** | `--lb-ink-2` `#3A3A3C` | bone | 11.35:1 | AA, **secondary** |

White **on** `--clay` — how the discount block uses it — is 5.10:1 and was
already fine. Only clay-as-text failed.

### An invisible element was splitting the price pair

`snippets/lbass-price.liquid` emitted schema.org availability as an **empty
`<span>`**. The price container is a flex row with a column gap, and an empty
span is still a flex item, so it contributed a full gap of invisible width.

Measured at 360px: the pair fits in **128px of a 130px row** — but the phantom
6px made it 134px, so the reference price wrapped onto a line of its own.

Changed to `<meta>`: identical microdata (the `content` attribute is parsed, not
the box) and `display:none` in the UA stylesheet, so not a flex item at all.

### Ratio

Requested 1.3–1.5×. Achieved:

| | phone | desktop |
|---|---|---|
| collection card | **1.46×** | **1.53×** |
| product page | **1.47×** | 1.58× |

Reaching it required raising the discount pill **alongside** the reference price
(16→18px desktop). Raising the reference alone would push it past the discount
and invert `price > discount > reference`. Both move together or neither can.

Card sizes are now fluid — `clamp(19px,5.4vw,23px)` against
`clamp(13px,3.7vw,15px)` — so the *pair* keeps fitting on one line as the column
narrows.

### The limit, stated rather than hidden

A four-digit reference price (1 199 DH) needs ~148px in a 130px phone column. No
readable type fits that, and shrinking every card for a price the catalogue does
not carry (the marked-down set tops out at 899/999 DH) is the wrong trade.

So the test asserts **side by side whenever the column can physically hold the
pair**, and when it cannot, that the wrap is graceful: sale price on the first
line, never the reference above it.

### Smaller things

- Strikethrough 1px → **2px**. At 1px on a 14px numeral the line was thinner
  than the strokes it crossed and read as an artefact. `skip-ink:none` keeps it
  unbroken across every glyph.
- `text-underline-offset` **removed, not retuned** — it moves underlines and has
  never affected a line-through.
- `nowrap` on both prices so a four-digit figure cannot break mid-number.
- One consistent column gap sets the distance between the two prices at every
  breakpoint.
