# encoding: utf-8
require_relative 'harness'

CARDS = [
  ["plain, no promo, no markdown",
   product(handle:"nike-air-max", title:"Nike Air Max Black/Green Sneakers | سبادري Nike",
           vendor:"Nike", price:59900, tags:["black"], cond:"good", type:"Shoes")],
  ["CAMPAIGN — tagged, available",
   product(handle:"vans-old-skool", title:"Vans Old Skool Black — فانز أولد سكول أصلي",
           vendor:"Vans", price:34900, tags:["summer-sale","black"], cond:"excellent_almost_new")],
  ["GENUINE MARKDOWN — compare-at 449 -> 299",
   product(handle:"zara-jacket", title:"Zara Khaki Jacket", vendor:"Zara",
           price:29900, cap:44900, tags:["khaki"], cond:"very_good", type:"Jackets")],
  ["CAMPAIGN + MARKDOWN together",
   product(handle:"tnf-puffer", title:"The North Face Black Puffer Jacket - Size M | جاكيطة TNF",
           vendor:"The North Face", price:74900, cap:99900, tags:["summer-sale"], cond:"good", type:"Jackets")],
  ["SOLD OUT + campaign tag (badge must NOT show)",
   product(handle:"on-running", title:"On Running Pink & Black Shoes - Size 43 | سبادري On",
           vendor:"On Running", price:90000, tags:["summer-sale"], available:false, cond:"good")],
  ["campaign tag + promo_eligible=false (veto)",
   product(handle:"hoka-red", title:"HOKA Red Running Shoes | سبادري HOKA", vendor:"HOKA",
           price:99900, tags:["summer-sale"], promo_eligible:false, cond:"new_without_ticket", ticket:"no_ticket")],
]

puts "="*78
puts "FULL CARD — snippets/lbass-product-card.liquid"
puts "="*78
html_cards = []
CARDS.each do |label, p|
  out, errs = render_snippet("lbass-product-card", {"product"=>p, "placement"=>"collection"})
  html_cards << out
  ribbon = out.include?("lb-promo-ribbon")
  line   = out.include?("lb-promo-line")
  struck = out.include?("lb-price__was")
  save   = out.include?("lb-price__save")
  stamp  = out[/lb-stamp[^>]*>([^<]*)</,1]
  puts format("  %-46s ribbon:%-3s line:%-3s struck:%-3s save:%-3s stamp:%s%s",
              label, ribbon ? "Y":"-", line ? "Y":"-", struck ? "Y":"-", save ? "Y":"-",
              stamp.to_s.strip, errs.any? ? "  ERR:#{errs}" : "")
end
File.write("#{__dir__}/cards.html", html_cards.join("\n"))
puts "\n  cards written to cards.html (#{html_cards.join.bytesize} bytes)"

puts
puts "="*78
puts "OFF SWITCH — same products, campaign disabled"
puts "="*78
leak = 0
CARDS.each do |label, p|
  out, _ = render_snippet("lbass-product-card", {"product"=>p}, settings: SETTINGS_OFF)
  bad = out.include?("lb-promo")
  leak += 1 if bad
  puts format("  %-4s %s", bad ? "LEAK" : "OK", label)
end
puts "\n  #{leak.zero? ? 'no promotional markup leaks when campaign is off' : "#{leak} LEAKS"}"

puts
puts "="*78
puts "NON-SALE PRODUCTS UNAFFECTED"
puts "="*78
plain = product(handle:"x", title:"Plain", vendor:"Nike", price:19900, tags:["black"])
on,  _ = render_snippet("lbass-product-card", {"product"=>plain}, settings: SETTINGS_ON)
off, _ = render_snippet("lbass-product-card", {"product"=>plain}, settings: SETTINGS_OFF)
puts "  campaign ON vs OFF output identical for an untagged product: #{on == off ? 'YES' : 'NO — DIFFERS'}"
