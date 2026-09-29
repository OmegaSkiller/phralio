import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import vm from "node:vm";
import { JSDOM } from "jsdom";
import { Store } from "../src/store.js";
import { extensionCopy } from "../src/extension-copy.js";
const source = await readFile("dist/chrome/background.js", "utf8");
const readerSource = await readFile("dist/chrome/reader.js", "utf8");
const capture = await readFile("dist/chrome/capture.js", "utf8");
const html = await readFile("src/reader.html", "utf8");
function memory(listeners = []) {
  let data = {};
  return {
    async get(k) {
      return structuredClone(k === null ? data : { [k]: data[k] });
    },
    async set(value) {
      const changes = {};
      for (const [k, v] of Object.entries(value))
        changes[k] = { oldValue: data[k], newValue: v };
      data = { ...data, ...structuredClone(value) };
      listeners.forEach((f) => f(changes, "local"));
    },
    async remove(k) {
      delete data[k];
    },
  };
}
async function settle(predicate) {
  for (let i = 0; i < 100; i++) {
    if (predicate()) return;
    await new Promise((resolve) => setImmediate(resolve));
  }
  assert.ok(predicate(), "UI should settle after async storage completes");
}
test("bundled capture returns a serializable result and tolerates repeated injection", async () => {
  const dom = new JSDOM(await readFile("test/fixtures.html", "utf8"), {
    url: "https://example.org/story",
    runScripts: "outside-only",
  });
  const context = dom.getInternalVMContext();
  const result = vm.runInContext(capture, context);
  assert.equal(result.reading.title, "The art of paying attention");
  assert.doesNotMatch(result.reading.text, /Fixture/);
  assert.equal(
    vm.runInContext(capture, context).reading.text,
    result.reading.text,
  );
  dom.window.close();
});
test("bundled toolbar action uses activeTab, saves article, opens autoplay; restricted pages fail safely", async () => {
  const calls = [],
    listeners = {};
  const chrome = {
    runtime: {
      id: "test",
      getURL: (p) => "chrome-extension://test/" + p,
      onMessage: { addListener: (f) => (listeners.message = f) },
    },
    action: { onClicked: { addListener: (f) => (listeners.action = f) } },
    storage: { local: memory() },
    tabs: { create: async (p) => calls.push(p) },
    scripting: {
      executeScript: async (p) => {
        assert.deepEqual(JSON.parse(JSON.stringify(p)), {
          target: { tabId: 12 },
          files: ["capture.js"],
        });
        return [
          { result: { reading: { title: "Article", text: "one two three" } } },
        ];
      },
    },
  };
  vm.runInNewContext(source, {
    chrome,
    crypto,
    TextEncoder,
    Intl,
    URL,
    console,
  });
  await listeners.action({ id: 12, url: "https://example.org/a" });
  assert.match(calls[0].url, /reader.html\?id=[a-f0-9]{64}&play=1/);
  await listeners.action({ id: 99, url: "chrome://settings" });
  assert.match(calls[1].url, /error=restrictedPage/);
  await listeners.action({
    id: 99,
    url: "https://example.org",
    incognito: true,
  });
  assert.match(calls[2].url, /error=privatePage/);
  assert.equal(
    listeners.message(
      { type: "init" },
      { id: "test", url: "https://evil.test" },
      () => assert.fail("untrusted reply"),
    ),
    false,
  );
});
test("reader integration: add, auto-play, pause, seek, bookmark, saved, reopen, settings and restore", async () => {
  const listeners = [],
    area = memory(listeners),
    store = new Store(area);
  const dom = new JSDOM(html, {
    url: "https://extension.test/reader.html",
    runScripts: "outside-only",
    pretendToBeVisual: true,
  });
  const w = dom.window;
  w.matchMedia = () => ({ matches: false, addEventListener() {} });
  Object.defineProperty(w.document, "fonts", {
    value: { load: async () => [], addEventListener() {} },
  });
  w.HTMLDialogElement.prototype.showModal = function () {
    this.open = true;
  };
  w.HTMLDialogElement.prototype.close = function () {
    this.open = false;
  };
  w.chrome = {
    runtime: {
      sendMessage: async (m) => {
        try {
          return { value: await store.handle(m) };
        } catch (e) {
          return { error: e.message };
        }
      },
    },
    storage: { onChanged: { addListener: (f) => listeners.push(f) } },
    tabs: { create: async () => {} },
  };
  vm.runInContext(readerSource, dom.getInternalVMContext());
  const d = w.document;
  const click = (label) => {
    const el = [...d.querySelectorAll("button")].find(
      (b) => b.getAttribute("aria-label") === label,
    );
    assert.ok(el, label);
    el.click();
  };
  await settle(() => d.querySelector("h1"));
  click("Add text");
  d.getElementById("input-title").value = "Regression passage";
  d.getElementById("input-text").value =
    "One two three four five six seven eight nine ten.";
  d.querySelector("form").dispatchEvent(
    new w.Event("submit", { bubbles: true, cancelable: true }),
  );
  await settle(() => d.body.classList.contains("playing"));
  assert.equal(d.getElementById("dialog").open, false);
  d.getElementById("canvas").click();
  assert.equal(d.body.classList.contains("playing"), false);
  const seek = d.getElementById("seek");
  seek.value = 4;
  seek.dispatchEvent(new w.Event("input"));
  click("Bookmark this word");
  await settle(
    () =>
      d.getElementById("bookmark-control").getAttribute("aria-label") ===
      "Remove bookmark",
  );
  click("Saved");
  await settle(() => d.querySelector(".reading-row"));
  assert.match(d.getElementById("main").textContent, /five/);
  d.querySelector(".reading-row .open").click();
  await settle(() => d.getElementById("word"));
  assert.equal(d.getElementById("word").textContent, "five");
  assert.equal(
    d.getElementById("notice").hidden,
    true,
    "same-tab reopen must not report another tab",
  );
  assert.equal(d.getElementById("seek").value, "4");
  // Simulate shaped DOM bounds: unequal word halves must not move the anchor.
  const word = d.getElementById("word");
  const anchor = word.querySelector("[data-anchor]");
  word.getBoundingClientRect = () => ({ left: 200, top: 100, width: 300 });
  const originalBounds = w.Element.prototype.getBoundingClientRect;
  w.Element.prototype.getBoundingClientRect = function () {
    if (this.hasAttribute("data-anchor"))
      return { left: 260, top: 110, width: 20, height: 40 };
    return originalBounds.call(this);
  };
  Object.defineProperty(d.getElementById("canvas"), "clientWidth", {
    configurable: true,
    value: 278,
  });
  assert.equal(anchor.textContent, "i");
  w.dispatchEvent(new w.Event("resize"));
  assert.equal(word.style.transform, "translate(-35px, -15px) scale(0.5)");
  Object.defineProperty(d.getElementById("canvas"), "clientWidth", {
    value: 800,
  });
  w.dispatchEvent(new w.Event("resize"));
  assert.equal(word.style.transform, "translate(-70px, -30px) scale(1)");
  w.Element.prototype.getBoundingClientRect = originalBounds;
  assert.ok(
    !w.location.search.includes("play="),
    "reload should resume paused",
  );
  click("Settings");
  await settle(() => d.querySelector('select[aria-label="Reading font"]'));
  const font = d.querySelector('select[aria-label="Reading font"]');
  assert.equal(font.options.length, 10);
  assert.equal(font.parentElement.className, "select-control");
  assert.equal(
    font.parentElement.querySelector("svg").getAttribute("aria-hidden"),
    "true",
  );
  font.value = "inter";
  font.dispatchEvent(new w.Event("change"));
  await settle(
    () =>
      d.documentElement.style.getPropertyValue("--reader-font") === '"Inter"',
  );
  const theme = d.querySelector('select[aria-label="Appearance"]');
  theme.value = "dark";
  theme.dispatchEvent(new w.Event("change"));
  await settle(() => d.body.classList.contains("dark"));
  const state = await store.handle({ type: "init" });
  assert.equal(state.settings.readingFont, "inter");
  assert.equal(state.settings.appearance, "dark");
  assert.equal(state.library[0].position, 4);
  w.close();
});
test("all extension locales cover identical nonempty keys", () => {
  const keys = Object.keys(extensionCopy.en).sort();
  assert.equal(Object.keys(extensionCopy).length, 10);
  for (const copy of Object.values(extensionCopy)) {
    assert.deepEqual(Object.keys(copy).sort(), keys);
    assert.ok(
      Object.values(copy).every((v) => typeof v === "string" && v.length),
    );
  }
});
test("all packages have least-privilege manifests and local assets", async () => {
  for (const browser of ["chrome", "firefox", "safari"]) {
    const m = JSON.parse(await readFile(`dist/${browser}/manifest.json`));
    assert.equal(m.manifest_version, 3);
    assert.deepEqual(m.permissions, ["activeTab", "scripting", "storage"]);
    assert.equal(m.host_permissions, undefined);
    assert.equal(m.action.default_popup, undefined);
    assert.match(
      m.content_security_policy.extension_pages,
      /object-src 'none'/,
    );
    for (const p of Object.values(m.icons))
      assert.ok((await readFile(`dist/${browser}/${p}`)).length);
    if (browser === "chrome")
      assert.equal(m.background.service_worker, "background.js");
    else assert.equal(m.background.persistent, false);
  }
});
