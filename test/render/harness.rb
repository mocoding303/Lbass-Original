# encoding: utf-8
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
require 'liquid'
require 'json'
require 'zlib'

THEME = File.expand_path('../..', __dir__)  # repo root
# The standalone gem's LocalFileSystem rejects hyphens in template names.
# Shopify's Liquid allows them and every snippet here uses them, so widen it.
class HyphenFS < Liquid::LocalFileSystem
  def full_path(template_path)
    raise Liquid::FileSystemError, "Illegal template name '#{template_path}'" unless template_path =~ /\A[^.\/][a-zA-Z0-9_\/\-]+\z/
    File.join(root, "#{template_path}.liquid")
  end
end
Liquid::Template.file_system = HyphenFS.new("#{THEME}/snippets")

module ShopFilters
  def money(cents)
    return '' if cents.nil?
    v = cents.to_i / 100.0
    s = format('%.2f', v)
    s = s.sub(/\.00$/, '')          # MAD storefront shows 199 DH, not 199.00 DH
    "#{s} DH"
  end
  def money_without_trailing_zeros(c) = money(c)
  def money_without_currency(cents) = format('%.2f', cents.to_i / 100.0)
  def image_url(img, opts = {}) = (img.is_a?(Hash) ? img['src'] : img).to_s
  def asset_url(f) = "//cdn.shopify.test/#{f}"
end
Liquid::Template.register_filter(ShopFilters)

def variant(price:, cap: nil, title: 'M', qty: 1, mgmt: 'shopify')
  { 'price' => price, 'compare_at_price' => cap, 'title' => title,
    'inventory_quantity' => qty, 'inventory_management' => mgmt,
    'available' => qty > 0 }
end

def mf(h) = h.transform_values { |v| { 'value' => v } }

def product(handle:, title:, vendor:, price:, cap: nil, tags: [], available: true,
            qty: 1, cond: 'excellent_almost_new', inspected: true, ticket: 'no_ticket',
            has_ticket: false, promo_eligible: nil, type: 'Shoes', default_variant: false)
  v = variant(price: price, cap: cap, qty: available ? qty : 0)
  lb = { 'condition_status' => cond,
         'inspection_status' => (inspected ? 'inspected_confirmed' : nil),
         'ticket_status' => ticket,
         'has_original_ticket' => has_ticket,
         'condition_notes' => nil, 'visible_defects' => nil }
  lb['promo_eligible'] = promo_eligible unless promo_eligible.nil?
  # crc32, not String#hash: Ruby seeds String#hash per process, so the stub id
  # changed on every run and dirtied the generated cards.html each time.
  { 'id' => Zlib.crc32(handle), 'handle' => handle, 'title' => title, 'vendor' => vendor,
    'url' => "/products/#{handle}", 'price' => price, 'available' => available,
    'tags' => tags, 'variants' => [v], 'selected_or_first_available_variant' => v,
    'featured_image' => { 'src' => "https://img.test/#{handle}.jpg", 'alt' => nil },
    'has_only_default_variant' => default_variant, 'product_type' => type,
    'metafields' => { 'lbass' => mf(lb) } }
end

SETTINGS_ON = {
  'promo_enabled' => true, 'promo_tag' => 'summer-sale', 'promo_second_pct' => 30,
  'promo_label' => 'تخفيضات الصيف', 'promo_badge_short' => 'على الثانية',
  'promo_badge_long' => 'زيد قطعة ثانية وخد التخفيض',
  'promo_note' => 'كيبان أوتوماتيكيا فالسلة بلا كود · كيتطبق على قطعة وحدة فكل طلب.',
  'promo_save_label' => 'وفّر'
}
SETTINGS_OFF = SETTINGS_ON.merge('promo_enabled' => false)

def render_snippet(name, assigns, settings: SETTINGS_ON)
  src = File.read("#{THEME}/snippets/#{name}.liquid", encoding: "UTF-8")
  tpl = Liquid::Template.parse(src, error_mode: :strict)
  # Shopify exposes settings/shop/cart/routes as GLOBALS, which survive the
  # isolated scope of {% render %}. In the gem that is static_environments —
  # Context#new_isolated_subcontext copies them, assigns it does not. Dawn
  # depends on this (snippets/card-product.liquid reads settings.card_style).
  globals = {
    "settings" => settings,
    "cart"     => { "currency" => { "iso_code" => "MAD" } },
    "shop"     => { "url" => "https://www.lbassoriginal.com", "currency" => "MAD" },
    "routes"   => { "root_url" => "/", "all_products_collection_url" => "/collections/all" }
  }
  ctx = Liquid::Context.build(
    environments: [assigns],
    static_environments: [globals],
    registers: Liquid::Registers.new,
    rethrow_errors: false
  )
  out = tpl.render(ctx)
  [out, tpl.errors]
end
