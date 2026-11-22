// Full-page screenshots of every page in two viewports, for checking the UI
// by eye before and after a change. Not part of CI.
//
//   bin/rails db:seed:replant dev:ui_states
//   bin/rails runner script/ui_pages.rb > tmp/ui_pages.json
//   bin/rails server            # in another terminal
//   node script/ui_snapshots.mjs tmp/ui_pages.json tmp/ui/after
//
// Needs Playwright (npm i -D playwright, or a global install).
import { createRequire } from "node:module";
import { mkdirSync, readFileSync } from "node:fs";

// require() also finds a global Playwright install through NODE_PATH.
const { chromium } = createRequire(import.meta.url)("playwright");

const [pagesFile = "tmp/ui_pages.json", outDir = "tmp/ui/latest"] = process.argv.slice(2);
const base = process.env.BASE_URL || "http://localhost:3000";
const password = process.env.CLIENT_PASSWORD || "demo-client-2026";
const logins = {
  admin: [process.env.ADMIN_EMAIL || "admin@example.com", process.env.ADMIN_PASSWORD || "demo-admin-2026"],
  yoga: ["client@demoyoga.example", password],
  cafe: ["client@democafe.example", password],
  tutor: ["client@demotutor.example", password],
};
const viewports = {
  mobile: { viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true },
  desktop: { viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1 },
};

const pages = JSON.parse(readFileSync(pagesFile, "utf8"));
const browser = await chromium.launch();

for (const [who, list] of Object.entries(pages)) {
  let storageState;
  if (logins[who]) {
    const ctx = await browser.newContext();
    const page = await ctx.newPage();
    await page.goto(`${base}/session/new`);
    await page.fill("input[name=email_address]", logins[who][0]);
    await page.fill("input[name=password]", logins[who][1]);
    await Promise.all([page.waitForURL((url) => !url.pathname.startsWith("/session")), page.press("input[name=password]", "Enter")]);
    storageState = await ctx.storageState();
    await ctx.close();
  }

  for (const [vpName, vp] of Object.entries(viewports)) {
    const ctx = await browser.newContext({ ...vp, storageState });
    const page = await ctx.newPage();
    mkdirSync(`${outDir}/${vpName}`, { recursive: true });
    for (const [slug, path] of list) {
      await page.goto(`${base}${path}`);
      await page.waitForLoadState("networkidle");
      await page.screenshot({ path: `${outDir}/${vpName}/${slug}.png`, fullPage: true });
      if (vpName === "desktop" && ["report", "sign-off"].includes(slug)) {
        await page.emulateMedia({ media: "print" });
        await page.pdf({ path: `${outDir}/${slug}.pdf`, format: "A4", printBackground: true });
        await page.emulateMedia({ media: "screen" });
      }
    }
    await ctx.close();
  }
}

await browser.close();
console.log(`Saved screenshots to ${outDir}`);
