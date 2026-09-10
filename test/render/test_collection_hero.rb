# encoding: utf-8
# Executes the resolution header of sections/lbass-collection-hero.liquid for a
# set of real collection handles and asserts which artwork each one lands on and
# what intrinsic size the resulting <img> will declare.
#
# The point of executing rather than reading: the mapping was previously
# asserted by eye, and that is how `men-tshirts`, `men-shorts` and `men-jeans`
# were missed for months while they silently rendered a product photo.
Encoding.default_external = Encoding::UTF_8
require 'liquid'

# The standalone gem's LocalFileSystem rejects hyphens; Shopify's does not.
class HyphenFS < Liquid::LocalFileSystem
  def full_path(p)
    raise Liquid::FileSystemError, "Illegal template name '#{p}'" unless p =~ %r{\A[^./][a-zA-Z0-9_/\-]+\z}
    File.join(root, "#{p}.liquid")
  end
end

THEME = File.expand_path('../..', __dir__)
Liquid::Template.file_system = HyphenFS.new("#{THEME}/snippets")

SRC = File.read("#{THEME}/sections/lbass-collection-hero.liquid", encoding: 'UTF-8')

# Take the {% liquid %} header up to, but not including, its closing line, then
# re-close it after appending probes. Located by content so edits above it that
# add or remove lines cannot silently shift the slice.
close = SRC.lines.index { |l| l.strip == '%}' } or abort 'could not find the closing %} of the liquid header'
HEADER = SRC.lines[0...close].join

SEP = '~~'
PROBE = <<~LIQ
  #{HEADER}
    echo hero_asset
    echo '#{SEP}'
    echo hero_asset_width
    echo 'x'
    echo hero_asset_height
    echo '#{SEP}'
    if hero_image == blank
      echo 'none'
    else
      echo hero_image.src
    endif
  %}
LIQ

TPL = Liquid::Template.parse(PROBE, error_mode: :strict)

def run(handle, image = nil, products = [])
  drop = {
    'handle' => handle, 'title' => handle, 'image' => image,
    'products' => products, 'all_products_count' => products.size,
    'metafields' => { 'lbass' => {} },
  }
  TPL.render!({ 'collection' => drop }, strict_variables: false).to_s.strip.split(SEP).map(&:strip)
end

fails = 0

# (handle, expected asset, expected intrinsic WxH)
[
  # the three the merchant just asked about
  ['women-sneakers',          'cat-shoes-ed.webp',       '1448x1086'],
  ['slides',                  'cat-shoes-ed.webp',       '1448x1086'],
  ['new-in',                  'hero-lifestyle-1.webp',   '1376x768' ],
  # added last round; these used to fall through to a product photo
  ['men-tshirts',             'cat-tshirts-ed.webp',     '1448x1086'],
  ['men-shorts',              'cat-pants-ed.webp',       '1448x1086'],
  ['men-jeans',               'cat-jeans-ed.webp',       '1448x1086'],
  # untouched handles must not have moved
  ['men-jackets',             'cat-jackets-ed.webp',     '1448x1086'],
  ['sneakers',                'cat-shoes-ed.webp',       '1448x1086'],
  ['accessories',             'cat-acc-ed.webp',         '1448x1086'],
  ['hoodies',                 'cat-hoodies-ed.webp',     '1448x1086'],
  ['صبابط',                   'cat-shoes-ed.webp',       '1448x1086'],
  ['تيشرتات-و-بولو',          'cat-tshirts-ed.webp',     '1448x1086'],
  # the portrait campaign shot must now declare its REAL size, not 1448x1086
  ['men',                     'editorial-campaign.webp', '896x1200' ],
  ['women',                   'editorial-campaign.webp', '896x1200' ],
  ['one-of-one',              'editorial-campaign.webp', '896x1200' ],
  # wide merchandising surface
  ['audited-drop-p001-p012',  'hero-lifestyle-1.webp',   '1376x768' ],
  # unlisted handle with no products: last-resort fallback, still a real size
  ['totally-unknown-handle',  'hero-lifestyle-1.webp',   '1376x768' ],
].each do |handle, want_asset, want_dim|
  asset, dim, img = run(handle)
  ok = asset == want_asset && dim == want_dim
  fails += 1 unless ok
  printf("  %-26s %-24s %-11s img=%-22s %s\n", handle, asset, dim, img, ok ? 'ok' : "FAIL want #{want_asset} #{want_dim}")
end

puts
# A merchant-set collection.image must still outrank the case list everywhere
# except audited-drop, which deliberately overrides it.
img = { 'src' => 'cdn://merchant-set.jpg', 'width' => 2000, 'height' => 1000 }
[['slides', 'cdn://merchant-set.jpg'], ['new-in', 'cdn://merchant-set.jpg'],
 ['women-sneakers', 'cdn://merchant-set.jpg'], ['men-jackets', 'cdn://merchant-set.jpg'],
 ['audited-drop-p001-p012', 'none']].each do |handle, want|
  asset, _dim, got = run(handle, img)
  ok = got == want
  fails += 1 unless ok
  printf("  collection.image on %-24s -> %-24s asset=%-22s %s\n", handle, got, asset, ok ? 'ok' : "FAIL want #{want}")
end

puts
# Whatever path is taken, the hero must never end up with nothing to render.
%w[slides new-in women-sneakers men-shorts audited-drop-p001-p012 unknown-xyz].each do |h|
  [nil, img].each do |i|
    asset, _d, got = run(h, i)
    next unless asset.empty? && got == 'none'
    fails += 1
    puts "  FAIL #{h} (image=#{i ? 'set' : 'nil'}) resolves to NEITHER an asset nor an image"
  end
end
puts '  every handle resolves to an asset or an image, with and without collection.image'

puts
abort("#{fails} FAILURES") if fails > 0
puts 'HERO RESOLUTION OK'
