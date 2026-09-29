import { build } from "esbuild";
import { mkdir, readFile, writeFile, cp, rm } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import sharp from "sharp";
import { fonts, languages } from "../src/core.js";
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
process.chdir(root);
const catalogs = {};
for (const lang of languages) {
  const arb = JSON.parse(await readFile(`../lib/l10n/app_${lang}.arb`, "utf8"));
  catalogs[lang] = Object.fromEntries(
    Object.entries(arb).filter(
      ([k, v]) => !k.startsWith("@") && typeof v === "string",
    ),
  );
}
await writeFile(
  "src/catalogs.js",
  "// Generated from the mobile catalogs. Run npm run build to refresh.\nexport const catalogs=" +
    JSON.stringify(catalogs) +
    ";\n",
);
await mkdir("dist", { recursive: true });
for (const browser of ["chrome", "firefox", "safari"]) {
  const dir = `dist/${browser}`;
  await rm(dir, { recursive: true, force: true });
  await mkdir(dir + "/assets", { recursive: true });
  await mkdir(dir + "/fonts", { recursive: true });
  await mkdir(dir + "/licenses", { recursive: true });
  await build({
    entryPoints: ["src/background.js", "src/reader.js"],
    outdir: dir,
    bundle: true,
    format: "iife",
    target: ["chrome120", "firefox128", "safari17"],
    legalComments: "eof",
  });
  await build({
    entryPoints: ["src/capture.js"],
    outfile: dir + "/capture.js",
    bundle: true,
    format: "iife",
    globalName: "PhralioCapture",
    footer: { js: "PhralioCapture.result;" },
    target: ["chrome120", "firefox128", "safari17"],
    legalComments: "eof",
  });
  for (const file of ["reader.html", "reader.css"])
    await cp("src/" + file, dir + "/" + file);
  for (const file of ["logo-ink.svg", "logo-paper.svg", "favicon.svg"])
    await cp("../assets/brand/" + file, dir + "/assets/" + file);
  for (const [, file] of Object.values(fonts)) {
    for (const suffix of [".ttf", "-OFL.txt"])
      await cp(
        "../assets/fonts/" + file + suffix,
        dir + "/fonts/" + file + suffix,
      );
  }
  const css = Object.values(fonts)
    .map(
      ([name, file]) =>
        `@font-face{font-family:'${name}';src:url('fonts/${file}.ttf') format('truetype');font-weight:100 900;font-style:normal;font-display:swap}`,
    )
    .join("\n");
  await writeFile(dir + "/fonts.css", css);
  await cp("node_modules/lucide/LICENSE", dir + "/licenses/lucide.txt");
  await cp(
    "node_modules/@mozilla/readability/LICENSE.md",
    dir + "/licenses/readability.txt",
  );
  const icons = {};
  for (const size of [16, 32, 48, 128, 256, 512]) {
    icons[size] = `assets/icon-${size}.png`;
    await sharp("../assets/brand/favicon.svg")
      .resize(size, size)
      .png()
      .toFile(dir + "/" + icons[size]);
  }
  const manifest = {
    manifest_version: 3,
    name: "Phralio",
    version: "1.0.0",
    description:
      "Find your reading rhythm. Read webpages with your pace, fonts and saved places.",
    permissions: ["activeTab", "scripting", "storage"],
    optional_permissions: ["clipboardRead"],
    action: { default_title: "Read with Phralio", default_icon: icons },
    icons,
    options_ui: { page: "reader.html#settings", open_in_tab: true },
    content_security_policy: {
      extension_pages:
        "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; font-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'",
    },
  };
  if (browser === "chrome") {
    manifest.background = { service_worker: "background.js" };
    manifest.minimum_chrome_version = "120";
  } else {
    manifest.background = { scripts: ["background.js"], persistent: false };
    if (browser === "safari") delete manifest.options_ui.open_in_tab;
    if (browser === "firefox")
      manifest.browser_specific_settings = {
        gecko: {
          id: "phralio-browser@phralio.app",
          strict_min_version: "142.0",
          data_collection_permissions: { required: ["none"] },
        },
      };
  }
  await writeFile(
    dir + "/manifest.json",
    JSON.stringify(manifest, null, 2) + "\n",
  );
}
console.log("Built Chrome, Firefox and Safari extension packages in dist/.");
