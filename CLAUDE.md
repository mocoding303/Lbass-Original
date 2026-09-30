# Lbass Original: agent notes

Live Shopify storefront (www.lbassoriginal.com) selling second-hand branded clothing and sneakers in Morocco, mostly one-of-one pieces. This repo is a snapshot of the live theme and is not connected to the store (see `README.md`). Read `docs/ARCHITECTURE-AUDIT.md` before changing theme code.

## Design guardrails

Generic design advice, including the `redesign-existing-projects` skill, is written for left-to-right English SaaS sites. Check it against these before applying it.

- **The site is Arabic and RTL:** `<html lang="ar-MA" dir="rtl">`. Prefer logical properties (`inset-inline-*`, `margin-inline-*`, `text-align: start`) over hard-coded left/right. Do not add `letter-spacing` to Arabic text, because it breaks letter joining. Keep the Arabic fonts (Alexandria, Tajawal); do not swap in fonts without Arabic glyphs.
- **Extend the existing identity, do not replace it.** Dark ink `#0A0A0B`, cream `#F4EFE6`, gold `#C89A0E` / `#E0B52A` and brand red `#BF2E15`. Anton for display, Epilogue for Latin text, Alexandria/Tajawal for Arabic. Gold and red are both part of the brand; do not collapse them to one accent.
- **Imagery must be real.** The store's promise is that every item is photographed individually with its condition shown (`assets/llms.txt`). Do not add stock, placeholder (picsum) or AI-generated product or hero imagery.
- **Vanilla Liquid with inline CSS and JS.** The theme has no external stylesheet or script assets and no build step. Do not introduce Tailwind, GSAP, npm packages or similar.
- **Do not change silently:** URLs, navigation labels, JSON-LD and other structured data, Meta Pixel and `lbass-cro-tracking` hooks, or class/id hooks that tracking depends on.
- **Two HTML shells.** `templates/index.liquid` and `templates/page.vault.liquid` use `{% layout none %}`, so edits to `layout/theme.liquid` do not reach them.
