# encoding: utf-8
# The homepage has its own card markup — it does NOT use snippets/lbass-product-card
# — and it had drifted from every other surface. This slices the homepage's
# product grid out of templates/index.liquid, executes it, and asserts:
#
#   1. PRICE  — the grid card agrees with snippets/lbass-price for the same
#               product (strikethrough, percentage, saving).
#   2. STOCK  — "القطع اللي متوفرة دابا" only ever shows pieces that are in
#               stock. Until 2026-09-30 it looped the whole collection with no
#               stock filter and printed 16 sold pieces under that heading.
#   3. SCOPE  — fragrance and cosmetics never appear in it (the homepage sells
#               second-hand clothing), the hero's piece is not repeated, and it
#               stops at 8 cards.
#   4. WORDS  — condition labels are the sitewide vocabulary used by
#               snippets/lbass-product-card and templates/product.liquid.
#
# (The Drop rail this file also used to check was merged into the grid.)
require_relative 'harness'

SRC = File.read("#{THEME}/templates/index.liquid", encoding: 'UTF-8')

# Slice by the assignment that opens the price block through the saving line that
# closes it, so the test tracks the real template rather than a copy.
def slice(src, var)
  lines = src.lines
  first = lines.index { |l| l.include?("assign #{var} = false") } or abort "#{var} block not found"
  last  = (first...lines.size).find { |i| lines[i].include?('class="psaving"') } or abort "#{var} saving line not found"
  lines[first..last].join
end

# The whole "available now" section, from its marker to its closing tag.
def section(src, marker)
  a = src.index(marker) or abort "#{marker} not found"
  b = src.index('</section>', a) or abort 'section end not found'
  src[a...(b + '</section>'.size)]
end

REAL  = slice(SRC, 'real_sale')
AVAIL = section(SRC, '<!-- ═══ AVAILABLE NOW ═══ -->')

fails = 0

puts '=' * 78
puts 'HOMEPAGE GRID — same numbers as the collection card, for the same product'
puts '=' * 78
puts '  %-18s %-22s %-22s %s' % %w[price/compare rendered card verdict]

[[49400, 54900], [19300, 30000], [12900, 18900], [20700, 23000]].each do |price, cap|
  p = product(handle: 'x', title: 'X', vendor: 'N', price: price, cap: cap)
  v = p['selected_or_first_available_variant']
  card, = render_snippet('lbass-price', { 'product' => p, 'variant' => v })
  card_pct  = card[/lb-price__off.*?&minus;(\d+)%/m, 1]
  card_save = card[/lb-price__save.*?<span dir="ltr">([^<]*)</m, 1].to_s.strip.sub(/\s*DH\z/, '')

  out, errs = render_source(REAL, { 'product' => p, 'variant' => v, 'real_one' => true })
  pct  = out[/&minus;(\d+)%/, 1]
  save = out[/psaving.*?<span dir="ltr">([^<]*)</m, 1].to_s.strip.sub(/\s*DH\z/, '')
  struck = out.include?('class="pold"')

  ok = pct == card_pct && save == card_save && struck && errs.empty?
  fails += 1 unless ok
  puts '  %-18s %-22s %-22s %s' % [
    "#{price / 100}/#{cap / 100}", "-#{pct}% / #{save}", "-#{card_pct}% / #{card_save}",
    ok ? 'ok' : "FAIL struck=#{struck} #{errs}"
  ]
end

puts
puts '=' * 78
puts 'NO COMPARE-AT -> no strikethrough, no percentage, no saving, price intact'
puts '=' * 78
p = product(handle: 'z', title: 'Z', vendor: 'N', price: 34900, cap: nil)
v = p['selected_or_first_available_variant']
out, errs = render_source(REAL, { 'product' => p, 'variant' => v, 'real_one' => true })
problems = []
problems << 'strikethrough rendered' if out.include?('class="pold"')
problems << 'percentage rendered'    if out =~ /&minus;\d+%/
problems << 'saving rendered'        if out.include?('class="psaving"')
problems << "render errors #{errs}"  unless errs.empty?
fails += problems.size
puts "  grid   #{problems.empty? ? 'clean' : "FAIL #{problems.join(', ')}"}"

puts
puts '=' * 78
puts 'AVAILABLE NOW — in stock only, clothing only, no repeat of the hero, max 8'
puts '=' * 78
def piece(handle, **kw)
  pr = product(handle: handle, title: "T #{handle}", vendor: 'Nike', price: 29900, **kw)
  pr['type'] = pr['product_type']
  pr
end
hero  = piece('hero-piece', type: 'Jackets')
items = [
  hero,
  piece('sold-piece', available: false),
  piece('perfume', type: 'Fragrance', cond: nil, inspected: false),
  piece('serum', type: 'Cosmetics', cond: nil, inspected: false),
  piece('good-piece', cond: 'good', ticket: 'no_ticket', has_ticket: false),
  piece('nwot-piece', cond: 'new_without_ticket', ticket: 'no_ticket', has_ticket: false),
  piece('note-no-notes', cond: 'needs_note'),
] + (1..9).map { |i| piece("fill-#{i}") }
cols = { 'audited-drop-p001-p012' => { 'products' => items } }
out, errs = render_source(AVAIL, { 'collections' => cols, 'hero_pick' => hero })
cards = out.scan(/<a class="real-card" href="\/products\/([^"]+)"/).flatten
checks = {
  'renders without errors'                  => errs.empty?,
  'stops at 8 cards'                        => cards.size == 8,
  'no sold piece'                           => !cards.include?('sold-piece') && !out.include?('تباعت'),
  'no fragrance or cosmetics'               => (cards & %w[perfume serum]).empty?,
  'hero piece not repeated'                 => !cards.include?('hero-piece'),
  "'good' says بحالة مزيانة (sitewide)"     => out.include?('>بحالة مزيانة<'),
  "'good' never says شوف الملاحظات"         => !out.match?(/good-piece.*?بحالة مزيانة · شوف الملاحظات/m),
  "'new_without_ticket' is labelled"        => out.include?('جديد بلا تيكيت'),
  'every card is tracked as new_drop'       => out.scan('data-cro-placement="new_drop"').size == cards.size,
  'see-all link keeps new_drop_click'       => out.include?('data-cro-event="new_drop_click"'),
}
checks.each do |name, ok|
  fails += 1 unless ok
  puts "  #{ok ? 'ok  ' : 'FAIL'}  #{name}"
end
puts "  (rendered: #{cards.join(', ')})"

puts
abort("#{fails} FAILURES") if fails > 0
puts 'HOME RAILS OK'
