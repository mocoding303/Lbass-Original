# encoding: utf-8
# Renders the product page's price block on its own and asserts it agrees with
# the collection card for the same product.
#
# The two used to disagree by construction: templates/product.liquid computed
# its percentage with a plain `divided_by`, which FLOORS, while the card rounds
# half-up. One price, two published discount claims, on the two pages a shopper
# compares most often.
require_relative 'harness'

SRC = File.read("#{THEME}/templates/product.liquid", encoding: 'UTF-8')

# Slice the price block out of the template by its markers, so the test tracks
# the real file rather than a copy that can rot.
lines = SRC.lines
first  = lines.index { |l| l.include?('<div class="pdp-price-wrap">') } or abort 'pdp-price-wrap not found'
last   = lines[first..].index { |l| l.strip == '</div>' && l == lines[first..].find { |x| x.strip == '</div>' } }
# The block ends at the first line that closes pdp-price-wrap at its indent.
close  = (first...lines.size).find { |i| lines[i] == "    </div>\n" } or abort 'end of price block not found'
BLOCK  = lines[first..close].join

fails = 0

def render_block(block, product)
  render_source(block, { "product" => product })
end

puts "=" * 78
puts "PDP PRICE BLOCK — same numbers as the card, for the same product"
puts "=" * 78
puts "  %-20s %-10s %-10s %-12s %s" % %w[price/compare pdp-pct card-pct saving verdict]

[[49400, 54900], [31400, 34900], [19300, 30000], [12900, 18900], [20700, 23000]].each do |price, cap|
  p = product(handle: 'x', title: 'X', vendor: 'N', price: price, cap: cap)
  v = p['selected_or_first_available_variant']

  pdp,  e1 = render_block(BLOCK, p)
  card, e2 = render_snippet('lbass-price', { 'product' => p, 'variant' => v })
  errs = e1 + e2

  # The template writes &minus;; a variant switch writes whatever data-pct holds.
  # Accept either spelling so the test checks the NUMBER, not the encoding.
  pdp_pct  = pdp[/pdp-save[^>]*>(?:&minus;|−)(\d+)%/, 1]
  card_pct = card[/lb-price__off.*?&minus;(\d+)%/m, 1]
  pdp_save = pdp[/data-savesum[^>]*>([^<]*)</, 1].to_s.strip
  card_save = card[/lb-price__save.*?<span dir="ltr">([^<]*)</m, 1].to_s.strip

  ok = pdp_pct == card_pct && !pdp_pct.nil? && pdp_save == card_save && errs.empty?
  fails += 1 unless ok
  puts "  %-20s %-10s %-10s %-12s %s" % [
    "#{price / 100}/#{cap / 100}", pdp_pct || '-', card_pct || '-', pdp_save.inspect,
    ok ? 'ok' : "FAIL (card saving #{card_save.inspect}) #{errs}"
  ]
end

puts
puts "=" * 78
puts "NO COMPARE-AT -> the sale elements are present but HIDDEN, never populated"
puts "=" * 78
# They stay in the DOM because the size-switch handler needs stable targets;
# `hidden` is what keeps them off the page.
p = product(handle: 'z', title: 'Z', vendor: 'N', price: 34900, cap: nil)
pdp, errs = render_block(BLOCK, p)
problems = []
problems << 'old price VISIBLE'  unless pdp[/<span class="pdp-old"[^>]*hidden/]
problems << 'percentage VISIBLE' unless pdp[/<span class="pdp-save"[^>]*hidden/]
problems << 'saving VISIBLE'     unless pdp[/<p class="pdp-saved"[^>]*hidden/]
problems << 'a percentage was printed' if pdp =~ /(?:&minus;|−)\d+%/
problems << 'a compare-at was printed' if pdp[/pdp-old[^>]*>\s*\d/]
problems << 'current price missing'    unless pdp.include?('pdp-price')
problems << "render errors #{errs}"    unless errs.empty?
fails += problems.size
puts "  #{problems.empty? ? 'clean — current price only, sale targets hidden and empty' : "FAIL #{problems.join(', ')}"}"

puts
puts "=" * 78
puts "EVERY SIZE BUTTON CARRIES ITS OWN SALE FIGURES"
puts "=" * 78
# The handler reads data-cap / data-pct / data-save off the clicked button. If
# the template stops emitting them, switching size leaves the strikethrough,
# the percentage and the saving describing the PREVIOUS variant.
btn_line = SRC[/<button class="sz".*?<\/button>/m].to_s
%w[data-vid data-price data-cap data-pct data-save].each do |attr|
  ok = btn_line.include?(attr)
  fails += 1 unless ok
  puts "  %-14s %s" % [attr, ok ? 'emitted' : 'FAIL missing']
end

js = SRC[/function applySale\(d\).*?\n  \}/m].to_s
%w[data-old data-savepct data-saved data-savesum].each do |hook|
  ok = SRC.include?(hook)
  fails += 1 unless ok
  puts "  %-14s %s" % [hook, ok ? 'targeted' : 'FAIL no target in template']
end
ok = !js.empty? && SRC.include?('applySale(btn.dataset)')
fails += 1 unless ok
puts "  %-14s %s" % ['applySale', ok ? 'defined and called from the size handler' : 'FAIL not wired']

puts
abort("#{fails} FAILURES") if fails > 0
puts 'PDP PRICE OK'
