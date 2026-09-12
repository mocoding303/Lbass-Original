# Transfer prompt — Lbass Original SEO/AEO/GEO playbook → Nur Fragrance

Everything below is extracted from the **actual implementation** in the
`lbass-original` theme, with file references so any claim can be checked. It is
not a generic SEO checklist.

Read "What does NOT transfer" before using it. Lbass sells **one-of-one
second-hand** goods. A fragrance store sells **new, branded, catalogued** product
with GTINs — several of the highest-value techniques below invert in that
context, and two of them become liabilities.

---

## THE PROMPT — paste this

````
ROLE
You are a Senior Technical SEO + Answer-Engine (AEO) + Generative-Engine (GEO)
Engineer. You are working on NUR FRAGRANCE. Your goal is measurable visibility
in (a) classic SERPs, (b) AI Overviews / featured snippets, and (c) LLM answers
in ChatGPT, Claude, Perplexity and Gemini.

CONTEXT I MUST GIVE YOU BEFORE YOU START
Fill these in. If any are blank, ASK — do not assume.
- Store URL:
- Platform (Shopify / Woo / custom) and theme access:
- Primary market + city:
- Primary customer language, and any secondary languages:
- Product type: own-brand / authorised reseller of designer houses / inspired-by
  (dupes) / decants & splits / niche house
- Do you hold GTINs (EAN/UPC) for what you sell?  yes / no / partial
- Existing review volume and platform:
- Google Search Console + Merchant Center connected?  yes / no

=========================================================
PHASE 0 — AUDIT BEFORE YOU CHANGE ANYTHING
=========================================================
Do not write a single tag until you have produced a baseline. Report:

1. Every structured-data @type currently emitted, and on which templates.
2. Every page where a <title> is byte-identical to another page's <title>.
   (On the reference site this audit found THREE duplicate-title pairs where
   a collection and its parent were self-cannibalising.)
3. Current robots meta per template type, and whether filtered / sorted /
   paginated URLs are indexable.
4. Whether /robots.txt blocks GPTBot, OAI-SearchBot, ChatGPT-User, ClaudeBot,
   PerplexityBot, Google-Extended, Bingbot, Applebot-Extended.
5. Whether /llms.txt and /.well-known/ or /agents.md exist.
6. Whether any FAQPage markup exists WITHOUT matching visible Q&A on the page.
   That is a structured-data violation and a manual-action risk. Report it as a
   defect, not a win.
7. Search Console: the brand's own name queries. What position does the site
   hold for its OWN brand, and in which spellings?

Output the baseline as a table. Then stop and show me before implementing.

=========================================================
PHASE 1 — INDEXATION FLOOR
=========================================================
1.1  Self-canonical on every indexable URL. Do NOT point canonicals at
     "consolidated" targets unless the target is live and 200. (On the
     reference site a previous consolidation pointed canonicals at handles that
     404'd — worse than no canonical at all.)

1.2  Conditional robots meta, not a blanket value:
       index, follow, max-image-preview:large   → real content pages
       noindex, follow                          → filtered, sorted, paginated,
                                                  internal-search, thank-you,
                                                  and any tag combination that
                                                  produces near-duplicate text
     "follow" matters: you still want link equity to flow out of those pages.

1.3  Title uniqueness. Every collection/landing page must differentiate its
     <title> AND its <h1> from its parent. If a child page cannot justify a
     different title, it should not be a separate indexable page.

1.4  hreflang: emit it ONLY if genuinely separate, indexable, self-canonical,
     reciprocally-linked URLs exist per language. A single URL tree serving
     mixed-language copy must NOT emit hreflang — it is noise that suppresses
     nothing and risks nothing being honoured. Use `inLanguage` in schema and
     `<html lang>` instead. Document the decision in a comment so the next
     person does not "fix" it.

=========================================================
PHASE 2 — ENTITY LAYER  (the foundation of GEO)
=========================================================
LLMs answer brand questions from an entity graph, not from keyword density.
Build the entity first; everything else hangs off it.

2.1  One Organization node with a stable @id: {{store_url}}/#organization
     Every other node (Product, FAQPage, BreadcrumbList, CollectionPage)
     references that @id. One canonical entity, not one per page.

2.2  alternateName — POPULATE IT FROM SEARCH CONSOLE, NOT FROM IMAGINATION.
     Pull 90 days of GSC brand queries and list every real spelling and
     transliteration people actually typed. On the reference site this found
     the brand ranking position 39-48 FOR ITS OWN NAME in Arabic spellings that
     were never in the markup. A brand on page 4 for itself is invisible to an
     LLM asked "who is X".
     Rule: if a spelling has zero impressions in GSC, it does not go in.

2.3  Choose the HONEST @type.
       OnlineStore    → sells online, ships; no walk-in shop
       LocalBusiness  → ONLY with a real street address + Google Business Profile
     Declaring Store/LocalBusiness with openingHours asserts a physical shop the
     public can walk into. An unverifiable claim costs trust rather than buying
     it. On the reference site this was downgraded from Store to OnlineStore for
     exactly that reason.

2.4  Address: addressLocality + addressRegion + addressCountry, with NO
     streetAddress, is the correct shape for an online-only business. Locality
     alone is still a genuine local-relevance signal.

2.5  contactPoint with contactType, areaServed, and availableLanguage.

2.6  sameAs → only profiles you actually control and that are live.

2.7  NEVER add awards, certifications, aggregateRating or review counts that
     are not verifiable. This is the single discipline that makes the whole
     entity trustworthy to a model. One fabricated node poisons the rest.

=========================================================
PHASE 3 — THE AI SURFACE  (this is what most stores skip)
=========================================================
3.1  robots.txt — do NOT block answer-engine crawlers unless you have a reason.
     Blocking GPTBot removes you from ChatGPT's retrieval. Keep Google-Extended
     allowed if you want to appear in AI Overviews. State the policy in a
     comment so nobody "hardens" it by accident.

3.2  Publish /llms.txt — a plain-text brand context file. Structure that works:
       # Brand — AI Assistant Context File   (+ last-updated date)
       ## What is <brand>?        one tight paragraph
       ## <Language> versions      the SAME paragraph per customer language
       ## Key Facts               bullets: city, sourcing, catalogue, payment,
                                  shipping rates, languages, guarantees
       ## Key Pages               absolute URLs with a one-line description each
       ## Freshness and source rules
                                  state explicitly that LIVE PRODUCT PAGES are
                                  the source of truth for price/stock, and that
                                  this file may lag. This is what stops a model
                                  quoting a stale price as current.

3.3  Publish an agent-discovery document (/agents.md or the platform's managed
     equivalent) with the same entity facts in Markdown. Markdown is what a
     retrieval pipeline ingests most cleanly.

3.4  `speakable` (SpeakableSpecification with cssSelector) on the homepage
     summary paragraph and on FAQ answers — it marks which sentences are the
     extractable answer.

3.5  `inLanguage` on every schema node, using the full locale (e.g. ar-MA, not
     ar). Mixed-language stores are routinely mis-detected without it.

=========================================================
PHASE 4 — AEO / ANSWER LAYER
=========================================================
4.1  ANSWER-FIRST. Every landing page opens with a 2-3 sentence paragraph that
     directly answers the query the page targets, before any marketing copy,
     before any product grid. That paragraph is what gets extracted.

4.2  FAQPage at scale, but GATED. The reference site carries ~67 Q&A pairs
     across 7 templates. The gate is the important part:
       - FAQ content lives in a METAFIELD (or CMS field), not hardcoded.
       - Schema renders ONLY when that field is populated.
       - No field → no markup. Never emit FAQPage speculatively.
     FAQPage without matching visible Q&A on the same page is a violation.

4.3  SINGLE SOURCE for each FAQ. The reference implementation has a known
     defect, documented in its own code: the visible Q&A lives in the page body
     while the schema is built from the metafield — two copies with nothing
     enforcing agreement. DO NOT COPY THAT. Render the visible list AND the
     schema from the same field, in one loop.

4.4  Write questions as real queries, in the customer's actual language,
     including the informal/dialect phrasing they type — not polished
     marketing questions nobody searches.

4.5  BreadcrumbList on every collection and product page.

=========================================================
PHASE 5 — PRODUCT SCHEMA   ⚠ THIS IS WHERE FRAGRANCE DIVERGES
=========================================================
The reference site sells one-of-one second-hand goods. Its product schema is
built around itemCondition: UsedCondition and has no GTINs, because the items
genuinely have none. For NEW BRANDED FRAGRANCE, invert this:

5.1  gtin13 / gtin / mpn / brand / sku on EVERY product. For new branded retail
     this is the highest-leverage field in the whole document — Google Merchant
     Center treats a missing GTIN on a product that has one as a data-quality
     failure, and LLM shopping surfaces use GTIN to resolve "which exact
     product is this".
     If you cannot obtain GTINs, say so explicitly and set `identifier_exists`
     correctly rather than inventing one.

5.2  itemCondition: https://schema.org/NewCondition

5.3  offers.priceValidUntil, availability from LIVE inventory (never a static
     InStock), priceCurrency, and a real `url`.

5.4  shippingDetails with your ACTUAL rates as OfferShippingDetails
     (shippingRate + deliveryTime + shippingDestination), and
     hasMerchantReturnPolicy with real merchantReturnDays and
     returnPolicyCategory. These two produce visible SERP annotations and are
     quoted almost verbatim by LLMs answering "does X ship to me / can I return".

5.5  additionalProperty (PropertyValue) for the attributes fragrance buyers
     actually filter and ask on: concentration (EDP/EDT/Parfum), volume in ml,
     olfactive family, top/heart/base notes, longevity, sillage, gender/unisex,
     launch year, perfumer. This is the structured data that lets a model answer
     "a warm vanilla EDP under X" and name you.

5.6  AggregateRating + Review — ONLY from a genuine review platform with real
     verified reviews. Fragrance discovery is review-driven, so this is a large
     lever, and fabricating it is both a policy violation and the fastest way to
     lose the trust the rest of this work buys.

⚠ 5.7  COMPLIANCE — ANSWER BEFORE YOU BUILD:
   - If Nur sells "inspired by" / dupe fragrances, naming the designer house in
     titles, meta, schema or alternateName is a trademark problem and a
     Merchant Center misrepresentation risk. Comparative naming is regulated
     differently per market. Flag it and get a decision before shipping any
     markup that does it.
   - If Nur sells decants/splits, do not imply house authorisation you do not
     have, and check carrier rules for shipping flammable liquids.
   - Never present a reference/compare-at price that was never genuinely
     charged. (The reference site refused exactly this and documented why —
     see its docs/PROMOTION.md.)

=========================================================
PHASE 6 — PROGRAMMATIC LANDING PAGES
=========================================================
6.1  ONE template keyed on page handle drives every landing page. Content is
     selected per handle; products are pulled DYNAMICALLY by tag/vendor/type
     with out-of-stock excluded automatically. Never hardcode product IDs into
     a landing page.

6.2  For fragrance, the query shapes that deserve pages:
       <note> perfume <market>            e.g. oud perfume Morocco
       <family> fragrance for <gender>
       best <occasion> perfume <market>
       <house> perfume <market>           (only if you are an authorised seller)
       long lasting perfume <market>
       perfume <city> delivery / cash on delivery
     Each page needs: a distinct H1, a distinct title, an answer-first
     paragraph, a real product grid, its own FAQ set, and a link to its parent
     collection.

6.3  ⚠ ANTI-PATTERN from the reference site — do not repeat it. Its pSEO
     template grew to 46KB of hardcoded per-handle content and does NOT render
     the page body at all, so editing the page in Admin is inert and any content
     change means editing the template. Keep landing-page CONTENT in the CMS/
     metafields and the template purely structural.

=========================================================
PHASE 7 — INTERNAL LINKING
=========================================================
7.1  Audit link DIRECTION, not just link count. The reference site found its 10
     published guides linked out to collections while nothing linked back —
     equity flowed one way only. Fix reciprocity.
7.2  Every landing page links to its parent collection and to 2-3 sibling
     guides, in real server-rendered HTML. Links injected by JavaScript are not
     reliably followed.
7.3  Every product links back to at least one editorial/guide page.

=========================================================
NON-NEGOTIABLE RULES
=========================================================
- Never invent a fact to fill a schema field. Blank is a valid, correct value.
- Never emit schema that has no visible on-page counterpart.
- Never block an answer-engine crawler without a stated reason.
- Every structural decision gets a code comment explaining WHY, including
  decisions NOT to do something — otherwise the next person reverses it.
- Verify by fetching the rendered page, not by trusting that the template
  looks right.

=========================================================
VERIFICATION — REQUIRED BEFORE YOU CALL ANY OF THIS DONE
=========================================================
1. Google Rich Results Test on: homepage, one collection, one product, one
   landing page. Zero errors, zero warnings you cannot justify.
2. Schema Markup Validator for the full graph, confirming @id references
   resolve to one Organization.
3. Fetch /robots.txt, /llms.txt, /agents.md and confirm 200 + correct content
   type.
4. curl each template with a GPTBot user-agent and confirm the same HTML is
   served (no cloaking, no JS-only content).
5. Confirm every FAQPage question also appears as visible text on the page.
6. GSC: watch brand-name position for the spellings added in 2.2.
7. Ask ChatGPT, Claude, Perplexity and Gemini: "What is Nur Fragrance?",
   "Where can I buy <category> in <city>?" Record the answers verbatim as a
   baseline, re-run in 30 days, and report the delta.

Start with PHASE 0 and show me the baseline before implementing anything.
````

---

## What does NOT transfer from Lbass

| Lbass technique | Why it does not transfer |
|---|---|
| `itemCondition: UsedCondition` | Nur sells new — must be `NewCondition` |
| No GTIN/MPN (items genuinely have none) | **Inverts.** For new branded retail, GTIN is the highest-value product field. Omitting it is a Merchant Center data-quality failure. |
| 1/1 scarcity messaging, "once sold it's gone" | Fragrance is restockable SKUs. Fake scarcity here is a false claim. |
| "Photographed individually, not stock photos" | A genuine differentiator for second-hand; meaningless for sealed retail bottles. |
| Condition metafields (`condition_status`, `ticket_status`) | Replace with concentration / volume / notes / longevity. |
| Sourcing story ("selected in Germany, checked in Marrakech") | Nur needs its own true provenance story, not this one. |

## Two techniques in Lbass you should NOT copy

1. **FAQ drift.** Visible Q&A lives in the page body, schema is built from a
   metafield. Two copies, nothing enforcing agreement — the code says so itself.
   Render both from one source.
2. **The 46KB pSEO template** that ignores `page.content`, making Admin edits
   inert. Keep content in the CMS.

## Verifiable references

| Technique | File |
|---|---|
| AI-crawler policy | `templates/robots.txt.liquid` |
| Entity + alternateName from GSC | `snippets/lbass-entity-schema.liquid` |
| Gated FAQPage | `snippets/lbass-page-faq-schema.liquid` |
| llms.txt | `assets/llms.txt` |
| Agent-discovery doc | `templates/agents.md.liquid` |
| Conditional robots, canonical, hreflang decision | `layout/theme.liquid` ~595–750 |
| `speakable` | `templates/index.liquid` ~2204 |
| pSEO engine | `templates/page.pseo.liquid` |
| Internal-link bridge | `snippets/lbass-pseo-links.liquid` |
