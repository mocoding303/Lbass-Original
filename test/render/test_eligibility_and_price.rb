# encoding: utf-8
require_relative 'harness'

puts "="*76
puts "ELIGIBILITY — snippets/lbass-promo.liquid (echoes 1/0)"
puts "="*76
fails = 0
cases = [
  ["campaign ON  + tagged + available",        product(handle:"a",title:"A",vendor:"Nike",price:19900,tags:["summer-sale"]), SETTINGS_ON,  "1"],
  ["campaign OFF + tagged + available",        product(handle:"b",title:"B",vendor:"Nike",price:19900,tags:["summer-sale"]), SETTINGS_OFF, "0"],
  ["campaign ON  + NOT tagged",                product(handle:"c",title:"C",vendor:"Nike",price:19900,tags:["black"]),       SETTINGS_ON,  "0"],
  ["campaign ON  + tagged + SOLD OUT",         product(handle:"d",title:"D",vendor:"Nike",price:19900,tags:["summer-sale"],available:false), SETTINGS_ON, "0"],
  ["campaign ON  + tagged + promo_eligible=F", product(handle:"e",title:"E",vendor:"Nike",price:19900,tags:["summer-sale"],promo_eligible:false), SETTINGS_ON, "0"],
  ["campaign ON  + tagged + promo_eligible=T", product(handle:"f",title:"F",vendor:"Nike",price:19900,tags:["summer-sale"],promo_eligible:true),  SETTINGS_ON, "1"],
  ["tag case-insensitive (Summer-Sale)",       product(handle:"g",title:"G",vendor:"Nike",price:19900,tags:["Summer-Sale"]), SETTINGS_ON,  "1"],
  ["substring must NOT match (summer-sales)",  product(handle:"h",title:"H",vendor:"Nike",price:19900,tags:["summer-sales"]),SETTINGS_ON,  "0"],
  ["tag with surrounding spaces",              product(handle:"i",title:"I",vendor:"Nike",price:19900,tags:[" summer-sale "]),SETTINGS_ON, "1"],
]
cases.each do |label, p, s, expect|
  out, errs = render_snippet("lbass-promo", {"product"=>p}, settings: s)
  got = out.strip
  ok = (got == expect); fails += 1 unless ok
  puts format("  %-4s %-44s -> %-3s (want %s)%s", ok ? "PASS":"FAIL", label, got, expect, errs.any? ? "  ERR:#{errs}" : "")
end

puts
puts "="*76
puts "PRICE — snippets/lbass-price.liquid   (5 price points from the brief)"
puts "="*76
[[10000,nil],[20000,nil],[29900,44900],[49900,69900],[99900,149900],[12900,18900]].each do |price,cap|
  p = product(handle:"p",title:"P",vendor:"Nike",price:price,cap:cap)
  out, errs = render_snippet("lbass-price", {"product"=>p,"variant"=>p["selected_or_first_available_variant"]})
  flat = out.gsub(/<[^>]+>/,"|").gsub(/\|+/,"|").gsub(/\s+/," ").strip
  label = cap ? "#{price/100} DH  (compare-at #{cap/100})" : "#{price/100} DH  (no compare-at)"
  puts format("  %-32s %s", label, flat)
  puts "     ERR:#{errs}" if errs.any?
end

puts
puts "="*76
puts "BADGE — snippets/lbass-promo-badge.liquid"
puts "="*76
pr = product(handle:"z",title:"Z",vendor:"Nike",price:19900,tags:["summer-sale"])
%w[ribbon line pdp].each do |fmt|
  out, errs = render_snippet("lbass-promo-badge", {"product"=>pr,"format"=>fmt})
  puts "  format=#{fmt}:"
  puts "    " + out.gsub(/\s+/," ").strip
  puts "    ERR:#{errs}" if errs.any?
end
out, _ = render_snippet("lbass-promo-badge", {"product"=>pr,"format"=>"ribbon"}, settings: SETTINGS_OFF)
puts "  campaign OFF -> #{out.strip.empty? ? 'renders NOTHING (correct)' : 'LEAKED: '+out.strip}"

puts
puts (fails.zero? ? "ELIGIBILITY: all #{cases.size} cases pass" : "ELIGIBILITY: #{fails} FAILURES")
