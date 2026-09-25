import 'dart:ui' show SemanticsAction;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phralio/app/providers.dart';
import 'package:phralio/app/reader_app.dart';
import 'package:phralio/core/document.dart';
import 'package:phralio/features/library/library_store.dart';
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
        overrides: [storeProvider.overrideWithValue(store!)],
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
    await tester.tap(find.byKey(const ValueKey('immersive-reader')));
    await tester.pump();
    expect(find.byType(WordContextView), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(store.close);
    semantics.dispose();
  });

  testWidgets('main navigation exposes Home, Read, Settings and Saved', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
      expect(find.text(label), findsWidgets);
    }
    await tester.tap(find.text('Saved').last);
    await tester.pumpAndSettle();
    expect(find.text('Bookmarks'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
