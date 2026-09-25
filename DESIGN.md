# Phralio design contract

This file governs the `redesign` branch. Read it before changing presentation.
The purpose is a calm, content-first reader with native iOS controls, without
losing the existing reading, import, library, accessibility or language features.

## Reference study — all eight supplied images

1. **Travel / “Where to?”** — A large leading title and one search field establish
   hierarchy. Content is grouped by purpose. The floating rounded tab bar is a
   separate glass layer; its active tab sits inside a quiet pill. Bright color is
   reserved for a few meaningful accents. Do not copy the promotional density.
2. **Luma event feed** — Compact top actions share a single capsule. The feed uses
   aligned thumbnail-and-text rows, subtle separators and muted metadata rather
   than a card around every object. Section headings and whitespace do the work.
   A compact floating glass tab bar overlays content at the bottom.
3. **Podcast player** — One large content object commands attention, followed by
   title, one prominent play action and a small overflow button. Secondary detail
   is subdued. The background takes a restrained tint from content. Playback has
   both a focused view and a compact continuation affordance.
4. **Workout home** — An editorial title, a single featured activity and clear
   section rhythm. Large rounded content containers feel intentional because
   there are few of them. Floating navigation stays visually distinct from the
   content. Avoid copying decorative imagery unrelated to reading.
5. **Shopping home** — Search is a single simple entry point; primary feature
   cards and small aligned rows have distinct hierarchy. Muted background color
   fades into a clean canvas. Glass belongs to navigation, not every content row.
6. **GitHub home** — The strongest reference for library/settings structure:
   grouped inset rows, consistent leading icons, restrained dividers, trailing
   chevrons and section headings. Plus and search are compact top actions.
7. **Simple settings** — A centered sheet title and full-width tappable rows.
   One line per setting, generous touch targets, consistent icons and chevrons.
   Do not introduce the promotional banner or account features we do not have.
8. **Luma settings sheet** — Progressive disclosure in a native-feeling sheet:
   drag handle, clear dismissal, grouped preferences/resources, understated
   section labels and secondary values. Appearance opens a deeper choice instead
   of exposing all options at once. No invented account/social actions.

## Shared patterns to apply

- One clear purpose and dominant action per screen.
- Large, left-aligned screen titles; short section headings; quiet metadata.
- Content laid out in lists with breathing room, not stacks of outlined cards.
- Floating capsule navigation with an obvious selected state and icon + label.
- Native menus and sheets reveal secondary actions only when needed.
- Consistent icon scale, generous round corners, delicate separators.
- Neutral backgrounds with restrained color; no ornamental gradients or fake art.
- Reading content remains the visual focus. Controls are supporting material.

## Non-negotiable constraints

- Preserve Home, Read, Saved and Settings destinations; keep all existing imports
   (TXT, EPUB, Markdown, URL, paste and clipboard), recent/starred items,
   bookmarks, contents navigation, reading position and whole-document progress.
- Preserve tap-to-start/stop, immersive playback, highlighted paused context,
   word-by-word seeking, image display/timing and speed/smart-pause preferences.
- Preserve local SQLite data and existing Riverpod/controller ownership. This is
   a presentation refactor, not a storage or reading-engine replacement.
- Preserve all ten UI languages, device-language selection and saved preferences.
   New visible copy must be localized in all catalogs.
- Preserve optional Umami consent and existing interaction events. Never include
   reading text, filenames, titles, URLs or positions in analytics.
- Use Lucide icons for app-provided iconography, including native controls.
   Platform-owned system affordances (sheet handles, menu selection marks) may
   remain system-rendered.
- On iOS 26+, use actual UIKit/SwiftUI Liquid Glass for native navigation/action
   controls; Flutter blur alone must not be described as native Liquid Glass.
   Older iOS and Android need functional, accessible fallbacks.
- Keep glass in the control layer. Reading text and lists need stable contrast.
   Respect dark mode, increased contrast, reduced transparency and reduced motion.
- Touch targets at least 44pt (prefer 48). Support safe areas, VoiceOver labels,
   keyboard dismissal and larger text without clipping or inaccessible actions.
- No fabricated features, marketing metrics, accounts, stock artwork or paywalls.

## Screen rules

### Home
Large Home title; a compact Add menu groups import, URL, clipboard and paste.
One continuation area when a reading exists, then a clean recent-reading list.
Use source type, progress and title as hierarchy. Star belongs in the row's
secondary actions. Empty state has one Add action and an available sample.

### Read
The current word/context owns the center. Paused chrome includes title, progress,
one play control, compact speed access and an overflow menu for contents,
bookmarks and preferences. Playback hides navigation and all unrelated controls.
Keep seeking available while paused without turning the screen into a dashboard.

### Saved
Use two simple sections for starred readings and bookmarks. Rows open the saved
item or position. Avoid presenting every action as a separate full-size button.

### Settings
An inset grouped list shows one row per preference and its current value. Language,
appearance and pause choices open a picker/menu; avoid grids of option buttons.
Type size and image duration appear in a focused detail sheet. Group reading,
appearance/language and privacy/resources. Keep analytics consent explicit.

## Tokens and restraint

- Base horizontal inset 20–24pt; section gaps 28–32pt; row padding 14–16pt.
- Titles 32–34pt bold, section headings 20–22pt semibold, body 16–17pt,
   secondary labels 13–14pt. Use the bundled IBM Plex Sans and scalable text.
- Primary accent: Brick on Paper and Ember on Ink, used for actions and selection.
- Group radius 22–26pt; floating controls use capsule/circle shapes.
- Main content has no heavy shadows, repeated borders or glass-card nesting.
- Keep explanatory text out of the primary flow unless it helps a decision.

## Acceptance and evidence

Review the actual Home, paused/focused Read, Saved, Settings and preference
pickers on iOS in light/dark appearance. Verify native glass/menu behavior on
iOS 26+ and Android fallback functionality. Run static analysis, existing unit
and interaction tests, and adapt native integration flows to the new interaction
paths. Exercise language changes, large text, persistence, imports, bookmarks
and focus mode. Record evidence and any remaining platform limitations honestly.

## Implemented structure and review notes

The final control bridge is deliberately small: UIKit renders glass navigation,
glass icon buttons and UIMenu; Flutter owns the reading surfaces, grouped rows
and platform sheet routes. The bridge reuses the bundled Lucide font and keeps
native menu/focus state stable when unchanged Dart configuration is rebuilt.

Home imports use +; the reader uses … for secondary actions. Settings values
align at the trailing edge at regular text sizes and move below labels at larger
sizes. A soft scroll-edge fade keeps content beneath the floating tab bar from
competing with its labels. Native transparency accessibility notifications and
the app's solid-controls preference take precedence over the glass treatment.

See docs/development/validation.md for simulator evidence and release checks.

## Approved brandkit implementation — The reading aperture

The approved `../phralio-brandkit/BRAND-GUIDE.md`, SVG masters, TTF fonts and
`brand-tokens.css` now govern the visual identity. The original eight-reference
study above still informs interaction and spacing, not color or logo geometry.

- Exact base tokens: Paper #F4F0E7, Ink #182523, Vermilion #BA4A32,
  Mist #C9D1CB, Brick #A73E2A and Ember #F29C82. Brick/Paper and Ember/Ink
  own functional contrast; Vermilion is not used for small text.
- IBM Plex Sans owns UI, controls, input and reading. Newsreader is reserved
  for editorial library headings; Chinese/Japanese use language-aware system
  fallbacks. Both supplied variable TTFs and OFL notices ship locally.
- Use the supplied split-P SVG assets unchanged. Keep clear space and an empty
  aperture. No logo, texture or decorative animation in the reading field.
- Glass remains native on iOS with palette and type shared from Flutter.
  OS-owned menus retain native presentation. Solid/high-contrast fallbacks stay.
- Platform icons derive from the square master, without baked-in corner masks.
  Android adaptive artwork stays inside its safe zone; splash has light/dark
  surfaces and a still, centered mark.
- Keep the 0.42 focal anchor, glyph-based alignment, timing, seeking, pause/resume,
  engine, SQLite data and privacy contracts unchanged. Only presentation changes.
- Verify actual fonts at phone sizes in both themes, persisted add/read/resume,
  imports/Saved/settings, 2× text, all locales, and native controls. Simulator
  evidence is distinct from physical-device accessibility/performance proof.

Font coverage was checked against the original TTF character maps: Plex covers
the requested Latin and Cyrillic UI scripts; Newsreader lacks Cyrillic and both
fonts lack CJK. Russian editorial headings therefore use Plex. Chinese/Japanese
use language-aware platform fallbacks. Never download fonts at runtime.
