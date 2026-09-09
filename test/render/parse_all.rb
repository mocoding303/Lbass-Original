# encoding: utf-8
# Parses every Liquid file in the theme under STRICT mode using Shopify's own
# engine, with stubs for the Shopify-only tags the standalone gem lacks.
# Catches the class of error that gets a theme upload rejected.
Encoding.default_external = Encoding::UTF_8
require 'liquid'
THEME = File.expand_path('../..', __dir__)

# Shopify-only tags. Block tags need a matching end tag; the rest are self-closing.
BLOCK  = %w[paginate form style javascript stylesheet schema capture_global]
SINGLE = %w[section sections layout include_relative content_for echo_shopify]

BLOCK.each do |t|
  Liquid::Template.register_tag(t, Class.new(Liquid::Block) { def render_to_output_buffer(_c, o) = o })
end
SINGLE.each do |t|
  Liquid::Template.register_tag(t, Class.new(Liquid::Tag) { def render_to_output_buffer(_c, o) = o })
end

files = Dir.glob("#{THEME}/{layout,templates,snippets,sections}/**/*.liquid").sort
bad = []
files.each do |f|
  rel = f.sub("#{THEME}/", '')
  begin
    Liquid::Template.parse(File.read(f, encoding: 'UTF-8'), error_mode: :strict)
  rescue => e
    bad << [rel, e.message]
  end
end

puts "parsed #{files.size} Liquid files under strict mode"
if bad.empty?
  puts "ALL PARSE CLEAN"
else
  puts "#{bad.size} FAILED:"
  bad.each { |r, m| puts "  #{r}\n      #{m}" }
end
exit(bad.empty? ? 0 : 1)
