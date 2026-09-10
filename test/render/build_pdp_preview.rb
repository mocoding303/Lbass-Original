# encoding: utf-8
# Renders the product page's price block with the product page's own CSS, so the
# discount hierarchy can be judged by eye rather than by reading declarations.
require_relative 'harness'

SRC = File.read("#{THEME}/templates/product.liquid", encoding: 'UTF-8')
CSS = SRC.scan(/<style>(.*?)<\/style>/m).flatten.join("\n")

lines = SRC.lines
first = lines.index { |l| l.include?('<div class="pdp-price-wrap">') } or abort 'price block not found'
close = (first...lines.size).find { |i| lines[i] == "    </div>\n" } or abort 'end not found'
BLOCK = lines[first..close].join

CASES = [
  ['on sale — the live -10%',      67400,  74900],
  ['on sale — deep discount',      19300,  30000],
  ['on sale — long price pair',   107900, 119900],
  ['NOT on sale',                  59900,  nil   ],
]

blocks = CASES.map do |label, price, cap|
  p = product(handle: 'x', title: 'X', vendor: 'N', price: price, cap: cap)
  out, errs = render_source(BLOCK, { 'product' => p })
  warn "ERRORS #{label}: #{errs}" if errs.any?
  %(<p class="lbl">#{label}</p>\n<div class="pdp-col">#{out}</div>)
end.join("\n")

html = <<~HTML
  <!doctype html><html lang="ar-MA" dir="rtl"><head><meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <style>#{CSS}
  body{margin:0;padding:16px;background:var(--ink,#0A0A0B);font-family:var(--ar,sans-serif)}
  .lbl{color:#6f6a63;font:700 11px system-ui;letter-spacing:.08em;text-transform:uppercase;margin:26px 0 8px}
  .pdp-col{max-width:420px}
  </style></head><body>#{blocks}</body></html>
HTML
File.write("#{__dir__}/pdp-preview.html", html)
puts "pdp-preview.html written (#{html.bytesize} bytes)"
