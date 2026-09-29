import test from "node:test";
import assert from "node:assert/strict";
import { JSDOM } from "jsdom";
import { extractPage } from "../src/extract.js";
import { tokenize } from "../src/core.js";
const prose =
  "Morning light falls across the table, where a book waits beside a cup of tea. Each sentence offers a quiet place to pause and begin again. ".repeat(
    8,
  );
test("article extraction removes navigation, forms, scripts and hidden content without modifying source", () => {
  const dom = new JSDOM(
    `<title>Quiet reading</title><nav>UNWANTED NAV</nav><article><h1>A quiet beginning</h1><p>${prose}</p><h2>Next chapter</h2><p>${prose}</p><p hidden>HIDDEN SECRET</p><form><input value="PASSWORD"><textarea>PRIVATE DRAFT</textarea></form><script>EVIL SCRIPT</script><img src="https://tracker.test/pixel" alt="Mountain ridges"></article><footer>UNWANTED FOOTER</footer>`,
    { url: "https://example.org/story" },
  );
  const before = dom.serialize();
  const r = extractPage(dom.window.document);
  assert.equal(dom.serialize(), before);
  assert.match(r.text, /Morning light/);
  assert.doesNotMatch(r.text, /UNWANTED|HIDDEN|PASSWORD|PRIVATE|EVIL/);
  assert.equal(r.url, "https://example.org/story");
  const h = r.headings.find((h) => h.title === "Next chapter");
  assert.ok(h);
  assert.equal(tokenize(r.text)[h.position].text, "Next");
  assert.equal(r.images[0].data, "");
  assert.equal(tokenize(r.text)[r.images[0].position].text, "\uFFFC");
});
test("short semantic articles fall back and HTML is text only", () => {
  const doc = new JSDOM(
    "<title>Short</title><main><p>&lt;img src=x onerror=alert(1)&gt; This is readable text.</p></main>",
    { url: "https://example.org" },
  ).window.document;
  const r = extractPage(doc);
  assert.match(r.text, /<img src=x/);
  assert.equal(r.images.length, 0);
});
test("no text page reports a useful error", () => {
  assert.throws(
    () =>
      extractPage(
        new JSDOM("<body><nav>Only menu</nav></body>").window.document,
      ),
    /emptyPage/,
  );
});
