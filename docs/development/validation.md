# Validation — 25 September 2026

Toolchain: Flutter 3.47.5 / Dart 3.13.4, Xcode 27.0. The SDK location is documented in `environment.md`.

## Passed

- `dart format --output=none --set-exit-if-changed lib test integration_test test_driver`
- `flutter analyze`: no issues.
- `flutter test`: 18 tests. Covers Unicode/source offsets, import rejection,
  punctuation/paragraph/numeric/long-word timing, sentence navigation, completion,
  pause/resume/live speed, long-event-loop stalls, premium denial, SQLite reopening,
  focal measurement, light/dark contrast and enlarged text on narrow screens.
- Timing tests simulate 10,000 words separately at 250, 400, 700, 1000 and 1500 WPM.
  They verify accumulated deadlines against a virtual monotonic clock. This proves
  scheduling arithmetic, not device frame-time performance or comprehension.
- iPhone 18 Pro / iOS 27 simulator: native build and integration test for save,
  playback, pause, seek, back, database close/reopen, restored word, paused
  restoration and licenses. The test uses a separate synthetic database.
- Actual `lib/main.dart` iOS launch with SQLite, observed via simulator capture.
- iOS screenshot driver: library plus light/dark reader captured from native
  rendering and visually reviewed. Fixed an insufficient dark-mode button contrast
  discovered in the first capture. Captures are under `docs/screenshots`.
- Python asset scripts compile; SVG-derived iOS icons are opaque RGB, Android
  includes legacy/adaptive/themed artwork. Native iOS asset compilation passed.
- GitHub API confirms `phralio` public, `phralio-pro` private, both on `main`,
  Issues disabled. Original histories preserved and local origins updated.

## Android

API 36 ARM64 Google APIs emulator (320 × 640 at 160 dpi): debug APK compilation
passed; native integration flow passed, including persisted word restoration and
licenses. A normal `lib/main.dart` debug build was also installed and launched. Initial harness failures exposed missing frame settling after a scroll
and the need to scroll to lazily built list children. Those tests now use actual
scrolling and make missed taps fatal. No taps were forced or warnings suppressed.

Run native device jobs serially from one checkout. Simultaneous iOS/Android test
runs produced debugger discovery/forwarding stalls; the isolated Android run
completed in 21 seconds with all tests passing. This was a local harness/tooling
issue, not evidence of app behavior. Logs remain under ignored `build/`.

Android screenshot driver passed. Library and light/dark reader captures were
visually reviewed. On the compact display the reader scrolls to lower progress
controls; no overflow was observed. A native debug accessibility-transform warning
appeared during screenshot surface conversion. Manual TalkBack testing remains
outstanding. Inspecting the semantics also found missing tap actions on labeled
icon wrappers; those actions are now preserved and asserted by a widget test.

## Limits

No physical-device tests, manual VoiceOver/TalkBack audit, release performance
profiling, store submission or signed distribution. No production signing keys.
Android release builds no longer silently use debug signing. GitHub Actions is
configured but has not run remotely because implementation commits are local.

Conventional page reading and Phase 3 PDF/entitlements remain future
work; OCR and real payments are not implemented. Final legal owner, production
identifiers, private security contact and formal trademark review remain release
requirements. No registered trademark or store readiness is claimed.

Upstream license text is retained verbatim, including its original whitespace;
owned-source whitespace checks pass with the third-party notice directory excluded.


## Library and appearance update

The newer results below supersede the foundation counts above.

- Static analysis and all 32 unit/widget tests pass. Coverage includes TXT encodings and limits,
  EPUB reading order/metadata/hidden content, DRM rejection, bounded expansion
  and CRC checks, schema 1 migration, duplicate import concurrency, stars,
  persisted appearance, numeric progress accessibility and narrow/large-text UI.
- iPhone 18 Pro / iOS 27 and Android API 36: both native integration flows pass.
  Tests cover real SQLite, import parsing, cancellation, stars, theme changes,
  close/reopen and duplicate EPUB restoration. Only the OS file selection is
  substituted in the automated import flow. The real iOS picker was separately
  opened and cancelled through Device Hub, returning to the unchanged library.
- New iOS and Android screenshots cover light/dark library and reader plus dark settings;
  captures use explicit in-app appearance settings and were visually reviewed.
- Icon notices include the Lucide Flutter port and upstream Lucide/Feather
  notices; upstream notices also appear in the normal app's license registry.
- Glass is a Flutter approximation inspired by Apple, not native UIGlassEffect.
  Reduced transparency and high contrast disable blur. No decorative animations
  were added. Manual assistive-technology and physical-device checks remain open.

- Both normal app builds were installed and launched after the integration tests.
  Full real OS-picker file selection still needs a manual check; Android's
  standalone emulator was not controllable through the available UI tool and
  Android Studio did not expose it in Running Devices. The sample EPUB is in
  the emulator's Downloads folder. No picker or accessibility failures were
  suppressed in tests. The automated file flow substitutes only selected files.
