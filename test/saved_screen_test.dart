import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:phralio/app/providers.dart';
import 'package:phralio/features/library/library_store.dart';
import 'package:phralio/features/library/saved_screen.dart';
import 'package:phralio/l10n/app_localizations.dart';
import 'package:phralio/l10n/l10n.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  testWidgets('Saved shows the bookmarked word and swipes remove saved marks', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(() async {
      final store = await LibraryStore.open(
        inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final id = await store.add('A reading', 'one two three');
      await store.setStarred(id, true);
      await store.toggleBookmark(id, 1);
      return (
        store: store,
        starred: await store.all(),
        bookmarks: await store.bookmarks(),
      );
    }))!;
    final store = fixture.store;
    addTearDown(store.close);

    var savedData = (starred: fixture.starred, bookmarks: fixture.bookmarks);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(store),
          savedProvider.overrideWith((ref) async => savedData),
        ],
        child: const MaterialApp(
          localizationsDelegates: appLocalizationDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SavedScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('two'), findsOneWidget);
    expect(find.text('A reading'), findsNWidgets(2));

    Future<void> swipeWithDeleteReveal(
      Finder row, {
      required bool starred,
    }) async {
      final rowBounds = tester.getRect(row);
      final gesture = await tester.startGesture(rowBounds.center);
      // Cross the gesture recognizer's touch slop before revealing the action.
      await gesture.moveBy(const Offset(-20, 0));
      await gesture.moveBy(const Offset(-80, 0));
      await tester.pump();
      final trash = find.descendant(
        of: row,
        matching: find.byIcon(LucideIcons.trash2),
      );
      expect(trash, findsOneWidget);
      final iconBounds = tester.getRect(trash);
      expect(iconBounds.left, greaterThan(rowBounds.right - 80));
      expect(iconBounds.right, lessThan(rowBounds.right));
      expect(tester.widget<Icon>(trash).color, CupertinoColors.white);
      final background = tester.widget<ColoredBox>(
        find.ancestor(of: trash, matching: find.byType(ColoredBox)).first,
      );
      expect(
        background.color,
        CupertinoColors.systemRed.resolveFrom(tester.element(row)),
      );
      // The reveal alone must not remove either saved mark.
      expect((await tester.runAsync(store.all))!.single.starred, starred);
      expect((await tester.runAsync(store.bookmarks))!, hasLength(1));
      await gesture.moveBy(const Offset(-500, 0));
      await gesture.up();
      await tester.pumpAndSettle();
    }

    await swipeWithDeleteReveal(
      find.byKey(const ValueKey('star-1')),
      starred: true,
    );
    await tester.pumpAndSettle();
    expect((await tester.runAsync(store.all))!.single.starred, isFalse);
    expect(find.text('two'), findsOneWidget);

    await swipeWithDeleteReveal(
      find.byKey(const ValueKey('bookmark-1-1')),
      starred: false,
    );
    await tester.pumpAndSettle();
    expect((await tester.runAsync(store.bookmarks))!, isEmpty);
    // Fresh provider data acknowledges the removals. Adding the same marks
    // again must not leave them hidden by the earlier dismissal.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SavedScreen)),
    );
    savedData = (starred: [], bookmarks: []);
    container.invalidate(savedProvider);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await store.setStarred(1, true);
      await store.toggleBookmark(1, 1);
      savedData = (
        starred: await store.all(),
        bookmarks: await store.bookmarks(),
      );
    });
    container.invalidate(savedProvider);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('star-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('bookmark-1-1')), findsOneWidget);
    expect(find.text('two'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
