# Reader refinements — 29 September 2026

Real iPhone 17 simulator renders (iOS 27, 402 × 874 logical points; landscape
874 × 402), captured with `integration_test/reader_refinements_test.dart`.
The test uses an isolated temporary SQLite library and deletes only its own
fixture database. Native menu/button presentation is included in the renders;
Flutter gestures exercise the reading canvas and playback controls.

| Paused reader | Light | AMOLED dark |
| --- | --- | --- |
| Portrait | [View](ios-portrait-light.png) | [View](ios-portrait-dark.png) |
| Landscape | [View](ios-landscape-light.png) | [View](ios-landscape-dark.png) |

Focused playback: [portrait](ios-portrait-focus.png),
[landscape](ios-landscape-focus.png).

Startup excerpt: source time [3.1 s](startup-10.png),
[3.6 s](startup-60.png), [3.9 s](startup-90.png).
The controller is held at those positions for deterministic still capture;
normal playback is separately run to completion. These show the supplied Lottie
export; the reference MP4 and Lottie have some original rendering differences.

Verified on the simulator:

- Title/control drag and wheel input leave chrome and reading position fixed.
- Canvas drag advances a word without moving title or controls.
- Playback, pause and SQLite progress saving work in both orientations.
- Light/dark surfaces and vibrant default accents render correctly.
- Startup loads the source 3–4 second frame range and completes once.

Widget/unit checks additionally cover compact phones (320 × 568), landscape
(640 × 320), tablet (834 × 1194), 2× text, keyboard navigation, all ten accent
contrast pairs, startup skip, and reduced motion. The full suite passed 85 tests;
static analysis passed. iOS simulator, macOS release and Android debug builds
passed. Physical iPhone, Android runtime and macOS runtime were not retested for
this refinement.

Reproduce:

```sh
flutter drive --driver=test_driver/screenshots.dart \
  --target=integration_test/reader_refinements_test.dart -d <iphone-simulator-id>
```
