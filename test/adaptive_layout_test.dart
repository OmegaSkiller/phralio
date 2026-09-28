import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phralio/app/accent.dart';
import 'package:phralio/app/adaptive_layout.dart';
import 'package:phralio/app/design.dart';
import 'package:phralio/app/providers.dart';
import 'package:phralio/app/reader_app.dart';
import 'package:phralio/core/settings.dart';
import 'package:phralio/features/library/library_store.dart';
import 'package:phralio/features/reader/reader_screen.dart';
import 'package:phralio/features/reader/accent_picker.dart';
import 'package:phralio/features/reader/settings_screen.dart';
import 'package:phralio/features/reader/word_context_view.dart';
import 'package:phralio/l10n/app_localizations.dart';
import 'package:phralio/l10n/l10n.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('all ten accents retain functional text contrast on both themes', () {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
    }

    expect(AccentColor.values, hasLength(10));
    for (final preset in AccentColor.values) {
      for (final palette in [ReaderColors.light, ReaderColors.dark]) {
        final accent = palette.isDark ? preset.dark : preset.light;
        for (final background in [
          palette.background,
          palette.surface,
          palette.elevated,
        ]) {
          expect(
            contrast(accent, background),
            greaterThanOrEqualTo(4.5),
            reason: '${preset.name} on $background',
          );
        }
        expect(contrast(accent, palette.onAccent), greaterThanOrEqualTo(4.5));
      }
    }
  });

  test(
    'accent survives SQLite reopen and old/unknown values use brand default',
    () async {
      expect(ReaderSettings.fromJson({}).accent, AccentColor.vermilion);
      expect(
        ReaderSettings.fromJson({'accent': 'unknown'}).accent,
        AccentColor.vermilion,
      );
      final directory = await Directory.systemTemp.createTemp(
        'phralio-accent-',
      );
      final path = '${directory.path}/reader.sqlite';
      for (final preset in AccentColor.values) {
        var store = await LibraryStore.open(path, factory: databaseFactoryFfi);
        await store.saveSettings(
          ReaderSettings(onboardingComplete: true, accent: preset),
        );
        await store.close();
        store = await LibraryStore.open(path, factory: databaseFactoryFfi);
        expect((await store.settings()).accent, preset);
        await store.close();
      }
      await directory.delete(recursive: true);
    },
  );

  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(640, 320),
    const Size(834, 1194),
    const Size(1194, 834),
    const Size(1120, 780),
  ]) {
    testWidgets('navigation and bounded settings remain usable at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryProvider.overrideWith((ref) async => []),
            initialSettingsProvider.overrideWithValue(
              ReaderSettings(
                onboardingComplete: true,
                accent: AccentColor.teal,
              ),
            ),
          ],
          child: const ReaderApp(),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in ['Home', 'Read', 'Saved', 'Settings']) {
        expect(find.byTooltip(label), findsOneWidget);
      }
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(
        ReaderColors.of(tester.element(find.byType(SettingsScreen))).accent,
        AccentColor.teal.light,
      );
      final list = find.descendant(
        of: find.byType(SettingsScreen),
        matching: find.byType(ListView),
      );
      expect(tester.getSize(list).width, lessThanOrEqualTo(760));
      await tester.ensureVisible(find.text('Accent color'));
      await tester.tap(find.text('Accent color'));
      await tester.pumpAndSettle();
      expect(find.text('Vermilion'), findsOneWidget);
      if (size.width >= 700) {
        expect(
          tester.getSize(find.byType(AccentPicker)).width,
          lessThanOrEqualTo(640),
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('landscape cutout does not collapse the navigation rail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(956, 440);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(
      left: 62,
      right: 62,
      bottom: 21,
    );
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialSettingsProvider.overrideWithValue(
            ReaderSettings(onboardingComplete: true),
          ),
          libraryProvider.overrideWith((ref) async => []),
        ],
        child: const ReaderApp(),
      ),
    );
    await tester.pumpAndSettle();
    for (final label in ['Home', 'Read', 'Saved', 'Settings']) {
      final target = find.byTooltip(label);
      expect(tester.getSize(target).width, greaterThanOrEqualTo(44));
      expect(tester.getTopLeft(target).dx, greaterThanOrEqualTo(62));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('macOS reader passage is centered in the whole window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1120, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await tester.runAsync(
      () =>
          LibraryStore.open(inMemoryDatabasePath, factory: databaseFactoryFfi),
    );
    final id = await tester.runAsync(
      () => store!.add('Center check', 'One two three four five.'),
    );
    final document = await tester.runAsync(() => store!.document(id!));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storeProvider.overrideWithValue(store!)],
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.macOS),
          localizationsDelegates: appLocalizationDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReaderLayout(
            navigation: NavigationLayout.sidebar,
            onImmersiveChanged: (_) {},
            hasBottomTabs: false,
            child: Padding(
              padding: const EdgeInsets.only(left: 240),
              child: ReaderScreen(document: document!),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.byType(WordContextView)).dx, closeTo(560, 1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(store.close);
  });

  testWidgets(
    'landscape reader exposes controls and keyboard actions preserve position across resize',
    (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = await tester.runAsync(
        () => LibraryStore.open(
          inMemoryDatabasePath,
          factory: databaseFactoryFfi,
        ),
      );
      final id = await tester.runAsync(
        () => store!.add(
          'Practice',
          'One two three four five six seven eight nine ten.',
        ),
      );
      final document = await tester.runAsync(() => store!.document(id!));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [storeProvider.overrideWithValue(store!)],
          child: MaterialApp(
            localizationsDelegates: appLocalizationDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ReaderScreen(document: document!),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('landscape-controls')), findsOneWidget);
      expect(
        tester.getBottomRight(find.bySemanticsLabel('Play reading')).dy,
        lessThan(390),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      tester.view.physicalSize = const Size(640, 320);
      await tester.pump();
      // Nearby prose and the focal word must fit without first scrolling the
      // passage on a short phone window.
      expect(
        tester.getBottomRight(find.byType(WordContextView)).dy,
        lessThanOrEqualTo(320),
      );
      expect(
        tester.widget<WordContextView>(find.byType(WordContextView)).position,
        1,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const ValueKey('immersive-reader')), findsOneWidget);
      tester.view.physicalSize = const Size(834, 1194);
      await tester.pump();
      expect(find.byKey(const ValueKey('immersive-reader')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      final position = tester
          .widget<WordContextView>(find.byType(WordContextView))
          .position;
      expect(position, greaterThan(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        await store.close();
      });
    },
  );
}
