// Takes the add-on screenshots on the site (docs/site/img/) from the guide's live examples.
//
//   pnpm guide:start                                   # in one terminal; note its URL
//   node scripts/site-screenshots.mjs http://localhost:4200
//
// Each shot opens a guide page, optionally interacts with an example, and captures its stage:
// the rendered form beside the live model.
import { mkdirSync } from 'node:fs'
import { chromium } from 'playwright'

const base = (process.argv[2] ?? 'http://localhost:4200').replace(/\/$/, '')
const out = new URL('../docs/site/img/', import.meta.url)
mkdirSync(out, { recursive: true })

const SHOTS = [
  {
    file: 'addon-date-picker.png',
    page: 'controls/date-picker.md',
    example: 'controls-date-picker',
    open: '[data-test-fw-field="due"] button',
    height: 560,
  },
  { file: 'addon-phone.png', page: 'controls/phone.md', example: 'controls-phone' },
  {
    file: 'addon-file-upload.png',
    page: 'controls/file-upload.md',
    example: 'controls-file-upload',
  },
  { file: 'addon-rich-text.png', page: 'controls/rich-text.md', example: 'controls-rich-text' },
]

const browser = await chromium.launch()
const page = await browser.newPage({
  viewport: { width: 1100, height: 900 },
  deviceScaleFactor: 2,
  colorScheme: 'light',
})

for (const shot of SHOTS) {
  await page.goto(`${base}/${shot.page}`)
  const stage = page.locator(`[data-test-example="${shot.example}"] .example-stage`)
  await stage.waitFor()
  await page.evaluate(() => document.fonts.ready)
  if (shot.open) {
    await stage.locator(shot.open).first().click()
    await page.waitForTimeout(300)
  }
  if (shot.height) await stage.evaluate((el, h) => (el.style.minHeight = `${h}px`), shot.height)
  await stage.screenshot({ path: new URL(shot.file, out).pathname, animations: 'disabled' })
  console.log(`docs/site/img/${shot.file}`)
}

await browser.close()
