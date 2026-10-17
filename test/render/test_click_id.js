// Google Ads click ID → order, on every road to checkout (2026-10-16).
//
// Orders #1013 and #1014 reached Shopify with no gclid. lbass-click-id wrote the ID onto the cart on
// page load, often before the cart had an item, and nothing wrote it again before checkout; the express
// COD form's cart permalink starts a NEW cart and drops cart attributes altogether.
//
// This test lifts the REAL code out of the theme (snippets/lbass-click-id.liquid, the PDP one-action and
// express-form handlers in templates/product*.liquid, the drawer's checkout handler in
// snippets/lbass-cart-drawer.liquid), runs it in Chromium against a mocked Shopify cart, and records
// what reaches the server: /cart/update.js bodies, the permalink URL, the /cart form post, and when
// checkout opens. It does not prove what Shopify does with those requests; that needs a real order.
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright-core');

const THEME = path.resolve(__dirname, '../..');
const read = (f) => fs.readFileSync(path.join(THEME, f), 'utf8');
const CLICK = read('snippets/lbass-click-id.liquid');
const DRAWER = read('snippets/lbass-cart-drawer.liquid');
const PDP = {
  product: read('templates/product.liquid'),
  fragrance: read('templates/product.fragrance.liquid'),
  beauty: read('templates/product.beauty.liquid'),
};

let failed = 0;
const check = (label, ok, extra = '') => { console.log(`  ${ok ? 'ok  ' : 'FAIL'}  ${label}${ok ? '' : '  ' + extra}`); if (!ok) failed++; };

// Liquid output tags inside these scripts are all `| json` values; any JSON literal keeps the JS valid.
const unliquid = (s, cartAttrs) => s
  .replace(/\{\{\s*cart\.attributes\s*\|\s*json\s*\}\}/g, JSON.stringify(cartAttrs))
  .replace(/\{\{\s*display_title\s*\|\s*json\s*\}\}/g, '"Test parka"')
  .replace(/\{\{[^}]*\}\}/g, '1');
const between = (src, start, end, label) => {
  const i = src.indexOf(start); if (i < 0) throw new Error(`${label}: start not found: ${start}`);
  const j = src.indexOf(end, i + start.length); if (j < 0) throw new Error(`${label}: end not found: ${end}`);
  return src.slice(i, j);
};

const clickScripts = (attrs) => unliquid(CLICK.match(/<script>[\s\S]*?<\/script>/g).join('\n'), attrs);
const ONE_ACTION = between(PDP.product, '  var lbPhoneMQ = window.matchMedia', '  // hide sticky bar while main CTA is in viewport', 'one action');
const expressBlock = (src, label) => between(src, "  var xForm = document.getElementById('pdpExpressForm');", '\n  // size guide button', label);
const DRAWER_CHECKOUT = between(DRAWER, "    var checkout = e.target.closest('#lbdrCheckout');", "    var upBtn = e.target.closest('[data-lbdr-up]');", 'drawer');

const STUBS = `<script>
  function currentVaultAttribution(){ return null; }
  function persistVaultCart(){}
  function publishVault(){}
</script>`;

function page({ kind, src = 'product', cartAttrs = {} }) {
  let body = '';
  if (kind === 'oneaction') {
    body = `<div class="pdp-direct"></div>
      <form id="pdpForm" action="/cart/add" method="post"><input name="id" value="111">
        <button id="pdpAdd" type="submit">x</button></form>
      <button id="pdpStickyAdd">y</button><p id="pdpDirectErr" hidden></p>
      ${STUBS}<script>var addBtn = document.getElementById('pdpAdd'), stickyAdd = document.getElementById('pdpStickyAdd');
      ${unliquid(ONE_ACTION, cartAttrs)}</script>`;
  } else if (kind === 'express') {
    body = `<input id="pdpVariantId" value="111"><p id="pdpxErr" hidden></p>
      <form id="pdpExpressForm" novalidate>
        <input class="pdpx-in" name="xname" value="Mouhssine Benaali">
        <input class="pdpx-in" name="xphone" value="0631731274">
        <input class="pdpx-in" name="xcity" value="Marrakech">
        <button id="xgo" type="submit">go</button></form>
      ${STUBS}<script>${unliquid(expressBlock(PDP[src], src), cartAttrs)}</script>`;
  } else if (kind === 'drawer') {
    body = `<a id="lbdrCheckout" href="/checkout">checkout</a><select id="lbdrDiscoverySource"><option value=""></option></select>
      <script>
        var D = document, state = { cart: { items: [{ product_id: 1 }], item_count: 1, total_price: 31900, attributes: ${JSON.stringify(cartAttrs)} } };
        function q(id){ return document.getElementById(id); } function vaultAttribution(){ return null; } function track(){}
        D.addEventListener('click', function(e){ ${DRAWER_CHECKOUT} });
      </script>`;
  } else if (kind === 'cartpage') {
    body = `<form action="/cart" method="post" class="cart-form"><input name="updates[]" value="1">
      <button id="cgo" type="submit" name="checkout">checkout</button></form>`;
  }
  return `<!doctype html><html><head><meta charset="utf-8"></head><body>${body}
    ${'<script>' + clickScripts(cartAttrs).replace(/<\/?script>/g, '') + '</script>'}</body></html>`;
}

async function run(browser, { kind, src, url, storage, cartAttrs, updateDelay = 150, updateHang = false, cartItems = [] }) {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 800 } });
  const log = [];
  let updates = 0;
  const t0 = Date.now();
  const stamp = (e) => log.push(Object.assign({ t: Date.now() - t0 }, e));
  await ctx.route('https://shop.test/**', async (route) => {
    const r = route.request(); const u = new URL(r.url());
    if (u.pathname === '/__page') return route.fulfill({ contentType: 'text/html', body: page({ kind, src, cartAttrs }) });
    if (u.pathname === '/cart.js') return route.fulfill({ contentType: 'application/json', body: JSON.stringify({ items: cartItems, attributes: cartAttrs || {} }) });
    if (u.pathname === '/cart/add.js') { stamp({ ev: 'add' }); return route.fulfill({ contentType: 'application/json', body: '{"items":[]}' }); }
    if (u.pathname === '/cart/update.js') {
      const id = ++updates;
      stamp({ ev: 'update', id, body: JSON.parse(r.postData() || '{}') });
      if (updateHang) return; // never answers
      await new Promise((res) => setTimeout(res, updateDelay));
      stamp({ ev: 'update-done', id });
      return route.fulfill({ contentType: 'application/json', body: '{}' });
    }
    if (u.pathname === '/checkout') { stamp({ ev: 'checkout' }); return route.fulfill({ contentType: 'text/html', body: 'checkout' }); }
    if (u.pathname.startsWith('/cart/111:')) { stamp({ ev: 'permalink', url: decodeURIComponent(r.url()) }); return route.fulfill({ contentType: 'text/html', body: 'permalink' }); }
    if (u.pathname === '/cart' && r.method() === 'POST') { stamp({ ev: 'cartpost', body: decodeURIComponent(r.postData() || '') }); return route.fulfill({ contentType: 'text/html', body: 'posted' }); }
    return route.fulfill({ status: 204, body: '' });
  });
  const p = await ctx.newPage();
  if (storage) {
    await p.goto('https://shop.test/__page?seed=1');
    await p.evaluate((s) => { for (const k in s) localStorage.setItem(k, s[k]); }, storage);
  }
  await p.goto('https://shop.test/__page' + (url || ''));
  const t1 = Date.now();
  if (kind === 'oneaction') await p.click('#pdpAdd');
  if (kind === 'express') await p.click('#xgo');
  if (kind === 'drawer') await p.click('#lbdrCheckout');
  if (kind === 'cartpage') await p.click('#cgo');
  await p.waitForTimeout(updateHang ? 3200 : 1400);
  await ctx.close();
  const after = log.filter((e) => e.t >= t1 - t0 - 5);
  const doneOf = (u) => u && log.find((e) => e.ev === 'update-done' && e.id === u.id);
  return { all: log, after, has: (ev) => after.find((e) => e.ev === ev), doneOf };
}

(async () => {
  const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args: ['--no-sandbox'] });
  const AD = '?gclid=TEST123';
  const gclidIn = (e) => e && e.body && e.body.attributes && e.body.attributes.gclid === 'TEST123';

  console.log('PDP ONE ACTION (phones): add → click ID onto the cart → /checkout');
  let r = await run(browser, { kind: 'oneaction', url: AD });
  const add = r.has('add'), upd = r.after.find((e) => e.ev === 'update' && e.t >= (add ? add.t : 0)), co = r.has('checkout');
  check('adds the piece', !!add);
  check('writes gclid=TEST123 onto the cart AFTER the add', gclidIn(upd), JSON.stringify(r.after));
  check('opens checkout only after that write has landed', co && upd && r.doneOf(upd) && co.t >= r.doneOf(upd).t, JSON.stringify(r.after));
  check('keeps the 700 ms analytics pause after the add', co && add && co.t - add.t >= 690, JSON.stringify(r.after));

  r = await run(browser, { kind: 'oneaction', url: AD, cartItems: [{ variant_id: 111 }] });
  check('piece already in the cart: writes gclid, then checkout', gclidIn(r.has('update')) && !!r.has('checkout') && !r.has('add'), JSON.stringify(r.after));

  r = await run(browser, { kind: 'oneaction', url: '', storage: { lb_gclid: JSON.stringify({ v: 'OLDCLICK', t: Date.now() - 3 * 864e5 }) } });
  check('ID stored from an earlier visit (no gclid in this URL) is written after the add', !!r.has('add') && r.after.some((e) => e.ev === 'update' && e.t >= r.has('add').t && e.body.attributes.gclid === 'OLDCLICK'), JSON.stringify(r.after));

  r = await run(browser, { kind: 'oneaction', url: '' });
  check('no ad click: no extra request, checkout still opens', !r.after.some((e) => e.ev === 'update') && !!r.has('checkout'), JSON.stringify(r.after));

  r = await run(browser, { kind: 'oneaction', url: AD, updateHang: true });
  check('cart write never answers: checkout still opens within ~2 s', !!r.has('checkout') && r.has('checkout').t - r.has('add').t < 2400, JSON.stringify(r.after));

  r = await run(browser, { kind: 'oneaction', url: '', storage: { lb_gclid: JSON.stringify({ v: 'EXPIRED', t: Date.now() - 91 * 864e5 }) } });
  check('an ID older than 90 days is not sent', !r.after.some((e) => e.ev === 'update' && JSON.stringify(e.body).includes('EXPIRED')), JSON.stringify(r.after));

  console.log('\nEXPRESS COD FORM: the cart permalink carries attributes[gclid]');
  for (const src of ['product', 'fragrance', 'beauty']) {
    r = await run(browser, { kind: 'express', src, url: AD + '&gbraid=GB1' });
    const pl = r.has('permalink');
    check(`${src}: permalink has attributes[gclid]=TEST123 and attributes[gbraid]=GB1`, !!pl && pl.url.includes('attributes[gclid]=TEST123') && pl.url.includes('attributes[gbraid]=GB1'), pl ? pl.url : JSON.stringify(r.after));
    check(`${src}: address prefill is still on the link`, !!pl && pl.url.includes('checkout[shipping_address][city]=Marrakech'), pl ? pl.url : '');
  }
  r = await run(browser, { kind: 'express', src: 'product', url: '' });
  check('no ad click: permalink unchanged (no attributes)', !!r.has('permalink') && !r.has('permalink').url.includes('attributes['), r.has('permalink') ? r.has('permalink').url : '');

  console.log('\nCART DRAWER: «checkout» makes sure the cart carries the ID first');
  r = await run(browser, { kind: 'drawer', url: AD, cartAttrs: {} });
  check('cart lacks the ID: writes it, then checkout', gclidIn(r.has('update')) && !!r.has('checkout') && !!r.doneOf(r.has('update')) && r.has('checkout').t >= r.doneOf(r.has('update')).t, JSON.stringify(r.after));
  r = await run(browser, { kind: 'drawer', url: AD, cartAttrs: { gclid: 'TEST123' } });
  check('cart already carries it: straight to checkout, no extra request', !r.after.some((e) => e.ev === 'update') && !!r.has('checkout'), JSON.stringify(r.after));

  console.log('\n/CART PAGE: the form posts attributes[gclid] with checkout');
  r = await run(browser, { kind: 'cartpage', url: AD });
  check('POST /cart includes attributes[gclid]=TEST123 and checkout', !!r.has('cartpost') && r.has('cartpost').body.includes('attributes[gclid]=TEST123') && r.has('cartpost').body.includes('checkout'), JSON.stringify(r.after));

  await browser.close();
  console.log(failed ? `\n${failed} FAILED` : '\nCLICK ID OK');
  process.exit(failed ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
