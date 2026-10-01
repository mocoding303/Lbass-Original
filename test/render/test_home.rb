# encoding: utf-8
# templates/index.liquid is {% layout none %}: it is its own HTML document, so
# nothing in layout/theme.liquid protects it. This executes the parts of it that
# carry the store's promises, straight out of the real files, and checks what
# must not drift:
#
#   1. HERO PIECE — the one piece in the hero (snippets/lbass-hero-proof, picked
#                   in index.liquid) is in stock, never fragrance or cosmetics,
#                   with THE DROP rail's condition words, price rule and 1/1
#                   test, and no stock code. THE DROP rail skips it.
#   2. HERO WALL  — the hero background is real in-stock product photos only:
#                   no hero piece, nothing sold, sized, 6 eager on phones.
#   3. HERO SLIDE — the owner's hero keeps its H1 (id and text) and CTA
#                   tracking; the old lifestyle picture and its preload are gone.
#   4. FAQ        — every question in the FAQPage schema is on the page, and its
#                   answer is the visible answer word for word.
#   5. HOOKS      — snippets, ids, tracking attributes and footer guide links
#                   that tracking, schema and the measurement plan depend on.
#   6. DELIVERY + SHARE — 50 MAD outside Marrakech everywhere; the share image
#                   is the 1200x630 brand card.
#   7. BAR        — the announcement bar is identical to layout/theme.liquid's
#                   (CLAUDE.md: .lb-bar lives in both shells; change both or neither).
#
# (The homepage rails' prices have their own suite: test_home_rails.rb.)
require_relative 'harness'
require 'json'
require 'cgi'

module HomeTestFilters
  def json(v) = JSON.generate(v)   # Shopify's json filter; the gem has none
  def date(v, fmt) = (v.to_s == 'now' ? Time.now : Time.parse(v.to_s)).strftime(fmt.to_s)
end
Liquid::Template.register_filter(HomeTestFilters)

SRC      = File.read("#{THEME}/templates/index.liquid", encoding: 'UTF-8')
LAYOUT   = File.read("#{THEME}/layout/theme.liquid", encoding: 'UTF-8')
CAROUSEL = File.read("#{THEME}/snippets/lbass-hero-carousel.liquid", encoding: 'UTF-8')
SWAP     = File.read("#{THEME}/snippets/lbass-hero-swap.liquid", encoding: 'UTF-8')

def between(src, from, to)
  a = src.index(from) or abort "#{from} not found"
  b = src.index(to, a) or abort "#{to} not found after #{from}"
  src[a...(b + to.size)]
end

def upto(src, from, to)   # like between, without the closing marker
  between(src, from, to).delete_suffix(to)
end

def text(html) = CGI.unescapeHTML(html.gsub(/<[^>]+>/, '')).gsub(/\s+/, ' ').strip

$fails = 0
def check(name, ok)
  $fails += 1 unless ok
  puts "  #{ok ? 'ok  ' : 'FAIL'}  #{name}"
end

def piece(handle, title: "T #{handle}", **kw)
  pr = product(handle: handle, title: title, vendor: 'Nike', price: 29900, **kw)
  pr['type'] = pr['product_type']
  pr
end
def drop(items) = { 'audited-drop-p001-p012' => { 'products' => items } }

sold    = piece('sold-jacket', type: 'Jackets', available: false)
perfume = piece('perfume', type: 'Fragrance', cond: nil, inspected: false)
serum   = piece('serum', type: 'Cosmetics', cond: nil, inspected: false)
pick    = piece('nike-windbreaker', title: 'Nike Windbreaker - Size M | جاكيطة Nike — LBO-P007', type: 'Jackets')
later   = piece('later-shoe', type: 'Shoes')

# ── 1. HERO PIECE ───────────────────────────────────────────────────────────
puts '=' * 78
puts 'HERO PIECE — one real, in-stock clothing piece, described like THE DROP rail'
puts '=' * 78
PICK = between(SRC, "{%- liquid\n  assign hero_pick = nil", "endfor\n-%}") + '{{ hero_pick.handle }}'
out, errs = render_source(PICK, { 'collections' => drop([sold, perfume, serum, pick, later]) })
check 'pick renders without errors',                   errs.empty?
check 'picks the first in-stock clothing piece',       out.strip == 'nike-windbreaker'
out, = render_source(PICK, { 'collections' => drop([sold, perfume, serum]) })
check 'nothing eligible: no pick',                     out.strip.empty?

card = ->(p) { render_snippet('lbass-hero-proof', { 'part' => 'card', 'hero_pick' => p }) }
out, errs = card.(pick)
tag = out[/<a class="lbh-piece"[^>]*>/].to_s
img = out[/<span class="lbh-piece-img">\s*(<img[^>]*>)/m, 1].to_s
check 'card renders without errors',                   errs.empty?
check 'links to the piece',                            tag.include?('href="/products/nike-windbreaker"')
check 'tracked as a hero CTA and a hero product card', tag.include?('data-cro-event="hero_cta_click" data-cro-label="hero_piece"') &&
                                                       tag.include?('data-cro-product-card') && tag.include?('data-cro-placement="hero"') &&
                                                       tag.include?(%(data-product-id="#{pick['id']}"))
check 'title without stock code or Arabic alias',      out.include?('>Nike Windbreaker - Size M<') && !text(out).include?('LBO-')
check 'price through the money filter',                out.include?('>299 DH<')
check 'says available, and 1/1 when one unit',         out.include?('متوفرة دابا · قطعة وحدة')
check 'image sized, priority, decorative alt',         img.match?(/\swidth="\d+"/) && img.match?(/\sheight="\d+"/) &&
                                                       img.include?('fetchpriority="high"') && !img.include?('loading="lazy"') && img.include?('alt=""')
out, = card.(piece('two-left', qty: 2, type: 'Jackets'))
check 'two units: no 1/1 claim',                       out.include?('متوفرة دابا') && !out.include?('قطعة وحدة')
out, = card.(piece('unchecked', inspected: false, type: 'Jackets'))
check 'inspection not confirmed: no condition words',  !out.include?('lbh-piece-cond')
check 'no piece: no card',                             card.(nil).first.strip.empty?

# Price rule: Shopify's compare-at only, percentage from snippets/lbass-sale.
onsale = piece('on-sale', cap: 34900, type: 'Jackets')
pct, = render_snippet('lbass-sale', { 'product' => onsale, 'variant' => onsale['selected_or_first_available_variant'] })
out, = card.(onsale)
check "sale: struck compare-at and lbass-sale's -#{pct.strip}%", out.include?('lbh-piece-old" dir="ltr">349 DH<') && out.include?("&minus;#{pct.strip}%")
out, = card.(later)
check 'no compare-at: no struck price, no percentage', !out.include?('lbh-piece-old') && !out.include?('&minus;')

# Condition words: the card must say what THE DROP rail says for the same piece.
RAIL_COND = upto(SRC, '{% assign drop_ticket = product.metafields', "{% capture drop_one_s %}") + '[[{{ drop_condition }}]]'
combos = [%w[new_with_ticket ticket_attached true], %w[excellent_almost_new no_ticket false], %w[very_good no_ticket false],
          %w[good no_ticket false], %w[very_good ticket_included true], %w[needs_note no_ticket false]]
same = combos.all? do |cond, ticket, has|
  p = piece("c-#{cond}", cond: cond, ticket: ticket, has_ticket: has == 'true', type: 'Jackets')
  rail = render_source(RAIL_COND, { 'product' => p }).first[/\[\[(.*?)\]\]/m, 1].to_s.strip
  mine = card.(p).first[%r{<span class="lbh-piece-cond">(.*?)</span>}, 1].to_s.strip
  rail == mine
end
check "condition words match THE DROP rail (#{combos.size} combinations)", same

# THE DROP rail skips the hero piece and still shows eight.
DROP_SEC = between(SRC, '<section class="sec" id="drop"', '</section>')
pieces = (1..10).map { |i| piece("p#{i}", type: 'Jackets') }
out, errs = render_source(DROP_SEC, { 'collections' => drop(pieces), 'hero_pick' => pieces[0] }, settings: SETTINGS_OFF, globals: { 'collections' => drop(pieces) })
shown = out.scan(/data-cro-placement="new_drop" data-product-id="(\d+)"/).flatten
check 'rail renders without errors',                   errs.empty?
check 'rail skips the hero piece and shows 8',         shown.size == 8 && !shown.include?(pieces[0]['id'].to_s) && shown.include?(pieces[8]['id'].to_s)
out, = render_source(DROP_SEC, { 'collections' => drop(pieces) }, settings: SETTINGS_OFF, globals: { 'collections' => drop(pieces) })
check 'no hero piece: rail shows the first 8',         out.scan(/data-cro-placement="new_drop" data-product-id="(\d+)"/).flatten == pieces.first(8).map { |p| p['id'].to_s }

# ── 2. HERO WALL ────────────────────────────────────────────────────────────
puts
puts '=' * 78
puts 'HERO WALL — the background is real in-stock product photos only'
puts '=' * 78
wall = ->(items, hero = nil) { render_snippet('lbass-hero-proof', { 'part' => 'wall', 'hero_pick' => hero }, globals: { 'collections' => drop(items) }) }
imgs = ->(html) { html.scan(/<img [^>]*>/) }
srcs = ->(html) { imgs.(html).map { |i| i[/src="([^"]*)"/, 1] } }
w = (1..12).map { |i| piece("w#{i}", type: 'T-Shirts') }

out, errs = wall.([pick, sold, perfume, serum] + w, pick)
check 'renders without errors',                        errs.empty?
check '8 photos (6 on phones)',                        imgs.(out).size == 8 && out.include?('data-n="8"')
check 'never the hero piece, sold, fragrance or cosmetics',
      (srcs.(out) & %w[nike-windbreaker sold-jacket perfume serum].map { |h| "https://img.test/#{h}.jpg" }).empty?
check 'decorative: aria-hidden wall, empty alt',       out.include?('class="lbh-bg lbh-bg--wall" data-n="8" aria-hidden="true"') && imgs.(out).all? { |i| i.include?('alt=""') }
check 'sized, low priority',                           imgs.(out).all? { |i| i.match?(/\swidth="\d+"/) && i.match?(/\sheight="\d+"/) && i.include?('fetchpriority="low"') }
check 'first 6 load with the page, 7-8 only from 768px', imgs.(out).first(6).none? { |i| i.include?('loading="lazy"') } &&
                                                       imgs.(out).last(2).all? { |i| i.include?('loading="lazy"') && i.include?('lbh-wall-x') }
many = (1..18).map { |i| piece("m#{i}", type: 'Shoes') }
out, = wall.(many)
check '16+ pieces: starts after the 8 THE DROP rail shows', srcs.(out).first == 'https://img.test/m9.jpg' && imgs.(out).size == 8
out, = wall.(w.first(5))
check '4 to 7 pieces: a 4-photo wall',                 imgs.(out).size == 4 && out.include?('data-n="4"')
out, = wall.(w.first(3))
check 'under 4 pieces: no wall, card styles still printed', !out.include?('lbh-bg--wall"') && out.include?('.lbh-piece{')

# ── 3. HERO SLIDE ───────────────────────────────────────────────────────────
puts
puts '=' * 78
puts "HERO SLIDE — the owner's hero, with the proof inside it"
puts '=' * 78
slide = CAROUSEL[/<header class="lbh".*?<\/header>/m].to_s
check 'index passes the pick to the hero and the strip', SRC.include?("{% render 'lbass-hero-carousel', hero_pick: hero_pick %}") &&
                                                         SRC.include?("{% render 'lbass-shop-by-category', hero_id: hero_pick.id %}")
check 'wall replaces the lifestyle picture',           slide.include?("{% render 'lbass-hero-proof', part: 'wall', hero_pick: hero_pick %}") && !slide.include?('hero-lifestyle-1.webp')
check 'card is the last item of the CTA group',        slide.include?(%(</a>{% render 'lbass-hero-proof', part: 'card', hero_pick: hero_pick %}</div><div class="lbh-trust">))
check 'no preload of the old picture',                 !SWAP.match?(/rel="preload"[^>]*\n?[^>]*hero-lifestyle-1\.webp/)
cols = drop([pick] + w)
out, errs = render_snippet('lbass-hero-carousel', { 'hero_pick' => pick, 'collections' => cols, 'theme' => { 'role' => 'main' } }, globals: { 'collections' => cols })
h1 = out[/<h1\b[^>]*>(.*?)<\/h1>/m, 1].to_s
check 'renders without errors',                        errs.empty?
check 'H1 keeps id="home-h1"',                         out.match?(/<h1\b[^>]*\bid="home-h1"/)
check 'H1 keeps its two lines',                        h1.scan(%r{<span class="lbh-ln[^"]*"[^>]*>(.*?)</span>}m).flatten.map { |l| text(l) } == ['Lbass Original —', 'حوايج Second-Hand أصلية فالمغرب']
check 'CTAs keep hero_cta_click labels',               %w[clothing_primary clothing_secondary].all? { |l| out.include?(%(data-cro-event="hero_cta_click" data-cro-label="#{l}")) }
check 'one piece card, one wall',                      out.scan('class="lbh-piece"').size == 1 && out.scan('lbh-bg--wall"').size == 1

# ── 4. FAQ ──────────────────────────────────────────────────────────────────
puts
puts '=' * 78
puts 'FAQ — every schema answer is the visible answer, word for word'
puts '=' * 78
FAQ    = between(SRC, '<section class="sec home-faq"', '</section>')
FAQ_LD = between(SRC, '<!-- ═══ FAQ SCHEMA ═══ -->', '</script>')
out, errs = render_source(FAQ + FAQ_LD, {})
visible = out.scan(%r{<summary>(.*?)</summary>\s*<p>(.*?)</p>}m).map { |q, a| [text(q), text(a)] }.to_h
ld = begin
  JSON.parse(out[%r{<script type="application/ld\+json">(.*?)</script>}m, 1].to_s)
rescue JSON::ParserError => e
  puts "  (schema does not parse: #{e.message[0, 120]})"
  {}
end
schema = Array(ld['mainEntity']).map { |q| [text(q['name'].to_s), text(q.dig('acceptedAnswer', 'text').to_s)] }
check 'renders without errors',                        errs.empty?
check 'schema is valid FAQPage JSON',                  ld['@type'] == 'FAQPage'
check "every schema question is on the page (#{schema.size} of #{visible.size})", !schema.empty? && schema.all? { |q, _| visible.key?(q) }
drift = schema.reject { |q, a| visible[q] == a }
check 'every schema answer is the visible answer',     drift.empty?
drift.first(3).each { |q, a| puts "        #{q[0, 50]}\n          visible: #{visible[q].to_s[0, 90]}\n          schema:  #{a[0, 90]}" }
check 'no duplicate schema questions',                 schema.map(&:first).uniq.size == schema.size
check 'speakable points at the visible FAQ',           Array(ld.dig('speakable', 'cssSelector')).include?('.home-faq details p')

# ── 5. HOOKS ────────────────────────────────────────────────────────────────
puts
puts '=' * 78
puts 'HOOKS — what tracking, schema and the measurement plan depend on'
puts '=' * 78
{
  'entity schema snippet (JSON-LD)'      => "{% render 'lbass-entity-schema' %}",
  'AI attribution'                       => "{% render 'lbass-ai-attribution' %}",
  'stamp tokens'                         => "{% render 'lbass-stamp' %}",
  'Meta Pixel'                           => "{% render 'lbass-meta-pixel' %}",
  'CRO tracking (menu, density, answer)' => "{% render 'lbass-cro-tracking' %}",
  'cart drawer'                          => "{% render 'lbass-cart-drawer' %}",
  'entity block'                         => "{% render 'lbass-entity-block' %}",
  'shop-by links block'                  => "{% render 'lbass-home-collections' %}",
  'fragrance best-sellers row'           => "{% render 'lbass-home-fragrances' %}",
  'canonical'                            => '<link rel="canonical" href="https://www.lbassoriginal.com/">',
  'answer block'                         => '<section class="lb-answer"',
  'Judge.me carousel'                    => 'featured_carousel',
  'Judge.me all-reviews text'            => "class='jdgm-widget jdgm-all-reviews-text'",
  'drop see-all event'                   => 'data-cro-event="new_drop_click" data-cro-label="section_header"',
  'drop cards tracked as new_drop'       => 'data-cro-placement="new_drop"',
  'Vault cards'                          => 'data-vault-card',
  'footer WhatsApp'                      => 'id="footWa" href="https://wa.me/491754264425"',
  'floating WhatsApp'                    => 'id="waFloat" href="https://wa.me/491754264425"',
  'newsletter men/women preference'      => "value='newsletter,homepage,pref-men'",
  'exit-popup men/women preference'      => "value='newsletter,exit-intent,pref-men'",
}.each { |name, needle| check name, SRC.include?(needle) }
tracking = File.read("#{THEME}/snippets/lbass-cro-tracking.liquid", encoding: 'UTF-8')
check 'section order and answer row still applied',    tracking.include?("{% if template == 'index' %}{% render 'lbass-home-density' %}{% endif %}") &&
                                                       tracking.include?("{% if template == 'index' %}{% render 'lbass-home-answer' %}{% endif %}")
foot = between(SRC, '<footer class="foot">', '</footer>')
guides = %w[/pages/authenticity /pages/condition-guide /pages/size-guide
            /blogs/news/farq-bin-vintage-second-hand-thrift /blogs/news/chno-ma3na-one-of-one-fashion
            /pages/shipping-and-payment /pages/refund-policy /blogs/news]
missing = guides.reject { |g| foot.include?(%(href="#{g}")) }
check "footer guide links (#{guides.size - missing.size}/#{guides.size})#{missing.empty? ? '' : ' missing: ' + missing.join(' ')}", missing.empty?
markup = SRC.gsub(%r{<script\b.*?</script>}m, '')
check 'no H1 in the template outside scripts (the hero owns it)', markup.scan(/<h1\b/).empty? && CAROUSEL.scan(/<h1\b/).size == 1

# ── 6. DELIVERY + SHARE IMAGE ───────────────────────────────────────────────
puts
puts '=' * 78
puts 'DELIVERY + SHARE IMAGE — 50 MAD outside Marrakech; the brand card'
puts '=' * 78
files = Dir["#{THEME}/{templates,snippets,sections,layout}/**/*.liquid"] + Dir["#{THEME}/{templates,config}/*.json"] + ["#{THEME}/assets/llms.txt"]
stale = files.select { |f| File.read(f, encoding: 'UTF-8').match?(/(?<![\d.,])(40|٤٠) ?(درهم|MAD|DH|Dh|dh|Dhs|د\.م)/) }
check "no 40 MAD delivery left#{stale.empty? ? '' : ': ' + stale.map { |f| f.sub("#{THEME}/", '') }.join(' ')}", stale.empty?
check 'hero chips say 50 outside Marrakech',           CAROUSEL.include?('<b>خارج مراكش</b> 50 درهم')
share = 'lbass-share-1200x630.jpg'
check 'og:image and twitter:image are the brand card', SRC.scan(/<meta (?:property="og:image(?::secure_url)?"|name="twitter:image") content="([^"]*)"/).flatten.then { |v| v.size == 3 && v.all? { |u| u.include?(share) } }
check 'og:image is 1200x630 JPEG',                     SRC.include?('<meta property="og:image:width" content="1200">') && SRC.include?('<meta property="og:image:height" content="630">') &&
                                                       SRC.include?('<meta property="og:image:type" content="image/jpeg">')
check 'the card exists in assets/',                    File.size?("#{THEME}/assets/#{share}").to_i > 10_000
check 'OnlineStore JSON-LD image is the card',         File.read("#{THEME}/snippets/lbass-entity-schema.liquid", encoding: 'UTF-8').include?(%("image": "https:{{ '#{share}' | asset_url }}"))

# ── 7. BAR ──────────────────────────────────────────────────────────────────
puts
puts '=' * 78
puts 'ANNOUNCEMENT BAR — identical in index.liquid and layout/theme.liquid'
puts '=' * 78
bar_css   = ->(s) { s.lines.map(&:strip).grep(/\A(\.lb-bar|@keyframes lbMarquee|@media\([^)]*\)\{\.lb-bar)/) }
bar_items = ->(s) { s[%r{<div class="lb-bar-track">(.*?)</div>}m, 1].to_s.scan(%r{<span class="lb-bar-item"[^>]*>(.*?)</span>}).flatten }
check "same CSS (#{bar_css.(SRC).size} rules)", !bar_css.(SRC).empty? && bar_css.(SRC) == bar_css.(LAYOUT)
check "same items (#{bar_items.(SRC).size})",   !bar_items.(SRC).empty? && bar_items.(SRC) == bar_items.(LAYOUT)

puts
abort("#{$fails} FAILURES") if $fails > 0
puts 'HOME OK'
