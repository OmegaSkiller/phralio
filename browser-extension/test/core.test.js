import test from "node:test";
import assert from "node:assert/strict";
import {
  defaults,
  settings,
  tokenize,
  focalIndex,
  glyphs,
  duration,
  Playback,
  validateReading,
} from "../src/core.js";
function clock() {
  let time = 0,
    id = 0;
  const tasks = new Map();
  return {
    now: () => time,
    set: (fn, ms) => {
      tasks.set(++id, { fn, at: time + ms });
      return id;
    },
    clear: (id) => tasks.delete(id),
    advance(ms) {
      time += ms;
      const due = [...tasks].filter(([, v]) => v.at <= time);
      for (const [id, t] of due) {
        tasks.delete(id);
        t.fn();
      }
    },
    get count() {
      return tasks.size;
    },
  };
}
test("settings match mobile defaults, clamp values and ignore unknown IDs", () => {
  assert.deepEqual(settings(), defaults);
  assert.equal(settings({ wpm: 9999, readingFont: "bogus" }).wpm, 1500);
  assert.equal(settings({ fontSize: 0 }).fontSize, 24);
  assert.equal(settings({ readingFont: "bogus" }).readingFont, "ibmPlexSans");
  assert.equal(settings({ highlight: "false" }).highlight, true);
});
test("UTF16 offsets, paragraphs, focal glyph and graphemes match app", () => {
  const t = tokenize("Hello, world.\n\nA 👨‍👩‍👧‍👦 story");
  assert.equal(t[1].paragraphEnd, true);
  assert.equal(t[2].offset, 15);
  assert.equal(t.at(-1).paragraphEnd, true);
  assert.equal(focalIndex("“reading”"), 3);
  assert.equal(glyphs("a\u0301").length, 1);
  assert.equal(focalIndex("!"), 0);
});
test("timing: punctuation, paragraphs, digits, long words, strong and images", () => {
  const token = { text: "hello", paragraphEnd: false };
  assert.equal(duration(token, defaults), 200);
  assert.equal(duration({ ...token, text: "hello," }, defaults), 270);
  assert.equal(duration({ ...token, text: "hello." }, defaults), 340);
  assert.equal(duration({ ...token, paragraphEnd: true }, defaults), 400);
  assert.equal(duration({ ...token, text: "42" }, defaults), 240);
  assert.equal(duration({ ...token, text: "1234567890" }, defaults), 256);
  assert.equal(
    duration(
      { ...token, paragraphEnd: true },
      { ...defaults, pauses: "strong" },
    ),
    500,
  );
  assert.equal(
    duration({ ...token, paragraphEnd: true }, { ...defaults, pauses: "off" }),
    200,
  );
  assert.equal(duration({ text: "\uFFFC" }, defaults), 5000);
});
test("pause and speed changes preserve remaining fraction; one timer", () => {
  const c = clock(),
    p = new Playback(
      tokenize("one two three"),
      { ...defaults, pauses: "off" },
      0,
      () => {},
      c,
    );
  p.play();
  c.advance(80);
  p.pause();
  assert.equal(p.remaining, 120);
  assert.equal(c.count, 0);
  p.configure({ ...defaults, pauses: "off", wpm: 600 });
  assert.equal(p.remaining, 60);
  p.play();
  assert.equal(c.count, 1);
  c.advance(59);
  assert.equal(p.position, 0);
  c.advance(1);
  assert.equal(p.position, 1);
  p.dispose();
  assert.equal(c.count, 0);
});
test("long stall pauses without skipped words; completion restarts", () => {
  const c = clock(),
    p = new Playback(
      tokenize("one two"),
      { ...defaults, pauses: "off" },
      0,
      () => {},
      c,
    );
  p.play();
  c.advance(1000);
  assert.equal(p.position, 0);
  assert.equal(p.playing, false);
  p.play();
  c.advance(200);
  c.advance(200);
  assert.equal(p.completed, true);
  p.play();
  assert.equal(p.position, 0);
});
test("sentence seek and word seek pause at valid positions", () => {
  const p = new Playback(
    tokenize("One sentence. Another phrase.\n\nLast."),
    defaults,
  );
  p.sentence(1);
  assert.equal(p.position, 2);
  p.sentence(1);
  assert.equal(p.position, 4);
  p.sentence(-1);
  assert.equal(p.position, 2);
  p.seek(999);
  assert.equal(p.completed, true);
  p.seek(-3);
  assert.equal(p.position, 0);
  p.dispose();
});
test("untrusted reading boundary rejects oversized/binary/empty, strips unsafe URLs and image data", () => {
  for (const text of ["", "a\0b", "x".repeat(200001)])
    assert.throws(() => validateReading({ text }));
  const r = validateReading({
    text: "hello world",
    url: "javascript:alert(1)",
    headings: [{ position: 999, title: "bad" }],
    images: [
      { position: 0, data: "data:image/svg+xml;base64,eA==", alt: "safe" },
    ],
  });
  assert.equal(r.url, "");
  assert.equal(r.images[0].data, "");
  assert.deepEqual(r.headings, []);
});
