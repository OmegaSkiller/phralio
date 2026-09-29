# The reading aperture — app review

The current `ios-*` images come from the iPhone 17 simulator on iOS 27 using
synthetic test readings. The startup frames are simctl captures of the normal
app; the other current images come from the integration screenshot flow.
`ios-native-*` and Android images are earlier baselines. These are simulator
renders, not physical-device performance evidence.

## Representative normal-app screens

- [Slash-P startup motion](ios-startup-motion.png)
- [Split-P startup frame](ios-startup-split.png)
- [Split-P startup in dark appearance](ios-startup-split-dark.png)
- [Light Home with native tabs](ios-library.png)
- [Dark Home](ios-library-dark.png)
- [Centered focused word, light](ios-focus-light.png)
- [Centered focused word, AMOLED black](ios-focus-dark.png)
- [Saved bookmark word](ios-saved-dark.png)
- [Settings](ios-settings-light.png)
- [Native tabs with system Increase Contrast enabled](ios-tabs-high-contrast.png)
- [Native tabs with system Reduce Transparency enabled](ios-tabs-reduce-transparency.png)

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
