# Collection hero images — men's categories

Applied 2026-09-10. **Live on the current published theme** — `collection.image`
is data, not theme code, so this needed no theme publish.

## What was wrong

| Collection | Before | Why |
|---|---|---|
| `men-jackets` | a **screenshot file** (`Screenshot2026-07-16at05.36.22.jpg`) | someone had set it as the collection image, and `collection.image` outranks the theme's own category art |
| `men-tshirts` | first product's photo | handle absent from the `case` list in `sections/lbass-collection-hero.liquid` |
| `men-shorts` | first product's photo | same |
| `men-jeans` | first product's photo (1 product) | same |

The theme already owned on-brand editorial art for three of these four. It was
simply never reachable: the hero resolves `hero_image` metafield →
`collection.image` → brand SVG → a `case` on the collection handle → first
product image. `men-tshirts`, `men-shorts` and `men-jeans` are newer handles
that were never added to that `case`, so they fell through to a product photo.

## What was applied

| Collection | Image | Note |
|---|---|---|
| `men-jackets` | `cat-jackets-ed.webp` | replaces the screenshot |
| `men-tshirts` | `cat-tshirts-ed.webp` | exact category match |
| `men-jeans` | `cat-jeans-ed.webp` | exact category match |
| `men-shorts` | `cat-pants-ed.webp` | ⚠ **closest available, not exact** — the image shows long cargo trousers, not shorts. There is no `cat-shorts` asset. |

All four are 1448×1086, byte-identical to the live theme's copies (MD5-verified),
and now committed to `assets/` — the original snapshot pulled only text files, so
the theme's own artwork had never been version-controlled.

Arabic alt text set on each, matching the existing house pattern.

## House style, for whoever generates the next one

Consistent across every `cat-*-ed.webp`:

- 4:3 landscape, 1448×1086
- One male model, North African, early 20s, dark curly hair
- Moroccan riad / medina: ochre tadelakt walls, carved cedar doorway, zellij tile
- Warm low-key light from the **right**; deep shadow filling the **left ~55%**,
  which is the negative space the hero's text overlay sits in
- Muted earth palette — olive, brown, charcoal, ochre, deep teal in the tile
- **No brand logos on any garment.** The existing set is scrupulous about this,
  and it should stay that way: generated imagery carrying a Nike swoosh or
  Adidas stripes is a trademark problem, not a style choice
- Garment-focused crops are in-style (`cat-pants-ed` crops the head off entirely)

## Still open

- **`men-shorts` needs a real shorts image.** It is the one genuine gap.
- **Higgsfield could not be used**: the connected account has **0 credits on the
  free plan** and no unlimited allowance, so no generation was possible. With
  credits, `soul_2` (portraits / fashion / editorial) at 4:3 is the right model.
- `men-jeans` holds **1 product**. A category hero for a one-item collection is
  worth questioning before investing art in it.
- The `case` list in `sections/lbass-collection-hero.liquid` still omits these
  three handles. `collection.image` overrides it so the site is correct today,
  but adding them would make the fallback right too, for any future collection
  that loses its image.
