import test from "node:test";
import assert from "node:assert/strict";
import { Store } from "../src/store.js";
function memory() {
  let data = {};
  return {
    async get(k) {
      return structuredClone(k === null ? data : { [k]: data[k] });
    },
    async set(value) {
      data = { ...data, ...structuredClone(value) };
    },
    async remove(k) {
      delete data[k];
    },
  };
}
test("dedup preserves progress, stars and bookmarks; changed content creates a new version", async () => {
  const s = new Store(memory());
  const reading = {
    title: "Test",
    text: "one two three",
    url: "https://example.org/a",
  };
  const id = await s.handle({ type: "add", reading });
  const d = await s.handle({ type: "open", id });
  await s.handle({ type: "progress", id, owner: d.owner, position: 2 });
  await s.handle({ type: "star", id });
  await s.handle({ type: "bookmark", id, position: 1 });
  assert.equal(await s.handle({ type: "add", reading }), id);
  const saved = await s.get(id);
  assert.equal(saved.position, 2);
  assert.equal(saved.starred, true);
  assert.equal(saved.bookmarks[0].word, "two");
  assert.notEqual(
    await s.handle({
      type: "add",
      reading: { ...reading, text: "changed words" },
    }),
    id,
  );
});
test("serialized field updates do not lose progress or marks; stale tab cannot overwrite progress", async () => {
  const s = new Store(memory());
  const id = await s.handle({
    type: "add",
    reading: { text: "one two three" },
  });
  const d = await s.handle({ type: "open", id });
  await Promise.all([
    s.handle({ type: "progress", id, owner: d.owner, position: 1 }),
    s.handle({ type: "star", id }),
    s.handle({ type: "bookmark", id, position: 2 }),
  ]);
  let saved = await s.get(id);
  assert.equal(saved.position, 1);
  assert.equal(saved.starred, true);
  assert.equal(saved.bookmarks.length, 1);
  const next = await s.handle({ type: "open", id });
  await assert.rejects(
    s.handle({ type: "progress", id, owner: d.owner, position: 0 }),
    /otherReader/,
  );
  await s.handle({ type: "progress", id, owner: next.owner, position: 3 });
  await s.handle({ type: "bookmark", id, position: 2 });
  assert.equal((await s.get(id)).bookmarks.length, 0);
});
test("local failures surface and do not poison later queue work", async () => {
  const area = memory();
  const set = area.set;
  area.set = async () => {
    throw Error("quota");
  };
  const s = new Store(area);
  await assert.rejects(
    s.handle({ type: "add", reading: { text: "hello" } }),
    /quota/,
  );
  area.set = set;
  assert.ok(await s.handle({ type: "add", reading: { text: "hello" } }));
  await assert.rejects(s.handle({ type: "open", id: "../bad" }));
});
