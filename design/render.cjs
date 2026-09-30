// Рендерит листы из design/v2/index.html в PNG (1440 pt @2x).
// Запуск: NODE_PATH=$(npm root -g) node design/render.cjs [папка]   (нужен playwright)
const { chromium } = require("playwright");
const path = require("path");

const src = path.join(__dirname, "v2", "index.html");
const out = process.argv[2] || path.join(__dirname, "v2");
const sheets = {
  "#dashboard": "Дашборд главная v2.png",
  "#sheet-focus": "Фокус-таймер.png",
  "#sheet-work": "Работа.png",
};

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
