# Phralio browser extensions

Phralio's reader for Chrome, Firefox and Safari. One shared implementation produces
three Manifest V3 packages. Click **Phralio on a webpage** to extract the article,
open a dedicated reader tab and immediately read with your saved preferences.
The original page stays open and unchanged. No file imports are included.

## Try it now

The Chrome extension was loaded and tested locally in **Google Chrome Beta** with
your approval. It is not published in any extension store.

### Chrome / Chromium

1. Open `chrome://extensions`.
2. Turn on **Developer mode**.
3. Choose **Load unpacked** and select this folder's `dist/chrome` directory.
4. In the browser's Extensions menu, pin **Phralio** if desired.
5. Open an ordinary article and click Phralio. Click the word to pause; controls appear.
6. Use **Settings** to change pace, type, theme and other preferences. Your next
   toolbar click uses those choices.

After rebuilding, use **Reload** on Phralio's extension card. Uninstalling the
extension removes its local library; reloading it does not.

### Firefox

Requires Firefox 142 or newer (the manifest uses Mozilla's data-collection declaration).

1. Open `about:debugging#/runtime/this-firefox`.
2. Choose **Load Temporary Add-on**.
3. Select `dist/firefox/manifest.json`.
4. Open an article and click Phralio in the Extensions menu.

Temporary add-ons disappear after Firefox restarts. Persistent installation in
normal Firefox requires Mozilla signing. The ZIP in `artifacts/packages` is an
unsigned development package, not an already-signed installable store release.
Firefox runtime testing remains outstanding on this machine.

### Safari on Mac

Safari needs a containing Apple app; loading the extension directory alone is not enough.
The generated project is `safari/Phralio Browser/Phralio Browser.xcodeproj`.

1. Open that project in Xcode.
2. Choose the **Phralio Browser (macOS)** scheme and **My Mac** destination.
3. Configure Signing & Capabilities for the app and extension. Local development
   may use **Sign to Run Locally**; distribution requires appropriate signing.
4. Run the containing app with Xcode, then enable Phralio in Safari's extension settings.
5. A locally unsigned development extension also needs Safari's **Allow Unsigned
   Extensions** developer option. This setting was **not enabled automatically**.
6. Visit an article and use the Phralio toolbar action. Safari may ask for site
   access; allow the article you chose.

Unsigned macOS and iOS simulator **builds succeeded**. Safari extension enablement
and live playback have **not** been verified. The macOS build is at
`artifacts/safari-macos/Build/Products/Debug/Phralio Browser.app`.

For iPhone/iPad, use **Phralio Browser (iOS)** in Xcode, choose your device and set
an appropriate development team for both targets. Install the containing app,
then enable the extension under Safari's extension settings. The simulator build
is at `artifacts/safari-ios/Build/Products/Debug-iphonesimulator/Phralio Browser.app`;
it cannot be installed on a physical iPhone. Store submission is a separate task.

## What matches the mobile app

- Exact split-P assets, bundled IBM Plex Sans interface, Newsreader editorial
  headings, Lucide icons, ten local reader fonts and all font licenses.
- White light theme, true-black dark reading surface, system appearance, ten
  functional accent colors and reduced-transparency setting.
- English, Russian, Spanish, Portuguese, Chinese, Japanese, Polish, German,
  French and Italian UI, generated from the app catalogs with additional browser copy.
- Pace from 100–1500 WPM, smart pauses (off/normal/strong), focal glyph toggle,
  Font Size from 24–72 and separate image duration from 1–60 seconds.
- Centered word, close vertical scope marks, thin progress line and no visible
  percentage in the reading field. Percentage remains in library rows.
- Click/Space to play and pause. Playback hides controls; pause shows context.
  Only the text canvas handles word-by-word scrolling/dragging.
- Word/sentence navigation, ±10 words, seek slider, heading contents, local
  progress, recent readings, stars and bookmarks with the bookmarked word shown.
- Home, Read, Saved and Settings, text entry, explicit clipboard action,
  source-page link, a short getting-started guide and open-source licenses.

Browser adaptations:

- The reader opens in its own extension tab so website CSS and scripts cannot
  alter its interface. Browser controls use HTML/CSS, **not native Apple Liquid Glass**.
- **Open webpage** opens your HTTPS URL in a browser tab; click Phralio there to
  capture it. This avoids persistent host permission for every website.
- The optional **Read clipboard** action asks for clipboard permission only when
  you choose it. If denied/unavailable, the Add text dialog supports manual paste.
- Library and preferences are separate per browser/profile and from the mobile
  app. There is no automatic device or browser synchronization.
- Analytics are not configured or sent. There is no account or cloud service.
- This does not implement the proposed guided-practice/rewards feature.

## Build and maintain

From this directory, with Node 22+ and npm installed:

```sh
npm ci
npm run check
npm run package
```

`check` builds all targets, runs 18 tests, and runs Firefox's add-on validator.
`package` writes three ZIPs under `artifacts/packages`. Chrome and Firefox ZIPs
contain a manifest at the root. Safari's ZIP contains WebExtension resources,
which still require Apple's containing app.

Generate the Safari project once, on a Mac with Xcode:

```sh
npm run safari
```

Existing projects are preserved; build resources reference `dist/safari` and are
refreshed by `npm run build`. Do not delete a project after adding signing changes
without saving them first. Generated projects and build artifacts are ignored by Git.

For UI development only:

```sh
npm run build
npm run preview
```

Visit `http://127.0.0.1:4318`. This preview uses a browser-API shim and separate
localStorage; it does **not** prove the extension permission/action integration.
A synthetic article is at `/test/fixtures.html` for real toolbar testing.

Sources:

- `src/core.js`: pure settings, tokenization, focal glyph and playback policy.
- `src/extract.js`: Mozilla Readability on a clone, then bounded text/headings/images.
- `src/background.js`: toolbar activation and authenticated extension messaging.
- `src/store.js`: serialized storage mutations and document ownership.
- `src/reader.js`, `reader.css`: UI and presentation; no website HTML insertion.
- `scripts/build.mjs`: manifests, local assets/fonts/licenses and app locales.
- `test/`: timing, extraction, persistence, action/message and DOM integration tests.

Read [DESIGN.md](DESIGN.md) before visual changes. See
[validation](docs/VALIDATION.md) and [screenshots](docs/screenshots/README.md).

## Boundaries and privacy

Only `activeTab`, `scripting`, and `storage` are required. `clipboardRead` is
optional. There are no background page watchers, persistent host permissions,
external messaging endpoints, remote scripts, analytics, remote fonts or remote
image downloads. Page text, headings, images and URLs remain in local extension
storage. Deleting a reading also removes its bookmarks. Browser profile storage
is not an encrypted vault; sensitive/private articles should be treated accordingly.
Private-window captures are refused rather than silently copied into a normal library.

The extractor works on the main page document, removing scripts, forms, hidden
content and common navigation. It cannot read browser settings/store pages,
protected PDFs, cross-origin frames, paywalled content not present on the page,
closed shadow roots, or every bespoke web application. Lazy-loaded text must
already be present. Paste the text when extraction is not appropriate.

Text is limited to 200,000 characters; overly complex pages are rejected. Up to 24
already-loaded images can be copied to local JPEG snapshots if browser canvas
rules allow it, downscaled to 1000×800, with a 1.5 MB aggregate encoded-image budget.
Cross-origin/uncopyable images use alt descriptions, without contacting image hosts.
Browser storage quota errors are visible; old readings are never silently evicted.

Unchanged captures reuse their saved position and marks. Changed article text is
saved separately so old bookmarks do not drift. Multiple tabs serialize writes;
opening the same reading in another tab pauses the older owner. Progress saves
roughly once per second during playback and on pause, navigation or visibility loss;
an abrupt browser/process crash can lose the latest second. A stalled or hidden
reader pauses instead of skipping unread words.

As in the mobile app, tokenization is whitespace-based. CJK UI is translated and
has system font fallbacks, but natural Chinese/Japanese word segmentation is not
implemented, so unspaced text is not a useful WPM measurement.

## Documentation consulted

- [WebExtension background environments](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/manifest.json/background)
- [activeTab permission](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/manifest.json/permissions#activetab_permission)
- [Safari WebExtension packaging](https://developer.apple.com/documentation/safariservices/packaging-a-web-extension-for-safari)
- [Mozilla Readability](https://github.com/mozilla/readability)
- [Reference extension](https://chromewebstore.google.com/detail/speed-reading/ihbdojmggkmjbhfflnchljfkgdhokffj)
