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
          // Baseline-aligned text of different sizes has different TOPS on the
          // same line, so "same line" is vertical overlap, not equal offsets.
          sameLine: (now && was)
            ? !(now.getBoundingClientRect().bottom <= was.getBoundingClientRect().top ||
                was.getBoundingClientRect().bottom <= now.getBoundingClientRect().top)
            : null,
          // Does the pair PHYSICALLY fit on one line in this column? If it does,
          // it must be on one line. If it cannot, the wrap has to be graceful.
          pairFits: (now && was && now.parentElement)
            ? (now.getBoundingClientRect().width + was.getBoundingClientRect().width +
               parseFloat(getComputedStyle(now.parentElement).columnGap || 0))
              <= now.parentElement.getBoundingClientRect().width
            : null,
          saleFirst: (now && was)
            ? now.getBoundingClientRect().top <= was.getBoundingClientRect().top + 1
            : null,
          wasWeight: was ? getComputedStyle(was).fontWeight : null,
          wasColor: was ? getComputedStyle(was).color : null,
          wasWrap: was ? getComputedStyle(was).whiteSpace : null,
          strikePx: was ? px(getComputedStyle(was).textDecorationThickness) : null,
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
        // Requested: the sale price is 1.3-1.5x the reference price. Anything
        // above ~1.55 makes the reference price look like a footnote; anything
        // at or below 1.0 stops it being a reference at all.
        if (c.nowPx && c.wasPx) {
          const ratio = c.nowPx / c.wasPx;
          if (ratio < 1.3 || ratio > 1.56) problems.push(`RATIO OUT OF BAND (${ratio.toFixed(2)}x, want 1.3-1.5)`);
        }
        // The two prices must sit on ONE line, side by side. At <=400px the
        // sale price used to take flex:1 0 100% and push the reference below it.
        // Side by side whenever the column can hold them. A four-digit reference
        // price (1 199 DH) needs ~148px in a 130px phone column, which no
        // readable type size fits; shrinking every card to accommodate a price
        // the catalogue does not currently carry would be the wrong trade. In
        // that case the wrap must still be graceful: sale price on the first
        // line, never the reference price above or alone.
        if (c.pairFits && c.sameLine === false) problems.push('PRICES SPLIT DESPITE FITTING');
        if (c.saleFirst === false) problems.push('REFERENCE PRICE ABOVE THE SALE PRICE');
        if (c.wasWrap && c.wasWrap !== 'nowrap') problems.push('REFERENCE PRICE CAN WRAP MID-NUMBER');
        if (c.strikePx !== null && c.strikePx < 1.5) problems.push(`STRIKETHROUGH TOO THIN (${c.strikePx}px)`);
        if (c.offText && /−\s*0%|-\s*0%/.test(c.offText)) problems.push('-0% PRINTED');
        if (c.badge && !c.wasText) problems.push('BADGE WITHOUT STRIKETHROUGH');
        // The badge is pinned bottom-RIGHT in both directions on purpose: it is
        // the only corner the stamp (always bottom-left) and the ribbon
        // (top, mirroring) both leave free. Assert it stays there.
        if (c.badge && !(c.gapR <= 12 && c.gapL > c.gapR)) {
          problems.push(`NOT BOTTOM-RIGHT (${dir} L=${c.gapL} R=${c.gapR})`);
        }
        if (problems.length) fails++;
        console.log(`  card ${c.i} badge:${String(c.badgeText||'-').padEnd(5)} now:${String(c.nowPx??'-').padEnd(4)} was:${String(c.wasPx??'-').padEnd(4)} ratio:${ratio}` +
          ` off:${String(c.offPx??'-').padEnd(4)} fits:${c.pairFits===null?'n/a':(c.pairFits?'Y':'N')} oneLine:${c.sameLine===null?'n/a':(c.sameLine?'Y':'N')}` +
          `  ${problems.length?'!! '+problems.join(' | '):'ok'}`);
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
            const r = e.getBoundingClientRect(), cs = getComputedStyle(e);
            return { px: parseFloat(cs.fontSize), top: Math.round(r.top), t: e.textContent.trim(),
                     strike: parseFloat(cs.textDecorationThickness) || null, wrap: cs.whiteSpace }; };
          const pr = c.querySelector('.pdp-price'), ol = c.querySelector('.pdp-old');
          const sameLine = (pr && ol && !ol.hidden)
            ? !(pr.getBoundingClientRect().bottom <= ol.getBoundingClientRect().top ||
                ol.getBoundingClientRect().bottom <= pr.getBoundingClientRect().top)
            : null;
          return { i, sameLine, save:g('.pdp-save'), price:g('.pdp-price'), old:g('.pdp-old'), saved:g('.pdp-saved') };
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
          if (c.old && c.price) {
            const ratio = c.price.px / c.old.px;
            if (ratio < 1.3 || ratio > 1.6) problems.push(`RATIO OUT OF BAND (${ratio.toFixed(2)}x)`);
            if (!c.sameLine) problems.push('PRICES ON SEPARATE LINES');
          }
          // The discount must sit ABOVE the price and be adjacent to it.
          if (c.price && c.save.top >= c.price.top) problems.push('DISCOUNT NOT ABOVE THE PRICE');
          if (/−\s*0%|-\s*0%/.test(c.save.t)) problems.push('-0% PRINTED');
        } else {
          if (c.old)   problems.push('STRUCK PRICE WITH NO DISCOUNT');
          if (c.saved) problems.push('SAVING WITH NO DISCOUNT');
        }
        if (!c.price) problems.push('PRICE MISSING');
        if (problems.length) fails++;
        if (c.old && c.old.wrap !== 'nowrap') { problems.push('REFERENCE PRICE CAN WRAP MID-NUMBER'); fails++; }
        if (c.old && c.old.strike !== null && c.old.strike < 1.5) { problems.push(`STRIKETHROUGH TOO THIN (${c.old.strike}px)`); fails++; }
        console.log(`  case ${c.i}  discount:${c.save ? c.save.px + 'px' : '-'}  price:${c.price ? c.price.px + 'px' : '-'}` +
          `  struck:${c.old ? c.old.px + 'px' : '-'}  ratio:${c.old && c.price ? (c.price.px / c.old.px).toFixed(2) + 'x' : '-'}` +
          `  saved:${c.saved ? c.saved.px + 'px' : '-'}  ${problems.length ? '!! ' + problems.join(' | ') : 'ok'}`);
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
