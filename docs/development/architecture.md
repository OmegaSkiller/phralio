# Architecture and invariants

The public Flutter application stands alone. Features own their UI and storage
operations. Riverpod composes SQLite, persisted settings and premium capabilities.
There is no private package dependency. Reading needs no network; optional usage
analytics and user-requested URL/image imports are the only app-initiated requests.

`core/document.dart` tokenizes whitespace-delimited text, preserves source offsets
and validates paste ingestion (nonblank, no NUL, maximum 200,000 UTF-16 code units).
`core/settings.dart` clamps persisted settings to usable ranges.
`core/playback.dart` owns playback without Flutter imports. Position identifies
the currently displayed word; position==length means every word received its dwell.
Pause preserves remaining dwell, live WPM changes preserve its fraction, seeks
pause, replay starts from zero. One cancellable Timer is scheduled against
Stopwatch's monotonic clock. Deadlines accumulate so ordinary dispatch latency
does not accumulate into drift. A long stall pauses on the current word instead
of skipping unread text. Remaining time uses a suffix-duration table.
Image markers are reading units with their own 1–30 second dwell, separate from
word speed.

The focal painter measures the highlighted grapheme's actual shaped selection
box and holds its center at 42% width. Long-word fitting preserves that anchor.
Word/progress stream builders keep frequent updates away from the full page.
The reading font ID is stored in the existing JSON preferences row; missing or
unknown IDs use IBM Plex Sans. Ten licensed font files load from the app bundle.
The choice affects the focused word and paused word list, while the brandkit
continues to own interface typography. Noto Sans and platform fonts supply
missing glyphs; font selection does not change tokenization or playback timing.

The original SQLite schema 1 stored original normalized text, title, word position, last-opened
and a JSON preferences row. Parameterized writes retain text locally. Progress
is checkpointed every 10 words and on pause/seek/lifecycle exit/disposal. Abrupt
process termination can lose up to the last checkpoint; normal restoration starts
paused. Future schema changes require explicit versioned migrations, never silent
reset of the library. Backups are governed by the host OS.

Premium contracts live in `features/premium/capabilities.dart`. A PDF capability
requires both an implementation and entitlement; free defaults deny it. OCR is
only a contract. Private code can override providers and import the public app.
Entitlement and parser implementations are not duplicated into arbitrary widgets.

Flutter routes and fields use Cupertino on Apple and Material on Android.
`app/native_controls.dart` embeds a small UIKit platform-view bridge from
`ios/Runner/NativeControls.swift`: native glass buttons, UIMenu actions and a
floating glass navigation container. Lucide glyphs are rendered from the same
bundled font used by Flutter. A per-view method channel forwards only action IDs;
Dart retains ownership of navigation, reading state and persistence.
Settings use grouped rows and interactive Cupertino sheets (Material sheets on
Android). Native controls update with locale, appearance and transparency changes.
The shared RSVP surface owns its own visual identity. No router dependency is
needed for the current shallow navigation stack.

The library/appearance update uses schema 2 with a transactional migration from
schema 1. Shelf queries select only metadata, cached word counts, global word
position, stars and format. Full text is loaded and tokenized in a worker isolate
when opened. Imported normalized text has a SHA-256 fingerprint with a unique
index; duplicate imports keep the original position and star. Old pasted copies
retain their separate identities. All migration steps roll back on failure.

`core/file_import.dart` parses TXT, Markdown and EPUB offline. EPUB container/package XML
locates the manifest; linear spine order becomes one normalized text stream.
Hidden/navigation/script/style content is omitted. No markup is rendered or
executed by the parser, no URLs fetched inside it, and no archive paths extracted. Source, inflated ZIP,
per-resource and text limits bound imports. CRC and actual expansion are checked;
reading-content encryption is rejected. Obfuscated fonts do not prevent text
reading. The worker returns normalized text, metadata, word count and fingerprint.
The OS picker grants access only to the file selected by the user.

Schema 3 adds heading metadata, bounded image blobs and per-document word
bookmarks without resetting existing libraries. Markdown is parsed to markup and
flattened through the same safe text/heading/image extractor as EPUB.
`core/remote_import.dart` fetches user-requested HTTPS pages with redirect and
byte limits, strips non-reading elements, and stores supported same-site images.
Remote Markdown images are optional; local sibling files are not assumed to be
available through the mobile picker. The four-tab shell owns primary navigation;
the reader owns immersive playback and paused word-by-word browsing.

Appearance is persisted alongside reading settings. Semantic colors resolve from
the active app theme, so explicit dark/light choices override the device setting.
iOS 26+ controls use actual `UIGlassEffect` / `UIButton.Configuration.glass()`.
Older iOS uses UIKit system materials. Android uses the Flutter glass fallback.
Native controls observe the OS Reduce Transparency / Increase Contrast settings;
both implementations also respect the app transparency preference and Flutter
high-contrast setting. Glass is reserved for controls, with opaque reading and
list surfaces. See the root DESIGN.md for the complete visual contract.

Flutter's `gen-l10n` compiles ten ARB catalogs in `lib/l10n` into typed UI
messages. The app follows the device locale by default or applies a saved
`AppLanguage` choice from the existing preferences row; unknown stored values
fall back to the device. iOS declares the supported languages in Info.plist.
Source titles, headings and reading text are never translated automatically.

`app/usage_analytics.dart` owns the Umami `/api/send` wire format and permits
only enum-defined screens, events and import sources. Configuration is compiled
from HTTPS `--dart-define` values; sharing remains off until saved consent is
enabled. The bounded in-memory sender has a three-second timeout and no retries
or persistent queue. Opt-out invalidates queued events and clears the Umami
session cache. Screens call it at navigation boundaries and actions call it after
successful local operations; network failures never affect local reading.

The approved brand palette and type roles live in `app/design.dart`;
`app/theme.dart` applies them to Material, Cupertino and startup recovery.
`ReaderTextField` owns the shared input boundaries/focus treatment. Exact brand
SVGs use flutter_svg and bundled variable TTFs load offline. Newsreader is limited
to library editorial headings. The UIKit bridge registers the same Plex font and
receives semantic colors through its existing configuration channel. These
presentation changes do not alter the engine, importers, schemas or analytics.
