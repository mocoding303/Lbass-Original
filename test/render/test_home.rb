# encoding: utf-8
# templates/index.liquid is {% layout none %}: it is its own HTML document, so
# nothing in layout/theme.liquid protects it. This executes the parts of it that
# carry the store's promises, straight out of the real template, and checks what
# must not drift:
#
#   1. HERO   — the one piece in the first screen is an in-stock clothing piece
#               (never sold, never fragrance or cosmetics), with the sitewide
#               condition words and no stock code; the H1 keeps its id and text.
#   2. FAQ    — the FAQPage schema says exactly what the visible FAQ says,
#               question for question. Both come from one list; until
#               2026-09-30 the schema carried 9 of the 31 questions and three
#               of those were paraphrased.
#   3. HOOKS  — the snippets, ids, tracking attributes and footer guide links
#               that tracking, schema and the measurement plan depend on.
#   4. BAR    — the announcement bar is identical to layout/theme.liquid's
#               (CLAUDE.md: .lb-bar lives in both shells; change both or neither).
#
# (The "available now" grid has its own suite: test_home_rails.rb.)
require_relative 'harness'
require 'json'
require 'cgi'

module HomeTestFilters
  def json(v) = JSON.generate(v)   # Shopify's json filter; the gem has none
end
Liquid::Template.register_filter(HomeTestFilters)

SRC    = File.read("#{THEME}/templates/index.liquid", encoding: 'UTF-8')
LAYOUT = File.read("#{THEME}/layout/theme.liquid", encoding: 'UTF-8')

def between(src, from, to)
  a = src.index(from) or abort "#{from} not found"
  b = src.index(to, a) or abort "#{to} not found after #{from}"
  src[a...(b + to.size)]
end

def text(html) = CGI.unescapeHTML(html.gsub(/<[^>]+>/, '')).gsub(/\s+/, ' ').strip

$fails = 0
def check(name, ok)
  $fails += 1 unless ok
  puts "  #{ok ? 'ok  ' : 'FAIL'}  #{name}"
end

# ── 1. HERO ─────────────────────────────────────────────────────────────────
puts '=' * 78
puts 'HERO — one real, in-stock clothing piece; H1 unchanged'
puts '=' * 78
HERO = between(SRC, '<!-- ═══ HERO ═══ -->', '</section>')

def piece(handle, title: "T #{handle}", **kw)
  pr = product(handle: handle, title: title, vendor: 'Nike', price: 29900, **kw)
  pr['type'] = pr['product_type']
  pr
end
sold    = piece('sold-jacket', type: 'Jackets', available: false)
perfume = piece('perfume', type: 'Fragrance', cond: nil, inspected: false)
serum   = piece('serum', type: 'Cosmetics', cond: nil, inspected: false)
pick    = piece('nike-windbreaker', title: 'Nike Windbreaker - Size M — LBO-P007', type: 'Jackets')
later   = piece('later-shoe', type: 'Shoes')
drop    = ->(items) { { 'audited-drop-p001-p012' => { 'products' => items } } }

out, errs = render_source(HERO, { 'collections' => drop.([sold, perfume, serum, pick, later]) })
price, = render_source('{{ p | money }}', { 'p' => 29900 })
piece_tag = out[/<a class="lbx-piece"[^>]*>/].to_s
piece_img = out[/<a class="lbx-piece".*?(<img[^>]*>)/m, 1].to_s
h1 = out[/<h1\b[^>]*>(.*?)<\/h1>/m, 1].to_s
check 'renders without errors',                       errs.empty?
check 'shows the first in-stock clothing piece',      piece_tag.include?('href="/products/nike-windbreaker"')
check 'skips sold, fragrance and cosmetics',          (%w[sold-jacket perfume serum] & out.scan(%r{/products/([\w-]+)}).flatten).empty?
check 'shows only one piece',                         out.scan('class="lbx-piece"').size == 1
check 'tracked as a hero product card click',         piece_tag.include?('data-cro-product-card') && piece_tag.include?('data-cro-placement="hero"') && piece_tag.include?('data-cro-label="hero_drop_piece"')
check 'sitewide condition words',                     out.include?('بحالة ممتازة · شبه جديد')
check 'no internal stock code (LBO-) in the text',    !text(out).include?('LBO-')
check 'price rendered through the money filter',      out.include?(price.strip)
check 'piece image has width and height',             piece_img.match?(/\swidth="\d+"/) && piece_img.match?(/\sheight="\d+"/)
check 'piece image is the priority image',            piece_img.include?('fetchpriority="high"') && !piece_img.include?('loading="lazy"')
check 'H1 keeps id="home-h1"',                        out.match?(/<h1\b[^>]*\bid="home-h1"/)
check 'H1 keeps its text',                            text(h1) == 'Lbass Original — حوايج Second-Hand أصلية فالمغرب'
check 'hero CTAs keep hero_cta_click',                %w[shop_now condition_proof].all? { |l| out.include?(%(data-cro-event="hero_cta_click" data-cro-label="#{l}")) }

out2, errs2 = render_source(HERO, { 'collections' => drop.([sold, perfume, serum]) })
check 'nothing in stock: no piece, promise and CTAs still render',
      errs2.empty? && !out2.include?('class="lbx-piece"') && out2.include?('id="home-h1"') && out2.include?('data-cro-label="shop_now"')

# ── 2. FAQ ──────────────────────────────────────────────────────────────────
puts
puts '=' * 78
puts 'FAQ — the schema says exactly what the visible FAQ says'
puts '=' * 78
FAQ    = between(SRC, '<!-- ═══ FAQ — END OF HOMEPAGE ═══ -->', '</section>')
FAQ_LD = between(SRC, '<!-- ═══ FAQ SCHEMA ═══ -->', '</script>')
out, errs = render_source(FAQ + FAQ_LD, {})
visible = out.scan(%r{<details><summary>(.*?)</summary><p>(.*?)</p></details>}m).map { |q, a| [text(q), text(a)] }
ld = begin
  JSON.parse(out[%r{<script type="application/ld\+json">(.*?)</script>}m, 1].to_s)
rescue JSON::ParserError => e
  puts "  (schema does not parse: #{e.message[0, 120]})"
  {}
end
schema = Array(ld['mainEntity']).map { |q| [text(q['name'].to_s), text(q.dig('acceptedAnswer', 'text').to_s)] }
check 'renders without errors',                        errs.empty?
check 'schema is valid FAQPage JSON',                  ld['@type'] == 'FAQPage'
check "same number of questions (#{visible.size} visible, #{schema.size} in schema)", visible.size.positive? && visible.size == schema.size
mism = visible.zip(schema).each_with_index.reject { |(v, s), _| v == s }
check 'every question and answer identical, in order', mism.empty?
mism.first(3).each { |(v, s), i| puts "        ##{i + 1} visible: #{v[1][0, 90]}\n             schema:  #{s.to_a[1].to_s[0, 90]}" }
check 'no duplicate questions',                        visible.map(&:first).uniq.size == visible.size
check 'no list separators leak into the page',         !out.include?('§§') && !out.include?('¤¤')
check 'speakable points at the visible FAQ',           Array(ld.dig('speakable', 'cssSelector')).include?('.home-faq details p')

# ── 3. HOOKS ────────────────────────────────────────────────────────────────
puts
puts '=' * 78
puts 'HOOKS — what tracking, schema and the measurement plan depend on'
puts '=' * 78
{
  'entity schema snippet (JSON-LD)'     => "{% render 'lbass-entity-schema' %}",
  'AI attribution'                      => "{% render 'lbass-ai-attribution' %}",
  'Meta Pixel'                          => "{% render 'lbass-meta-pixel' %}",
  'CRO tracking (also renders the menu)' => "{% render 'lbass-cro-tracking' %}",
  'cart drawer'                         => "{% render 'lbass-cart-drawer' %}",
  'entity block'                        => "{% render 'lbass-entity-block' %}",
  'canonical'                           => '<link rel="canonical" href="https://www.lbassoriginal.com/">',
  'answer block'                        => '<section class="lb-answer"',
  'Judge.me carousel'                   => "{{ jm_metafields.featured_carousel }}",
  'Judge.me all-reviews text'           => "class='jdgm-widget jdgm-all-reviews-text'",
  'grid see-all event'                  => 'data-cro-event="new_drop_click" data-cro-label="see_all"',
  'grid cards tracked as new_drop'      => 'data-cro-placement="new_drop"',
  'shop-by block'                       => "{% render 'lbass-home-collections' %}",
  'trust links event'                   => 'data-cro-event="home_trust_click"',
  'terms WhatsApp event'                => 'data-cro-event="whatsapp_click" data-cro-label="home_terms"',
  'Vault cards'                         => 'data-vault-card',
  'footer WhatsApp'                     => 'id="footWa" href="https://wa.me/491754264425?text=',
  'floating WhatsApp'                   => 'id="waFloat" href="https://wa.me/491754264425?text=',
}.each { |name, needle| check name, SRC.include?(needle) }

foot = between(SRC, '<footer class="foot">', '</footer>')
guides = %w[/pages/authenticity /pages/condition-guide /pages/size-guide
            /blogs/news/farq-bin-vintage-second-hand-thrift /blogs/news/chno-ma3na-one-of-one-fashion
            /pages/shipping-and-payment /pages/refund-policy /blogs/news]
missing = guides.reject { |g| foot.include?(%(href="#{g}")) }
check "footer guide links (#{guides.size - missing.size}/#{guides.size})#{missing.empty? ? '' : ' missing: ' + missing.join(' ')}", missing.empty?
check 'exactly one H1 in the template', SRC.scan(/<h1\b/).size == 1

# ── 4. BAR ──────────────────────────────────────────────────────────────────
puts
puts '=' * 78
puts 'ANNOUNCEMENT BAR — identical in index.liquid and layout/theme.liquid'
puts '=' * 78
bar_css   = ->(s) { s.lines.map(&:strip).grep(/\A(\.lb-bar|@keyframes lbMarquee|@media\(max-width:480px\)\{\.lb-bar)/) }
bar_items = ->(s) { s[%r{<div class="lb-bar-track">(.*?)</div>}m, 1].to_s.scan(%r{<span class="lb-bar-item"[^>]*>(.*?)</span>}).flatten }
check "same CSS (#{bar_css.(SRC).size} rules)", !bar_css.(SRC).empty? && bar_css.(SRC) == bar_css.(LAYOUT)
check "same items (#{bar_items.(SRC).size})",   !bar_items.(SRC).empty? && bar_items.(SRC) == bar_items.(LAYOUT)

puts
abort("#{$fails} FAILURES") if $fails > 0
puts 'HOME OK'
