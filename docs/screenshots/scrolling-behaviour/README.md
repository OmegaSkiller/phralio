# Contextual paused reader

These screenshots show the new paused word-by-word view at word 26 of a synthetic
sample reading. The iPhone 18 Pro simulator is 402×874 logical points; the compact
Android API 36 emulator is 320×640 logical pixels. Both themes were captured by
`integration_test/scrolling_screenshots_test.dart` through the device screenshot
driver. The compact Android page scrolls to reveal its lower controls.

| Theme | iOS | Android |
| --- | --- | --- |
| Paper | [iPhone](ios-light.png) | [Android](android-light.png) |
| Ink | [iPhone](ios-dark.png) | [Android](android-dark.png) |

The reference image guided the large active word and surrounding passage.
Phralio's palette, fixed reading anchor and undecorated canvas remain intact.
