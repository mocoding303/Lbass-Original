# encoding: utf-8
# Executes the promotional pricing components and asserts the things a shopper
# actually depends on:
#
#   1. the percentage on the card image and the percentage in the price row are
#      the SAME number, always, for any price pair;
#   2. rounding is half-up, so the printed percentage matches what a shopper
#      gets dividing the two printed prices;
#   3. a product with no genuine compare-at renders NO promotional markup at all
#      -- no -0%, no empty saving, no badge;
#   4. the saving equals compare_at - price exactly.
require_relative 'harness'

fails = 0
def bad!; end

puts "=" * 78
puts "ONE PERCENTAGE, TWO SURFACES — lbass-sale drives both badge and pill"
puts "=" * 78
puts "  %-22s %-8s %-8s %-8s %s" % %w[price/compare badge pill exact verdict]

# Price pairs chosen to exercise the rounding boundary in both directions.
# (price_cents, compare_cents, expected_pct)
PAIRS = [
  [ 49400,  54900, 10],   # the live -10% markdown: 10.018% -> 10
  [ 31400,  34900, 10],   # 10.028% -> 10
  [ 20700,  23000, 10],   # exactly 10%
  [ 89900,  99900, 10],   # 10.01% -> 10
  [ 19300,  30000, 36],   # 35.667% -> 36 half-up. Floor would print 35.
  [ 19400,  30000, 35],   # 35.333% -> 35
  [ 12900,  18900, 32],   # 31.746% -> 32 half-up. Floor would print 31.
  [ 13000,  18900, 31],   # 31.217% -> 31
  [ 14950,  29900, 50],   # exactly 50%
  [     1,      3, 67],   # 66.67% -> 67, degenerate but must not crash
  [ 99900, 100000,  0],   # 0.1% -> 0. Rounds AWAY, so no badge renders.
]

PAIRS.each do |price, cap, want|
  p = product(handle: "x", title: "X", vendor: "Nike", price: price, cap: cap)
  v = p["selected_or_first_available_variant"]

  sale,  e1 = render_snippet("lbass-sale",           { "product" => p, "variant" => v })
  badge, e2 = render_snippet("lbass-markdown-badge", { "product" => p, "variant" => v })
  row,   e3 = render_snippet("lbass-price",          { "product" => p, "variant" => v })
  errs = e1 + e2 + e3

  sale = sale.strip
  badge_pct = badge[/&minus;(\d+)%/, 1]
  pill_pct  = row[/lb-price__off[^>]*>.*?&minus;(\d+)%/m, 1]

  exact = (cap - price) * 100.0 / cap

  ok = sale == want.to_s
  ok &&= (want.zero? ? badge_pct.nil? : badge_pct == want.to_s)
  ok &&= (want.zero? ? pill_pct.nil?  : pill_pct  == want.to_s)
  ok &&= errs.empty?

  # A sub-1% markdown drops the percentage but must KEEP the honest parts:
  # the price really was reduced, and the saving really is 1 DH.
  if want.zero?
    ok &&= row.include?("lb-price__was")
    ok &&= row.include?("lb-price__save")
  end

  fails += 1 unless ok

  puts "  %-22s %-8s %-8s %-8s %s" % [
    "#{price / 100.0}/#{cap / 100.0}",
    badge_pct || "-", pill_pct || "-", format("%.2f%%", exact),
    ok ? "ok" : "FAIL want #{want} (sale echoed #{sale.inspect}) #{errs}"
  ]
end

puts
puts "  scanning every pair for a printed -0% ..."
zero_leaks = PAIRS.reject do |price, cap, _|
  q = product(handle: "x", title: "X", vendor: "N", price: price, cap: cap)
  v = q["selected_or_first_available_variant"]
  b, = render_snippet("lbass-markdown-badge", { "product" => q, "variant" => v })
  r, = render_snippet("lbass-price",          { "product" => q, "variant" => v })
  !(b + r).include?("&minus;0%")
end
fails += zero_leaks.size
puts(zero_leaks.empty? ? "  no surface prints -0%" : "  FAIL -0% printed for #{zero_leaks.inspect}")

puts
puts "=" * 78
puts "HALF-UP, NOT FLOOR — the bug templates/product.liquid used to carry"
puts "=" * 78
[[19300, 30000], [12900, 18900], [4900, 7900]].each do |price, cap|
  floor = ((cap - price) * 100) / cap                      # what divided_by does
  sale, = render_snippet("lbass-sale", { "product" => product(handle: "y", title: "Y", vendor: "N", price: price, cap: cap) })
  half  = ((cap - price) * 100.0 / cap).round
  ok = sale.strip == half.to_s
  fails += 1 unless ok
  puts "  %-16s floor=%-4s half-up=%-4s rendered=%-4s %s" % [
    "#{price / 100}/#{cap / 100}", floor, half, sale.strip, ok ? "ok" : "FAIL"
  ]
end

puts
puts "=" * 78
puts "NO PROMOTION -> NO PROMOTIONAL MARKUP"
puts "=" * 78
# compare_at absent, equal to price, and BELOW price (a data error) must all be
# treated as "not on sale" rather than rendering a negative or zero discount.
[["no compare-at", nil], ["compare-at == price", 34900], ["compare-at < price (bad data)", 30000]].each do |label, cap|
  p = product(handle: "z", title: "Z", vendor: "Nike", price: 34900, cap: cap)
  v = p["selected_or_first_available_variant"]
  badge, = render_snippet("lbass-markdown-badge", { "product" => p, "variant" => v })
  row,   = render_snippet("lbass-price",          { "product" => p, "variant" => v })
  sale,  = render_snippet("lbass-sale",           { "product" => p, "variant" => v })

  problems = []
  problems << "badge rendered"          unless badge.strip.empty?
  problems << "strikethrough rendered"  if row.include?("lb-price__was")
  problems << "percentage rendered"     if row.include?("lb-price__off")
  problems << "savings rendered"        if row.include?("lb-price__save")
  problems << "is-sale class"           if row.include?("is-sale")
  problems << "-0% printed"             if row.include?("&minus;0%")
  problems << "sale echoed #{sale.strip.inspect}" unless sale.strip == "0"
  # the price itself must still be there
  problems << "PRICE MISSING"           unless row.include?("lb-price__now")

  fails += 1 unless problems.empty?
  puts "  %-32s %s" % [label, problems.empty? ? "clean — price only" : "FAIL #{problems.join(', ')}"]
end

puts
puts "=" * 78
puts "SAVING == compare_at - price, EXACTLY"
puts "=" * 78
[[49400, 54900, "55"], [19300, 30000, "107"], [20700, 23000, "23"]].each do |price, cap, want_dh|
  p = product(handle: "s", title: "S", vendor: "N", price: price, cap: cap)
  row, = render_snippet("lbass-price", { "product" => p, "variant" => p["selected_or_first_available_variant"] })
  got = row[/lb-price__save.*?<span dir="ltr">([^<]*)</m, 1].to_s.strip
  ok = got.include?(want_dh)
  fails += 1 unless ok
  puts "  %-18s saving printed as %-14s %s" % ["#{price / 100}/#{cap / 100}", got.inspect, ok ? "ok" : "FAIL want #{want_dh}"]
end

puts
puts "=" * 78
puts "PRECOMPUTED pct MUST MATCH SELF-COMPUTED pct"
puts "=" * 78
# The collection card asks lbass-sale once and passes the answer to both the
# badge and the price row. If the pass-through and the fallback ever disagree,
# a card and a rail on the same page would print different numbers.
[[49400, 54900], [19300, 30000], [12900, 18900]].each do |price, cap|
  p = product(handle: "q", title: "Q", vendor: "N", price: price, cap: cap)
  v = p["selected_or_first_available_variant"]
  self_badge, = render_snippet("lbass-markdown-badge", { "product" => p, "variant" => v })
  pct,        = render_snippet("lbass-sale",           { "product" => p, "variant" => v })
  pass_badge, = render_snippet("lbass-markdown-badge", { "product" => p, "variant" => v, "pct" => pct.strip })
  self_row,   = render_snippet("lbass-price",          { "product" => p, "variant" => v })
  pass_row,   = render_snippet("lbass-price",          { "product" => p, "variant" => v, "pct" => pct.strip })
  ok = self_badge == pass_badge && self_row == pass_row
  fails += 1 unless ok
  puts "  %-18s badge %-9s row %-9s %s" % [
    "#{price / 100}/#{cap / 100}",
    self_badge == pass_badge ? "identical" : "DIFFER",
    self_row == pass_row ? "identical" : "DIFFER",
    ok ? "ok" : "FAIL"
  ]
end

puts
abort("#{fails} FAILURES") if fails > 0
puts "SALE PRESENTATION OK"
