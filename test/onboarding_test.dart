import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phralio/app/design.dart';
import 'package:phralio/app/providers.dart';
import 'package:phralio/app/reader_app.dart';
import 'package:phralio/core/file_import.dart';
import 'package:phralio/core/settings.dart';
import 'package:phralio/features/library/library_screen.dart';
import 'package:phralio/features/library/library_store.dart';
import 'package:phralio/features/onboarding/onboarding_screen.dart';
import 'package:phralio/features/reader/focal_word.dart';
import 'package:phralio/features/reader/word_context_view.dart';
import 'package:phralio/l10n/app_localizations.dart';
import 'package:phralio/l10n/l10n.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Settings extends SettingsController {
  @override
  ReaderSettings build() => ReaderSettings();
  @override
  Future<void> update(ReaderSettings value) async => state = value;
}

void main() {
  sqfliteFfiInit();
  test(
    'legacy preferences bypass onboarding; new and unfinished users see it',
    () {
      expect(ReaderSettings.fromJson({'wpm': 425}).onboardingComplete, true);
      expect(ReaderSettings().onboardingComplete, false);
      expect(
        ReaderSettings.fromJson(ReaderSettings().toJson()).onboardingComplete,
        false,
      );
    },
  );
  test(
    'practice fixtures use real supported file formats and headings',
    () async {
      for (final ext in ['txt', 'md', 'epub']) {
        final reading = FileImport.parse((
          name: 'practice.$ext',
          bytes: await File('assets/onboarding/practice.$ext').readAsBytes(),
        ));
        expect(reading.wordCount, greaterThan(20));
        if (ext != 'txt') {
          expect(reading.headings.length, greaterThanOrEqualTo(2));
        }
      }
    },
  );

  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        150,
        scrollable: find.byType(Scrollable).last,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('traditional first-run tour completes without changing pace', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(_Settings.new),
          libraryProvider.overrideWith((ref) async => []),
        ],
        child: const ReaderApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await tap(tester, find.text('Take a guided tour'));
    await tap(tester, find.text('Start'));
    expect(find.byType(FocalWord), findsNothing);
    for (var i = 0; i < 9; i++) {
      expect(find.text('${i + 1} / 9'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('tour-next')));
    }
    expect(find.byType(LibraryScreen), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LibraryScreen)),
    );
    expect(container.read(settingsProvider).onboardingComplete, true);
    expect(container.read(settingsProvider).wpm, 300);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'interactive practice is isolated; Finish persists chosen appearance only',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final store = await tester.runAsync(
        () => LibraryStore.open(
          inMemoryDatabasePath,
          factory: databaseFactoryFfi,
        ),
      );
      final id = await tester.runAsync(
        () => store!.add('Existing reading', 'One two three four five six.'),
      );
      final document = await tester.runAsync(() => store!.document(id!));
      await tester.runAsync(() => store!.savePosition(document!, 3));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store!),
            libraryProvider.overrideWith((ref) async => []),
          ],
          child: const ReaderApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, find.text('Start'));
      expect(find.text('200 words per minute'), findsOneWidget);
      final initialWord = tester
          .widget<FocalWord>(find.byType(FocalWord))
          .token
          .text;
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester.widget<FocalWord>(find.byType(FocalWord)).token.text,
        initialWord,
        reason: 'Reduced motion disables instructional autoplay',
      );
      await tap(tester, find.byKey(const ValueKey('tour-next')));
      await tap(tester, find.text('Use a sample'));
      await tap(tester, find.widgetWithText(ActionButton, 'Read'));
      expect(find.text('Tried it'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('tour-next')));
      final play = find.widgetWithText(ActionButton, 'Play reading');
      await tap(tester, play);
      await tap(tester, find.widgetWithText(ActionButton, 'Pause reading'));
      await tap(tester, play);
      expect(find.text('Tried it'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('tour-next')));
      await tap(tester, find.byKey(const ValueKey('tour-next')));
      final before = tester
          .widget<WordContextView>(find.byType(WordContextView))
          .position;
      await tester.ensureVisible(find.byType(WordContextView));
      await tester.drag(find.byType(WordContextView), const Offset(0, -72));
      await tester.pumpAndSettle();
      expect(
        tester.widget<WordContextView>(find.byType(WordContextView)).position,
        greaterThan(before),
      );
      await tap(tester, find.byKey(const ValueKey('tour-next')));
      await tap(tester, find.text('Try offline example'));
      expect(find.text('Tried it'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('tour-next')));
      // The file parsers are separately checked above; importing user files uses
      // the same native boundary as the ordinary library.
      await tap(tester, find.byKey(const ValueKey('tour-next')));
      await tap(tester, find.text('Bookmark this word'));
      expect(find.text('Word 3'), findsOneWidget);
      await tap(tester, find.text('Word 3'));
      await tap(tester, find.byKey(const ValueKey('tour-next')));
      await tap(tester, find.text('Dark'));
      await tap(tester, find.text('Teal'));
      await tap(tester, find.text('Reading font'));
      await tap(tester, find.text('Merriweather'));
      expect(await tester.runAsync(store.bookmarks), isEmpty);
      expect((await tester.runAsync(store.all))!.single.position, 3);
      expect(
        (await tester.runAsync(store.settings))!.accent,
        AccentColor.vermilion,
      );
      await tap(tester, find.byKey(const ValueKey('tour-next')));
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      final saved = await tester.runAsync(store.settings);
      expect(saved!.accent, AccentColor.teal);
      expect(saved.appearance, Appearance.dark);
      expect(saved.readingFont, ReadingFont.merriweather);
      expect(saved.wpm, 300);
      expect(saved.shareUsage, false);
      expect(saved.onboardingComplete, true);
      expect((await tester.runAsync(store.all))!.single.id, id);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(store.close);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'every language fits the traditional tour at large text and phone landscape',
    (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final locale in AppLocalizations.supportedLocales) {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              locale: locale,
              localizationsDelegates: appLocalizationDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const OnboardingScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(
          tester.element(find.byType(OnboardingScreen)),
        );
        await tap(tester, find.text(l.tourTraditional));
        await tap(tester, find.text(l.tourStart));
        for (var i = 0; i < 8; i++) {
          await tap(tester, find.byKey(const ValueKey('tour-next')));
          expect(tester.takeException(), isNull, reason: locale.toString());
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
}
