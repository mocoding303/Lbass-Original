const { chromium } = require('playwright-core');
(async () => {
  const b = await chromium.launch({ executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome', args:['--no-sandbox'] });
  const p = await b.newPage({ viewport:{width:390,height:900}, deviceScaleFactor:3 });
  await p.goto('file://' + __dirname + '/preview.html', {waitUntil:'networkidle'});
  await p.waitForTimeout(250);
  // cards 1 (markdown + campaign ribbon) and 2 (markdown only, deep discount)
  const wraps = await p.$$('#rtl .lbqa-wrap');
  await wraps[1].screenshot({ path: __dirname + '/crop-both.png' });
  await wraps[2].screenshot({ path: __dirname + '/crop-markdown.png' });
  await wraps[0].screenshot({ path: __dirname + '/crop-nosale.png' });
  await b.close(); console.log('cropped');
})();
