<p align="left"><img src="assets/brand/logo-horizontal.svg" alt="Phralio" width="290"></p>

An offline reading app that gives each word a stable point of attention.
Built with Flutter for iOS and Android, with native navigation and controls.

Phralio presents text one word at a time using RSVP (rapid serial visual
presentation). Its focal character stays in one measured position as words
change. Pace and punctuation pauses are controls for personal comfort, not
promises of faster comprehension.

**Status: offline reader with a local book library.** TXT and DRM-free EPUB
importing, stars, saved positions and explicit light/dark themes are implemented.
Conventional page reading, PDF reflow and purchasing remain later milestones.

<img src="docs/screenshots/ios-library.png" alt="Phralio library on iPhone simulator" width="240"> <img src="docs/screenshots/ios-reader.png" alt="Measured focal word on iPhone simulator" width="240"> <img src="docs/screenshots/ios-reader-dark.png" alt="Reader in dark mode" width="240">

<img src="docs/screenshots/android-library.png" alt="Native Android library" width="200"> <img src="docs/screenshots/android-reader-dark.png" alt="Native Android dark reader on compact display" width="200">

### Read now

- Import TXT or DRM-free EPUB, paste text, or try the original sample reading.
- Browse recent readings or starred favorites; see progress across the whole file.
- Importing identical text again resumes its saved place instead of adding a copy.
- Play, pause, resume, jump ten words, move between sentences or scrub position.
- Adjust 100–1500 WPM live; choose Off, Normal or Strong smart pauses.
- Keep the focal glyph anchored using real text measurement, including composed
  Unicode characters; adjust type size or turn highlighting off.
- Restore document position and settings from local SQLite. Reopening starts paused.
- Choose System, Light or Dark appearance, saved across restarts.
- Lucide icons and restrained glass controls; reduce transparency for solid surfaces.

No account or content upload. Text stays on the device; OS backup behavior
still applies. Optional Umami usage statistics are off by default and only
available in builds configured with an Umami property. They include screen visits
and fixed app actions, never book text, titles, filenames or reading positions.
Paste limit: 200,000 UTF-16 code units. File import: 32 MB source,
64 MB total EPUB expansion, 16 MB per text resource, 2 million text code units.
EPUB imports the main reading order as text; images, original layout and DRM
are unsupported. TXT accepts UTF-8 or BOM-marked UTF-16. Tokenization
is whitespace-based; specialized CJK segmentation is not yet provided.

### Run and test

New to Flutter? Start with the [step-by-step emulator and testing guide](docs/development/quickstart.md).

Use Flutter 3.47.5 stable / Dart 3.13.4 or a compatible newer stable SDK.
Install Xcode for iOS or Android Studio/SDK with an emulator for Android.

```sh
flutter pub get
flutter run
dart format --output=none --set-exit-if-changed lib test integration_test test_driver
flutter analyze
flutter test
flutter test integration_test -d <device-id>
```

See [environment](docs/development/environment.md) and
[validation](docs/development/validation.md) for the actual development setup,
executed checks and remaining release work. GitHub Actions validates formatting,
analysis and tests without privileged secrets. CI execution requires a push.

To enable optional Umami tracking in a build, create a dedicated Umami website
property and supply its HTTPS server URL, website UUID and app hostname:

```sh
flutter run -d <device-id> \
  --dart-define=UMAMI_URL=https://stats.example.org \
  --dart-define=UMAMI_WEBSITE_ID=12345678-1234-1234-1234-123456789abc \
  --dart-define=UMAMI_HOSTNAME=app.example.org
```

Replace all example values with your own. The hostname should match the hostname
configured for that Umami property. In the app, open **Reading settings → Share
usage statistics** to opt in. Builds without these values leave the switch
disabled and send nothing. Analytics delivery is best effort: offline events are
dropped, reading never waits for the server, and opting out stops future sends.

Screenshots use synthetic text and the actual native app renderer. Regenerate:

```sh
flutter drive --driver=test_driver/screenshots.dart --target=integration_test/screenshots_test.dart -d <device-id>
```

### Architecture

Pure Dart tokenization, settings and a monotonic playback engine live in `core`.
Feature folders own library storage, reader UI and premium contracts. Riverpod
injects the SQLite store and capabilities. Narrow stream listeners update the
word and progress surfaces. [Architecture and invariants](docs/development/architecture.md).

The public app builds by itself. The private Pro repository may consume the
public package and supply entitlement/PDF implementations through composition;
public code never imports private source. This milestone contains safe free
contracts, not a working commercial parser or payment system.

### Identity and licensing

Phralio was selected after [preliminary public naming research](docs/brand/naming-research.md).
No material conflicting software use was found in the reviewed sources; this is
not formal legal clearance. Similar-mark findings and search limitations are
recorded. [Brand concepts](docs/brand/brand-concepts.md) and
[brand guide](docs/brand/brand-guide.md) document the original identity.

- Software code: [Mozilla Public License 2.0](LICENSE).
- Third-party components: their [respective licenses](THIRD_PARTY_NOTICES.md).
- Name, logo and product identity: separate [branding terms](TRADEMARKS.md).
- Legal owner is deliberately a centralized placeholder pending owner selection.

Outside contributions and support requests are not currently accepted; see
[CONTRIBUTING](CONTRIBUTING.md). No CLA is required or provided.
[Security/privacy](SECURITY.md) · [Roadmap](docs/development/roadmap.md).
