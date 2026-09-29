import { settings, validateReading } from "./core.js";
export class Store {
  constructor(area) {
    this.area = area;
    this.queue = Promise.resolve();
  }
  run(fn) {
    const task = this.queue.then(fn);
    this.queue = task.catch(() => {});
    return task;
  }
  async get(id) {
    const result = await this.area.get("doc:" + id);
    return result["doc:" + id] || null;
  }
  async list() {
    const all = await this.area.get(null);
    return Object.entries(all)
      .filter(([k]) => k.startsWith("doc:"))
      .map(([, d]) => {
        const { text, images, ...summary } = d;
        return summary;
      })
      .sort((a, b) => b.openedAt - a.openedAt);
  }
  async add(raw) {
    const reading = validateReading(raw);
    const digest = await crypto.subtle.digest(
      "SHA-256",
      new TextEncoder().encode(reading.url + "\n" + reading.text),
    );
    const id = [...new Uint8Array(digest)]
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");
    const existing = await this.get(id);
    const doc = existing
      ? { ...existing, openedAt: Date.now() }
      : {
          ...reading,
          id,
          position: 0,
          starred: false,
          bookmarks: [],
          openedAt: Date.now(),
        };
    await this.area.set({ ["doc:" + id]: doc });
    return id;
  }
  async handle(m) {
    return this.run(async () => {
      if (m.type === "init") {
        const raw = await this.area.get("settings");
        return { settings: settings(raw.settings), library: await this.list() };
      }
      if (m.type === "settings") {
        const old = await this.area.get("settings");
        const next = settings({ ...settings(old.settings), ...m.patch });
        await this.area.set({ settings: next });
        return next;
      }
      if (m.type === "add") return this.add(m.reading);
      if (!/^[a-f0-9]{64}$/.test(m.id || "")) throw Error("readingUnavailable");
      const doc = await this.get(m.id);
      if (!doc) throw Error("readingUnavailable");
      if (m.type === "open") {
        doc.owner = crypto.randomUUID();
        doc.openedAt = Date.now();
        await this.area.set({ ["doc:" + doc.id]: doc });
        return doc;
      }
      if (m.type === "progress") {
        if (doc.owner !== m.owner) throw Error("otherReader");
        if (
          !Number.isInteger(m.position) ||
          m.position < 0 ||
          m.position > doc.count
        )
          throw Error("readingUnavailable");
        doc.position = m.position;
      } else if (m.type === "star") doc.starred = !doc.starred;
      else if (m.type === "bookmark") {
        if (
          !Number.isInteger(m.position) ||
          m.position < 0 ||
          m.position >= doc.count
        )
          throw Error("readingUnavailable");
        const index = doc.bookmarks.findIndex((b) => b.position === m.position);
        if (index >= 0) doc.bookmarks.splice(index, 1);
        else
          doc.bookmarks.push({
            position: m.position,
            word: doc.text.match(/\S+/gu)[m.position],
          });
      } else if (m.type === "delete") {
        await this.area.remove("doc:" + m.id);
        return true;
      } else throw Error("readingUnavailable");
      await this.area.set({ ["doc:" + doc.id]: doc });
      return doc;
    });
  }
}
