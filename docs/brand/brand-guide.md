# Phralio identity

Pronounced **FRAH-lee-oh**. Phrase + folio: a name with room for focused reading
and future document tools. See [naming research](naming-research.md) for the
actual search scope and unresolved legal review.

## Fixed interval

The central stem represents a stable point of attention. Two separated fragments
suggest words before and after it. Keep at least one stem width of clear space.
Use the mark at 24px or larger when possible; its three simple shapes remain
recognizable at 16px. Never add speed lines, gradients or a medical cross join.

Masters: `assets/brand/logo-mark.svg`, `logo-wordmark.svg`, `logo-horizontal.svg`,
`app-icon-source.svg`. The custom path wordmark is artwork, not a bundled font.
Use its single-color shape in petrol on light surfaces, pale mint on dark, or
solid black/white for monochrome. No registered-mark symbol is used.

## Color and typography

`lib/app/design.dart` owns semantic color roles for independently designed light
and dark themes. Light: mineral background #F5F8F8, deep text #152B2B, petrol
accent #006A60. Dark: background #101D1D, text #E6F0ED, mint accent #71DCC4.
Secondary and subtle text remain readable; disabled content has a separate role.
Focal emphasis adds weight as well as color and can be turned off.

UI uses supported native system typography: Cupertino on iOS, Material on Android.
No Apple font files are bundled. Display hierarchy is 34/28, document titles 20,
body 17, secondary 14, labels 12–13; ordinary text respects device scaling.
RSVP defaults to 42 logical pixels (24–72 adjustable), then honors text scaling
and measures the shaped glyph. Only words too wide for the surface are scaled to
fit. UTF-16 source offsets and grapheme clusters preserve composed characters.
Whitespace-delimited scripts are the current tokenizer scope; lexical CJK
segmentation and a general bidi reading policy are future work.

## Interaction

Page spacing 24, control targets 48, reader anchor 42% of available width.
The focal glyph is measured, not padded with spaces or centered as a whole word.
One deliberate selection haptic accompanies play/pause. There is no decorative
motion; native navigation follows platform accessibility preferences.

The reader stays calm while playing: muted document heading, stationary guides,
no flashing transitions. Controls remain reachable. The word semantics are not
a live region: screen readers must not announce 1,500 rapid updates per minute.
Native control labels and ordinary UI scaling are tested; manual VoiceOver and
TalkBack audits remain release work.

## Reproduction

`python3 tool/sync_identity.py` applies display name, package name and separate
Apple/Android application IDs from `tool/identity.json`. Run Dart format afterward.
Android's implementation namespace stays independent of the application ID.
Renaming a Dart package also requires updating package imports explicitly.

`python3 tool/generate_icons.py` uses Pillow 12.3.0 (build tool, not an app dependency)
to rasterize the SVG rectangle master. It generates opaque RGB iOS icon sizes,
legacy Android PNGs, adaptive foreground/background and API 33 themed artwork.
The platform may mask launcher corners; source masters do not bake in a corner mask.
Current Xcode asset catalogs compile these conventional icons. Store submission,
new icon appearance variants and store review have not been validated.
