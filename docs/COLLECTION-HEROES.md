# Collection hero images

How `sections/lbass-collection-hero.liquid` picks the picture at the top of a
collection page, what each collection currently gets, and where the gaps are.

`collection.image` is **data, not theme code**, so changes to it go live
immediately with no theme publish. Changes to the `case` list in the section
are code and need a deploy.

## Resolution order

1. `collection.metafields.lbass.hero_image`
2. `collection.image`
3. brand SVG, for `brand-*` handles (a separate layout, not a photo)
4. a `case` on the collection handle → a theme asset
5. first **available** product's featured image
6. first product's featured image
7. `section.settings.fallback_image`
8. `hero-lifestyle-1.webp`

Steps 5 and 6 are the failure mode: a handle missing from the `case` in step 4
silently renders whatever product happens to sort first. It looks deliberate,
so nobody notices. Every collection fixed below was in that state.

## Applied 2026-09-10

| Collection | Image | Intrinsic | Note |
|---|---|---|---|
| `men-jackets` | `cat-jackets-ed.webp` | 1448×1086 | replaced a **screenshot file** (`Screenshot2026-07-16at05.36.22.jpg`) someone had set as `collection.image` |
| `men-tshirts` | `cat-tshirts-ed.webp` | 1448×1086 | exact |
| `men-jeans` | `cat-jeans-ed.webp` | 1448×1086 | exact |
| `men-shorts` | `cat-pants-ed.webp` | 1448×1086 | ⚠ **not exact** — long cargo trousers, not shorts. No `cat-shorts` asset exists. |
| `women-sneakers` | `cat-shoes-ed.webp` | 1448×1086 | exact |
| `slides` | `cat-shoes-ed.webp` | 1448×1086 | ⚠ **not exact** — lace-up sneakers, not slides. No `cat-slides` asset exists. |
| `new-in` | `hero-frame-1.webp` | 1376×768 | wide mixed-category still-life |

All seven set via `collectionUpdate`, MD5-verified byte-identical to the live
theme's own copies, with Arabic alt text. All are now committed to `assets/` —
the original repo snapshot pulled only text files, so the artwork had never been
under version control.

`women-sneakers`, `slides` and `new-in` were also added to the `case` list so
the fallback is right underneath, but that part needs a theme deploy to matter.

## Why `new-in` does not use `editorial-campaign.webp`

That is the usual broad-collection fallback and it is the wrong shape. It is
**896×1200 portrait**; the hero box is full-width at `clamp(560px, Xvh, 900px)`
with `object-fit: cover`, so the crop is roughly **2:1**. A portrait shot loses
most of its subject there.

This is already written down twice in the repo. `snippets/lbass-hero-bg.liquid`
rejected the same class of image as the homepage hero:

> rev3 — Was hero-lifestyle-3b (one pair of folded jeans plus roses, a lantern,
> sunglasses). Cropped into a wide hero it reads as a vintage still-life, not a
> clothing shop… **If you swap this, judge the WIDE crop** — a picture that works
> as a square thumbnail can lose its subject entirely at 1280×880.

and the `audited-drop-p001-p012` override in the section itself says the portrait
"was enlarged into a 16:9 hero and cropped the model".

`hero-frame-1.webp` / `hero-lifestyle-1.webp` (identical bytes, 1376×768) is the
image chosen for exactly this constraint: Jordan sneakers, Levi's denim, a belt,
a bag and jewellery on Moroccan zellige. Sneakers + denim + accessories is
precisely what `new-in` holds.

## The artwork, accurately

An earlier revision of this file claimed every image is "one North African male
model, warm light from the right, shadow filling the left". That was generalised
from four files and is wrong. What is actually in `assets/`:

**Still-life, no model** — `cat-shoes-ed`, `cat-acc-ed` (1448×1086 each). Warm
ochre wall upper-**left**, deep shadow filling the **right**. Shallow depth of
field, muted earth palette.

**Male model** — `editorial-campaign.webp` (896×1200): denim jacket, Marrakech
doorway, zellij column.

**Female model** — `hero-frame-3.webp` / `hero-lifestyle-3.png` (896×1200): black
hoodie and sunglasses on a rooftop over the medina at golden hour. The store does
own women's-facing editorial; it is simply portrait, so it cannot carry a hero.

**Wide still-life** — `hero-frame-1.webp` (1376×768, goods on zellige) and
`hero-frame-4.webp` / `hero-lifestyle-3b.webp` (1264×848, folded denim with
lantern and beads). These are the only assets that survive the hero crop.

**Do not use** — `hero-frame-2.webp` / `hero-lifestyle-2.webp` (1200×670). Every
garment in it carries a fabricated **"VINTEWAGE LONDON"** wordmark, an artifact
of whatever generated it. It is currently on the homepage twice. Putting an
invented brand name across a page is worth removing, not extending.

The text overlay sits at the **bottom** of the hero (`align-items: flex-end`)
under a full-bleed scrim, so composition does not need to reserve a side gutter —
it needs to survive a wide crop and stay legible under a dark scrim.

Brand logos: the still-lifes carry real marks (a Vans stripe, a Nike swoosh, a
Levi's tab) for brands the store actually stocks, which is ordinary nominative
use. **Do not generate new imagery carrying a brand mark** — an invented Nike
product is a trademark problem, not a style choice.

## Still open

- **`slides` needs a real slides image.** Composing one from the store's own
  photography was tried and abandoned: the only usable frame
  (`lbass-prod-p010a-01.webp`, Nike navy slides) is a portrait phone snapshot on
  a carpet, and any crop tight enough to read as editorial enlarges the swoosh to
  fill the frame. The attempt is not committed.
- **`men-shorts` needs a real shorts image.** Same category of gap.
- **Six collections now share `cat-shoes-ed.webp`** — `sneakers`, `shoes`,
  `men-shoes`, `women-shoes`, `women-sneakers`, `slides`. Correct, but flat.
- **Image generation is blocked.** The connected Higgsfield account is on the
  free plan with **0 credits** and no unlimited allowance. With credits, `soul_2`
  at 4:3 is the right model; brief it against the accurate description above, and
  judge the **wide** crop, not the thumbnail.

## Testing

`test/render/test_collection_hero.rb` executes the section's resolution header
against 22 handles and asserts both the chosen artwork and the intrinsic size it
declares, with and without a merchant-set `collection.image`. Assert by running
it, not by reading the `case` list — reading it is how `men-tshirts`,
`men-shorts` and `men-jeans` went unnoticed.

```
ruby test/render/test_collection_hero.rb
ruby test/render/parse_all.rb
```
