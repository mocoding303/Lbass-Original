const { chromium } = require('playwright-core');
(async () => {
  const b = await chromium.launch({ executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args:['--no-sandbox','--disable-dev-shm-usage'] });
  const url = 'file://' + __dirname + '/preview.html';
  let fails = 0;
  for (const [name, width] of [['mobile',390],['desktop',1280],['narrow',360]]) {
    const page = await b.newPage({ viewport:{width,height:900}, deviceScaleFactor:2 });
    await page.goto(url,{waitUntil:'networkidle'});
    await page.waitForTimeout(250);
    if (name !== 'narrow') await page.screenshot({path:`${__dirname}/sale-${name}.png`, fullPage:true});

    const m = await page.evaluate(() => {
      const px = s => parseFloat(s);
      const rd = (root) => [...root.querySelectorAll('.lbqa-wrap')].map((w,i) => {
        const img  = w.querySelector('.card-img');
        const bdg  = w.querySelector('.lb-md-badge');
        const rib  = w.querySelector('.lb-promo-ribbon');
        const stmp = w.querySelector('.lb-stamp');
        const now  = w.querySelector('.lb-price__now');
        const was  = w.querySelector('.lb-price__was');
        const off  = w.querySelector('.lb-price__off');
        const sav  = w.querySelector('.lb-price__save');
        const r = e => e ? e.getBoundingClientRect() : null;
        const ir = r(img), br = r(bdg), rr = r(rib), sr = r(stmp);
        const overlaps = (a,z) => !!(a&&z) && !(a.right<=z.left||z.right<=a.left||a.bottom<=z.top||z.bottom<=a.top);
        const wr = w.getBoundingClientRect();
        return {
          i,
          badge: !!bdg,
          badgeText: bdg ? bdg.textContent.trim() : null,
          badgeInImage: br&&ir ? (br.left>=ir.left-1&&br.right<=ir.right+1&&br.top>=ir.top-1&&br.bottom<=ir.bottom+1) : null,
          // RTL puts inset-inline-end on the LEFT; LTR on the right. Just report the gap to each edge.
          gapL: br&&ir ? Math.round(br.left-ir.left) : null,
          gapR: br&&ir ? Math.round(ir.right-br.right) : null,
          badgeHitsRibbon: overlaps(br,rr),
          badgeHitsStamp:  overlaps(br,sr),
          nowPx: now ? px(getComputedStyle(now).fontSize) : null,
          wasPx: was ? px(getComputedStyle(was).fontSize) : null,
          offPx: off ? px(getComputedStyle(off).fontSize) : null,
          savText: sav ? sav.textContent.trim().replace(/\s+/g,' ') : null,
          offText: off ? off.textContent.trim().replace(/\s+/g,' ') : null,
          wasText: was ? was.textContent.trim().replace(/\s+/g,' ') : null,
          overflowsCard: [...w.querySelectorAll('*')].some(el=>{const q=el.getBoundingClientRect();return q.width>0&&(q.right>wr.right+1||q.left<wr.left-1);}),
        };
      });
      return {
        overflowX: document.documentElement.scrollWidth > document.documentElement.clientWidth,
        rtl: rd(document.getElementById('rtl')),
        ltr: rd(document.getElementById('ltr')),
      };
    });

    console.log('\n' + '='.repeat(96));
    console.log(`${name.toUpperCase()} @${width}px   page overflow-x: ${m.overflowX ? 'YES (BAD)' : 'none'}`);
    console.log('='.repeat(96));
    if (m.overflowX) fails++;

    for (const dir of ['rtl','ltr']) {
      console.log(` --- ${dir.toUpperCase()} ---`);
      m[dir].forEach(c => {
        const ratio = (c.nowPx && c.wasPx) ? (c.nowPx/c.wasPx).toFixed(2) : '-';
        const problems = [];
        if (c.badge && c.badgeInImage === false) problems.push('BADGE OUTSIDE IMAGE');
        if (c.badgeHitsRibbon) problems.push('BADGE OVERLAPS RIBBON');
        if (c.badgeHitsStamp)  problems.push('BADGE OVERLAPS STAMP');
        if (c.overflowsCard)   problems.push('CHILD OVERFLOWS CARD');
        if (c.nowPx && c.wasPx && c.nowPx <= c.wasPx) problems.push('SALE PRICE NOT LARGER');
        // Requested hierarchy: price strongest, discount second, struck price
        // third. The discount used to be 11px against a 13-14px strikethrough,
        // i.e. ranked BELOW the thing it is supposed to outrank.
        if (c.offPx && c.wasPx && c.offPx <= c.wasPx) problems.push(`DISCOUNT NOT LARGER THAN STRUCK (${c.offPx} <= ${c.wasPx})`);
        if (c.offPx && c.nowPx && c.offPx >= c.nowPx) problems.push(`DISCOUNT OUTRANKS PRICE (${c.offPx} >= ${c.nowPx})`);
        if (c.offText && /−\s*0%|-\s*0%/.test(c.offText)) problems.push('-0% PRINTED');
        if (c.badge && !c.wasText) problems.push('BADGE WITHOUT STRIKETHROUGH');
        // The badge is pinned bottom-RIGHT in both directions on purpose: it is
        // the only corner the stamp (always bottom-left) and the ribbon
        // (top, mirroring) both leave free. Assert it stays there.
        if (c.badge && !(c.gapR <= 12 && c.gapL > c.gapR)) {
          problems.push(`NOT BOTTOM-RIGHT (${dir} L=${c.gapL} R=${c.gapR})`);
        }
        if (problems.length) fails++;
        console.log(`  card ${c.i} badge:${c.badgeText||'-'} inImg:${c.badgeInImage===null?'n/a':(c.badgeInImage?'Y':'N')} gapL/R:${c.gapL??'-'}/${c.gapR??'-'}` +
          `  now:${c.nowPx??'-'} was:${c.wasPx??'-'} ratio:${ratio}  off:${c.offText||'-'}  ${problems.length?'!! '+problems.join(' | '):'ok'}`);
      });
    }
    await page.close();
  }
  // ── Product page ────────────────────────────────────────────────────────
  const pdpFile = __dirname + '/pdp-preview.html';
  if (require('fs').existsSync(pdpFile)) {
    for (const [name, width] of [['mobile', 390], ['desktop', 1280]]) {
      const page = await b.newPage({ viewport:{width,height:900} });
      await page.goto('file://' + pdpFile, {waitUntil:'networkidle'});
      const m = await page.evaluate(() => ({
        overflowX: document.documentElement.scrollWidth > document.documentElement.clientWidth,
        cols: [...document.querySelectorAll('.pdp-col')].map((c,i) => {
          const g = s => { const e = c.querySelector(s); if (!e || e.hidden) return null;
            const r = e.getBoundingClientRect();
            return { px: parseFloat(getComputedStyle(e).fontSize), top: Math.round(r.top), t: e.textContent.trim() }; };
          return { i, save:g('.pdp-save'), price:g('.pdp-price'), old:g('.pdp-old'), saved:g('.pdp-saved') };
        }),
      }));
      console.log('\n' + '='.repeat(96));
      console.log(`PRODUCT PAGE ${name.toUpperCase()} @${width}px   page overflow-x: ${m.overflowX ? 'YES (BAD)' : 'none'}`);
      console.log('='.repeat(96));
      if (m.overflowX) fails++;
      m.cols.forEach(c => {
        const problems = [];
        if (c.save) {
          if (!c.old)                       problems.push('DISCOUNT WITHOUT STRIKETHROUGH');
          else if (c.save.px <= c.old.px)   problems.push(`DISCOUNT NOT LARGER THAN STRUCK (${c.save.px} <= ${c.old.px})`);
          if (c.price && c.save.px > c.price.px) problems.push(`DISCOUNT OUTRANKS PRICE (${c.save.px} > ${c.price.px})`);
          // The discount must sit ABOVE the price and be adjacent to it.
          if (c.price && c.save.top >= c.price.top) problems.push('DISCOUNT NOT ABOVE THE PRICE');
          if (/−\s*0%|-\s*0%/.test(c.save.t)) problems.push('-0% PRINTED');
        } else {
          if (c.old)   problems.push('STRUCK PRICE WITH NO DISCOUNT');
          if (c.saved) problems.push('SAVING WITH NO DISCOUNT');
        }
        if (!c.price) problems.push('PRICE MISSING');
        if (problems.length) fails++;
        console.log(`  case ${c.i}  discount:${c.save ? c.save.px + 'px ' + c.save.t : '-'}  price:${c.price ? c.price.px + 'px' : '-'}` +
          `  struck:${c.old ? c.old.px + 'px' : '-'}  saved:${c.saved ? c.saved.px + 'px' : '-'}  ${problems.length ? '!! ' + problems.join(' | ') : 'ok'}`);
      });
      await page.close();
    }
  } else {
    console.log('\n(no pdp-preview.html — run build_pdp_preview.rb first)');
    fails++;
  }

  await b.close();
  console.log('\n' + (fails ? `${fails} PROBLEMS` : 'GEOMETRY OK'));
  process.exit(fails ? 1 : 0);
})().catch(e=>{console.error('FAIL',e.message);process.exit(1);});
