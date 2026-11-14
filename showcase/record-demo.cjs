'use strict';

const path = require('path');
const fs = require('fs');
const { chromium } = require('playwright');

const ROOT = __dirname;
const URL = process.env.DEMO_URL || 'http://127.0.0.1:8765/showcase/demo-video.html';
const OUT_DIR = path.join(ROOT, 'video-raw');
const REHEARSAL = process.argv.includes('--rehearse');

async function ensureVisible(page, locator, label) {
  const el = typeof locator === 'string' ? page.locator(locator).first() : locator;
  const visible = await el.isVisible().catch(() => false);
  if (!visible) {
    console.error(`REHEARSAL FAIL: "${label}"`);
    return false;
  }
  console.log(`REHEARSAL OK: "${label}"`);
  return true;
}

(async () => {
  const browser = await chromium.launch({ headless: true });

  if (REHEARSAL) {
    const context = await browser.newContext({ viewport: { width: 1920, height: 1080 } });
    const page = await context.newPage();
    await page.goto(URL, { waitUntil: 'networkidle' });
    const checks = [
      ['header', 'header'],
      ['.spread', 'code/plot spread'],
      ['#code', 'code block'],
      ['.figure-pane img', 'trajectory figure'],
      ['.stats', 'stats row'],
    ];
    let ok = true;
    for (const [sel, label] of checks) {
      if (!(await ensureVisible(page, sel, label))) ok = false;
    }
    await browser.close();
    if (!ok) process.exit(1);
    console.log('REHEARSAL PASSED');
    return;
  }

  fs.mkdirSync(OUT_DIR, { recursive: true });

  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 },
    deviceScaleFactor: 1,
    recordVideo: { dir: OUT_DIR, size: { width: 1920, height: 1080 } }
  });
  const page = await context.newPage();

  try {
    await page.goto(URL, { waitUntil: 'networkidle' });
    await page.waitForFunction(() => document.documentElement.dataset.ready === '1', { timeout: 15000 });
    await page.waitForFunction(() => document.documentElement.dataset.phase === 'done', { timeout: 30000 });
    await page.waitForTimeout(1800);
  } catch (err) {
    console.error('DEMO ERROR:', err.message);
    process.exitCode = 1;
  } finally {
    const video = page.video();
    await context.close();
    if (video) {
      const src = await video.path();
      const dest = path.join(ROOT, 'surveymixr-demo.webm');
      fs.copyFileSync(src, dest);
      console.log('Video saved:', dest);
    }
    await browser.close();
  }
})();
