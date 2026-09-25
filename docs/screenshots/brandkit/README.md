# The reading aperture — app review

The `ios-native-*` images are simctl captures of the normal app, operated through
Device Hub. Other files come from the real iOS/Android integration screenshot
runs using synthetic test readings. iOS: 402×874pt, 3×. Android: compact 320×640,
1×. These are simulator renders, not physical-device performance evidence.

## Representative normal-app screens

- [Paper Home](ios-native-home-light.png)
- [Ink Home](ios-native-home-dark.png)
- [Paused reader](ios-native-reader-light.png)
- [Focused reader](ios-native-focus-light.png)
- [Dark Settings](ios-native-settings-dark.png)

## Additional coverage

| State | iOS | Compact Android |
| --- | --- | --- |
| Empty library | [Paper](ios-empty.png) | [Paper](android-empty.png) |
| Add text | [Form](ios-add-text.png) | [Form](android-add-text.png) |
| URL | [Form](ios-url.png) | [Form](android-url.png) |
| Error | [Alert](ios-error.png) | [Alert](android-error.png) |
| Focused reading | [Ink](ios-focus-dark.png) | [Ink](android-focus-dark.png) |
| Paused reading | [Paper](ios-reader.png) | [Paper](android-reader.png) |
| Saved | [Ink](ios-saved-dark.png) | [Ink](android-saved-dark.png) |
| Settings | [Paper](ios-settings-light.png) | [Paper](android-settings-light.png) |
| Language sheet | [Sheet](ios-language-sheet.png) | [Sheet](android-language-sheet.png) |
| Japanese fallback | [Settings](ios-settings-ja.png) | [Settings](android-settings-ja.png) |
| Cyrillic | [Settings](ios-settings-ru.png) | [Settings](android-settings-ru.png) |

At compact sizes, pages scroll beneath the floating navigation; content has
bottom clearance so every row remains reachable. Native-control captures can
include the OS material's dynamic reflections, while the reading canvas stays
opaque and undecorated.
