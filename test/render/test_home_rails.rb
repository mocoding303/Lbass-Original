# encoding: utf-8
# The homepage has its own card markup — it does NOT use snippets/lbass-product-card
# — and it had drifted from every other surface:
#
#   the "Drop" rail   showed price + strikethrough, but no percentage and no saving
#   the "Real" rail   showed the price and NOTHING else, so a genuinely marked-down
#                     piece looked full price on the homepage and discounted on the
#                     collection grid and the product page
#
# This slices both rails out of templates/index.liquid, executes them, and asserts
# they now agree with snippets/lbass-price for the same product.
require_relative 'harness'

SRC = File.read("#{THEME}/templates/index.liquid", encoding: 'UTF-8')

# Slice by the assignment that opens each block through the saving line that
# closes it, so the test tracks the real template rather than a copy.
def slice(src, var)
  lines = src.lines
  first = lines.index { |l| l.include?("assign #{var} = false") } or abort "#{var} block not found"
  last  = (first...lines.size).find { |i| lines[i].include?('class="psaving"') } or abort "#{var} saving line not found"
  lines[first..last].join
end

DROP = slice(SRC, 'drop_sale')
REAL = slice(SRC, 'real_sale')

fails = 0

puts '=' * 78
puts 'HOMEPAGE RAILS — same numbers as the collection card, for the same product'
puts '=' * 78
puts '  %-18s %-6s %-22s %-22s %s' % %w[price/compare rail rendered card verdict]

[[49400, 54900], [19300, 30000], [12900, 18900], [20700, 23000]].each do |price, cap|
  p = product(handle: 'x', title: 'X', vendor: 'N', price: price, cap: cap)
  v = p['selected_or_first_available_variant']
  card, = render_snippet('lbass-price', { 'product' => p, 'variant' => v })
  card_pct  = card[/lb-price__off.*?&minus;(\d+)%/m, 1]
  card_save = card[/lb-price__save.*?<span dir="ltr">([^<]*)</m, 1].to_s.strip.sub(/\s*DH\z/, '')

  { 'drop' => DROP, 'real' => REAL }.each do |name, block|
    out, errs = render_source(block, { 'product' => p, 'variant' => v, 'drop_one' => true, 'real_one' => true })
    pct  = out[/&minus;(\d+)%/, 1]
    save = out[/psaving.*?<span dir="ltr">([^<]*)</m, 1].to_s.strip.sub(/\s*DH\z/, '')
    struck = out.include?('class="pold"')

    ok = pct == card_pct && save == card_save && struck && errs.empty?
    fails += 1 unless ok
    puts '  %-18s %-6s %-22s %-22s %s' % [
      "#{price / 100}/#{cap / 100}", name,
      "-#{pct}% / #{save}", "-#{card_pct}% / #{card_save}",
      ok ? 'ok' : "FAIL struck=#{struck} #{errs}"
    ]
  end
end

puts
puts '=' * 78
puts 'NO COMPARE-AT -> no strikethrough, no percentage, no saving, price intact'
puts '=' * 78
p = product(handle: 'z', title: 'Z', vendor: 'N', price: 34900, cap: nil)
v = p['selected_or_first_available_variant']
{ 'drop' => DROP, 'real' => REAL }.each do |name, block|
  out, errs = render_source(block, { 'product' => p, 'variant' => v, 'drop_one' => true, 'real_one' => true })
  problems = []
  problems << 'strikethrough rendered' if out.include?('class="pold"')
  problems << 'percentage rendered'    if out =~ /&minus;\d+%/
  problems << 'saving rendered'        if out.include?('class="psaving"')
  problems << "render errors #{errs}"  unless errs.empty?
  # The Drop rail must fall back to the 1/1 stamp in that slot, not go blank.
  problems << '1/1 fallback lost'      if name == 'drop' && !out.include?('>1/1<')
  fails += problems.size
  puts "  %-6s %s" % [name, problems.empty? ? 'clean' : "FAIL #{problems.join(', ')}"]
end

puts
abort("#{fails} FAILURES") if fails > 0
puts 'HOME RAILS OK'
