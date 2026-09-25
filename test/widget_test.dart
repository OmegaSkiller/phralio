import 'package:phralio/core/settings.dart';
import 'package:phralio/features/library/library_screen.dart';

import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phralio/app/reader_app.dart';
import 'package:phralio/app/providers.dart';
import 'package:phralio/app/design.dart';
import 'package:phralio/core/document.dart';
import 'package:phralio/features/reader/focal_word.dart';
import 'package:phralio/features/reader/reader_screen.dart';
import 'package:phralio/features/library/library_store.dart';
import 'package:phralio/l10n/app_localizations.dart';
import 'package:phralio/l10n/l10n.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('semantic text and filled controls retain accessible contrast', () {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
    }

    for (final colors in [ReaderColors.light, ReaderColors.dark]) {
      for (final text in [
        colors.text,
        colors.secondary,
        colors.subtle,
        colors.focal,
      ]) {
        expect(contrast(text, colors.background), greaterThanOrEqualTo(4.5));
      }
      expect(
        contrast(colors.accent, colors.onAccent),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
  testWidgets(
    'shaped focal glyph remains anchored, including long Unicode words',
    (tester) async {
      for (final word in [
        'I',
        '“Focus,”',
        'е́то',
        'extraordinarily-longword',
        '👩‍💻',
      ]) {
        for (final scale in [1.0, 2.0, 3.0]) {
          final layout = FocalLayout(
            ReaderToken(word, 0, false),
            const TextStyle(fontSize: 42),
            Colors.teal,
            true,
            320,
            TextScaler.linear(scale),
          );
          expect(
            layout.left + layout.focalCenter * layout.scale,
            closeTo(320 * Measures.anchor, 0.01),
          );
          expect(layout.left, greaterThanOrEqualTo(15.99));
          expect(
            layout.left + layout.painter.width * layout.scale,
            lessThanOrEqualTo(304.01),
          );
          layout.dispose();
        }
      }
    },
  );
  testWidgets(
    'populated library exposes numeric progress and independent star action',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryProvider.overrideWith(
              (ref) async => [
                const LibraryEntry(
                  id: 1,
                  title: 'Book',
                  wordCount: 100,
                  position: 42,
                  openedAt: 1,
                  starred: false,
                  format: 'EPUB',
                  author: 'Author',
                ),
              ],
            ),
          ],
          child: const ReaderApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('42% read'), findsWidgets);
      await tester.ensureVisible(find.bySemanticsLabel('Star Book'));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Star Book'))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        true,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
  testWidgets('reader remains usable with double text scaling in dark mode', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    sqfliteFfiInit();
    final store = (await tester.runAsync(() async {
      final store = await LibraryStore.open(
        inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      await store.add(
        'A longer document title',
        'One two three. Four five six.',
      );
      return store;
    }))!;
    final document = (await tester.runAsync(
      () async => store.document((await store.all()).single.id),
    ))!;
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storeProvider.overrideWithValue(store)],
        child: MaterialApp(
          localizationsDelegates: appLocalizationDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData.dark(),
          home: ReaderScreen(document: document),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final label in ['Play reading', 'Reading actions']) {
      final control = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == label,
      );
      if (control.evaluate().isEmpty) {
        await tester.dragFrom(const Offset(12, 500), const Offset(0, -350));
        await tester.pumpAndSettle();
      }
      expect(control, findsOneWidget, reason: label);
      await tester.ensureVisible(control);
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(control)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
    }
    await tester.dragFrom(const Offset(12, 250), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('1 of 6 words'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await store.close();
    });
    semantics.dispose();
  });
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets(
      '$platform explicit appearance overrides OS and solid surfaces disable blur',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              libraryProvider.overrideWith((ref) async => []),
              initialSettingsProvider.overrideWithValue(
                ReaderSettings(
                  appearance: Appearance.dark,
                  reduceTransparency: true,
                ),
              ),
            ],
            child: const ReaderApp(),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(LibraryScreen));
        expect(ReaderColors.of(context), ReaderColors.dark);
        expect(
          find.byWidgetPredicate((w) => w is BackdropFilter && w.enabled),
          findsNothing,
        );
        debugDefaultTargetPlatformOverride = null;
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets(
      '$platform library adapts and handles large type on narrow screen',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [libraryProvider.overrideWith((ref) async => [])],
            child: const ReaderApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsWidgets);
        expect(find.bySemanticsLabel('Add reading'), findsOneWidget);
        debugDefaultTargetPlatformOverride = null;
        expect(tester.takeException(), isNull);
      },
    );
  }
}
