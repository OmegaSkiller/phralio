# Phralio — The reading aperture

The approved workspace `phralio-brandkit/BRAND-GUIDE.md` supersedes the earlier
Fixed interval concept. Its exact SVG masters, font files and license texts are
copied into the app; the reference folder is unchanged. See [DESIGN.md](../../DESIGN.md)
for the app's screen rules and preservation constraints.

## Palette and typography

`lib/app/design.dart` maps the exact CSS tokens to semantic colors:

| Role | Light | Dark |
| --- | --- | --- |
| Canvas | Paper `#F4F0E7` | Ink `#182523` |
| Text | Ink `#182523` | Paper `#F4F0E7` |
| Actions and focal character | Brick `#A73E2A` | Ember `#F29C82` |
| On action | Paper | Ink |

Mist `#C9D1CB` supplies dark secondary text. Supporting surfaces/separators are
quiet Paper/Ink-derived neutrals. Vermilion `#BA4A32` is retained as a decorative
token, not normal-sized text. Native controls receive semantic colors from Dart;
there is no separate hard-coded native accent palette.

IBM Plex Sans leads the interface and reader. The supplied variable TTF keeps
real weight variation; native tabs explicitly use weight 500. Newsreader is
reserved for library editorial headings with an optical-size axis matching the
heading size. Russian headings use Plex because Newsreader lacks Cyrillic.
Chinese and Japanese use system CJK fallback fonts; user text is never translated.
Both font OFL licenses are bundled and listed in the app's license registry.

## Mark, icons and launch

Use the supplied two-piece split-P SVG masters without alteration. Keep the
aperture empty, preserve the built-in clear space, and never animate the logo.
The Home lockup uses the outlined Newsreader wordmark. The active reading field
contains only the word or document image, with no logo, texture or brand motion.

[Artwork tooling](../../assets/brand/README.md) generates opaque iOS and legacy
Android icons, adaptive/themed Android vectors and static light/dark splash
assets. Platform masks are applied by the OS; the source stays square. Android
adaptive artwork fits the circular safe zone. Splash follows system appearance
until the persisted app preference is loaded. Store submission is separate.

## Interaction and accessibility

Keep 24pt page gutters and 48pt action targets. Native UIKit glass and menus
remain on supported iOS; Android and older iOS keep functional platform fallbacks.
Inputs have a visible boundary and a stronger focus outline. Surfaces honor
dark mode, text scaling, reduced transparency and high contrast. The app adds
no branding animations. OS-owned menus retain system typography and behavior.

The fixed reader anchor is 42% of available width. Shaped glyph measurement,
Unicode graphemes, word fitting, timing, punctuation pauses, seeking and saved
progress are preserved. Focal emphasis combines accent, weight and underline;
turning highlight off removes all three. Text scaling expands the word's paint
area. Whitespace tokenization still does not segment unspaced CJK into words.

Manual physical-device VoiceOver/TalkBack and performance checks remain release
work; simulator rendering and automated semantics tests are separate evidence.
