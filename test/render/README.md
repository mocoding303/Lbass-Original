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
