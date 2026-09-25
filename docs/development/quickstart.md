# Run and test Phralio on this Mac

These instructions match the setup verified on 25 September 2026. Work in the
public `phralio` folder; the private `phralio-pro` folder is not needed to run the
free app. There are no account, backend or signing-key setup steps for simulators.

## 1. Refresh your terminal

The old Flutter SDK under Documents returned `Operation not permitted`, even when
reading its executable. The verified Flutter 3.47.5 / Dart 3.13.4 SDK now lives at
`/Users/omegaskiller/development/flutter`. The Flutter PATH entry in `~/.zprofile`
was updated, with a backup kept alongside it. The old Documents SDK was left alone.

Open a new terminal tab, or refresh the existing one:

```sh
source ~/.zprofile
rehash
which flutter
flutter --version
```

`which flutter` should print `/Users/omegaskiller/development/flutter/bin/flutter`.
If an IDE terminal still uses the old path, restart the IDE. If its Flutter plugin
asks for the SDK path, select `/Users/omegaskiller/development/flutter` (not `bin`).

Then enter the app folder and download its dependencies:

```sh
cd /Users/omegaskiller/SideProjects/flashread-workspace/phralio
flutter pub get
```

Run the remaining Flutter commands from this folder.

## 2. Run on an iPhone simulator

Your Xcode 27 calls the simulator app **Device Hub**:

```sh
open -a DeviceHub
```

Select **iPhone 18 Pro — Simulator** in its sidebar. If it is stopped, start it
using Device Hub's start control. This is the simulated phone, not the physical
phone with your personal name.

Start the app on that specific simulator:

```sh
flutter run -d F5326375-E5A1-4511-B66D-44D6801B469A
```

Flutter builds the app, installs it and opens it inside the simulated phone.
Leave this terminal running while you use the app. Click and drag in the phone
window as you would tap and swipe a real phone.

The identifier above is this Mac's current iPhone 18 Pro simulator. If you delete
or replace that simulator, run `flutter devices` and copy its new identifier.
On Xcode 26 and earlier the window app was called Simulator; `open -a Simulator`
is the corresponding older command.

## 3. Run on Android

A test emulator called `Phralio_API_36` is already configured:

```sh
flutter emulators --launch Phralio_API_36
```

Wait until its Android home screen appears, then check the running-device list:

```sh
flutter devices
```

When it shows `emulator-5554`, run:

```sh
flutter run -d emulator-5554
```

If the list shows another ID, use that instead. `Phralio_API_36` is the saved
emulator configuration's name; `emulator-5554` is the running device's ID. They
serve different purposes. The configured screen is intentionally compact, so
some reading controls require scrolling.

The emulator can also be launched from Android Studio's Device Manager. The
first build can be slow while tools download; later launches are much quicker.

## 4. Everyday edit/run loop

While `flutter run` owns the terminal, these are single key presses, not shell commands:

| Key | Effect |
| --- | --- |
| `r` | Hot reload: apply most Dart/UI changes while retaining current state. |
| `R` | Hot restart: restart the Dart app; saved SQLite documents remain. |
| `q` | End the Flutter run session. The emulator window may remain open. |

Save edited files before reloading. Native Android/iOS configuration or new plugin
changes may require quitting and running again. You can use a second terminal tab
for commands while the app runs. Start with one platform at a time.

## 5. Try the app manually

1. Tap **Try a short reading**, then open **A little more room** from the library.
2. Play, pause, adjust WPM and use the sentence / ten-word navigation controls.
3. Scroll to the progress slider if needed and move to another point in the text.
4. Return to the library and reopen the reading; it should resume at its saved
   word, paused. Quit and relaunch to check the same behavior across launches.
5. Open Reading settings. Change smart pauses, focal highlighting and type size.
6. Use **Add text** to save your own passage. Empty text should show an error.
7. Check light/dark appearance and larger system text sizes on the simulator.

The first milestone supports pasted text and a sample reading. TXT/EPUB import,
normal reading and PDF/OCR are not implemented yet. WPM is a pacing setting, not
a comprehension score. Emulator data stays local; uninstalling the app or erasing
a simulator removes its local library.

## 6. Automated checks

Quit the interactive run with `q`, then run:

```sh
flutter analyze
flutter test
```

`analyze` checks source-code problems. `test` runs the unit/widget suite; it does
not need a running emulator. The current baseline is 18 passing tests. The suite
checks timing, text parsing, focal alignment, SQLite persistence and UI/accessibility.

For the real device flow, keep the selected simulator/emulator booted and run one
of these commands, then let it finish before starting another device test:

```sh
flutter test integration_test/reader_flow_test.dart -d F5326375-E5A1-4511-B66D-44D6801B469A
```

```sh
flutter test integration_test/reader_flow_test.dart -d emulator-5554
```

This test drives the app automatically: add synthetic text, play/pause, change
position, reopen the database and verify restoration and the license screen. It
uses a separate test database. Do not click the device while the test runs.

Run device tests **serially** from this checkout. Concurrent device jobs caused
local Flutter debugger attachment problems during setup. After an integration
test, run `flutter run -d <device-id>` again to replace its temporary test
entrypoint with the normal app.

To reproduce the documentation screenshots:

```sh
flutter drive --driver=test_driver/screenshots.dart --target=integration_test/screenshots_test.dart -d <device-id>
```

Replace `<device-id>` with the actual ID; do not type the angle brackets literally.
This writes synthetic-data screenshots into `docs/screenshots`.

## Troubleshooting

- `Operation not permitted` mentions the old Documents path: refresh the terminal
  as in step 1 and check `which flutter`; do not run Flutter with sudo.
- `No pubspec.yaml`: you are in the wrong folder; use the full `cd` command above.
- Device missing: open/boot the simulator, wait for its home screen and rerun
  `flutter devices`. Do not select Chrome or macOS for this mobile-only project.
- General setup check: `flutter doctor -v`.
- Packages have newer versions: that notice alone is not an error. The lockfile
  records the versions validated for this milestone; upgrades are a separate task.

Official references: [iOS setup](https://docs.flutter.dev/platform-integration/ios/setup),
[Android setup](https://docs.flutter.dev/platform-integration/android/setup),
[integration tests](https://docs.flutter.dev/testing/integration-tests).

## Import files and test the new library

1. Tap **Import file** and choose a `.txt` or DRM-free `.epub` from the system
   picker. The repository includes original sample files in `test/fixtures`.
   On Android, drag them into the emulator and look in Downloads. On iOS, place
   them in Files using the simulator's Safari downloads or a file provider.
2. Read a few words, pause and tap Back. The shelf shows the whole-file percentage.
3. Tap the star beside the file, then **Starred**. Your reading should appear there.
4. Close and reopen the app. Open the reading: it should resume paused at the same
   word. Import the same file again: it should resume without making a duplicate.
5. Open **Reading settings** and try **Light**, **Dark**, and **System**. Try
   **Reduce transparency** for solid controls. Settings survive an app restart.

EPUB imports text in book order. Pictures, original page layout and DRM are not
supported. TXT supports UTF-8 and BOM-marked UTF-16. Import errors leave your
existing library unchanged. Do not uninstall the app to test restarting:
uninstalling can remove the local database.

Run the added native file/library flow (selecting the file is simulated; parsing,
SQLite, reading and the interface are real):

```sh
flutter test integration_test/library_flow_test.dart -d <device-id>
```
