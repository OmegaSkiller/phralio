export const fonts = {
  ibmPlexSans: ["IBM Plex Sans", "IBMPlexSans"],
  newsreader: ["Newsreader", "Newsreader"],
  inter: ["Inter", "Inter"],
  roboto: ["Roboto", "Roboto"],
  openSans: ["Open Sans", "OpenSans"],
  montserrat: ["Montserrat", "Montserrat"],
  nunitoSans: ["Nunito Sans", "NunitoSans"],
  merriweather: ["Merriweather", "Merriweather"],
  sourceSans3: ["Source Sans 3", "SourceSans3"],
  notoSans: ["Noto Sans", "NotoSans"],
};
export const accents = {
  vermilion: ["#C73518", "#FF6040"],
  terracotta: ["#B84208", "#FF8A38"],
  rose: ["#C51C5A", "#FF5593"],
  plum: ["#9323BF", "#CC69FF"],
  indigo: ["#5142DE", "#9780FF"],
  blue: ["#0068D6", "#459BFF"],
  teal: ["#007B79", "#16C9BA"],
  forest: ["#13802A", "#39D667"],
  olive: ["#5B7000", "#A3CC21"],
  ochre: ["#8F6000", "#FFBD24"],
};
export const defaults = Object.freeze({
  wpm: 300,
  pauses: "normal",
  highlight: true,
  appearance: "system",
  language: "system",
  readingFont: "ibmPlexSans",
  accentColor: "vermilion",
  reduceTransparency: false,
  fontSize: 42,
  imageSeconds: 5,
});
export const languages = [
  "en",
  "ru",
  "es",
  "pt",
  "zh",
  "ja",
  "pl",
  "de",
  "fr",
  "it",
];
export function settings(raw = {}) {
  const s = { ...defaults };
  for (const [key, min, max] of [
    ["wpm", 100, 1500],
    ["fontSize", 24, 72],
    ["imageSeconds", 1, 60],
  ]) {
    if (Number.isFinite(raw[key]))
      s[key] = Math.round(Math.min(max, Math.max(min, raw[key])));
  }
  for (const [key, values] of [
    ["pauses", ["off", "normal", "strong"]],
    ["appearance", ["system", "light", "dark"]],
    ["language", ["system", ...languages]],
    ["readingFont", Object.keys(fonts)],
    ["accentColor", Object.keys(accents)],
  ]) {
    if (values.includes(raw[key])) s[key] = raw[key];
  }
  for (const key of ["highlight", "reduceTransparency"])
    if (typeof raw[key] === "boolean") s[key] = raw[key];
  return s;
}
const segmenter = new Intl.Segmenter(undefined, { granularity: "grapheme" });
export const glyphs = (text) =>
  [...segmenter.segment(text)].map((x) => x.segment);
export const sentenceEnd = (text) => /[.!?…。！？][”’"')\]]*$/.test(text);
export function tokenize(text) {
  const matches = [...text.matchAll(/\S+/gu)];
  return matches.map((m, i) => ({
    text: m[0],
    offset: m.index,
    paragraphEnd:
      i === matches.length - 1 ||
      /\r?\n\s*\r?\n/.test(
        text.slice(m.index + m[0].length, matches[i + 1].index),
      ),
  }));
}
export function focalIndex(text) {
  const letters = glyphs(text)
    .map((x, i) => (/[\p{L}\p{N}]/u.test(x) ? i : -1))
    .filter((i) => i >= 0);
  const n = letters.length;
  return (
    letters[
      Math.min(n - 1, n <= 1 ? 0 : n <= 5 ? 1 : n <= 9 ? 2 : n <= 13 ? 3 : 4)
    ] ?? 0
  );
}
export function duration(token, s) {
  if (!token) return 0;
  if (token.text === "\uFFFC") return s.imageSeconds * 1000;
  let extra = 0;
  if (s.pauses !== "off") {
    extra = token.paragraphEnd
      ? 1
      : sentenceEnd(token.text)
        ? 0.7
        : /[,;:，；：][”’"')\]]*$/.test(token.text)
          ? 0.35
          : 0;
    extra += Math.min(16, Math.max(0, glyphs(token.text).length - 8)) * 0.04;
    if (/\d/.test(token.text)) extra += 0.2;
  }
  return (60000 / s.wpm) * (1 + extra * (s.pauses === "strong" ? 1.5 : 1));
}
export class Playback {
  constructor(
    tokens,
    s,
    position = 0,
    onChange = () => {},
    clock = {
      now: () => performance.now(),
      set: (fn, ms) => setTimeout(fn, ms),
      clear: (id) => clearTimeout(id),
    },
  ) {
    this.tokens = tokens;
    this.settings = s;
    this.clock = clock;
    this.onChange = onChange;
    this.position = Math.max(0, Math.min(tokens.length, position));
    this.playing = false;
    this.remaining = this.full;
  }
  get full() {
    return duration(this.tokens[this.position], this.settings);
  }
  get completed() {
    return this.position === this.tokens.length;
  }
  emit() {
    this.onChange(this);
  }
  schedule() {
    this.clock.clear(this.timer);
    this.timer = this.clock.set(
      () => this.tick(),
      Math.max(0, this.deadline - this.clock.now()),
    );
  }
  play() {
    if (this.playing || !this.tokens.length) return;
    if (this.completed) {
      this.position = 0;
      this.remaining = this.full;
    }
    this.playing = true;
    this.deadline = this.clock.now() + this.remaining;
    this.schedule();
    this.emit();
  }
  pause() {
    if (!this.playing) return;
    this.remaining = Math.max(0, this.deadline - this.clock.now());
    this.playing = false;
    this.clock.clear(this.timer);
    this.emit();
  }
  seek(target) {
    this.clock.clear(this.timer);
    this.playing = false;
    this.position = Math.max(
      0,
      Math.min(this.tokens.length, Math.round(target)),
    );
    this.remaining = this.full;
    this.emit();
  }
  configure(s) {
    const fraction = this.full
      ? Math.max(
          0,
          Math.min(
            1,
            (this.playing ? this.deadline - this.clock.now() : this.remaining) /
              this.full,
          ),
        )
      : 1;
    this.settings = s;
    this.remaining = this.full * fraction;
    if (this.playing) {
      this.deadline = this.clock.now() + this.remaining;
      this.schedule();
    }
    this.emit();
  }
  sentence(direction) {
    let i = Math.min(this.position, this.tokens.length - 1);
    if (direction < 0) {
      i = Math.max(0, i - 1);
      while (
        i > 0 &&
        !sentenceEnd(this.tokens[i - 1].text) &&
        !this.tokens[i - 1].paragraphEnd
      )
        i--;
    } else {
      while (
        i < this.tokens.length &&
        !sentenceEnd(this.tokens[i].text) &&
        !this.tokens[i].paragraphEnd
      )
        i++;
      if (i < this.tokens.length) i++;
    }
    this.seek(i);
  }
  tick() {
    if (!this.playing) return;
    if (this.clock.now() - this.deadline > Math.max(250, this.full * 2)) {
      this.playing = false;
      this.remaining = this.full;
      this.emit();
      return;
    }
    this.position++;
    this.remaining = this.full;
    if (this.completed) this.playing = false;
    else {
      this.deadline += this.remaining;
      this.schedule();
    }
    this.emit();
  }
  dispose() {
    this.clock.clear(this.timer);
    this.playing = false;
  }
}
export function validateReading(raw) {
  if (
    !raw ||
    typeof raw.text !== "string" ||
    !raw.text.trim() ||
    raw.text.length > 200000 ||
    raw.text.includes("\0")
  )
    throw Error("pasteInvalid");
  const text = raw.text.replace(/\r\n?/g, "\n").trim(),
    count = tokenize(text).length;
  const title =
    typeof raw.title === "string"
      ? glyphs(raw.title.trim()).slice(0, 100).join("")
      : "";
  let url = "";
  try {
    const u = new URL(raw.url);
    if (
      ["https:", "http:"].includes(u.protocol) &&
      !u.username &&
      !u.password
    ) {
      u.hash = "";
      url = u.href;
    }
  } catch {}
  const validPos = (p) => Number.isInteger(p) && p >= 0 && p < count;
  const headings = (Array.isArray(raw.headings) ? raw.headings : [])
    .filter((h) => validPos(h.position) && typeof h.title === "string")
    .slice(0, 1000)
    .map((h) => ({
      title: h.title.slice(0, 200),
      position: h.position,
      level: Math.max(1, Math.min(6, h.level || 1)),
    }));
  let bytes = 0;
  const images = (Array.isArray(raw.images) ? raw.images : [])
    .filter((i) => validPos(i.position))
    .slice(0, 24)
    .map((i) => {
      let data =
        typeof i.data === "string" &&
        /^data:image\/(png|jpeg|webp);base64,[A-Za-z0-9+/=]+$/.test(i.data) &&
        i.data.length < 350000
          ? i.data
          : "";
      bytes += data.length;
      if (bytes > 1500000) data = "";
      return {
        position: i.position,
        alt: typeof i.alt === "string" ? i.alt.slice(0, 300) : "",
        data,
      };
    });
  return { title, text, url, headings, images, count };
}
