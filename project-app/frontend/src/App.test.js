import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import App from "./App.vue";

describe("Customer Portal", () => {
  it("renders the customer list and registration form", () => {
    global.fetch = () => Promise.resolve({ ok: true, json: () => Promise.resolve([]) });
    const wrapper = mount(App);
    expect(wrapper.get("h1").text()).toBe("顧客一覧");
    expect(wrapper.get("button").text()).toBe("登録する");
  });
});
