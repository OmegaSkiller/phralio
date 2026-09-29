# Browser-extension validation — 2026-09-29

## Implemented and tested

- `npm run build`: Chrome, Firefox and Safari Manifest V3 packages.
- `npm test`: 18 passing tests. Timing parity, punctuation/paragraphs/numbers,
  graphemes, pause remainder, speed changes, stalls, restart and seeking;
  extraction, malicious HTML treated as text, form/hidden removal, contents and
  image positions; deduplication, changed-content versions, bookmarks/stars,
  concurrent storage mutations, stale-tab protection, quota failure recovery;
  bundled capture return value and repeated injection; bundled background
  toolbar/autoplay and restricted/private-page handling; untrusted message rejection;
  add → autoplay → pause → seek → bookmark → Saved → reopen → settings persistence;
  ten locale catalogs and browser manifests.
- Firefox `web-ext lint`: **0 errors, 0 notices, 2 warnings**. Both
  `UNSAFE_VAR_ASSIGNMENT` warnings are inside bundled Mozilla Readability, which
  manipulates a detached cloned DOM. The privileged UI never inserts the article's
  HTML, only text nodes and validated local raster data URLs. Warnings are recorded,
  not suppressed; store reviewers may request the upstream source/build explanation.
- `npm` install audit reported 0 known vulnerabilities at install time.
- Xcode macOS and iOS Simulator containing-app + extension builds succeeded with
  `CODE_SIGNING_ALLOWED=NO`. This is compilation evidence, not signing/install proof.

## Installed Chrome test

Phralio was loaded as an unpacked extension into Google Chrome Beta after explicit
user approval. A synthetic article was opened through an ordinary HTTP page.
Clicking Phralio in the actual Extensions menu:

1. Extracted 321 words and excluded fixture navigation/sidebar/footer.
2. Opened the dedicated extension-origin reader and immediately played.
3. Clicking the reading field paused and exposed word context and controls.
4. Star and bookmark persisted; Saved displayed the bookmarked word **little**.
5. Reloading the extension and opening the saved reading restored position **78**.
6. A 240 WPM preference and Light appearance were saved and used by the reader.
7. Contents listed three extracted section headings. Selecting **Room to return**
   sought to **Room**, position **164**, still paused.

Live QA exposed and fixed a collapsed focused canvas and an own-tab storage-change
notification race. The latter has a DOM integration regression test. Final minor
sticky-navigation/landscape spacing changes were verified in the same built UI
through the Chrome preview, rather than another installed-extension reload.

## Browser-rendered UI checks

The separate local preview uses the actual bundled reader code and a local API
shim. It was inspected in Chrome with both appearances, the normal desktop window,
390×844 and 844×390 layouts. Narrow-window playback and click-to-pause worked.
390×844 had no horizontal overflow. At short landscape sizes the controls move
beside the text canvas. Desktop dark/light, narrow paused/focused and landscape
screenshots are in `screenshots/`, clearly named `preview-*`.

The in-app browser's viewport screenshot capture produced inconsistent scaling;
those captures were replaced with normal Chrome captures. No claim about actual
Safari/mobile runtime behavior is based on the preview.

## Outstanding platform checks

- Firefox is not installed here: no actual Firefox toolbar/storage/clipboard run.
- Safari extension not enabled: no live Safari action, permissions or playback test.
  Unsigned-extension support was not enabled automatically.
- Physical iPhone/iPad installation and Safari extension interactions not tested.
- Clipboard permission prompts, cross-origin image capture limits and diverse
  production-site extraction need a broader browser/site acceptance pass.
- No Mozilla signing, Chrome Web Store submission, Apple distribution signing or
  store publication. No Git commit or push was requested or performed.

## Manual acceptance checklist

- Load the browser's package, click Phralio on a public article, verify immediate
  reading with saved pace/font/theme. Pause, resume, seek and use Contents.
- Change every setting; reload the reader and verify persistence. Try all locales,
  long titles, long words, larger browser text, high contrast and reduced motion.
- Star, unstar, bookmark, remove a bookmark and reopen it from Saved. Confirm
  bookmarks display their actual word and deleting a reading removes its marks.
- Close and reopen the reader; verify progress. Open the same reading twice and
  verify the older tab pauses without overwriting the newer tab's position.
- Try a settings/store page, empty page and a page whose extraction fails. Verify
  the error offers a usable Home/Add text path and does not save a blank reading.
- Verify image display and image timing with a same-origin loaded raster; verify
  alt text for an unavailable/cross-origin image without an extra network request.
- Try clipboard permission accepted and declined. Manual paste must remain usable.
- Inspect the network panel: no analytics, remote fonts/code or image downloads.

## Focal alignment and settings spacing follow-up

- Replaced whole-word centering with measured focal-grapheme centering in both
  the shared Flutter painter and the extension. Long words fit the larger side
  around that anchor; disabling highlight does not change the anchor. The browser
  progress bar no longer contributes to the vertically centered stage height.
- Native selects keep native menus, with a Lucide chevron inset 16 px, 16 px
  leading padding and 48 px reserved on the chevron side. App setting rows already
  provide 16 px outer padding and a 12 px gap before their disclosure chevron.
- 19 Flutter tests pass (`widget_test.dart`, `reader_interaction_test.dart`),
  including real bundled-font geometry at widths 240/390/844, text scales 1/2/3,
  Unicode and long words, and highlight on/off. Targeted static analysis passes.
- All 18 extension tests pass, including asymmetric measured-word regression
  assertions at two widths. All three extension bundles rebuilt; Firefox lint
  retains only the two documented upstream Readability warnings.
- The rebuilt local UI preview was inspected in the in-app Chromium browser in
  light/dark appearance. DOM bounds reported zero horizontal/vertical anchor
  error for all ten fonts on the long-word fixture, including highlight disabled.
  Narrow viewport fitting retained the anchor within 0.01 px; viewport screenshot
  scaling is inconsistent here, so only normal desktop screenshots are retained.
- This follow-up did not rerun native device/simulator, installed-extension,
  Firefox or Safari runtime checks. Existing platform evidence above is separate.
