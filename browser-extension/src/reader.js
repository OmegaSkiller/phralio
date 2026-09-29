import {
  createElement,
  House,
  BookOpen,
  Bookmark,
  Settings,
  Play,
  Pause,
  ChevronLeft,
  ChevronRight,
  ChevronDown,
  ChevronsLeft,
  ChevronsRight,
  Star,
  List,
  Plus,
  Clipboard,
  Globe,
  X,
  Trash2,
  RotateCcw,
} from "lucide";
import {
  Playback,
  settings,
  fonts,
  accents,
  glyphs,
  focalIndex,
  tokenize,
} from "./core.js";
import { catalogs } from "./catalogs.js";
import { extensionCopy } from "./extension-copy.js";
const api = globalThis.browser || globalThis.chrome;
const $ = (id) => document.getElementById(id);
let prefs = settings(),
  library = [],
  current = null,
  player = null,
  view = "home",
  locale = "en",
  lastSave = 0,
  saving = Promise.resolve(),
  openingId = null,
  saveFailed = false;
const icons = {
  home: House,
  read: BookOpen,
  saved: Bookmark,
  settings: Settings,
  play: Play,
  pause: Pause,
  left: ChevronLeft,
  right: ChevronRight,
  back: ChevronsLeft,
  forward: ChevronsRight,
  star: Star,
  bookmark: Bookmark,
  contents: List,
  plus: Plus,
  clipboard: Clipboard,
  globe: Globe,
  close: X,
  remove: Trash2,
  retry: RotateCcw,
};
const t = (key, args = {}) => {
  let value =
    extensionCopy[locale]?.[key] ??
    catalogs[locale]?.[key] ??
    catalogs.en[key] ??
    key;
  for (const [k, v] of Object.entries(args))
    value = value.replaceAll("{" + k + "}", String(v));
  return value;
};
function node(tag, attrs = {}, ...children) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (k === "class") el.className = v;
    else if (k.startsWith("on")) el.addEventListener(k.slice(2), v);
    else if (v !== undefined && v !== false)
      el.setAttribute(k, v === true ? "" : String(v));
  }
  for (const c of children.flat()) {
    if (c != null)
      el.append(c instanceof Node ? c : document.createTextNode(String(c)));
  }
  return el;
}
function button(label, icon, click, cls = "") {
  const el = node("button", {
    type: "button",
    class: cls,
    title: label,
    "aria-label": label,
    onclick: click,
  });
  if (icon) {
    const svg = createElement(icons[icon]);
    svg.setAttribute("aria-hidden", "true");
    el.append(svg);
  }
  if (!cls.includes("icon")) el.append(node("span", {}, label));
  return el;
}
async function rpc(message) {
  const result = await api.runtime.sendMessage(message);
  if (!result || result.error) throw Error(result?.error || "storageFailed");
  return result.value;
}
function notice(error, retry) {
  const box = $("notice");
  box.replaceChildren(node("span", {}, t(error.message || error)));
  if (retry) box.append(button(t("tryAgain"), "retry", retry));
  box.append(
    button(t("close"), "close", () => (box.hidden = true), "icon ghost"),
  );
  box.hidden = false;
}
function safe(fn) {
  return async (...args) => {
    try {
      await fn(...args);
    } catch (e) {
      notice(e);
    }
  };
}
function applyTheme() {
  locale =
    prefs.language === "system"
      ? navigator.language.split("-")[0] in catalogs
        ? navigator.language.split("-")[0]
        : "en"
      : prefs.language;
  document.documentElement.lang = locale;
  const dark =
    prefs.appearance === "dark" ||
    (prefs.appearance === "system" &&
      matchMedia("(prefers-color-scheme: dark)").matches);
  document.body.classList.toggle("dark", dark);
  document.body.classList.toggle("solid", prefs.reduceTransparency);
  document.documentElement.style.setProperty(
    "--accent",
    accents[prefs.accentColor][dark ? 1 : 0],
  );
  document.documentElement.style.setProperty(
    "--reader-font",
    JSON.stringify(fonts[prefs.readingFont][0]),
  );
  document.documentElement.style.setProperty(
    "--reader-size",
    prefs.fontSize + "px",
  );
  $("logo").src = "assets/logo-" + (dark ? "paper" : "ink") + ".svg";
}
async function refresh() {
  const result = await rpc({ type: "init" });
  library = result.library;
  prefs = result.settings;
  applyTheme();
}
async function updateSettings(patch) {
  prefs = await rpc({ type: "settings", patch });
  applyTheme();
  player?.configure(prefs);
  if (view === "settings") renderSettings();
  else if (view === "read") renderWord();
  renderNav();
}
function renderNav() {
  $("nav").replaceChildren(
    ...["home", "read", "saved", "settings"].map((key) =>
      button(
        t(key),
        key,
        safe(() => navigate(key)),
        key === view ? "active" : "",
      ),
    ),
  );
  for (const b of $("nav").children)
    if (b.classList.contains("active")) b.setAttribute("aria-current", "page");
}
function persist(force = false) {
  if (!current || !player) return Promise.resolve();
  const now = performance.now();
  if (!force && now - lastSave < 1000) return saving;
  lastSave = now;
  const snapshot = {
    type: "progress",
    id: current.id,
    owner: current.owner,
    position: player.position,
  };
  current.position = player.position;
  saving = saving.then(async () => {
    try {
      await rpc(snapshot);
      saveFailed = false;
    } catch (e) {
      if (!saveFailed) {
        saveFailed = true;
        player?.pause();
        notice(e, () => persist(true));
      }
    }
  });
  return saving;
}
async function navigate(next) {
  player?.pause();
  await persist(true);
  view = next;
  document.body.classList.remove("playing");
  document.body.classList.toggle("reader-mode", next === "read");
  $("main").className = "";
  renderNav();
  if (next === "home" || next === "saved") {
    await refresh();
    renderLibrary(next === "saved");
  } else if (next === "settings") renderSettings();
  else if (current) renderReader();
  else if (library.length) await openReading(library[0].id);
  else
    $("main").replaceChildren(
      node("h1", {}, t("read")),
      node("p", { class: "empty" }, t("addReadingToBegin")),
      button(t("addText"), "plus", addDialog, "primary"),
    );
}
async function openReading(id, auto = false, position) {
  player?.pause();
  await persist(true);
  openingId = id;
  let doc;
  try {
    doc = await rpc({ type: "open", id });
  } finally {
    openingId = null;
  }
  current = doc;
  $("notice").hidden = true;
  history.replaceState(null, "", "?id=" + id);
  player?.dispose();
  player = new Playback(
    tokenize(doc.text),
    prefs,
    position ?? doc.position,
    () => {
      renderWord();
      persist(!player.playing);
    },
  );
  view = "read";
  renderNav();
  document.body.classList.add("reader-mode");
  renderReader();
  await document.fonts.load(
    `500 ${prefs.fontSize}px "${fonts[prefs.readingFont][0]}"`,
  );
  renderWord();
  if (auto && !document.hidden) player.play();
}
function readingRow(doc, bookmark) {
  const progress = Math.round((100 * doc.position) / doc.count);
  const open = button(
    "",
    null,
    safe(() => openReading(doc.id, false, bookmark?.position)),
    "open",
  );
  open.replaceChildren(
    node("strong", {}, doc.title || t("untitledReading")),
    node(
      "small",
      {},
      bookmark
        ? bookmark.word
        : t("wordsCount", { count: doc.count }) +
            " · " +
            t("percentRead", { percent: progress }),
    ),
  );
  const actions = node("div", { class: "row-actions" });
  if (bookmark)
    actions.append(
      button(
        t("removeBookmark"),
        "bookmark",
        safe(async () => {
          await rpc({
            type: "bookmark",
            id: doc.id,
            position: bookmark.position,
          });
          await navigate("saved");
        }),
        "icon active",
      ),
    );
  else {
    actions.append(
      button(
        t(doc.starred ? "unstarTitle" : "starTitle", { title: doc.title }),
        "star",
        safe(async () => {
          await rpc({ type: "star", id: doc.id });
          await navigate(view);
        }),
        "icon " + (doc.starred ? "active" : "ghost"),
      ),
    );
    actions.append(
      button(t("remove"), "remove", () => confirmDelete(doc), "icon ghost"),
    );
  }
  return node("div", { class: "reading-row" }, open, actions);
}
function renderLibrary(saved = false) {
  const main = $("main");
  main.className = "";
  main.replaceChildren(
    node("span", { class: "pill" }, "Phralio / " + t("localLibrary")),
    node("h1", {}, t(saved ? "keepFavorites" : "makeRoom")),
    node("p", { class: "intro" }, t(saved ? "tapStarHint" : "browserIntro")),
  );
  if (!saved)
    main.append(
      node(
        "div",
        { class: "actions" },
        button(t("addText"), "plus", addDialog, "primary"),
        button(t("readClipboard"), "clipboard", safe(readClipboard)),
        button(t("openPage"), "globe", urlDialog),
      ),
    );
  const rows = saved ? library.filter((d) => d.starred) : library;
  main.append(
    node(
      "div",
      { class: "section-head" },
      node("h2", {}, t(saved ? "starred" : "recent")),
      node("small", {}, t("localOnly")),
    ),
  );
  if (rows.length) main.append(...rows.map((d) => readingRow(d)));
  else
    main.append(
      node("p", { class: "empty" }, t(saved ? "starredEmpty" : "getStarted")),
    );
  if (saved) {
    main.append(node("h2", {}, t("bookmarks")));
    const marks = library.flatMap((d) =>
      d.bookmarks.map((b) => readingRow(d, b)),
    );
    main.append(
      ...(marks.length
        ? marks
        : [node("p", { class: "empty" }, t("bookmarkEmpty"))]),
    );
  } else if (!library.length)
    main.append(
      button(
        t("tryShortReading"),
        "read",
        safe(async () => {
          const id = await rpc({
            type: "add",
            reading: { title: t("sampleTitle"), text: t("obSampleText") },
          });
          await openReading(id);
        }),
      ),
    );
}
function dialog(title, ...content) {
  player?.pause();
  $("dialog-content").replaceChildren(
    node(
      "div",
      { class: "dialog-head" },
      node("h2", {}, title),
      button(t("close"), "close", () => $("dialog").close(), "icon ghost"),
    ),
    ...content,
  );
  if (!$("dialog").open) $("dialog").showModal();
}
function confirmDelete(doc) {
  dialog(
    t("remove"),
    node("p", {}, t("deleteConfirm")),
    button(
      t("remove"),
      "remove",
      safe(async () => {
        await rpc({ type: "delete", id: doc.id });
        if (current?.id === doc.id) {
          player?.dispose();
          player = null;
          current = null;
        }
        $("dialog").close();
        await navigate(view === "saved" ? "saved" : "home");
      }),
      "primary",
    ),
  );
}
function addDialog(text = "") {
  if (typeof text !== "string") text = "";
  const title = node("input", {
    id: "input-title",
    type: "text",
    maxlength: 100,
    placeholder: t("giveName"),
  });
  const body = node(
    "textarea",
    { id: "input-text", maxlength: 200000, placeholder: t("pasteHint") },
    text,
  );
  const submit = button(t("saveAndRead"), "play", () => {}, "primary");
  submit.type = "submit";
  const form = node(
    "form",
    {
      onsubmit: safe(async (e) => {
        e.preventDefault();
        submit.disabled = true;
        try {
          const id = await rpc({
            type: "add",
            reading: { title: title.value, text: body.value },
          });
          $("dialog").close();
          await openReading(id, true);
        } finally {
          submit.disabled = false;
        }
      }),
    },
    node("label", { for: "input-title", class: "form-label" }, t("title")),
    title,
    node("label", { for: "input-text", class: "form-label" }, t("yourText")),
    body,
    node("p", { class: "hint" }, t("pasteLimit")),
    node("div", { class: "actions" }, submit),
  );
  dialog(t("addText"), form);
}
async function readClipboard() {
  try {
    if (api.permissions) {
      const granted = await api.permissions.request({
        permissions: ["clipboardRead"],
      });
      if (!granted) {
        addDialog();
        return;
      }
    }
    const text = await navigator.clipboard.readText();
    if (!text.trim()) {
      notice("clipboardEmpty");
      return;
    }
    addDialog(text);
  } catch {
    addDialog();
    notice("clipboardEmpty");
  }
}
function urlDialog() {
  const input = node("input", {
    id: "input-url",
    type: "url",
    required: true,
    placeholder: "https://example.org/article",
  });
  const submit = button(t("openPage"), "globe", () => {}, "primary");
  submit.type = "submit";
  dialog(
    t("openPage"),
    node("p", {}, t("openPageHint")),
    node(
      "form",
      {
        onsubmit: safe(async (e) => {
          e.preventDefault();
          const u = new URL(input.value);
          if (u.protocol !== "https:" || u.username || u.password)
            throw Error("urlReadFailed");
          await api.tabs.create({ url: u.href });
          $("dialog").close();
        }),
      },
      node("label", { for: "input-url", class: "form-label" }, t("pageUrl")),
      input,
      node("div", { class: "actions" }, submit),
    ),
  );
}
function toggle() {
  if (player?.playing) player.pause();
  else player?.play();
}
function renderReader() {
  const main = $("main");
  main.className = "reader-page";
  const star = button(
    t(current.starred ? "unstarTitle" : "starTitle", { title: current.title }),
    "star",
    safe(async () => {
      const result = await rpc({ type: "star", id: current.id });
      current.starred = result.starred;
      renderReader();
    }),
    "icon " + (current.starred ? "active" : "ghost"),
  );
  const mark = button(
    t("bookmarkThisWord"),
    "bookmark",
    safe(async () => {
      if (player.completed) return;
      const result = await rpc({
        type: "bookmark",
        id: current.id,
        position: player.position,
      });
      current.bookmarks = result.bookmarks;
      renderWord();
    }),
    "icon ghost",
  );
  mark.id = "bookmark-control";
  const canvas = node(
    "div",
    {
      class: "canvas",
      id: "canvas",
      tabindex: 0,
      role: "button",
      "aria-label": t("playReading"),
    },
    node("div", { class: "context before", id: "before" }),
    node(
      "div",
      { class: "stage" },
      node("div", { class: "scope" }),
      node(
        "div",
        { class: "word-slot", id: "word-slot" },
        node("div", { class: "word", id: "word", dir: "auto" }),
      ),
      node("div", { id: "reading-image" }),
      node("div", { class: "scope" }),
      node(
        "div",
        {
          class: "progress",
          role: "progressbar",
          id: "progress",
          "aria-label": t("wholeFileProgress"),
          "aria-valuemin": 0,
          "aria-valuemax": 100,
        },
        node("span", { id: "progress-fill" }),
      ),
    ),
    node("div", { class: "context after", id: "after" }),
  );
  let drag = null,
    dragged = false,
    wheel = 0;
  canvas.addEventListener("pointerdown", (e) => {
    if (player.playing) return;
    drag = e.clientY;
    dragged = false;
    canvas.setPointerCapture(e.pointerId);
  });
  canvas.addEventListener("pointermove", (e) => {
    if (drag === null) return;
    const delta = drag - e.clientY;
    if (Math.abs(delta) >= 36) {
      dragged = true;
      player.seek(player.position + Math.trunc(delta / 36));
      drag = e.clientY;
    }
  });
  canvas.addEventListener("pointerup", () => {
    drag = null;
  });
  canvas.addEventListener("pointercancel", () => {
    drag = null;
    dragged = true;
  });
  canvas.addEventListener("click", () => {
    if (!dragged) toggle();
    dragged = false;
  });
  canvas.addEventListener(
    "wheel",
    (e) => {
      e.preventDefault();
      if (player.playing) return;
      wheel +=
        e.deltaY * (e.deltaMode === 1 ? 16 : e.deltaMode === 2 ? 200 : 1);
      if (Math.abs(wheel) >= 48) {
        player.seek(player.position + Math.sign(wheel));
        wheel = 0;
      }
    },
    { passive: false },
  );
  const play = button(t("playReading"), "play", toggle, "primary play");
  play.id = "play-control";
  const speed = node("input", {
    id: "speed",
    type: "range",
    min: 100,
    max: 1500,
    step: 10,
    value: prefs.wpm,
    "aria-label": t("readingSpeed"),
    oninput: (e) => {
      prefs = settings({ ...prefs, wpm: Number(e.target.value) });
      player.configure(prefs);
      $("pace-output").textContent = prefs.wpm + " WPM";
    },
    onchange: safe((e) => updateSettings({ wpm: Number(e.target.value) })),
  });
  const seek = node("input", {
    id: "seek",
    class: "seek",
    type: "range",
    min: 0,
    max: player.tokens.length,
    step: 1,
    value: player.position,
    "aria-label": t("readingPosition"),
    oninput: (e) => player.seek(Number(e.target.value)),
  });
  main.replaceChildren(
    node(
      "div",
      { class: "reader-head chrome" },
      node(
        "div",
        {},
        node("h2", {}, current.title || t("untitledReading")),
        node(
          "small",
          { id: "reader-meta" },
          t("wordsCount", { count: current.count }),
        ),
      ),
      node(
        "div",
        { class: "tools" },
        star,
        mark,
        button(t("contents"), "contents", contentsDialog, "icon ghost"),
      ),
    ),
    canvas,
    node(
      "div",
      { class: "reader-controls chrome" },
      node(
        "div",
        { class: "transport" },
        button(
          t("previousSentence"),
          "back",
          () => player.sentence(-1),
          "icon ghost",
        ),
        button(
          t("backTenWords"),
          "left",
          () => player.seek(player.position - 10),
          "icon ghost",
        ),
        play,
        button(
          t("forwardTenWords"),
          "right",
          () => player.seek(player.position + 10),
          "icon ghost",
        ),
        button(
          t("nextSentence"),
          "forward",
          () => player.sentence(1),
          "icon ghost",
        ),
      ),
      node(
        "div",
        { class: "pace" },
        speed,
        node(
          "output",
          { id: "pace-output", for: "speed", class: "stat" },
          prefs.wpm + " WPM",
        ),
      ),
      seek,
      node("p", { class: "hint" }, t("readerHint")),
    ),
  );
  renderWord();
}
function renderWord() {
  if (view !== "read" || !player || !$("word")) return;
  document.body.classList.toggle("playing", player.playing);
  const token = player.tokens[player.position];
  $("canvas").classList.toggle("has-image", token?.text === "\uFFFC");
  const word = $("word");
  word.style.fontSize = prefs.fontSize + "px";
  word.style.transform = "";
  $("word-slot").style.height = prefs.fontSize * 1.25 + "px";
  $("word-slot").hidden = token?.text === "\uFFFC";
  word.replaceChildren();
  $("reading-image").replaceChildren();
  if (token?.text === "\uFFFC") {
    const im = current.images.find((i) => i.position === player.position);
    word.hidden = true;
    $("reading-image").append(
      im?.data
        ? node("img", { src: im.data, alt: im.alt || t("image") })
        : node("p", {}, im?.alt || t("imageUnavailable")),
    );
  } else {
    word.hidden = false;
    const text = token?.text || t("complete");
    const focal = focalIndex(text);
    word.append(
      ...glyphs(text).map((g, i) =>
        node(
          "span",
          {
            class: prefs.highlight && i === focal && token ? "focal" : "",
            "data-anchor": i === focal,
          },
          g,
        ),
      ),
    );
    const bounds = word.getBoundingClientRect();
    const anchor = word.querySelector("[data-anchor]").getBoundingClientRect();
    const x = anchor.left + anchor.width / 2 - bounds.left;
    const y = anchor.top + anchor.height / 2 - bounds.top;
    const reach = Math.max(x, bounds.width - x, 1);
    const scale = Math.min(
      1,
      Math.max(0, $("canvas").clientWidth / 2 - 24) / reach,
    );
    word.style.transform = `translate(${-x * scale}px, ${-y * scale}px) scale(${scale})`;
  }
  $("before").textContent = player.tokens
    .slice(Math.max(0, player.position - 26), player.position)
    .map((x) => (x.text === "\uFFFC" ? "" : x.text))
    .join(" ");
  $("after").textContent = player.completed
    ? t("finishedRestart")
    : player.tokens
        .slice(player.position + 1, player.position + 27)
        .map((x) => (x.text === "\uFFFC" ? "" : x.text))
        .join(" ");
  const progress = (player.position / player.tokens.length) * 100;
  $("progress-fill").style.width = progress + "%";
  $("progress").setAttribute("aria-valuenow", String(Math.round(progress)));
  $("seek").value = player.position;
  const saved = current.bookmarks.some((b) => b.position === player.position);
  $("bookmark-control").classList.toggle("active", saved);
  $("bookmark-control").setAttribute(
    "aria-label",
    t(saved ? "removeBookmark" : "bookmarkThisWord"),
  );
  $("bookmark-control").title = t(
    saved ? "removeBookmark" : "bookmarkThisWord",
  );
  $("bookmark-control").disabled = player.completed;
  $("canvas").setAttribute(
    "aria-label",
    t(player.playing ? "pauseReading" : "playReading"),
  );
  const play = $("play-control");
  play.replaceChildren(createElement(icons[player.playing ? "pause" : "play"]));
  play.setAttribute(
    "aria-label",
    t(player.playing ? "pauseReading" : "playReading"),
  );
  play.title = play.getAttribute("aria-label");
}
function contentsDialog() {
  dialog(
    t("contents"),
    ...(current.headings.length
      ? current.headings.map((h) =>
          button(
            h.title,
            null,
            () => {
              player.seek(h.position);
              $("dialog").close();
            },
            "contents-row",
          ),
        )
      : [node("p", { class: "muted" }, t("noHeadings"))]),
    ...(current.url
      ? [
          node(
            "p",
            { class: "source-link" },
            node(
              "a",
              {
                href: current.url,
                target: "_blank",
                rel: "noreferrer noopener",
              },
              t("sourcePage"),
            ),
          ),
        ]
      : []),
  );
}
function selectSetting(key, label, choices, hint) {
  const select = node(
    "select",
    {
      "aria-label": t(label),
      onchange: safe((e) => updateSettings({ [key]: e.target.value })),
    },
    choices.map(([value, text]) =>
      node("option", { value, selected: prefs[key] === value }, text),
    ),
  );
  const chevron = createElement(ChevronDown);
  chevron.setAttribute("aria-hidden", "true");
  return settingRow(
    label,
    node("div", { class: "select-control" }, select, chevron),
    hint,
  );
}
function settingRow(label, control, hint) {
  return node(
    "div",
    { class: "setting" },
    node(
      "div",
      {},
      node("label", {}, t(label)),
      hint ? node("p", {}, t(hint)) : null,
    ),
    control,
  );
}
function numberSetting(key, label, min, max) {
  return settingRow(
    label,
    node("input", {
      type: "number",
      min,
      max,
      value: prefs[key],
      "aria-label": t(label),
      onchange: safe(async (e) => {
        if (!e.target.checkValidity()) {
          e.target.reportValidity();
          return;
        }
        await updateSettings({ [key]: Number(e.target.value) });
      }),
    }),
  );
}
function toggleSetting(key, label, hint) {
  return settingRow(
    label,
    node("input", {
      type: "checkbox",
      checked: prefs[key],
      "aria-label": t(label),
      onchange: safe((e) => updateSettings({ [key]: e.target.checked })),
    }),
    hint,
  );
}
function renderSettings() {
  const main = $("main");
  main.className = "settings-page";
  main.replaceChildren(
    node("h1", {}, t("findCadence")),
    node("p", { class: "intro" }, t("comfortablePace")),
    node("h2", {}, t("readerSettings")),
    numberSetting("wpm", "readingSpeed", 100, 1500),
    selectSetting(
      "pauses",
      "smartPauses",
      ["off", "normal", "strong"].map((x) => [x, t(x)]),
      "smartPausesHint",
    ),
    selectSetting(
      "readingFont",
      "readingFont",
      Object.entries(fonts).map(([id, [name]]) => [id, name]),
    ),
    numberSetting("fontSize", "typeSize", 24, 72),
    toggleSetting("highlight", "highlightFocal"),
    numberSetting("imageSeconds", "imageDuration", 1, 60),
    node("p", { class: "hint" }, t("imagePrivacy")),
    node("h2", {}, t("appearance")),
    selectSetting(
      "appearance",
      "appearance",
      ["system", "light", "dark"].map((x) => [x, t(x)]),
    ),
    selectSetting(
      "accentColor",
      "accentColor",
      Object.keys(accents).map((x) => [
        x,
        t("accent" + x[0].toUpperCase() + x.slice(1)),
      ]),
    ),
    toggleSetting(
      "reduceTransparency",
      "reduceTransparency",
      "solidControlsHint",
    ),
    selectSetting("language", "language", [
      ["system", t("deviceLanguage")],
      ...Object.entries({
        en: "English",
        ru: "Русский",
        es: "Español",
        pt: "Português",
        zh: "简体中文",
        ja: "日本語",
        pl: "Polski",
        de: "Deutsch",
        fr: "Français",
        it: "Italiano",
      }),
    ]),
    node("h2", {}, t("localLibrary")),
    node("p", { class: "muted" }, t("browserPrivacy")),
    node("h2", {}, t("shortcuts")),
    node("p", { class: "muted" }, t("shortcutHint")),
    node(
      "div",
      { class: "actions" },
      button(t("tourTitle"), "read", helpDialog),
      button(t("licenses"), "contents", safe(licensesDialog)),
    ),
  );
}
function helpDialog() {
  dialog(
    t("tourTitle"),
    node("h2", {}, t("getStarted")),
    node("p", {}, t("openPageHint")),
    node("h2", {}, t("obReadTitle")),
    node("p", {}, t("readerHint")),
    node("p", {}, t("shortcutHint")),
    node("h2", {}, t("obSaveTitle")),
    node("p", {}, t("obNavSaved")),
    node("p", {}, t("browserPrivacy")),
    button(
      t("tryShortReading"),
      "play",
      safe(async () => {
        const id = await rpc({
          type: "add",
          reading: { title: t("sampleTitle"), text: t("obSampleText") },
        });
        $("dialog").close();
        await openReading(id);
      }),
      "primary",
    ),
  );
}
async function licensesDialog() {
  const names = [
    "IBMPlexSans",
    "Newsreader",
    "Inter",
    "Roboto",
    "OpenSans",
    "Montserrat",
    "NunitoSans",
    "Merriweather",
    "SourceSans3",
    "NotoSans",
  ];
  const files = [
    ...names.map((n) => "fonts/" + n + "-OFL.txt"),
    "licenses/lucide.txt",
    "licenses/readability.txt",
  ];
  const texts = await Promise.all(
    files.map(async (p) => ({ name: p, text: await (await fetch(p)).text() })),
  );
  dialog(
    t("licenses"),
    ...texts.map((f) =>
      node(
        "details",
        {},
        node("summary", {}, f.name),
        node("pre", { class: "license" }, f.text),
      ),
    ),
  );
}
$("brand").addEventListener(
  "click",
  safe(async (e) => {
    e.preventDefault();
    await navigate("home");
  }),
);
window.addEventListener("resize", renderWord);
document.fonts.addEventListener("loadingdone", renderWord);
matchMedia("(prefers-color-scheme: dark)").addEventListener(
  "change",
  applyTheme,
);
window.addEventListener("blur", () => {
  player?.pause();
  persist(true);
});
document.addEventListener("visibilitychange", () => {
  if (document.hidden) {
    player?.pause();
    persist(true);
  }
});
window.addEventListener("pagehide", () => {
  player?.pause();
  persist(true);
});
window.addEventListener("keydown", (e) => {
  if (
    $("dialog").open ||
    ["INPUT", "TEXTAREA", "SELECT", "BUTTON", "A"].includes(e.target.tagName) ||
    view !== "read" ||
    !player
  )
    return;
  if (e.code === "Space") {
    e.preventDefault();
    toggle();
  } else if (["ArrowLeft", "ArrowRight"].includes(e.key)) {
    e.preventDefault();
    const dir = e.key === "ArrowLeft" ? -1 : 1;
    e.shiftKey ? player.sentence(dir) : player.seek(player.position + dir);
  } else if (e.key === "Escape") {
    e.preventDefault();
    if (player.playing) player.pause();
    else safe(() => navigate("home"))();
  }
});
api.storage.onChanged.addListener((changes, area) => {
  if (area !== "local") return;
  if (changes.settings) {
    prefs = settings(changes.settings.newValue);
    applyTheme();
    player?.configure(prefs);
    if (view === "settings") renderSettings();
    renderNav();
  }
  const change = current && changes["doc:" + current.id];
  if (
    change &&
    openingId !== current.id &&
    change.newValue?.owner !== current.owner
  ) {
    player?.pause();
    notice("otherReader");
  }
});
(async () => {
  try {
    await refresh();
    const query = new URLSearchParams(location.search);
    if (query.has("id"))
      await openReading(query.get("id"), query.get("play") === "1");
    else await navigate(location.hash === "#settings" ? "settings" : "home");
    if (query.has("error")) notice(query.get("error"));
  } catch (e) {
    await navigate("home").catch(() => {});
    notice(e);
  }
})();
