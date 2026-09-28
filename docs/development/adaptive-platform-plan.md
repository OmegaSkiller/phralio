# Adaptive app, onboarding, and macOS delivery

Branch: `codex/adaptive-onboarding-macos`.

## Requirements and proof

- Tablet portrait and landscape: adapt navigation, content widths, forms, sheets,
  library, saved readings, settings, and reader controls to window constraints.
  Verify native simulator renders, split/resized windows, both themes and large text.
- Phone landscape: keep reading and controls usable in short windows; retain
  fixed focal alignment and all gestures, timing, saved progress, and accessibility.
- Ten accent presets: coordinated light/dark pairs, accessible functional contrast,
  immediate application throughout Flutter and native controls, persisted locally.
- Traditional onboarding: welcome/start plus paste text, playback, pace, scrolling,
  URL, TXT/EPUB/Markdown import, bookmarks, fonts/theme/accent steps.
- Interactive onboarding: same curriculum with an actual 200 WPM welcome reader,
  intentional instructional pauses and actions performed in a replayable practice
  session. Both versions must be available from first-run welcome and Settings.
  Completion is persisted; skipping and reduced-motion/screen-reader paths work.
- macOS: runnable native target, Liquid Glass on supported systems with accessible
  fallback, desktop navigation, sensible resizable windows, native menus, keyboard
  and pointer actions. Verify real file import and local storage/relaunch.
- Preserve ten UI languages, privacy/analytics consent, existing schema, parsing,
  fonts/licenses, focal anchor, engine timing and library data.

## Delivery sequence

1. Adaptive shell/content/reader presentation and palette preference.
2. macOS target and native AppKit control bridge, desktop interactions.
3. Two complete onboarding experiences and localized content.
4. Automated regression checks, builds, real runtime flows and representative
   screenshots. Record exact evidence and unavailable checks here.

## Starting evidence

- Starting checkout was clean `main`, commit `b723c14`.
- Existing iOS target supports phone/tablet orientations but uses phone layouts.
- Current settings are a JSON record in SQLite; additive fields need no schema
  migration. Existing native controls are UIKit-only.
- Official Flutter docs support adding a macOS target and `AppKitView`; native
  view input must be tested because macOS platform-view support has limitations.

## Implemented

- Adaptive tab/rail/sidebar navigation; bounded library, settings and dialogs;
  safe-area-aware phone landscape with separate passage and control panes.
  Compact context preserves the focal word and one surrounding line on each side.
- Ten locally persisted accent pairs: Vermilion, Terracotta, Rose, Plum, Indigo,
  Blue, Teal, Forest, Olive and Ochre. Every functional accent passes 4.5:1 on
  all three surface colors and its action foreground in both themes.
- Traditional and interactive nine-lesson onboarding, translated in all ten
  app languages. The real reader starts explanations at 200 WPM. Practice uses
  the existing parser, playback, picker and typography; library content stays
  isolated. Only completion and explicitly finished appearance choices persist.
  Existing preference records bypass first-run onboarding; replay is in Settings.
- macOS 12+ target with native AppKit navigation/buttons/menus, NSGlassEffectView
  on macOS 26+, older-system visual effects and reduced-transparency fallback.
  Native file selection, sandboxed local SQLite, restored window bounds,
  keyboard shortcuts, pointer scrolling and theme-aware title bar.
- No changes to tokenization, playback engine, timing, focal anchoring or
  library schema. File selection was consolidated for library and onboarding;
  streamed input retains the existing import size boundary.

## Validation record — 28 September 2026

| Check | Result |
| --- | --- |
| Dart formatting and `flutter analyze` | Passed; no analysis issues |
| `flutter test` | 68 tests passed |
| Adaptive regressions | Six viewport sizes including 640 × 320, both tablet orientations, notch-safe rail, accent contrast/persistence, keyboard actions and state during resize |
| Onboarding regressions | Both modes, all ten languages at large text, reduced motion, legacy preferences, isolated practice and finished settings |
| macOS build | Debug and universal release builds passed |
| iOS build | Simulator build passed |
| Android build | Debug APK passed |
| Reader integration | Passed on macOS, iPhone simulator and Android emulator: add/read/pause/seek/reopen/resume and font/license checks |
| Library integration | Passed on macOS: TXT/EPUB parsing, cancellation, stars, theme, deduplication and reopened local storage |
| Native macOS interaction | Real system menu and file chooser imported Markdown; Space/Escape/arrow keys and mouse wheel moved through reading; Cmd+, and Cmd2 navigated correctly |
| macOS restart | Full quit and launch of release build restored the imported reading at word 27 of 45 and its light appearance; dark appearance also updated native title bar and controls |
| Render review | Real iPhone and compact Android portrait/landscape, iPad portrait, and macOS in both themes; onboarding modes captured |
| Screenshot integration | Passed on iPhone, Android and iPad (portrait-only for iPad); real hit-test failures remain fatal |

Apple integration-test helpers invoke the same Dart callbacks as the native
channel because injected Flutter pointers cannot operate UIKit/AppKit menus.
The library integration test substitutes the picker; the separate macOS UI check
uses the actual native chooser. These are distinct levels of proof.

Screenshots and reproduction instructions: [adaptive gallery](../screenshots/adaptive/README.md).

## Remaining validation limits

- iPad landscape: widget layout coverage at 1194 × 834 passed. Actual simulator
  rotation was rejected by iOS 27 windowing (`UISceneErrorDomain` 101), and this
  Xcode installation lacks the Simulator GUI. No real iPad landscape render is
  claimed. Split-window device rendering remains unverified.
- Android tablet: no tablet emulator configured; tablet-size widget coverage only.
- macOS: actual 1120 × 780 content window reviewed, plus automated layout resize
  coverage. Native drag resizing could not be exercised through the UI tool.
- No full VoiceOver/TalkBack walkthrough or older-OS glass-fallback device run.
- No store signing, notarization or distribution. The release app is a local
  development artifact; GitHub Actions runs its checks after a push.

Third-party build diagnostics include file_selector_macos' deprecated
`allowedFileTypes` API and a Gradle native-access warning; neither blocked builds.
