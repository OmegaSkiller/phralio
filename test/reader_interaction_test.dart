import 'dart:ui' show SemanticsAction;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phralio/app/providers.dart';
import 'package:phralio/app/adaptive_layout.dart';
import 'package:phralio/app/reader_app.dart';
import 'package:phralio/core/document.dart';
import 'package:phralio/core/settings.dart';
import 'package:phralio/features/library/library_store.dart';
import 'package:phralio/features/reader/focal_word.dart';
import 'package:phralio/features/reader/reader_screen.dart';
import 'package:phralio/features/reader/word_context_view.dart';
import 'package:phralio/l10n/app_localizations.dart';
import 'package:phralio/l10n/l10n.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  testWidgets('reader tap enters and leaves focus with word context', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final store = await tester.runAsync(
      () =>
          LibraryStore.open(inMemoryDatabasePath, factory: databaseFactoryFfi),
    );
    final id = await tester.runAsync(
      () => store!.add('Test', 'One two three four.'),
    );
    final document = await tester.runAsync(() => store!.document(id!));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(store!),
          initialSettingsProvider.overrideWithValue(
            ReaderSettings(
              onboardingComplete: true,
              readingFont: ReadingFont.inter,
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReaderScreen(document: document!),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WordContextView), findsOneWidget);
    expect(find.text('two three four.'), findsOneWidget);
    expect(
      tester.widget<FocalWord>(find.byType(FocalWord)).readingFont,
      ReadingFont.inter,
    );
    expect(
      tester.widget<Text>(find.text('two three four.')).style?.fontFamily,
      ReadingFont.inter.family,
    );
    await tester.drag(find.byType(WordContextView), const Offset(0, -40));
    await tester.pumpAndSettle();
    expect(
      tester.widget<WordContextView>(find.byType(WordContextView)).position,
      1,
    );
    expect(find.text('One'), findsOneWidget);
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(find.byType(WordContextView)),
        scrollDelta: const Offset(0, 120),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<WordContextView>(find.byType(WordContextView)).position,
      2,
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('word-context-semantics')))
          .getSemanticsData()
          .hasAction(SemanticsAction.decrease),
      isTrue,
    );
    await tester.drag(find.byType(WordContextView), const Offset(0, 40));
    await tester.pumpAndSettle();
    expect(
      tester.widget<WordContextView>(find.byType(WordContextView)).position,
      1,
    );
    await tester.tap(find.byType(WordContextView));
    await tester.pump();
    expect(find.byKey(const ValueKey('immersive-reader')), findsOneWidget);
    expect(find.text('Read'), findsNothing);
    expect(find.text('25% read'), findsNothing);
    final topMark = find.byKey(const ValueKey('scope-mark-top'));
    final bottomMark = find.byKey(const ValueKey('scope-mark-bottom'));
    final track = find.byKey(const ValueKey('focused-progress-track'));
    final fill = find.byKey(const ValueKey('focused-progress-fill'));
    expect(topMark, findsOneWidget);
    expect(bottomMark, findsOneWidget);
    expect(tester.getCenter(topMark).dx, tester.getCenter(bottomMark).dx);
    expect(
      tester.getCenter(bottomMark).dy - tester.getCenter(topMark).dy,
      lessThan(140),
    );
    expect(
      tester.getTopLeft(track).dy,
      greaterThan(tester.getBottomRight(bottomMark).dy),
    );
    expect(
      tester.getSize(fill).width,
      closeTo(tester.getSize(track).width * .25, .1),
    );
    expect(
      tester.widget<FocalWord>(find.byType(FocalWord)).readingFont,
      ReadingFont.inter,
    );
    await tester.tap(find.byKey(const ValueKey('immersive-reader')));
    await tester.pump();
    expect(find.byType(WordContextView), findsOneWidget);
    expect(find.text('25% read'), findsNothing);
    expect(topMark, findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(store.close);
    semantics.dispose();
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(640, 320),
    const Size(834, 1194),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('paused chrome stays fixed at $size with ${scale}x text', (
        tester,
      ) async {
        tester.view.physicalSize = size;
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
            'Fixed reader',
            'One two three four five six seven eight nine ten eleven twelve.',
          ),
        );
        final document = await tester.runAsync(() => store!.document(id!));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [storeProvider.overrideWithValue(store!)],
            child: MaterialApp(
              localizationsDelegates: appLocalizationDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: ReaderLayout(
                navigation: NavigationLayout.forSize(size.width, size.height),
                hasBottomTabs: size.width < 600,
                onImmersiveChanged: (_) {},
                child: ReaderScreen(document: document!),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final title = find.text('Fixed reader');
        final play = find.bySemanticsLabel('Play reading');
        final canvas = find.byType(WordContextView);
        final titleRect = tester.getRect(title);
        final playRect = tester.getRect(play);
        final canvasRect = tester.getRect(canvas);
        expect(
          find.descendant(
            of: find.byType(ReaderScreen),
            matching: find.byType(Scrollable),
          ),
          findsNothing,
        );
        expect(canvasRect.height, greaterThan(40));
        expect(playRect.bottom, lessThan(size.height));
        await tester.drag(title, const Offset(0, -80));
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: tester.getCenter(play),
            scrollDelta: const Offset(0, 120),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.widget<WordContextView>(canvas).position, 0);
        await tester.drag(canvas, const Offset(0, -40));
        await tester.pumpAndSettle();
        expect(tester.widget<WordContextView>(canvas).position, 1);
        expect(tester.getRect(title), titleRect);
        expect(tester.getRect(play), playRect);
        expect(tester.getRect(canvas), canvasRect);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        final saved = await tester.runAsync(() => store.document(id!));
        expect(saved!.position, 1);
        await tester.runAsync(store.close);
      });
    }
  }

  testWidgets('main navigation exposes Home, Read, Settings and Saved', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialSettingsProvider.overrideWithValue(
            ReaderSettings(onboardingComplete: true),
          ),
          libraryProvider.overrideWith((ref) async => []),
          savedProvider.overrideWith(
            (ref) async =>
                (starred: <LibraryEntry>[], bookmarks: <BookmarkEntry>[]),
          ),
        ],
        child: const ReaderApp(),
      ),
    );
    await tester.pumpAndSettle();
    for (final label in ['Home', 'Read', 'Settings', 'Saved']) {
      expect(find.byTooltip(label), findsOneWidget);
    }
    await tester.tap(find.byTooltip('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Bookmarks'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
