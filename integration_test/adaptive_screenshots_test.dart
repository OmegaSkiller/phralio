import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:phralio/app/providers.dart';
import 'package:phralio/app/reader_app.dart';
import 'package:phralio/core/settings.dart';
import 'package:phralio/features/library/library_store.dart';
import 'package:phralio/features/library/library_screen.dart';
import 'package:phralio/features/onboarding/onboarding_screen.dart';
import 'package:phralio/features/reader/word_context_view.dart';

import 'controls.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('native adaptive surfaces in both orientations and themes', (
    tester,
  ) async {
    final file = '${await getDatabasesPath()}/adaptive-screenshots.sqlite';
    await deleteDatabase(file);
    final store = await LibraryStore.open(file);
    final id = await store.add('A little more room', sampleText);
    await store.savePosition(await store.document(id), 25);
    const device = String.fromEnvironment(
      'CAPTURE_DEVICE',
      defaultValue: 'device',
    );
    Future<void> launch(Appearance appearance) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            initialSettingsProvider.overrideWithValue(
              ReaderSettings(onboardingComplete: true, appearance: appearance),
            ),
          ],
          child: const ReaderApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      await binding.endOfFrame;
      await binding.takeScreenshot('adaptive/$device-$name');
    }

    try {
      for (final landscape
          in (const bool.fromEnvironment(
                'CAPTURE_LANDSCAPE',
                defaultValue: true,
              )
              ? [false, true]
              : [false])) {
        await SystemChrome.setPreferredOrientations(
          landscape
              ? [DeviceOrientation.landscapeLeft]
              : [DeviceOrientation.portraitUp],
        );
        await launch(Appearance.light);
        if (Platform.isAndroid && !landscape) {
          await binding.convertFlutterSurfaceToImage();
          await tester.pump();
        }
        // Wait for actual platform metrics, not a forced MediaQuery size.
        for (var frames = 0; frames < 120; frames++) {
          final size = tester.view.physicalSize;
          if ((size.width > size.height) == landscape) break;
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(
          tester.view.physicalSize.width > tester.view.physicalSize.height,
          landscape,
        );
        final orientation = landscape ? 'landscape' : 'portrait';
        await capture('$orientation-home-light');
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('open-reading-$id')),
          160,
        );
        await tester.ensureVisible(find.byKey(ValueKey('open-reading-$id')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('open-reading-$id')));
        // Opening an existing book awaits SQLite before pushing its route.
        // A settled frame does not imply that the asynchronous query completed.
        for (
          var frame = 0;
          frame < 120 && find.byType(WordContextView).evaluate().isEmpty;
          frame++
        ) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.pumpAndSettle();
        if (find.byType(WordContextView).evaluate().isEmpty) {
          await capture('$orientation-open-failure');
        }
        expect(find.byType(WordContextView), findsOneWidget);
        await capture('$orientation-reader-light');
        final container = ProviderScope.containerOf(
          tester.element(find.byType(WordContextView)),
        );
        await container
            .read(settingsProvider.notifier)
            .update(
              container
                  .read(settingsProvider)
                  .copyWith(
                    appearance: Appearance.dark,
                    accent: AccentColor.teal,
                  ),
            );
        await capture('$orientation-reader-dark');
        await tester.tap(find.bySemanticsLabel('Play reading'));
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('immersive-reader')), findsOneWidget);
        await capture('$orientation-reader-focus-dark');
        await tester.tap(find.byKey(const ValueKey('immersive-reader')));
        await tester.pumpAndSettle();
        expect((await store.document(id)).position, greaterThan(25));
        await tapIcon(tester, 'Back');
        await tapTab(tester, 'Settings');
        await capture('$orientation-settings-dark');
        expect(tester.takeException(), isNull);
      }
      // The full interactive journey is covered by onboarding_screenshots_test.
      await tester.pumpWidget(const SizedBox.shrink());
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            initialSettingsProvider.overrideWithValue(
              ReaderSettings(appearance: Appearance.light),
            ),
          ],
          child: const ReaderApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);
      await capture('onboarding-welcome');
      await tester.ensureVisible(find.byKey(const ValueKey('tour-next')));
      await tester.tap(find.byKey(const ValueKey('tour-next')));
      await tester.pumpAndSettle();
      await capture('onboarding-read');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
      await deleteDatabase(file);
      await SystemChrome.setPreferredOrientations([]);
    }
  });
}
