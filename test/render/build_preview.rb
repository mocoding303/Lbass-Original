# encoding: utf-8
require_relative 'harness'
require 'base64'

# Real theme CSS: theme.liquid's <style> blocks + lbass-stamp + lbass-promo-css
theme_css = File.read("#{THEME}/layout/theme.liquid", encoding: "UTF-8")
                .scan(/<style>(.*?)<\/style>/m).flatten.join("\n")
stamp_css, = render_snippet("lbass-stamp", {})
promo_css, = render_snippet("lbass-promo-css", {})
css = theme_css + "\n" + stamp_css.scan(/<style>(.*?)<\/style>/m).flatten.join("\n") +
      "\n" + promo_css.scan(/<style>(.*?)<\/style>/m).flatten.join("\n")

# The QA matrix: no discount, the live -10%, a deep discount, a long price, a
# sold piece that is also marked down, and a card carrying BOTH the markdown
# badge and the campaign ribbon (the pair that must not read as one claim).
CARDS = [
  product(handle:"a", title:"Nike Air Max Black/Green Sneakers | سبادري Nike", vendor:"Nike",
          price:59900, tags:["black"], cond:"good"),
  product(handle:"b", title:"Vans Old Skool Black — فانز أولد سكول أصلي", vendor:"Vans",
          price:31400, cap:34900, tags:["summer-sale"], cond:"excellent_almost_new"),
  product(handle:"c", title:"Zara Khaki Jacket", vendor:"Zara",
          price:29900, cap:44900, tags:["khaki"], cond:"very_good", type:"Jackets"),
  product(handle:"d", title:"The North Face Black Puffer Jacket - Size M | جاكيطة TNF",
          vendor:"The North Face", price:67400, cap:74900, tags:["summer-sale"], cond:"good", type:"Jackets"),
  product(handle:"e", title:"On Running Pink & Black Shoes - Size 43 | سبادري On", vendor:"On Running",
          price:90000, cap:120000, tags:["summer-sale"], available:false, cond:"good"),
  product(handle:"f", title:"HOKA Red Running Shoes | سبادري HOKA", vendor:"HOKA",
          price:89900, cap:99900, tags:["summer-sale"], cond:"new_without_ticket"),
  # Longest realistic price pair, to prove the row does not overflow a 2-col card.
  product(handle:"g", title:"On Running Cloudmonster White & Gold - Size 43 | سبادري On",
          vendor:"On Running", price:107900, cap:119900, tags:["black"], cond:"good"),
  # A markdown too small to round to 1%: struck price and saving, but NO -0%.
  product(handle:"h", title:"Carhartt Grey Crossbody Shoulder Bag", vendor:"Carhartt",
          price:99900, cap:100000, tags:["black"], cond:"good", type:"Accessories"),
]
SWATCH = %w[8a8f7a 2f3540 6d6250 3a3f36 7a5f5f 8f3f30 4a5157 5c5348]

cards = CARDS.each_with_index.map do |p, i|
  svg = "<svg xmlns='http://www.w3.org/2000/svg' width='500' height='625'>" \
        "<rect width='500' height='625' fill='##{SWATCH[i]}'/></svg>"
  p["featured_image"]["src"] = "data:image/svg+xml;base64," + Base64.strict_encode64(svg)
  out, errs = render_snippet("lbass-product-card", {"product"=>p, "placement"=>"collection"})
  warn "ERRORS on card #{i}: #{errs}" if errs.any?
  out
end.join("\n")

pdp, = render_snippet("lbass-promo-badge",
  {"product"=>CARDS[1], "format"=>"pdp", "active"=>"yes"})

html = <<~HTML
<!doctype html><html lang="ar-MA" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>#{css}
  body{margin:0;padding:16px;background:var(--ink,#0A0A0B)}
  .grid{display:grid;grid-template-columns:1fr 1fr;gap:12px}
  @media(min-width:750px){.grid{grid-template-columns:repeat(4,1fr);gap:18px}}
  .lbl{color:#8a8f7a;font:700 12px system-ui;margin:22px 0 8px;letter-spacing:.08em;text-transform:uppercase}
  .pdpbox{max-width:520px;background:var(--ink2,#121214);border:1px solid var(--line,#26262B);
          border-radius:14px;padding:16px;margin-top:8px}
</style></head><body>
<p class="lbl">Collection grid — RTL (the live storefront)</p>
<div class="grid" id="rtl">#{cards}</div>
<p class="lbl">Collection grid — LTR (same markup, mirrored)</p>
<div class="grid" id="ltr" dir="ltr">#{cards}</div>
<p class="lbl">Product page — campaign block</p>
<div class="pdpbox">#{pdp}</div>
</body></html>
HTML
require 'base64'
File.write("#{__dir__}/preview.html", html)
puts "preview.html written (#{html.bytesize} bytes, css #{css.bytesize} bytes)"
