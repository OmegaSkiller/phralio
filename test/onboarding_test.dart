import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  _Settings(this.initial, {this.fail = false});
  final ReaderSettings initial;
  bool fail;
  @override
  ReaderSettings build() => initial;
  @override
  Future<void> update(ReaderSettings value) async {
    if (fail) throw const FileSystemException('Test save failure');
    state = value;
  }
}

Finder key(String value) => find.byKey(ValueKey(value));

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> next(WidgetTester tester) async {
  final button = tester.widget<ActionButton>(key('tour-next'));
  await tap(
    tester,
    button.onPressed == null ? key('tour-skip-step') : key('tour-next'),
  );
}

Future<void> goTo(WidgetTester tester, OnboardingStep step) async {
  for (var i = 0; i < OnboardingStep.values.length; i++) {
    if (key('onboarding-step-${step.name}').evaluate().isNotEmpty) return;
    await next(tester);
  }
  fail('Did not reach $step');
}

Future<void> _launch(WidgetTester tester, _Settings settings) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith(() => settings),
        libraryProvider.overrideWith((ref) async => []),
      ],
      child: const ReaderApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  sqfliteFfiInit();

  test('legacy preferences bypass onboarding; new users see it', () {
    expect(ReaderSettings.fromJson({'wpm': 425}).onboardingComplete, true);
    expect(ReaderSettings().onboardingComplete, false);
    expect(
      ReaderSettings.fromJson(ReaderSettings().toJson()).onboardingComplete,
      false,
    );
  });

  test('practice files use supported parsers and real headings', () async {
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
  });

  testWidgets(
    'hands-on journey teaches real actions and keeps practice out of SQLite',
    (tester) async {
      final store = (await tester.runAsync(
        () => LibraryStore.open(
          inMemoryDatabasePath,
          factory: databaseFactoryFfi,
        ),
      ))!;
      addTearDown(store.close);
      final id = (await tester.runAsync(
        () => store.add('Existing', 'one two three four five six'),
      ))!;
      await tester.runAsync(
        () async => store.savePosition(await store.document(id), 3),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            libraryProvider.overrideWith((ref) async => []),
          ],
          child: const ReaderApp(),
        ),
      );
      await tester.pumpAndSettle();
      await next(tester);
      final initial = tester.widget<FocalWord>(find.byType(FocalWord)).token;
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester.widget<FocalWord>(find.byType(FocalWord)).token,
        initial,
        reason: 'Practice starts only after a deliberate tap',
      );
      expect(tester.widget<ActionButton>(key('tour-next')).onPressed, isNull);
      await tester.tap(key('onboarding-reading-field'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(key('onboarding-immersive'), findsOneWidget);
      expect(key('tour-next'), findsNothing);
      await tester.tap(key('onboarding-reading-field'));
      await tester.pumpAndSettle();
      expect(find.byType(WordContextView), findsOneWidget);
      final paused = tester
          .widget<WordContextView>(find.byType(WordContextView))
          .position;
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester.widget<WordContextView>(find.byType(WordContextView)).position,
        paused,
      );
      await tap(tester, key('onboarding-play'));
      expect(key('onboarding-immersive'), findsOneWidget);
      await tester.tap(key('onboarding-reading-field'));
      await tester.pumpAndSettle();
      await next(tester);
      await tap(tester, key('pace-200'));
      await next(tester);
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
      await next(tester);
      await tap(tester, key('source-text'));
      await tap(tester, find.text('Use a sample'));
      await tap(tester, find.widgetWithText(ActionButton, 'Read'));
      expect(find.text('A little more room'), findsOneWidget);
      await next(tester);
      await tap(tester, find.text('A new perspective'));
      expect(tester.widget<FocalWord>(find.byType(FocalWord)).token.text, 'A');
      await next(tester);
      final imageSlider = find.byType(CupertinoSlider).evaluate().isNotEmpty
          ? find.byType(CupertinoSlider)
          : find.byType(Slider);
      await tester.ensureVisible(imageSlider);
      await tester.tapAt(tester.getTopLeft(imageSlider) + const Offset(28, 10));
      await tester.pumpAndSettle();
      await tap(tester, key('onboarding-play'));
      await tap(tester, key('onboarding-play'));
      await next(tester);
      await tap(tester, key('practice-star'));
      await tap(tester, key('practice-bookmark'));
      expect(key('practice-star-row'), findsOneWidget);
      expect(key('practice-bookmark-row'), findsOneWidget);
      await tester.ensureVisible(key('practice-bookmark-row'));
      await tester.drag(key('practice-bookmark-row'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(key('practice-bookmark-row'), findsNothing);
      await tap(tester, key('practice-bookmark'));
      await tester.ensureVisible(key('practice-star-row'));
      await tester.drag(key('practice-star-row'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(key('practice-star-row'), findsNothing);
      await tap(tester, key('practice-star'));
      await next(tester);
      await tap(tester, key('practice-resume'));
      await tester.ensureVisible(find.byType(WordContextView));
      await tester.drag(find.byType(WordContextView), const Offset(0, -72));
      await tester.pumpAndSettle();
      final position = tester
          .widget<WordContextView>(find.byType(WordContextView))
          .position;
      await tap(tester, key('practice-return'));
      await tap(tester, key('practice-resume'));
      expect(
        tester.widget<WordContextView>(find.byType(WordContextView)).position,
        position,
      );
      await next(tester);
      await tap(tester, find.text('Reading font'));
      await tap(tester, find.text('Merriweather'));
      await next(tester);
      await tap(tester, key('appearance-dark'));
      await tap(tester, find.text('Accent color'));
      await tap(tester, find.text('Teal'));
      await next(tester);
      expect(find.text('10 of 10 steps practiced'), findsOneWidget);
      expect((await tester.runAsync(store.all))!.single.position, 3);
      expect(await tester.runAsync(store.bookmarks), isEmpty);
      expect(
        (await tester.runAsync(store.settings))!.appearance,
        Appearance.system,
      );
      await tap(tester, key('tour-next'));
      await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      final saved = (await tester.runAsync(store.settings))!;
      expect(saved.onboardingComplete, true);
      expect(saved.wpm, 200);
      expect(saved.appearance, Appearance.dark);
      expect(saved.accent, AccentColor.teal);
      expect(saved.readingFont, ReadingFont.merriweather);
      expect(saved.shareUsage, false);
      expect((await tester.runAsync(store.all))!.single.id, id);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('back keeps choices; skipping discards every draft preference', (
    tester,
  ) async {
    final settings = _Settings(ReaderSettings(wpm: 425, shareUsage: true));
    await _launch(tester, settings);
    await goTo(tester, OnboardingStep.pace);
    await tap(tester, key('pace-150'));
    await next(tester);
    await tap(tester, key('tour-back'));
    expect(tester.widget<ActionButton>(key('tour-next')).onPressed, isNotNull);
    expect(find.text('150 words per minute'), findsWidgets);
    await tap(tester, key('tour-exit'));
    expect(find.byType(LibraryScreen), findsOneWidget);
    expect(settings.state.wpm, 425);
    expect(settings.state.shareUsage, true);
    expect(settings.state.onboardingComplete, true);
  });

  testWidgets('save failure keeps choices visible and retry succeeds', (
    tester,
  ) async {
    final settings = _Settings(ReaderSettings(wpm: 425), fail: true);
    await _launch(tester, settings);
    await goTo(tester, OnboardingStep.ready);
    expect(find.text('0 of 10 steps practiced'), findsOneWidget);
    await tap(tester, key('tour-next'));
    expect(
      find.text('Your settings could not be saved. Please try again.'),
      findsOneWidget,
    );
    expect(settings.state.onboardingComplete, false);
    settings.fail = false;
    await tap(tester, key('tour-next'));
    expect(find.byType(LibraryScreen), findsOneWidget);
    expect(settings.state.wpm, 425);
  });

  testWidgets(
    'replay can close mid-lesson without saving and finishes back to its caller',
    (tester) async {
      final settings = _Settings(ReaderSettings(onboardingComplete: true));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [settingsProvider.overrideWith(() => settings)],
          child: MaterialApp(
            localizationsDelegates: appLocalizationDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const OnboardingScreen(replay: true),
                    ),
                  ),
                  child: const Text('Replay'),
                ),
              ),
            ),
          ),
        ),
      );
      await tap(tester, find.text('Replay'));
      await goTo(tester, OnboardingStep.pace);
      await tap(tester, key('pace-150'));
      await tap(tester, key('tour-exit'));
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(settings.state.wpm, 300);
      await tap(tester, find.text('Replay'));
      await goTo(tester, OnboardingStep.ready);
      await tap(tester, key('tour-next'));
      expect(find.byType(OnboardingScreen), findsNothing);
    },
  );

  testWidgets(
    'language previews immediately but skip retains the saved language',
    (tester) async {
      final settings = _Settings(ReaderSettings());
      await _launch(tester, settings);
      await tap(tester, key('onboarding-language'));
      await tap(tester, find.text('Deutsch'));
      expect(find.text('Übung starten'), findsOneWidget);
      expect(settings.state.language, AppLanguage.system);
      await tap(tester, key('tour-exit'));
      expect(settings.state.language, AppLanguage.system);
    },
  );

  testWidgets(
    'backgrounding pauses practice and foregrounding does not autoplay',
    (tester) async {
      await _launch(tester, _Settings(ReaderSettings()));
      await next(tester);
      await tester.tap(key('onboarding-reading-field'));
      await tester.pump();
      expect(key('onboarding-immersive'), findsOneWidget);
      final word = tester.widget<FocalWord>(find.byType(FocalWord)).token;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      // Paused apps do not render frames. Verify the paused UI after resuming.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(key('onboarding-immersive'), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.widget<FocalWord>(find.byType(FocalWord)).token, word);
      expect(
        tester.widget<ActionButton>(key('onboarding-play')).label,
        'Play reading',
      );
    },
  );

  testWidgets(
    'clipboard needs explicit Paste, invalid input recovers, and web extraction is local',
    (tester) async {
      var clipboardReads = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            clipboardReads++;
            return {'text': 'Some words from the clipboard can be read here.'};
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _launch(tester, _Settings(ReaderSettings()));
      await goTo(tester, OnboardingStep.sources);
      await tap(tester, key('source-clipboard'));
      expect(clipboardReads, 0);
      await tap(tester, find.widgetWithText(ActionButton, 'Read'));
      expect(
        tester
            .widget<ActionButton>(find.widgetWithText(ActionButton, 'Read'))
            .onPressed,
        isNotNull,
      );
      expect(
        find.text('Some words from the clipboard can be read here.'),
        findsNothing,
      );
      await tap(tester, find.widgetWithText(ActionButton, 'Paste'));
      expect(clipboardReads, 1);
      await tap(tester, find.widgetWithText(ActionButton, 'Read'));
      expect(
        find.text('Some words from the clipboard can be read here.'),
        findsOneWidget,
      );
      await tap(tester, key('source-web'));
      await tap(tester, find.text('Extract sample article'));
      expect(find.text('A little more room'), findsOneWidget);
      expect(find.textContaining('void(0)'), findsNothing);
      expect(clipboardReads, 1);
    },
  );

  testWidgets('draft appearance covers sheet chrome without saving it', (
    tester,
  ) async {
    final settings = _Settings(ReaderSettings(appearance: Appearance.light));
    await _launch(tester, settings);
    await goTo(tester, OnboardingStep.style);
    await tap(tester, key('appearance-dark'));
    await tap(tester, find.text('Language'));
    final close = find.byWidgetPredicate(
      (w) => w is IconAction && w.label == 'Close',
    );
    expect(ReaderColors.of(tester.element(close)).isDark, true);
    expect(settings.state.appearance, Appearance.light);
    await tap(tester, close);
    await tap(tester, key('tour-exit'));
    expect(settings.state.appearance, Appearance.light);
  });

  testWidgets('all ten locales fit every step in both themes at 2x text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    for (final appearance in [Appearance.light, Appearance.dark]) {
      tester.view.physicalSize = appearance == Appearance.light
          ? const Size(375, 667)
          : const Size(844, 390);
      for (final language in AppLanguage.values.where(
        (l) => l != AppLanguage.system,
      )) {
        final settings = _Settings(
          ReaderSettings(appearance: appearance, language: language),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await _launch(tester, settings);
        for (final step in OnboardingStep.values) {
          expect(key('onboarding-step-${step.name}'), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: '$language $appearance $step',
          );
          if (step != OnboardingStep.ready) await next(tester);
        }
        expect(tester.takeException(), isNull, reason: '$language $appearance');
      }
    }
  });
}
