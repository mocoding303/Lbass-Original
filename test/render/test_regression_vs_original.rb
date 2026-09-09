# encoding: utf-8
require_relative 'harness'
require 'base64'

def render_src(src, assigns, settings: SETTINGS_ON)
  tpl = Liquid::Template.parse(src, error_mode: :lax)
  globals = { "settings"=>settings, "cart"=>{"currency"=>{"iso_code"=>"MAD"}},
              "shop"=>{"url"=>"https://x"}, "routes"=>{"root_url"=>"/"} }
  ctx = Liquid::Context.build(environments: [assigns], static_environments: [globals],
                              registers: Liquid::Registers.new, rethrow_errors: false)
  [tpl.render(ctx), tpl.errors]
end

orig_src = File.read("#{__dir__}/orig-card.liquid", encoding: "UTF-8")

def norm(html)
  html.gsub(/\s+/, " ")
      .gsub(/>\s+</, "><")
      .strip
end

puts "="*78
puts "REGRESSION — original inline card  vs  snippets/lbass-product-card"
puts "(campaign OFF, so the only difference should be the new price component)"
puts "="*78

samples = [
  ["plain / no markdown", product(handle:"a", title:"Nike Air Max | سبادري", vendor:"Nike",
      price:59900, tags:["black"], cond:"good")],
  ["sold out",           product(handle:"b", title:"On Running | سبادري", vendor:"On Running",
      price:90000, tags:["x"], available:false, cond:"good")],
  ["new with ticket",    product(handle:"c", title:"HOKA Red", vendor:"HOKA", price:99900,
      tags:["y"], cond:"new_with_ticket", ticket:"ticket_attached", has_ticket:true)],
  ["default variant",    product(handle:"d", title:"Jordan Tee", vendor:"Jordan", price:24900,
      tags:["z"], cond:"very_good", default_variant:true)],
]

samples.each do |label, p|
  o, oe = render_src(orig_src, {"product"=>p})
  n, ne = render_snippet("lbass-product-card", {"product"=>p, "placement"=>"collection"},
                          settings: SETTINGS_OFF)
  on, nn = norm(o), norm(n)

  # structural signals that must survive the refactor
  sig = ->(h) { {
    vendor:   h[/class="card-vendor"[^>]*>([^<]*)</,1],
    title:    h[/class="card-title"[^>]*>([^<]*)</,1],
    stamp:    h[/lb-stamp[^>]*>([^<]*)</,1],
    href:     h[/<a class="card" href="([^"]+)"/,1],
    chips:    h.scan(/class="chip[^"]*"[^>]*>(.*?)<\/span>/m).flatten.map{|x| x.gsub(/<[^>]+>/,"").strip},
    price:    h[/(\d[\d.,]*\s*DH)/,1],
    itemprop: h.scan(/itemprop="(\w+)"/).flatten.sort,
    dataAttrs: h.scan(/data-([a-z-]+)="/).flatten.sort.uniq,
    imgAlt:   h[/alt="([^"]*)"/,1],
    quickAdd: h.include?("lbqa") || h.include?("زيدها للسلة") || h.include?("تباعت"),
  } }
  a, b = sig.(on), sig.(nn)
  diffs = a.keys.reject { |k| a[k] == b[k] }
  puts "\n  #{label}"
  if diffs.empty?
    puts "    IDENTICAL on all structural signals"
  else
    diffs.each { |k| puts "    #{k}:\n        was: #{a[k].inspect}\n        now: #{b[k].inspect}" }
  end
  puts "    ERRORS old:#{oe.size} new:#{ne.size}" if oe.any? || ne.any?
end
