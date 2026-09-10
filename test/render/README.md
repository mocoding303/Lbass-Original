# Render tests

Executes the theme's Liquid with Shopify's own engine, so a syntax error or a
logic bug is caught here instead of on a theme upload.

    gem install liquid          # Shopify's Liquid, 5.x
    npm install playwright-core # only for screenshot.js

    ruby test/render/test_eligibility_and_price.rb
    ruby test/render/test_card_matrix.rb
    ruby test/render/test_regression_vs_original.rb
    ruby test/render/build_preview.rb && node test/render/screenshot.js

Run with `RUBYOPT="-EUTF-8"` if your locale is not UTF-8 — the templates are
full of Arabic and the gem refuses to parse them under US-ASCII.

## What each file covers

| File | Covers |
|---|---|
| `test_eligibility_and_price.rb` | 9 campaign-eligibility cases (tag, availability, veto, case, substring, whitespace) + price rendering across 6 price points |
| `test_card_matrix.rb` | the full card in 6 states; asserts nothing promotional leaks when the campaign is off, and that an untagged product renders byte-identically on/off |
| `test_regression_vs_original.rb` | diffs the extracted component against `orig-card.liquid` (the pre-refactor inline markup from commit e1be0c4) on vendor, title, stamp, href, chips, price, microdata, data-attributes, alt text and quick-add |
| `build_preview.rb` + `screenshot.js` | assembles a real RTL page with the theme's actual CSS and measures layout in Chromium at 390px and 1280px |

## Fidelity notes

Two things the standalone gem does differently from Shopify, both handled in
`harness.rb`:

- **Globals.** Shopify exposes `settings`, `shop`, `cart` and `routes` to
  snippets even through the isolated scope of `{% render %}` (Dawn relies on
  this — `snippets/card-product.liquid` reads `settings.card_style`). The gem
  models that as `static_environments`, not assigns.
- **Hyphens.** `Liquid::LocalFileSystem` rejects hyphenated template names;
  Shopify allows them and every snippet here uses them. `HyphenFS` widens it.

`money` is approximated as `N DH` to match the storefront's format.

## Promotional pricing

```
ruby test/render/test_sale_presentation.rb   # one percentage across both surfaces, rounding, no -0%
ruby test/render/test_pdp_price.rb           # product page agrees with the card, for the same product
node test/render/test_variant_switch.js      # switching size moves ALL four price elements
ruby test/render/build_preview.rb && node test/render/measure_sale.js
```

`measure_sale.js` renders the QA matrix (no discount, the live -10%, a deep
discount, a long price pair, a sold piece, a sub-1% markdown, and a card
carrying both the markdown badge and the campaign ribbon) at 360px, 390px and
1280px in **both** RTL and LTR, then asserts in a real browser that:

* the sale price is strictly larger than the struck price (measured ratio 1.6-1.9x),
* the markdown badge stays inside its own image and never overlaps the 1/1
  stamp or the campaign ribbon,
* the badge stays pinned bottom-right in both directions,
* no card child overflows its card and the page never scrolls horizontally,
* `-0%` reaches no surface.

The JS tests need `playwright-core`; run `npm i` in this directory first. They
use the pre-installed Chromium at `/opt/pw-browsers/`.
