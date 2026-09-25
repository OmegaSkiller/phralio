# Development environment — 25 September 2026

Verified current stable release from Google's official manifest:
Flutter 3.47.5, Dart 3.13.4, stable revision 6a19cca56475dbfba1478ee68d7bd0c2ef891da1.

The preinstalled SDK in Documents could not be read/executed by this process
(macOS returned Operation not permitted, including outside the sandbox).
A separate clean checkout of Flutter's official stable branch was installed at
`/private/tmp/reader-flutter-sdk` for this session. No existing SDK or privacy
settings were modified. This temporary SDK is not a durable project dependency.

`flutter doctor -v` with that checkout passed Android, Xcode, network and device
checks. Its only warning was that PATH still pointed to the inaccessible SDK.
Use a current stable SDK on PATH for normal development.

Xcode 27.0 (27A266a), iOS 27 simulator runtimes, Android SDK 37 / build tools
37.0.0 and emulator 37.1.11 were present. Android licenses were already accepted.
No Android virtual device was listed at inspection. Real-device testing is not
implied by doctor detecting a connected device.

For validation, an isolated `Phralio_API_36` ARM64 Google APIs emulator was created.
Its initial image uses a compact 320 × 640 / 160 dpi display. The first Android build
also installed the Flutter-required NDK 28.2.13676358 and platform 36 through official
SDK tooling. Existing user emulators and SDK installations were not removed.
