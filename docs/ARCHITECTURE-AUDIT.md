# Lbass Original — Theme Architecture Audit

**Audited:** 2026-09-09
**Live theme:** `LIVE — Lbass 20260904 (filters + newsletter)` (`gid://shopify/OnlineStoreTheme/207249506635`, role `MAIN`)
**Store:** www.lbassoriginal.com · Basic plan · MAD · Morocco · 64 products
**Source of this snapshot:** pulled from the live theme via Admin GraphQL (`theme.files`). 74 of 75 text files verified byte-identical by MD5 against the live theme; `config/settings_data.json` differs only by an auto-generated comment header the API prepends.

> This repository was **empty** before this commit. The live theme had no version control. This snapshot establishes the baseline.

---

## 1. Theme architecture

**Bespoke, hand-written theme. Not Dawn, not any Theme Store theme, not Online Store 2.0.**

| Signal | Finding |
|---|---|
| `templates/*.json` | **None.** All 18 templates are `.liquid` → **Vintage (pre-OS 2.0) architecture** |
| `themeStoreId` | `null` → not derived from a Theme Store theme |
| Sections | **2 only** (`lbass-hero`, `lbass-collection-hero`); no section groups, no `sections/*.json` |
| `assets/*.css` / `assets/*.js` | **Zero.** No external stylesheet or script files at all |
| CSS / JS delivery | 100% inline — 72 inline `<script>` tags, dozens of inline `<style>` blocks |
| `config/settings_schema.json` | Contains **only** `theme_info` → **no merchant-editable theme settings whatsoever** |

Consequence: nothing is editable from the Shopify theme editor except the two hero sections' own settings. Announcement copy, shipping thresholds, colours, layout — all require code edits.

### Size and shape

```
19,015 lines · 1.21 MB of Liquid across 68 text files
  18 templates · 48 snippets · 2 sections · 2 locales · 2 config · 2 layout

templates/index.liquid            247 KB   ← monolith
templates/product.liquid          159 KB
layout/theme.liquid                77 KB
templates/page.pseo.liquid         55 KB
snippets/lbass-stamp.liquid        52 KB   ← global CSS
templates/collection.liquid        47 KB
snippets/lbass-collection-filters  47 KB
```

### ⚠️ Two parallel HTML shells — the central architectural problem

`templates/index.liquid` and `templates/page.vault.liquid` both declare `{% layout none %}` and emit their **own complete HTML document** (`<!DOCTYPE>`, `<html>`, `<head>`, `<body>`). `layout/theme.liquid` therefore **never runs** on `/` or `/pages/vault`.

Anything added to the layout silently does not apply to those two pages. Current divergence:

| Snippet | `layout/theme.liquid` | `index.liquid` | `page.vault.liquid` |
|---|:--:|:--:|:--:|
| `lbass-stamp` (global CSS) | ✅ | ✅ | ❌ |
| `lbass-meta-pixel` | ✅ | ✅ | ❌ |
| `lbass-cro-tracking` | ✅ | ✅ | ❌ |
| `lbass-entity-schema` | ✅ | ✅ | ❌ |
| `lbass-google-review-badge` | ✅ | ✅ | ❌ |
| `lbass-jdgm-image-guard` | ✅ | ✅ | ❌ |
| `lbass-ai-attribution` | ✅ | ✅ | ❌ |
| `lbass-unique-badge` | ✅ | ❌ | ❌ |
| `lbass-tag-ar` | ✅ | ❌ | ❌ |
| `lbass-cart-drawer` | ✅ | ✅ | ✅ |

**`/pages/vault` currently ships with no Meta Pixel, no CRO tracking and no structured data.**

The workaround this forces is worse than the problem: because `index.liquid` bypasses the layout, structural components are **piggybacked onto unrelated host snippets** so they reach the homepage at all —

- `snippets/lbass-entity-schema.liquid` (a JSON-LD block in `<head>`) renders `lbass-badge-fix`, `lbass-hero-swap`, `lbass-marquee-fix`, `lbass-page-faq-schema`
- `snippets/lbass-cro-tracking.liquid` (an analytics snippet) renders **the entire site navigation** (`lbass-menu`), plus `lbass-cards-fix`, `lbass-home-answer`, `lbass-home-density`, `lbass-pseo-links`

The nav living inside the tracking snippet is a load-bearing accident. It is documented in-file, but it means a change to analytics can take down the menu.

---

## 2. File inventory

**Templates (18):** `index`, `product`, `collection`, `list-collections`, `search`, `cart`, `blog`, `article`, `page`, `page.pseo`, `page.vault`, `page.start-here`, `page.how-we-check`, `page.newsletter-confirmation`, `page.judgeme_reviews`, `page.herotest`, `robots.txt`, `agents.md`

`agents.md.liquid` is an LLM/agent-discovery document (mirrors `assets/llms.txt`) — unusual but intentional and harmless.

**Sections (2):** `lbass-hero` (used only by `page.herotest`), `lbass-collection-hero` (used by `collection.liquid`). These are the only files with `{% schema %}` and thus the only customizer-editable surface.

**Snippets (48):** grouped by role —
- *Filtering/PLP:* `collection-filters`, `collection-topics`, `collection-cro`, `colour-nav`, `pagination`, `quick-add`, `one-of-one`, `unique-badge`
- *Cart:* `cart-drawer` (38 KB, Ajax)
- *Nav:* `menu`, `menu-guides`, `menu-nav-patch`
- *Hero:* `hero-bg`, `hero-cta`, `hero-fx`, `hero-mobile`, `hero-swap`, `hero-type`
- *SEO/schema:* `entity-schema`, `entity-block`, `page-faq-schema`, `pseo-h1`, `pseo-links`, `canonical-map`, `tag-ar`
- *Tracking:* `cro-tracking`, `cro-tracking-hook`, `meta-pixel`, `meta-pixel-base`, `ai-attribution`
- *CSS patch layers:* `stamp` (52 KB), `badge-fix`, `cards-fix`, `marquee-fix`, `jdgm-image-guard`

**Locales (2):** `en.default.json`, `fr.json` — each contains exactly one key (`general.accessibility.skip_to_content`). See §8.

**Config (2):** `settings_schema.json` (theme_info only), `settings_data.json` (app embeds: Judge.me core ✅, Securify browser-blocker ✅, Judge.me cart-drawer widget ❌ disabled)

---

## 3. Collection filtering

**Implementation:** `snippets/lbass-collection-filters.liquid` (47 KB), rendered by `templates/collection.liquid:266` and `templates/search.liquid`.

This file is the **best-engineered part of the theme.** It uses Shopify's native `collection.filters` / `search.filters` end to end — no client-side filtering — so results survive refresh, back-button, deep links and pagination. It correctly:

- maps English filter labels/values to Arabic at render time (`lb_label_map` / `lb_value_map`), falling through to Shopify's own text when unmapped
- handles `price_range` via `min_value`/`max_value` rather than `active_values`
- auto-retires its custom colour/gender path-tag pills when a native equivalent is detected in Search & Discovery
- uses logical properties (`inset-inline`, `text-align: start`) instead of the hardcoded `direction: ltr` the previous version had

A prior version rendered **seven fake filter pills** (Colour, Campaigns, Specialty sizes, Savings, Material, Fit, Collar) with no `name` attribute, six saying "Coming soon", plus a fake price slider and a permanently-disabled "Deals" toggle. All removed 2026-09-02.

### Findings

**F1 — Native tag filters appear not to be enabled in Search & Discovery.**
In-file note (verified 2026-09-02): `?filter.p.tag=black` returned all 64 products, i.e. the parameter is ignored. The store *has* the Search & Discovery app (its `shopify--discovery--*` metafield definitions exist). **Needs a 30-second confirmation in Admin → Search & Discovery → Filters.** I could not re-verify live — the storefront domain is blocked by this environment's network egress policy.

**F2 — `{% paginate %}` wraps a different array than the grid loops.** `templates/collection.liquid`
```liquid
106: {% paginate collections[collection_source_handle].products by 250 %}   ← handle lookup, unfiltered
269: {% for product in collection_product_source %}                        ← = collection.products, filtered
```
The `paginate` object describes the unfiltered, handle-based collection while the grid renders the filtered view. `by 250` is valid (Shopify's range is 1–250), and with 64 products there is only ever one page — so **this is latent, not currently visible.** It becomes a real pagination bug the moment the catalogue exceeds 250 products.

**F3 — Dead client-side filter remnants.** `templates/collection.liquid:506–545` still ships CSS for `.lbf`, `.lbf-chip`, `.lbf-select`, `.lbf-clear`, `.lbf-count`, `.lbf-scope`, `.lbf-hide` and declares `var state = { avail, gender, brand, size, price }`. **No markup emits any `.lbf-*` class and `state` is never read** — the surviving click handler only does vault attribution. Safe to delete.

**F4 — Every collection page fetches up to 250 products.** `paginate … by 250` pulls variant, image, pricing and availability data for the whole catalogue on every PLP request. Shopify's own performance guidance is to fetch only what you render. At 64 products this is a TTFB cost; it scales badly.

**F5 — Latent landmine: `shopify.color-pattern` is only 11% populated.** The filters snippet will auto-detect a native colour filter and *retire the working path-tag colour pill.* But only **7 of 64 products** have `shopify.color-pattern` set (and `shopify.size`: 3/64, `shopify.shoe-size`: 1/64). Enabling that filter in Search & Discovery today would replace a working facet with one that hides 89% of the catalogue. **Populate the metafields before enabling the filter.**

---

## 4. Product card

**There is no reusable product-card component.** The card markup is written inline and independently in at least seven places:

| Location | Card markup |
|---|---|
| `templates/collection.liquid:313` | full card — image, vendor, title, price, chips, microdata |
| `templates/search.liquid:66` | reduced card — no chips, no microdata |
| `templates/index.liquid:1218`, `:1312`, `:2372` | homepage drop / rail cards |
| `templates/page.vault.liquid:332` | vault card (**this one does render compare-at**) |
| `templates/page.pseo.liquid:221` | pSEO card |
| `templates/page.start-here.liquid:50` | start-here card |
| `templates/page.newsletter-confirmation.liquid:76` | confirmation card |
| `snippets/lbass-look-card.liquid` | look-builder card (the one genuinely shared component) |

They share the class names `.card`, `.card-img`, `.card-body`, `.card-vendor`, `.card-title`, `.card-price` — styled centrally in `layout/theme.liquid:809` and overridden in `lbass-stamp.liquid:267`/`:372` — but **not** the markup or the pricing logic. They have already drifted (see §5).

This is the single highest-leverage refactor available: one `snippets/lbass-product-card.liquid` taking `product` + a variant flag would collapse ~7 copies and make pricing consistent by construction.

---

## 5. Pricing and compare-at-price

Filters in use: `money` ×20, `money_without_trailing_zeros` ×5, `money_without_currency` ×2.

**F6 — Collection cards never render compare-at-price.** `templates/collection.liquid:341` emits `{{ product.price | money }}` and nothing else. A product with a genuine `compare_at_price` shows **no sale price and no strike-through in the main product grid** — while the homepage (`index.liquid:1283`) and the vault page (`page.vault.liquid:336`) both do render it. Same catalogue, three different answers, directly caused by §4.

**F7 — PDP pricing logic is correct and should be the model.** `templates/product.liquid:715` renders the old price and a computed `−N%` **only** when Shopify's own `compare_at_price > price`. The file carries an explicit, well-reasoned rule that the `lbass.retail_ref` metafield (what the model costs new) is *not* a compare-at value and must never become one, because Shopify pushes compare-at into the Product schema and the Merchant feed as a price reduction — and a figure that was never the store's price would be misrepresentation. Rendered as plain text, never struck through, never subtracted into a "you save X". **Preserve this exactly.**

**F8 — Currency is hardcoded in schema output.** `templates/collection.liquid:579` emits `"priceCurrency": "MAD"` literally, and prices are computed as `product.price | divided_by: 100.0` — which assumes a 2-decimal currency. Correct for MAD today; brittle. Use `cart.currency.iso_code` / `shop.currency` and `money_without_currency`.

**F9 — Shipping costs hardcoded in copy.** `20 درهم داخل مراكش / 40 درهم خارج مراكش / free from 500` appears as literal text in `product.liquid:731` and elsewhere, duplicated across templates and the `OnlineStore` JSON-LD. A rate change requires a multi-file grep.

---

## 6. Arabic / RTL localization

**F10 — Shopify believes this store is French. The markup says Arabic.**

```
shopLocales  →  [{ locale: "fr", primary: true, published: true }]     ← the ONLY locale
markets      →  [{ name: "Morocco", primary: true }]
theme locales → en.default.json, fr.json                                ← no ar.json
markup       →  <html lang="ar-MA" dir="rtl">                           ← hardcoded, 3 places
copy         →  ~100% Moroccan Darija
```

Uses of the `| t` translation filter across the whole theme: **zero.** Every customer-facing string is hardcoded Arabic in Liquid. The locale files are Shopify's auto-generated stubs containing one key each.

This is not merely untidy. The **Google & YouTube sales channel is installed** (§7), and Merchant Center derives feed language from the store's locale. A `fr` feed pointing at `ar-MA` landing pages is a mismatch Google can and does flag. Same signal reaches Search: `og:locale` says `ar_MA`, Shopify says `fr`.

RTL handling in the *markup* is otherwise good: `dir="auto"` on user-content fields, `dir="ltr"` islands for Latin/numeric runs, `<bdi>` around brand names, logical properties in the filters bar, and a deliberate MSA-vs-Darija split (`snippets/lbass-tag-ar.liquid` — MSA in titles/H1s to match Search Console queries, Darija on the visible chips). The reasoning is documented and correct. **Do not "harmonise" those two.**

`layout/theme.liquid:704–722` also contains a correct, deliberate decision *not* to emit hreflang, since the store serves one language at one set of URLs.

---

## 7. Announcement bars and promotional components

| Component | Where | Editable? |
|---|---|---|
| `.announce` gold marquee | `templates/index.liquid:899` — **homepage only** | No — hardcoded |
| `.lb-bar` trust strip | `layout/theme.liquid:870` **and** `templates/index.liquid:910` — **duplicated verbatim**, CSS included | No — hardcoded |
| Hero ticker | `sections/lbass-hero.liquid:108` | ✅ Yes — real section setting |
| `.vault-urgency` | `templates/index.liquid:1727` | No |
| Brand marquee | `snippets/lbass-brand-proof.liquid` | **orphaned — never rendered** |

**F11 — `.lb-bar` is maintained in two files.** The layout copy is guarded by `{% unless template == 'index' %}` so it does not double-render, but the markup and CSS are byte-duplicated. Edit one and the homepage silently drifts from every other page.

**F12 — Promotional metafields are defined but barely wired.** `lbass.promo_eligible` (6 references), `lbass.promo_badge` (1), `lbass.promo_note` (1) exist as definitions and are populated on ~41/50 sampled products — but null on the ~10 most recently added. There is no consistent promo surface across the card variants.

---

## 8. Structured data / Google Merchant Center

**Google & YouTube channel is installed** (`Publication/359324156235`), so this feeds a live Merchant Center account.

Schema coverage is genuinely strong: `Product`, `Offer`, `OfferShippingDetails`, `Brand`, `AggregateRating` (gated), `BreadcrumbList`, `ItemList`, `FAQPage` (68 Q&A pairs), `HowTo`, `Organization`, `OnlineStore`, `WebSite`+`SearchAction`, `BlogPosting`, `CollectionPage`, `AboutPage`, `SpeakableSpecification`.

**F13 — `itemCondition` is handled correctly** — `NewCondition`/`UsedCondition` gated behind `condition_confirmed`, emitted only when the store actually knows. For a second-hand catalogue this is the single most important Merchant Center attribute and it is right.

**F14 — `robots.txt.liquid` is correct** — preserves `robots.default_groups` rather than replacing them, and deliberately does not block GPTBot / OAI-SearchBot / ClaudeBot / PerplexityBot.

**F15 — Canonical URLs are hardcoded on two pages.** `index.liquid:9` and `page.vault.liquid:9` emit a literal `https://www.lbassoriginal.com/...` instead of `{{ canonical_url }}` (used correctly at `layout/theme.liquid:605`). Correct today; breaks on any domain change.

**F16 — Feed/page language mismatch.** See F10 — the highest-priority Google issue in this audit.

**F17 — `og:locale:alternate` advertises `fr_MA` and `en_US`** (`layout/theme.liquid:751-752`) but no alternate-language URLs exist.

---

## 9. Duplicate, deprecated and conflicting code

### Orphaned — defined, never rendered (~35 KB)

| Snippet | Size |
|---|---|
| `lbass-collection-cro.liquid` | 10.3 KB |
| `lbass-brand-proof.liquid` | 9.4 KB |
| `lbass-ai-landing.liquid` | 9.3 KB |
| `lbass-cro-tracking-hook.liquid` | 2.5 KB |
| `lbass-pseo-h1.liquid` | 2.0 KB |
| `lbass-canonical-map.liquid` | 1.1 KB |
| `meta-pixel-base.liquid` | 0.8 KB |

### Dead behind a hardcoded flag (~30 KB)

`snippets/lbass-pdp-vault.liquid` (29.7 KB) is rendered only under `use_vault_pdp`, which is `{%- assign use_vault_pdp = false -%}` at `templates/product.liquid:38`. It contains a **second complete `@type: "Product"` JSON-LD block** — currently inert, but it would produce duplicate Product schema on every vault PDP if the flag were ever flipped back. The revert instructions in the file header do not mention this.

### Duplication

- **Product card markup** — ~7 independent copies (§4)
- **`.lb-bar` announcement strip** — 2 verbatim copies (§7)
- **HTML document shell** — 3 copies of `<html>/<head>/<body>` (§1)
- **`hero-lifestyle-*.png` + `hero-frame-*.webp`** — several assets are byte-identical duplicates under different names (`cat-jackets.webp` ≡ `cat-jackets-ed.webp`, `hero-lifestyle-1.webp` ≡ `hero-frame-1.webp`, `look-rooftop.webp` ≡ `hero-frame-3.webp`), plus ~12 MB of unused multi-megabyte PNGs alongside their WebP equivalents

### CSS specificity war

**1,199 `!important` declarations**, 688 of them in `lbass-stamp.liquid`. Five snippets exist purely to out-specify earlier ones (`badge-fix`, `cards-fix`, `marquee-fix`, `menu-nav-patch`, `jdgm-image-guard`), and render order is load-bearing — `layout/theme.liquid:860-863` carries a comment that `lbass-unique-badge` **must** come after `lbass-stamp` or the badge is flattened. `collection.liquid:174` documents a rule that never painted because `lbass-stamp`'s `.chip{…!important}` outranked it at any specificity.

### Hardcoded product-specific logic

**258 `when '<handle>'` branches** across `templates/index.liquid`, `templates/product.liquid`, `templates/list-collections.liquid`, `templates/page.pseo.liquid`, `sections/lbass-collection-hero.liquid` and **`layout/theme.liquid`**. Example — `templates/index.liquid:1252`:

```liquid
{% when 'lbass-p001-striped-shirt-shorts-set' %}{% assign drop_image = 'lbass-preview-p001-striped-set.webp' | asset_url %}
```

Product imagery mapped by handle to theme assets, when `product.featured_image` is available. `layout/theme.liquid:401` hardcodes `collections['adidas-originals']`. Every new product requires a theme edit.

### Data-quality issues that constrain the theme

- **Tag vocabulary is not normalised.** The 64 products carry ~180 distinct tags with heavy near-duplication: `L` / `Size L` / `size-l`; `adidas` / `Adidas Originals`; `new-balance` / `New Balance`; `tommy-hilfiger` / `Tommy Hilfiger`; `second-hand` / `Second Hand`; `condition:good` / `Good Condition`; `shoes` / `type:shoes`. Enabling a tag filter today would show shoppers three separate "L" facets.
- **Vendor is fragmented** — `Adidas` and `Adidas Originals` are separate vendors, splitting the brand facet.
- **`productType` is clean and well-populated** (Shoes, Pants, Jackets, T-Shirts, Accessories, Shorts, Sets) — the best available facet source and currently unused as one.
- **Theme references ~24 `lbass.*` metafields that have no definition** (`meas_chest`, `meas_waist`, `meas_length`, `meas_sleeve`, `meas_inseam`, `meas_insole`, `faq`, `styling`, `occasion`, `fits_for`, `fits_against`, `retail_ref`, `retail_ref_src`, `hero_*`, `emo_line`, …). They work as unstructured metafields but are not editable in Admin and cannot become filters.
- **Standard taxonomy metafields are defined but the theme ignores them entirely** — `shopify.color-pattern`, `shopify.size`, `shopify.shoe-size` have **zero** references in any Liquid file.
- `adidas-copa-black-football-boots-size-44` has variant option `Size = 43`.

---

## 10. What is genuinely good

Worth stating plainly, because the recommendations above should not read as a rewrite proposal:

- The filters snippet is correct, native, RTL-aware and honest about what it cannot do.
- PDP pricing refuses to fabricate a compare-at price and documents why. That is a compliance decision most themes get wrong.
- `itemCondition` gating is correct for a second-hand catalogue.
- The in-code commentary is exceptional — nearly every non-obvious decision carries a dated rationale with measured before/after numbers. This audit was possible largely because of it.
- The MSA-vs-Darija title/chip split is a real insight, not an accident.

---

## 11. Suggested order of work

Ordered by risk-adjusted value, not by effort.

| # | Item | Refs |
|---|---|---|
| 1 | Confirm Search & Discovery filter config; decide tag-normalisation before enabling any tag facet | F1, §9 |
| 2 | Resolve the `fr` locale vs `ar-MA` markup mismatch — affects Merchant Center feed and Search | F10, F16 |
| 3 | Extract one `snippets/lbass-product-card.liquid`; fix compare-at on collection cards as part of it | F6, §4 |
| 4 | Restore `page.vault.liquid` to the shared layout, or at minimum render pixel/tracking/schema there | §1 |
| 5 | Delete dead code: 7 orphan snippets, `lbass-pdp-vault`, `.lbf-*` remnants (~65 KB) | F3, §9 |
| 6 | Fix the `paginate` array mismatch before the catalogue passes 250 products | F2 |
| 7 | Populate `shopify.color-pattern` / `size` / `shoe-size`, *then* enable native facets | F5 |
| 8 | De-duplicate `.lb-bar`; move announcement copy into theme settings | F11 |
| 9 | Replace hardcoded handle switches with `product.featured_image` and metafields | §9 |
| 10 | Unwind `index.liquid`'s `{% layout none %}` so components stop piggybacking on tracking/schema snippets | §1 |

Items 1, 2 and 7 are configuration/data, not code — they should be settled before any theme change that depends on them.

---

## Verification notes

- Theme source pulled via Admin GraphQL `theme(id:).files`; 74/75 text files MD5-verified byte-identical to live.
- `paginate … by 250` checked against Shopify docs — valid (range 1–250). The defect is the array mismatch, not the page size.
- Live storefront rendering could **not** be verified: `www.lbassoriginal.com` is blocked by this environment's network egress policy. F1 rests on an in-repo note dated 2026-09-02 and needs an admin-side confirmation.
- Product/metafield/locale/publication facts come from live Admin API reads on 2026-09-09.
- Metafield population figures are from all 64 products.
