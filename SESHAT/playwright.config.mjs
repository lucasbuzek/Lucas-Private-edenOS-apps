import { defineConfig } from "@playwright/test";
export default defineConfig({
  testDir: "./tests-browser",
  use: { baseURL: "http://127.0.0.1:4173", browserName: "chromium", headless: true },
  timeout: 30000, expect: { timeout: 10000 },
  workers: 1, retries: 0,
  webServer: { command: "node scripts/serve-web.mjs", url: "http://127.0.0.1:4173", reuseExistingServer: false, timeout: 20000 },
});
