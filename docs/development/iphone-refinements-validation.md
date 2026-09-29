# iPhone refinements: completion evidence

Verified against the current local `features/onboarding-redesign` worktree on
29 September 2026. This records local implementation and validation, not a
commit, push, store release, or physical-device test.

| Requested behavior | Implementation and evidence |
| --- | --- |
| Horizontally centered reading word | `FocalLayout` centers the complete shaped word. `widget_test.dart` checks all ten fonts, short/long Unicode words and 1×/2×/3× scaling. Fresh [light](../screenshots/brandkit/ios-focus-light.png) and [dark](../screenshots/brandkit/ios-focus-dark.png) iPhone renders confirm the field. |
| Supplied slashing P at startup | `StartupScreen` plays the original bundled vector composition once. Playback bounds are source frames 180–240 at 60 fps, honoring the later request for only 0:03–0:04. Startup tests verify the bounds, one-second duration, completion, skip and reduced motion. [Simulator frames](../screenshots/reader-refinements/README.md) show the excerpt. |
| Native iPhone bottom navigation | `NativeControls.swift` constructs `UITabBar` and `UITabBarItem`, with UIKit selection and appearance. [Current Settings render](../screenshots/brandkit/ios-settings-light.png) shows the native tab bar; the adaptive rail/sidebar remains for larger layouts. |
| Respect device transparency | Native controls observe `reduceTransparencyStatusDidChangeNotification`; the effective solid setting includes `UIAccessibility.isReduceTransparencyEnabled`, Increase Contrast and the app preference. The bar switches to `configureWithOpaqueBackground`. The existing [system Reduce Transparency capture](../screenshots/brandkit/ios-tabs-reduce-transparency.png) was inspected alongside the current implementation; this system toggle was not rerun during the final Saved regression check. |
| Crisp white and AMOLED black; functional accents | `ReaderColors` uses white/black canvases and neutral surfaces; `withAccent` replaces only the accent. All ten palettes pass contrast checks. Fresh screenshots show vibrant focal letters, controls and selected native icons. |
| Swipe left to remove starred readings and bookmarks | Both Saved groups use end-to-start dismissal. The iPhone integration run removes each mark, checks SQLite, and verifies the document text remains. A regression found stale hiding after re-adding a mark; the view now clears dismissal state when refreshed data acknowledges removal. Widget and simulator checks confirm re-added marks appear. |
| Bookmarked word below title | `LibraryStore.bookmarks()` resolves the stored token position; Saved uses that word as the row subtitle. The integration run checks “Reading” at position 6. See the [Saved render](../screenshots/brandkit/ios-saved-dark.png). |
| “Font Size” label | English localization contains the exact requested label; the integration run asserts it appears and “Type size” does not. See Settings above. |
| Smart pauses explanation | The Settings row describes added time for punctuation, paragraphs, numbers and longer words. The current iPhone render and integration assertion verify that explanation. The existing timing policy matches the copy. |

## Final checks

- `flutter analyze`: no issues.
- `flutter test`: 85 tests passed, including the extended Saved regression.
- `flutter drive --driver=test_driver/screenshots.dart --target=integration_test/screenshots_test.dart -d <iPhone-17-simulator>`: passed on iOS 27; refreshed screenshots in `docs/screenshots/brandkit/`.
- `git diff --check`: passed.
- The earlier reader-refinement run verified portrait/landscape, both themes,
  canvas-only word scrolling, playback/pause, saved progress and startup frames.
  The final change affects only Saved dismissal-state reconciliation.
- iOS simulator builds passed after the final fix. macOS release and Android
  debug builds passed during the preceding reader refinement; those two builds
  were not rerun for the final Dart-only Saved correction.

Native tab callbacks are exercised through the integration helper; that helper
does not prove native pointer hit testing. Normal-app native navigation and
system transparency behavior have separate simulator captures. Physical iPhone
hardware, Android runtime and macOS runtime are not part of this final audit.

All pre-existing local work, the onboarding redesign and the separate Reading
Rhythm feature proposal remain in place. No merge, commit, push or release was
performed by this completion audit.
