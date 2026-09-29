import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:phralio/app/providers.dart';
import 'package:phralio/app/reader_app.dart';
import 'package:phralio/core/settings.dart';
import 'package:phralio/features/library/library_screen.dart';
import 'package:phralio/features/library/library_store.dart';
import 'package:phralio/features/onboarding/onboarding_screen.dart';
import 'package:phralio/features/reader/word_context_view.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('practice, customize, finish and persist on device', (
    tester,
  ) async {
    final file = '${await getDatabasesPath()}/onboarding-redesign-test.sqlite';
    await deleteDatabase(file);
    final store = await LibraryStore.open(file);
    final existing = await store.add('Existing reading', sampleText);
    await store.savePosition(await store.document(existing), 12);
    const device = String.fromEnvironment(
      'CAPTURE_DEVICE',
      defaultValue: 'iphone',
    );
    Finder key(String name) => find.byKey(ValueKey(name));

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> next() => tap(key('tour-next'));
    Future<void> capture(String name) async {
      // Capture the initial composition, even after an action scrolled into view.
      // Open sheets and the immersive reader retain their own scroll positions.
      if (find
          .byKey(const ValueKey('onboarding-scroll'))
          .evaluate()
          .isNotEmpty) {
        final scroll = tester.widget<SingleChildScrollView>(
          key('onboarding-scroll'),
        );
        scroll.controller!.jumpTo(0);
      }
      await tester.pumpAndSettle();
      await binding.endOfFrame;
      if (const bool.fromEnvironment('CAPTURE_ALL', defaultValue: true) ||
          {
            '00-welcome-light',
            '03-move-dark',
            '10-style-light',
            '10-landscape-dark',
          }.contains(name)) {
        await binding.takeScreenshot('onboarding/$device-$name');
      }
      expect(tester.takeException(), isNull);
    }

    Future<void> rotate(bool landscape) async {
      await SystemChrome.setPreferredOrientations(
        landscape
            ? [DeviceOrientation.landscapeLeft]
            : [DeviceOrientation.portraitUp],
      );
      for (var frame = 0; frame < 120; frame++) {
        final size = tester.view.physicalSize;
        if ((size.width > size.height) == landscape) break;
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(
        tester.view.physicalSize.width > tester.view.physicalSize.height,
        landscape,
      );
    }

    try {
      for (final appearance in [Appearance.light, Appearance.dark]) {
        await rotate(false);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storeProvider.overrideWithValue(store),
              initialSettingsProvider.overrideWithValue(
                ReaderSettings(appearance: appearance),
              ),
            ],
            child: const ReaderApp(),
          ),
        );
        await tester.pumpAndSettle();
        if (Platform.isAndroid && appearance == Appearance.light) {
          await binding.convertFlutterSurfaceToImage();
          await tester.pump();
        }
        final theme = appearance.name;
        await capture('00-welcome-$theme');
        await next();
        await capture('01-read-$theme');
        await tap(key('onboarding-reading-field'));
        expect(key('onboarding-immersive'), findsOneWidget);
        await capture('01-focus-$theme');
        await tap(key('onboarding-reading-field'));
        final paused = tester
            .widget<WordContextView>(find.byType(WordContextView))
            .position;
        await capture('01-paused-$theme');
        expect(
          tester.widget<WordContextView>(find.byType(WordContextView)).position,
          paused,
        );
        await tap(key('onboarding-play'));
        expect(key('onboarding-immersive'), findsOneWidget);
        await tap(key('onboarding-reading-field'));
        await next();
        await tap(key('pace-200'));
        await capture('02-pace-$theme');
        await next();
        await tester.ensureVisible(find.byType(WordContextView));
        await tester.drag(find.byType(WordContextView), const Offset(0, -100));
        await tester.pumpAndSettle();
        expect(
          tester.widget<WordContextView>(find.byType(WordContextView)).position,
          greaterThan(0),
        );
        await capture('03-move-$theme');
        await next();
        await capture('04-sources-$theme');
        await tap(key('source-web'));
        await capture('04-web-sheet-$theme');
        await tap(find.text('Extract sample article'));
        expect(find.text('A little more room'), findsOneWidget);
        await next();
        await tap(find.text('A new perspective'));
        await capture('05-contents-$theme');
        await next();
        await capture('06-images-$theme');
        await tap(key('onboarding-play'));
        await tap(key('onboarding-play'));
        await next();
        await tap(key('practice-star'));
        await tap(key('practice-bookmark'));
        await capture('07-saved-$theme');
        await tester.ensureVisible(key('practice-bookmark-row'));
        await tester.drag(key('practice-bookmark-row'), const Offset(-600, 0));
        await tester.pumpAndSettle();
        expect(key('practice-bookmark-row'), findsNothing);
        await tap(key('practice-bookmark'));
        await next();
        await capture('08-library-$theme');
        await tap(key('practice-resume'));
        await tester.ensureVisible(find.byType(WordContextView));
        await tester.drag(find.byType(WordContextView), const Offset(0, -100));
        await tester.pumpAndSettle();
        final moved = tester
            .widget<WordContextView>(find.byType(WordContextView))
            .position;
        await tap(key('practice-return'));
        await tap(key('practice-resume'));
        expect(
          tester.widget<WordContextView>(find.byType(WordContextView)).position,
          moved,
        );
        await next();
        await tap(find.text('Reading font'));
        await capture('09-font-sheet-$theme');
        await tap(find.text('Merriweather'));
        await capture('09-type-$theme');
        await next();
        await tap(key('appearance-$theme'));
        await capture('10-style-$theme');
        if (appearance == Appearance.dark &&
            const bool.fromEnvironment(
              'CAPTURE_LANDSCAPE',
              defaultValue: true,
            )) {
          await rotate(true);
          await capture('10-landscape-dark');
          await rotate(false);
        }
        await next();
        expect(find.text('10 of 10 steps practiced'), findsOneWidget);
        await capture('11-ready-$theme');
        await next();
        for (
          var frame = 0;
          frame < 120 && find.byType(LibraryScreen).evaluate().isEmpty;
          frame++
        ) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(find.byType(LibraryScreen), findsOneWidget);
        final saved = await store.settings();
        expect(saved.onboardingComplete, true);
        expect(saved.wpm, 200);
        expect(saved.readingFont, ReadingFont.merriweather);
        expect(saved.appearance, appearance);
        expect(saved.shareUsage, false);
        expect((await store.all()).single.position, 12);
        expect(await store.bookmarks(), isEmpty);
      }
      // Recreate the app from persisted settings: no onboarding, no practice data.
      final saved = await store.settings();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            initialSettingsProvider.overrideWithValue(saved),
          ],
          child: const ReaderApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(LibraryScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
      await deleteDatabase(file);
      await SystemChrome.setPreferredOrientations([]);
    }
  });
}
