// Takes the add-on screenshots on the site (docs/site/img/) from the guide's live examples.
//
//   pnpm build && pnpm --filter docs-app exec vite build --mode development
//   node scripts/site-screenshots.mjs
//
// It serves docs-app/dist, opens each guide page in Chromium (Playwright, which isn't a
// dependency of this repo: have it installed globally), optionally opens the control, and
// captures the example's stage: the rendered form beside the live model.
import { createReadStream, existsSync, mkdirSync, statSync } from 'node:fs'
import { createServer } from 'node:http'
import { createRequire } from 'node:module'
import { extname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const { chromium } = createRequire(import.meta.url)('playwright')

const SHOTS = [
  {
    file: 'addon-date-picker.png',
    page: 'controls/date-picker.md',
    example: 'controls-date-picker',
    open: '[data-test-fw-field="stay"] button.fw-date-picker',
  },
  {
    file: 'addon-phone.png',
    page: 'controls/phone.md',
    example: 'controls-phone',
    fill: { mobile: '07700900123', office: '+3361234' },
  },
  {
    file: 'addon-file-upload.png',
    page: 'controls/file-upload.md',
    example: 'controls-file-upload',
    // Files serialize verbosely: leave the model out, and the form says it all.
    hideModel: true,
  },
  { file: 'addon-rich-text.png', page: 'controls/rich-text.md', example: 'controls-rich-text' },
]

const root = fileURLToPath(new URL('../docs-app/dist/', import.meta.url))
const out = fileURLToPath(new URL('../docs/site/img/', import.meta.url))
if (!existsSync(join(root, 'index.html'))) throw new Error(`Build the guide first: no ${root}`)
mkdirSync(out, { recursive: true })

const TYPES = {
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.html': 'text/html',
  '.svg': 'image/svg+xml',
}

// The guide is a single-page app: anything that isn't a file is its index.html.
const server = createServer((req, res) => {
  let file = join(root, decodeURIComponent(req.url.split('?')[0]))
  if (!file.startsWith(root) || !existsSync(file) || statSync(file).isDirectory()) {
    file = join(root, 'index.html')
  }
  res.setHeader('content-type', TYPES[extname(file)] ?? 'application/octet-stream')
  createReadStream(file).pipe(res)
}).listen(0)
const base = `http://localhost:${server.address().port}`

const browser = await chromium.launch()
const page = await browser.newPage({
  viewport: { width: 1100, height: 900 },
  deviceScaleFactor: 2,
  colorScheme: 'light',
})

for (const shot of SHOTS) {
  await page.goto(`${base}/${shot.page}`)
  const example = page.locator(`[data-test-example="${shot.example}"]`)
  const stage = example.locator('.example-stage')
  await stage.waitFor()
  await stage.evaluate(el => el.ownerDocument.fonts.ready)
  for (const [path, text] of Object.entries(shot.fill ?? {})) {
    await example.locator(`[data-test-fw-field="${path}"] input`).pressSequentially(text)
  }
  if (shot.open) {
    await example.locator(shot.open).first().click()
    await page.waitForTimeout(600)
  }
  // An open calendar overhangs the stage: grow the stage to hold it, then capture the stage.
  await stage.evaluate(el => {
    const dropdown = [...el.ownerDocument.querySelectorAll('.ember-basic-dropdown-content')].find(
      d => d.getBoundingClientRect().height > 0,
    )
    if (!dropdown) return
    const overhang = dropdown.getBoundingClientRect().bottom - el.getBoundingClientRect().bottom
    if (overhang > 0) el.style.paddingBottom = `${overhang + 24}px`
  })
  if (shot.hideModel) await stage.locator('.example-model').evaluate(el => el.remove())
  await stage.screenshot({ path: join(out, shot.file) })
  console.log(`docs/site/img/${shot.file}`)
}

await browser.close()
server.close()
