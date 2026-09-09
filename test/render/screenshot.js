const { chromium } = require('playwright-core');
(async () => {
  const browser = await chromium.launch({
    executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome',
    args: ['--no-sandbox','--disable-dev-shm-usage']
  });
  const url = 'file://' + __dirname + '/preview.html';
  for (const [name, width] of [['mobile', 390], ['desktop', 1280]]) {
    const page = await browser.newPage({ viewport: { width, height: 900 }, deviceScaleFactor: 2 });
    await page.goto(url, { waitUntil: 'networkidle' });
    await page.waitForTimeout(300);
    await page.screenshot({ path: `${__dirname}/promo-${name}.png`, fullPage: true });

    const m = await page.evaluate(() => {
      const out = { overflowX: document.documentElement.scrollWidth > document.documentElement.clientWidth, cards: [] };
      document.querySelectorAll('.lbqa-wrap').forEach((wrap, i) => {
        const img = wrap.querySelector('.card-img');
        const rib = wrap.querySelector('.lb-promo-ribbon');
        const ir = img && img.getBoundingClientRect();
        const rr = rib && rib.getBoundingClientRect();
        out.cards.push({
          i,
          ribbon: !!rib,
          // RTL: ribbon should hug the RIGHT edge of its own image
          insideOwnImage: rr && ir ? (rr.left >= ir.left - 1 && rr.right <= ir.right + 1 &&
                                      rr.top >= ir.top - 1 && rr.bottom <= ir.bottom + 1) : null,
          gapFromRightEdge: rr && ir ? Math.round(ir.right - rr.right) : null,
          gapFromTop: rr && ir ? Math.round(rr.top - ir.top) : null,
          ribbonWiderThanImage: rr && ir ? rr.width > ir.width : null,
          struck: !!wrap.querySelector('.lb-price__was'),
          save: (wrap.querySelector('.lb-price__save')||{}).textContent?.trim().replace(/\s+/g,' ') || null,
          off: (wrap.querySelector('.lb-price__off')||{}).textContent?.trim() || null,
        });
      });
      // does any element overflow its card?
      out.overflowingCards = [...document.querySelectorAll('.lbqa-wrap')].filter(w => {
        const wr = w.getBoundingClientRect();
        return [...w.querySelectorAll('*')].some(el => {
          const r = el.getBoundingClientRect();
          return r.width > 0 && (r.right > wr.right + 1 || r.left < wr.left - 1);
        });
      }).length;
      return out;
    });
    console.log('\n' + '='.repeat(60));
    console.log(`${name.toUpperCase()} @${width}px   page overflow-x: ${m.overflowX ? 'YES (BAD)' : 'none'}   cards with overflowing children: ${m.overflowingCards}`);
    console.log('='.repeat(60));
    m.cards.forEach(c => console.log(
      ` card ${c.i}  ribbon:${c.ribbon?'Y':'-'}  contained:${c.insideOwnImage===null?'n/a':(c.insideOwnImage?'YES':'NO !!')}` +
      `  rightGap:${c.gapFromRightEdge ?? '-'}  topGap:${c.gapFromTop ?? '-'}  struck:${c.struck?'Y':'-'}  off:${c.off??'-'}  save:${c.save??'-'}`));
  }
  await browser.close();
})().catch(e => { console.error('FAIL', e.message); process.exit(1); });
