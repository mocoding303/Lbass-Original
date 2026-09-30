# Taste Skill (third-party skills)

Source: https://github.com/Leonxlnx/taste-skill (MIT), commit
ce26fc25c0e5e8cab638f883de62d9a86ee5e45b (2026-09-26), the repository whose
README links to https://tasteskill.dev.

All 13 skills were installed on 2026-09-30 and 12 were removed the same day.
Only `redesign-existing-projects` remains: an unmodified copy of
`skills/redesign-skill/`.

## Why only one

This is a live, Arabic (`<html lang="ar-MA" dir="rtl">`), dark, vanilla-Liquid
storefront whose trust promise is real photos of every item. None of the 13
skills mentions RTL or Arabic, and most assume a greenfield React/Tailwind site.

| Removed directory | Upstream folder | Reason |
| --- | --- | --- |
| `design-taste-frontend` | `taste-skill` | Defaults to React/Next/Tailwind/Motion, and section 4.8 requires AI-generated hero and product imagery whenever an image tool is available. |
| `design-taste-frontend-v1` | `taste-skill-v1` | Superseded by the default skill; same assumptions. |
| `gpt-taste` | `gpt-tasteskill` | Needs GSAP/React/Tailwind and randomizes the layout per prompt, the opposite of a fixed brand system. |
| `full-output-enforcement` | `output-skill` | Written for chat output; pushes whole-file rewrites, which is wrong for targeted edits in 40-250 KB templates. |
| `high-end-visual-design` | `soft-skill` | Prescribes its own palette and fonts; the store already has an identity. |
| `minimalist-ui` | `minimalist-skill` | Same: warm monochrome, muted pastels. |
| `industrial-brutalist-ui` | `brutalist-skill` | Same: its own palette and type system (beta upstream). |
| `image-to-code`, `imagegen-frontend-web`, `imagegen-frontend-mobile`, `brandkit` | same names | Need an image generator and trigger on broad design tasks; the store sells on real photos. |
| `stitch-design-taste` | `stitch-skill` | Only for Google Stitch `DESIGN.md` files. |

To restore one: `git checkout a1e7ad4 -- .claude/skills/<directory>`, or
`npx skills add https://github.com/Leonxlnx/taste-skill --skill "<directory>"`.

Upstream license (MIT), reproduced as that license requires:

---

MIT License

Copyright (c) 2026 Leonxlnx

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
