/*
  LBASS CUSTOM EVENTS → GA4  ·  Shopify custom pixel (paste into Admin, not the theme)

  WHY
  The theme publishes its own events with Shopify.analytics.publish:
  lbass_whatsapp_click, lbass_product_card_click, lbass_hero_cta_click,
  lbass_home_trust_click, lbass_new_drop_click, lbass_home_collection_click,
  lbass_vault_*, lbass_ai_referral_landing, lbass_add_to_cart and more.
  Those events travel on Shopify's customer-events bus. GA4 only receives what
  a pixel forwards, and the Google & YouTube app forwards only its own standard
  events (page views, product views, cart, checkout, purchase). So until this
  pixel is installed, none of the lbass_* events reach GA4.

  This pixel forwards lbass_* and ai_* events to the same GA4 property. It sends
  NO page_view and NO ecommerce events, so nothing the Google & YouTube app
  already sends is counted twice.

  INSTALL (about 5 minutes)
  1. GA4 → Admin → Data streams → your web stream → copy the Measurement ID
     (it starts with G-).
  2. Shopify Admin → Settings → Customer events → Add custom pixel.
     Name it "Lbass events → GA4" and paste this whole file.
  3. Replace G-XXXXXXXXXX on the first code line with your Measurement ID.
  4. Customer privacy: Permission "Required", purpose "Analytics" (you ship to
     the EU, so consent applies). Save, then Connect.
  5. Check it: open the store in a private window, click a product and a
     WhatsApp button, then GA4 → Reports → Realtime → "Event count by Event
     name". lbass_product_card_click and lbass_whatsapp_click should appear
     within a minute.
  6. Optional: GA4 → Admin → Events → mark lbass_whatsapp_click as a key event
     (WhatsApp is a sales channel for this store).

  LIMITS
  - The pixel runs in Shopify's sandbox. It reuses the visitor's GA client id
    (the _ga cookie), so events land on the same user as the app's page views;
    GA4 may still start a separate session for them. Compare event counts, and
    events per user, rather than per-session funnels mixing the two sources.
  - Parameters are flattened to what GA4 accepts: at most 20, names up to 40
    characters, values up to 100.
*/
const GA4_ID = 'G-XXXXXXXXXX';

const tag = document.createElement('script');
tag.src = 'https://www.googletagmanager.com/gtag/js?id=' + GA4_ID;
tag.async = true;
document.head.appendChild(tag);
window.dataLayer = window.dataLayer || [];
function gtag() { window.dataLayer.push(arguments); }
gtag('js', new Date());

// Configure once, with the visitor's existing GA client id when there is one.
const ready = browser.cookie.get('_ga')
  .then((ga) => {
    const m = /^GA\d\.\d\.(.+)$/.exec(ga || '');
    const config = { send_page_view: false };
    if (m) config.client_id = m[1];
    gtag('config', GA4_ID, config);
  })
  .catch(() => gtag('config', GA4_ID, { send_page_view: false }));

function flat(data) {
  const out = {};
  Object.keys(data || {}).slice(0, 20).forEach((key) => {
    const value = data[key];
    if (value === null || value === undefined || value === '') return;
    const name = String(key).replace(/[^a-zA-Z0-9_]/g, '_').slice(0, 40);
    out[name] = typeof value === 'number'
      ? value
      : String(typeof value === 'object' ? JSON.stringify(value) : value).slice(0, 100);
  });
  return out;
}

analytics.subscribe('all_custom_events', (event) => {
  const name = String(event.name || '');
  if (!/^(lbass_|ai_)/.test(name)) return;
  const doc = (event.context && event.context.document) || {};
  const params = Object.assign(flat(event.customData), {
    page_location: doc.location && doc.location.href,
    page_title: doc.title,
    page_referrer: doc.referrer,
  });
  ready.then(() => gtag('event', name.slice(0, 40), params));
});
