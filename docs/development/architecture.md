# Architecture and invariants

The public Flutter application stands alone. Features own their UI and storage
operations. Riverpod composes SQLite, persisted settings and premium capabilities.
There is no private package dependency. Reading needs no network; optional usage
analytics is the only app-initiated request.

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

The focal painter measures the highlighted grapheme's actual shaped selection
box and holds its center at 42% width. Long-word fitting preserves that anchor.
Word/progress stream builders keep frequent updates away from the full page.

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

Native routes/buttons/text fields are Cupertino on Apple and Material on Android.
The shared RSVP surface owns its own visual identity. No router dependency is
needed for the current shallow navigation stack.

The library/appearance update uses schema 2 with a transactional migration from
schema 1. Shelf queries select only metadata, cached word counts, global word
position, stars and format. Full text is loaded and tokenized in a worker isolate
when opened. Imported normalized text has a SHA-256 fingerprint with a unique
index; duplicate imports keep the original position and star. Old pasted copies
retain their separate identities. All migration steps roll back on failure.

`core/file_import.dart` parses TXT and EPUB offline. EPUB container/package XML
locates the manifest; linear spine order becomes one normalized text stream.
Hidden/navigation/script/style content is omitted. No markup is rendered or
executed, no URLs fetched, and no archive paths extracted. Source, inflated ZIP,
per-resource and text limits bound imports. CRC and actual expansion are checked;
reading-content encryption is rejected. Obfuscated fonts do not prevent text
reading. The worker returns normalized text, metadata, word count and fingerprint.
The OS picker grants access only to the file selected by the user.

Appearance is persisted alongside reading settings. Semantic colors resolve from
the active app theme, so explicit dark/light choices override the device setting.
Glass uses clipped Flutter blur with a strong tint; high contrast or the in-app
reduce-transparency setting removes blur. App-owned icons use Lucide. Cupertino
and Material continue to own routes, dialogs, fields and controls.

`app/usage_analytics.dart` owns the Umami `/api/send` wire format and permits
only enum-defined screens, events and import sources. Configuration is compiled
from HTTPS `--dart-define` values; sharing remains off until saved consent is
enabled. The bounded in-memory sender has a three-second timeout and no retries
or persistent queue. Opt-out invalidates queued events and clears the Umami
session cache. Screens call it at navigation boundaries and actions call it after
successful local operations; network failures never affect local reading.
