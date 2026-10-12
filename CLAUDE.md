# Phralio (public Flutter app) - CLAUDE.md

Offline-first RSVP reader (one word at a time, fixed focal letter between scope marks). Flutter, iOS + Android + macOS, ten UI languages. Public repo `OmegaSkiller/phralio`, MPL-2.0 (brand assets under separate TRADEMARKS.md). Owner: OmegaSkiller (ivo@codechameleon.com).
Docs to read first: `README.md`, `DESIGN.md`, `docs/development/{architecture,roadmap,validation,adaptive-platform-plan,native-sharing}.md`, `docs/brand/brand-guide.md`.

## Workspace map (`/Users/omegaskiller/SideProjects/flashread-workspace/`)
The product was first named "Flashread"; repo/folder names (`flashread-workspace`) are legacy. Brand is **Phralio**.
- `phralio/` (this repo): the public app plus `browser-extension/` (Chrome/Firefox/Safari, built with esbuild, own package.json).
- `phralio-site/` (git, branch `redesign`): Astro marketing site, 10 locales. Reads brand from brandkit, copy rules from growth.
- `phralio-growth/` (git, branch `redesign`): PRIVATE marketing/positioning/research docs. Source of truth for voice and offer. No code.
- `phralio-pro/` (git, `main`): private proprietary commercial layer. Depends on this repo, never the reverse (composition boundary, `phralio-pro/docs/composition.md`). Only contracts/tests so far; no PDF/purchasing code.
- Not git, not committed, reference only: `phralio-brandkit/` (approved brand authority: BRAND-GUIDE.md, brand-tokens.css, SVG masters, fonts; also a `.zip`), `phralio-logo-motion/` (Hyperframes + Lottie "slashing P" logo animation, has its own CLAUDE.md), `phralio-ui-saved-swipe/` (a git worktree of this repo on `codex/ui-saved-swipe-delete`, see Branches).

## Commands (from README/pubspec/CI)
- Flutter 3.47.5 / Dart 3.13.4 stable or newer. SDK lives at `/Users/omegaskiller/development/flutter` (the old one in Documents gave "Operation not permitted"; keep PATH pointing to the new one).
- `flutter pub get` (also regenerates the git-ignored l10n Dart files from `lib/l10n/*.arb`), `flutter run [-d macos|<device>]`
- `dart format --output=none --set-exit-if-changed lib test integration_test test_driver`, `flutter analyze`, `flutter test`, `flutter test integration_test -d <device>`
- CI: `.github/workflows/validate.yml` (analysis + tests; runs only on push).
- Screenshots: `flutter drive --driver=test_driver/screenshots.dart --target=integration_test/screenshots_test.dart -d <device-id>` writes `docs/screenshots/app-store/`.
- Optional Umami usage stats compile in only with dart-define values for a script URL and website ID (names in README; never commit values). Off by default and user opt-in.
- Extension: `cd browser-extension && npm run check` (build + node tests + web-ext lint); `npm run safari`, `npm run package`.
- Icons/identity: `tool/generate_icons.py`, `tool/sync_identity.py`, `tool/identity.json`.

## Layout
`lib/app` (shell, tabs, analytics), `lib/core`, `lib/features/{library,onboarding,premium,reader,sharing}`, `lib/l10n` (ten ARBs), `test/`, `integration_test/`, `goldie/`, `apple/` + `ios/` + `macos/` + `android/` (native, incl. Share Extensions), `docs/`.

## Conventions the user repeatedly asked for
- Icons: Lucide everywhere. Dark theme and light theme. Native Apple feel (liquid glass, native bottom nav that respects the transparency setting).
- i18n: all ten languages (en, ru, es, pt, zh, ja, pl, de, fr, it); every new string goes into all ARBs.
- Brand: follow the approved brandkit (split-P mark, Paper #F4F0E7, Ink #182523, Vermilion #BA4A32 as references). App uses white/AMOLED surfaces, ten vibrant accent presets; IBM Plex Sans UI, Newsreader for editorial headings.
- Reader: focal letter must be exactly centered horizontally AND vertically (real text measurement); short scope marks near the focal letter, no underline under the red letter; paused view shows nearby prose but only the text canvas scrolls.
- Never claim speed/comprehension gains: WPM is a comfort control. No ADHD/medical promises.
- Workflow: one feature per branch named `features/<name>`, commit and push when asked, user merges to `main` after review. Ask about branch conflicts instead of resolving silently.
- Screenshots use synthetic text only.

## Current state (as of 12 Oct 2026)
- Branch `features/sharer` (checked out, **no upstream yet**; at same commit as `origin/features/onboarding-redesign`, `d88381a`, which includes the adaptive-guided-reading proposal doc). `main` = `ad443e2` (adaptive onboarding + macOS).
- **Uncommitted work (33 paths): native share-sheet feature** (URLs and supported files into Phralio): `lib/features/sharing/`, iOS/macOS ShareExtension targets, `apple/`, entitlements, Android manifest/MainActivity, `docs/development/native-sharing.md`, tests (`test/sharing_test.dart`, `integration_test/sharing_test.dart`), plus l10n and README edits. Android opens the app directly; iOS/macOS save to a private inbox via App Groups, reviewed on next open. App Group signing setup is required (see native-sharing.md). Do not discard; finish, run analyze/tests, then commit.
- Also uncommitted/new in the same tree: `README.md` edits and screenshots in `docs/screenshots/sharing/`.
- Done earlier (all in git history): brandkit redesign, 10 reading fonts, scrolling word-by-word layout, scope marks and progress, adaptive iPad/macOS layouts, interactive Duolingo-style onboarding, URL/Markdown/EPUB import, bookmarks/contents, Umami opt-in, browser extension (local reading + saved library).
- Separate worktree `phralio-ui-saved-swipe` on `codex/ui-saved-swipe-delete` (pushed, `993067d`): trash icon on red background when swiping a Saved item; not merged to `main`.
- Ideas, not built: `docs/ideas/guided-reading-rhythm.md`; Home-screen quick actions (Resume, Clipboard, Add text, Saved) via `quick_actions` was discussed only.
- Not implemented: conventional page reading, PDF reflow/OCR, purchasing, sync; CJK tokenization (whitespace-based, so Chinese/Japanese prose is not segmented properly). iPad landscape and Android tablet lack full device proof.

## Gotchas
- App Group / signing identifiers for Share Extensions need the user's Apple team; do not invent them. Release signing/notarization not set up.
- Real-device iPhone testing: user installs from Xcode; centering was previously wrong on a physical iPhone, re-verify there.
- Local Android validation uses an isolated `Phralio_API_36` emulator.
- The public marketing site's claims lag this repo; `phralio-growth/research/product-state.md` must be refreshed after meaningful changes.
- Codex automations: none relate to this project.
