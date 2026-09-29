# Phralio onboarding: learn by reading

Branch: `features/onboarding-redesign`. This plan precedes implementation.

## Research and decisions

- [Duolingo iOS walkthrough](https://theuxologist.com/case-studies/habit-forming-within-onboarding): one decision at a time, visible progress, direct practice, immediate feedback, and an anchored Continue action. This is observed interface evidence, not proof of retention or conversion.
- [Apple HIG: Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding): teach through interaction; keep tutorials optional, brief, replayable, and focused; postpone customization; ship samples so downloads never block learning.
- Apply [UX Heuristics](/Users/omegaskiller/.agents/skills/ux-heuristics/SKILL.md) and [iOS HIG Design](/Users/omegaskiller/.agents/skills/ios-hig-design/SKILL.md). Retain the user's IBM Plex Sans, Lucide icons, crisp white/AMOLED themes and functional accents. Those explicit brand choices supersede the skill's SF font/symbol defaults.

Initial heuristic assessment: **6/10 UX**, **7/10 HIG** (design review, not a user study). The highest-severity issue is teaching moving instructions before the reader knows how to pause (severity 3). Format selection before first value, dense multi-action lessons, unrestricted Next without meaningful completion feedback, and incomplete feature coverage are severity 2. Fix with a single paced journey, stationary instructions, one task per step, explicit progress, safe samples, and optional advanced controls.

## Layout contract

- Full-screen optional lesson flow; no app tab bar inside the tutorial.
- Safe-area header: Back (48-point target), honest progress, Skip tour/Close. Welcome also exposes language.
- Left-aligned short heading, one sentence explaining the current task, one generous interactive practice area. Labels and text remain visible; no instructions delivered only as moving words.
- A stable bottom action area contains a checkmark plus factual feedback after the task, the primary Continue button, and Skip this step while a task is incomplete. Success never advances automatically. Back preserves choices and completed work.
- Welcome introduces three groups: Read, Save, Make it yours. No account, goal questionnaire, invented score, streak, marketing opt-in, or notification request.
- Portrait content is bounded to 560 points. At 700 points of usable width, wide/short windows use two columns for instruction and practice. The wide stage is bounded to 960 × 800 points and its action area to 560 points; small windows and large type scroll. The footer joins the scroll flow in very short or high-text-scale windows so it cannot hide the lesson.
- Use existing semantic colors/type, Cupertino/Material controls and native app sheets. Borders and selection checks support the functional accent. No ornamental backgrounds behind reading words.
- Respect text scaling, reduced motion, safe areas, keyboard navigation and system Back. Avoid autoplay; only an explicit Play/Tap starts the existing reading engine. Pause on backgrounding, sheet opening, Back, Skip and completion.

## Screen-by-screen plan and feature coverage

| Screen | Layout and action | Evidence / next state |
| --- | --- | --- |
| Welcome | Split-P, short promise, three lesson groups, language control, Start practice | Opens a paused sample; full scope is ten optional hands-on steps |
| 1. Tap to read | A real centered reading field; tap starts immersive playback; tap again pauses into surrounding text; resume remains available | Confirms pause preserved the word; explains focal letter, scope and whole-reading progress |
| 2. Find your pace | 150/200/300 WPM choices, live preview, optional full speed slider and Off/Normal/Strong pauses | Explicit changes preview immediately; pace is comfort, never an ability score |
| 3. Move through words | Real paused context, vertical swipe, previous/next word, expandable sentence/ten-word/scrub controls | Position updates and task confirms after an actual move |
| 4. Bring something to read | Choose Text, Clipboard, Web or Files; contextual sheet has sample or explicit import action | Real text validation, HTML stripping, TXT/Markdown/DRM-free EPUB parsers; cancellation/errors retain the step; all samples stay local |
| 5. Jump to a section | Three headings from a locally parsed Markdown sample; choose a heading | Reader moves to that heading; explain EPUB/Markdown Contents |
| 6. Give images time | A local sample image embedded in text; 1–60 second viewing duration and Play preview | Existing image timing is exercised; no network needed |
| 7. Keep a favorite place | Star a sample reading and bookmark its current word; miniature Saved rows support swipe-left removal and restore | Bookmark word appears under reading title; separate stars and bookmarks, no real library writes |
| 8. Pick up where you left off | Practice library card with progress; open, move, return, resume; four destination labels explain Home/Read/Saved/Settings | Resume restores the practice position paused; explain automatic local saved progress |
| 9. Make words comfortable | Live word preview, ten bundled font choices, font size, focal-highlight switch | Preview only; preferences save on Finish |
| 10. Make it yours | Light/Dark/System choices, accent picker, language, Reduce Transparency | Immediate local preview; respects device settings; customization is optional |
| Ready | Factual practiced-step count, chosen pace/font/theme summary, local-storage and optional-analytics explanation, Open my library | Save explicitly edited preferences + onboardingComplete; show retry on write failure; replay returns to Settings |

## State and data boundaries

- Replace the old dual-format onboarding. Keep the existing public `OnboardingScreen(replay:)` entry point and `onboardingComplete` migration behavior.
- Keep drafts, demonstration stars/bookmarks/progress and completion flags in the screen's disposable session. Reuse `Playback`, `FocalWord`, `WordContextView`, importers and existing theme/sheet controls.
- Never insert practice documents or marks into SQLite. Finishing merges only edited preferences into the current settings; skipping/closing discards every draft preference. Existing documents, progress and analytics consent remain intact.
- Clipboard is read only after the user presses Paste. The web sample uses local HTML and is identified as offline; a real file is opened only through the existing picker. No network request is needed for the tour.
- Preserve the ten supported locales. No English fallback copy in translated flows. Samples derived from localized copy preserve reading behavior, including existing whitespace tokenization limitations.

## Validation and acceptance

- Test complete first-run flow, real interaction completion, back/skip/replay, settings write failure/retry, draft-only changes, zero practice-library writes, resume position, gesture/scrub/contents, local source parsing and image duration.
- Check all ten locales, both themes, small portrait and short landscape, 2× text, reduced motion and app backgrounding.
- Run formatter, static analysis and full existing tests; build available targets; capture real simulator screens and exercise the complete flow. Separate simulator evidence from physical-device performance/haptics.
- Final heuristic scores and any remaining limitations must be grounded in the implemented UI and validation, not assigned as a claim of user research.

## Implementation and validation record — 29 September 2026

Implemented the complete journey, ten-language copy, source sheets and a local
image example. Removed the old format chooser and traditional-tour branch.
The shared sheet helper accepts a presentation wrapper so draft theme/language
also apply to the sheet chrome. Reading timing, parsers, settings format and
library persistence are unchanged by this task.

- `flutter analyze`: no issues. Formatting and `git diff --check`: passed.
- Full unit/widget suite: **75 passed**. The **11 onboarding tests** were rerun
  after the final tablet layout adjustment and passed. They cover legacy-user
  migration, actual practice actions, SQLite isolation, edited-only preference
  saving, skip/back/replay, save failure/retry, language preview, background
  pause, explicit clipboard access and draft-themed sheet chrome.
- Every step rendered without overflow in all **10 locales**, with **2× text**
  and reduced animation, at **375 × 667 light** and **844 × 390 dark** logical
  sizes. Catalog copy keys and interpolation placeholders match across locales.
- Real iOS 27 simulator journeys: **iPhone 17** (402 × 874), **iPhone 17e**
  (390 × 844), and **iPad Pro 11-inch M5** (834 × 1210), both themes. Phone
  landscape was captured as well. The test exercises read/pause/resume, pace,
  word dragging, article extraction, contents, image preview, bookmarking and
  removal, reopening at the same practice position, font/theme choices, Finish,
  and app recreation from persisted settings. Existing library progress is
  checked before and after; no practice reading or bookmark enters SQLite.
- Real screenshots prompted fixes to welcome-scope visibility, compact preview
  spacing, the phone landscape breakpoint, and oversized tablet action width.
  See the [gallery](../screenshots/onboarding/README.md).
- Final builds passed: `flutter build ios --simulator`, `flutter build macos`
  (release), and `flutter build apk --debug`. Android and macOS were compiled;
  their redesigned onboarding was not interactively device-tested in this task.
- Installed the normal app on iPhone 17 after the integration run and directly
  clicked the native Language, sheet Close and lesson Back controls in Device
  Hub. Each reached the expected screen. Left the simulator at the welcome screen.

### Final heuristic review

**UX: 9/10. HIG: 9/10**, provisional design-review scores, not usability-study
results. No unresolved severity-3 or severity-4 task blockers were found.

Orientation, primary action, visible progress, feedback, recoverable errors,
Back/Skip, and visible touch alternatives pass the UX diagnostic. Search is not
applicable to this bounded tutorial. The remaining severity-2 concern is length:
ten optional lessons fulfill the requested feature coverage, but could feel long
to someone who only wants to paste text. To establish a 10/10 UX result, observe
five first-time readers, then move any consistently skipped advanced material
to contextual help based on their behavior.

Safe areas, platform sheets/controls, themes, touch targets and text scaling pass
the inspected HIG checks. To establish a 10/10 HIG result, verify the remaining
physical-device Dynamic Type, gesture and haptic behavior; simulator tests cannot
establish those qualities. Preserve the user's explicit typography and Lucide
icon direction rather than replacing it with SF defaults.

### Practical limits

- No physical iPhone/iPad run, native-speaker translation review, or user study
  was performed. The tablet runtime disallows programmatic orientation changes;
  tablet landscape is covered by responsive widget logic, not a device capture.
- The web lesson deliberately uses local HTML. Actual URL fetching and native
  file-picker permissions reuse existing app behavior; neither requires network
  or permission prompts to complete onboarding. Clipboard is read only on Paste.
- The tour does not change tokenization. CJK practice uses spaced phrases to
  work with the existing whitespace tokenizer. Bundled TXT/Markdown/EPUB parser
  examples remain English documents; lesson copy is localized.
- All earlier uncommitted work was preserved. A comparison of **49 pre-existing
  tracked patches outside this task's files** found no changes. This task has
  not committed, pushed, merged or released anything.
