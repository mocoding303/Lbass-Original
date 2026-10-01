# encoding: utf-8
# templates/index.liquid is {% layout none %}: it is its own HTML document, so
# nothing in layout/theme.liquid protects it. This executes the parts of it that
# carry the store's promises, straight out of the real files, and checks what
# must not drift:
#
#   1. FAQ        — every question in the FAQPage schema is on the page, and its
#                   answer is the visible answer word for word.
#   2. HOOKS      — snippets, ids, tracking attributes and footer guide links
#                   that tracking, schema and the measurement plan depend on.
#   3. DELIVERY + SHARE — 50 MAD outside Marrakech everywhere; the share image
#                   is the 1200x630 brand card.
#   4. BAR        — the announcement bar is identical to layout/theme.liquid's
#                   (CLAUDE.md: .lb-bar lives in both shells; change both or neither).
#
# (The homepage rails' prices have their own suite: test_home_rails.rb.)
require_relative 'harness'
require 'json'
require 'cgi'

module HomeTestFilters
  def json(v) = JSON.generate(v)   # Shopify's json filter; the gem has none
end
Liquid::Template.register_filter(HomeTestFilters)

SRC      = File.read("#{THEME}/templates/index.liquid", encoding: 'UTF-8')
LAYOUT   = File.read("#{THEME}/layout/theme.liquid", encoding: 'UTF-8')
CAROUSEL = File.read("#{THEME}/snippets/lbass-hero-carousel.liquid", encoding: 'UTF-8')

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

# ── 1. FAQ ──────────────────────────────────────────────────────────────────
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

# ── 2. HOOKS ────────────────────────────────────────────────────────────────
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

# ── 3. DELIVERY + SHARE IMAGE ───────────────────────────────────────────────
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

# ── 4. BAR ──────────────────────────────────────────────────────────────────
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
