// Extracts the REAL applySale() from templates/product.liquid, drives it
// against the REAL markup the template emits, and asserts that switching size
// never leaves a stale discount on the page.
//
// The bug this pins: before 2026-09-10 the size handler repriced the headline
// and nothing else, so choosing a different size showed the new price beside
// the PREVIOUS variant's strikethrough, percentage and saving.
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright-core');

const THEME = path.resolve(__dirname, '../..');
const SRC = fs.readFileSync(path.join(THEME, 'templates/product.liquid'), 'utf8');

const fn = SRC.match(/function applySale\(d\)\{[\s\S]*?\n  \}/);
if (!fn) { console.error('FAIL: applySale() not found in templates/product.liquid'); process.exit(1); }

// Markup mirrors what the template renders: three sizes, only two marked down,
// with the middle one at a different depth from the first.
const html = `
<span class="pdp-price" data-price>494 DH</span>
<span class="pdp-old" data-old>549 DH</span>
<span class="pdp-save" data-savepct>−10%</span>
<p class="pdp-saved" data-saved>وفّر <span dir="ltr" data-savesum>55 DH</span></p>
<div id="pdpSizes">
  <button class="sz" data-vid="1" data-price="494 DH" data-cap="549 DH" data-pct="−10%" data-save="55 DH">M</button>
  <button class="sz" data-vid="2" data-price="193 DH" data-cap="300 DH" data-pct="−36%" data-save="107 DH">L</button>
  <button class="sz" data-vid="3" data-price="349 DH" data-cap=""       data-pct=""     data-save="">XL</button>
</div>
<script>
  var priceEl = document.querySelector('[data-price]');
  var oldEl   = document.querySelector('[data-old]');
  var pctEl   = document.querySelector('[data-savepct]');
  var savedEl = document.querySelector('[data-saved]');
  var saveSum = document.querySelector('[data-savesum]');
  ${fn[0]}
  document.querySelectorAll('#pdpSizes .sz').forEach(function(btn){
    btn.addEventListener('click', function(){
      if (priceEl && btn.dataset.price) priceEl.textContent = btn.dataset.price;
      applySale(btn.dataset);
    });
  });
</script>`;

const OUT = path.join(__dirname, 'variant-switch.html');
fs.writeFileSync(OUT, html);

(async () => {
  const b = await chromium.launch({ executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args:['--no-sandbox'] });
  const p = await b.newPage();
  await p.goto('file://' + OUT);

  const read = () => p.evaluate(() => {
    const t = s => { const e = document.querySelector(s); return e ? e.textContent.trim() : null; };
    const h = s => { const e = document.querySelector(s); return e ? e.hidden : null; };
    return {
      price: t('[data-price]'),
      old:   h('[data-old]')   ? null : t('[data-old]'),
      pct:   h('[data-savepct]') ? null : t('[data-savepct]'),
      saved: h('[data-saved]') ? null : t('[data-savesum]'),
    };
  });

  const CASES = [
    ['M  (494 / 549, -10%)', 0, { price:'494 DH', old:'549 DH', pct:'−10%', saved:'55 DH' }],
    ['L  (193 / 300, -36%)', 1, { price:'193 DH', old:'300 DH', pct:'−36%', saved:'107 DH' }],
    ['XL (349, NOT on sale)',2, { price:'349 DH', old:null,     pct:null,   saved:null }],
    ['back to M',            0, { price:'494 DH', old:'549 DH', pct:'−10%', saved:'55 DH' }],
  ];

  let fails = 0;
  console.log('='.repeat(78));
  console.log('VARIANT SWITCH — price, strikethrough, percentage and saving move together');
  console.log('='.repeat(78));
  for (const [label, idx, want] of CASES) {
    await p.evaluate(i => document.querySelectorAll('#pdpSizes .sz')[i].click(), idx);
    const got = await read();
    const ok = JSON.stringify(got) === JSON.stringify(want);
    if (!ok) fails++;
    console.log(`  ${label.padEnd(24)} price:${String(got.price).padEnd(8)} was:${String(got.old).padEnd(8)} pct:${String(got.pct).padEnd(7)} save:${String(got.saved).padEnd(8)} ${ok ? 'ok' : 'FAIL want ' + JSON.stringify(want)}`);
  }

  await b.close();
  console.log('\n' + (fails ? `${fails} FAILURES` : 'VARIANT SWITCH OK'));
  process.exit(fails ? 1 : 0);
})().catch(e => { console.error('FAIL', e.message); process.exit(1); });
