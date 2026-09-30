// Рендерит листы из design/<версия>/index.html в PNG (1440 pt @2x).
// Запуск: NODE_PATH=$(npm root -g) node design/render.cjs [v2|v3] [папка]   (нужен playwright)
// Без версии рендерится v2.
const { chromium } = require("playwright");
const path = require("path");

const versions = {
  v2: {
    "#dashboard": "Дашборд главная v2.png",
    "#sheet-focus": "Фокус-таймер.png",
    "#sheet-work": "Работа.png",
  },
  v3: {
    "#dashboard": "Дашборд главная v3.png",
  },
};

const args = process.argv.slice(2);
const version = versions[args[0]] ? args.shift() : "v2";
const sheets = versions[version];
const src = path.join(__dirname, version, "index.html");
const out = args[0] || path.join(__dirname, version);

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2 });
  await page.goto("file://" + src + "?shot", { waitUntil: "networkidle" });
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(800);
  for (const [selector, file] of Object.entries(sheets)) {
    await (await page.$(selector)).screenshot({ path: path.join(out, file) });
    console.log("✓", file);
  }
  await browser.close();
})();
