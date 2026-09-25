# Architecture and invariants

The public Flutter application stands alone. Features own their UI and storage
operations. Riverpod composes SQLite, persisted settings and premium capabilities.
There is no private package dependency and no network requirement at runtime.

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

SQLite schema 1 stores original normalized text, title, word position, last-opened
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
