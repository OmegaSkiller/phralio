import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phralio/app/providers.dart';
import 'package:phralio/app/reader_app.dart';
import 'package:phralio/core/document.dart';
import 'package:phralio/core/settings.dart';
import 'package:phralio/features/library/library_store.dart';
import 'package:phralio/features/reader/focal_word.dart';
import 'package:phralio/features/reader/reader_screen.dart';
import 'package:phralio/l10n/app_localizations.dart';
import 'package:phralio/l10n/l10n.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  testWidgets('reader tap enters and leaves focus with word context', (
    tester,
  ) async {
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
            ReaderSettings(readingFont: ReadingFont.inter),
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
    expect(find.byType(ListWheelScrollView), findsOneWidget);
    expect(tester.widget<Text>(find.text('One')).style?.fontFamily, 'Inter');
    await tester.tap(find.byType(ListWheelScrollView));
    await tester.pump();
    expect(find.byKey(const ValueKey('immersive-reader')), findsOneWidget);
    expect(find.text('Read'), findsNothing);
    expect(
      tester.widget<FocalWord>(find.byType(FocalWord)).readingFont,
      ReadingFont.inter,
    );
    await tester.tap(find.byKey(const ValueKey('immersive-reader')));
    await tester.pump();
    expect(find.byType(ListWheelScrollView), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(store.close);
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
