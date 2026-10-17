import { expect, test } from "@playwright/test";

test("adds a customer to the list", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "顧客一覧" })).toBeVisible();
  await page.getByLabel("顧客名").fill("青空商事");
  await page.getByRole("button", { name: "登録する" }).click();
  await expect(page.getByRole("cell", { name: "青空商事" })).toBeVisible();
});
