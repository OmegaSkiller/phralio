import 'controls.dart';

import 'dart:typed_data';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:phralio/app/design.dart';
import 'package:phralio/app/providers.dart';
import 'package:phralio/app/reader_app.dart';
import 'package:phralio/core/settings.dart';
import 'package:phralio/features/library/library_store.dart';
import 'package:phralio/features/library/library_screen.dart';
import 'package:phralio/features/reader/word_context_view.dart';
import 'package:sqflite/sqflite.dart';

import '../test/import_test.dart' show epub;

// Only the OS selection is substituted: parsing, widgets and SQLite are real.
class _Selection extends FileSelectorPlatform {
  XFile? next;
  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async => next;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('import, star, theme, cancel, resume and reimport a whole EPUB', (
    tester,
  ) async {
    final originalPicker = FileSelectorPlatform.instance;
    final picker = _Selection();
    FileSelectorPlatform.instance = picker;
    final path = '${await getDatabasesPath()}/integration-library.sqlite';
    await deleteDatabase(path);
    var store = await LibraryStore.open(path);
    Future<void> launch() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            initialSettingsProvider.overrideWithValue(await store.settings()),
          ],
          child: const ReaderApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapText(String label) async {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    try {
      await launch();
      await tapText('Import file'); // Cancel is not an error and adds nothing.
      expect(await store.all(), isEmpty);
      picker.next = XFile.fromData(epub(), path: 'fixture.epub');
      await tapText('Import file');
      expect(find.byType(WordContextView), findsOneWidget);
      await chooseMenu(tester, 'Reading actions', 'Next sentence');
      await tester.pumpAndSettle();
      await tapIcon(tester, 'Back');
      await tester.pumpAndSettle();
      final saved = (await store.all()).single;
      expect(saved.wordCount, 8);
      expect(saved.position, greaterThan(0));
      final word = (await store.document(saved.id)).tokens[saved.position].text;
      expect(saved.progress, lessThan(1));
      await tester.ensureVisible(
        find.byWidgetPredicate(
          (w) => w is IconAction && w.label == 'Star A book & a pause',
        ),
      );
      await tester.pumpAndSettle();
      await tapIcon(tester, 'Star A book & a pause');
      await tester.pumpAndSettle();
      await chooseMenu(tester, 'Library filter', 'Starred');
      expect(find.text('A book & a pause'), findsOneWidget);
      await tapTab(tester, 'Settings');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appearance').last);
      await tester.pumpAndSettle();
      await tapText('Dark');
      expect((await store.settings()).appearance, Appearance.dark);
      await tapTab(tester, 'Home');
      await tester.pumpAndSettle();
      expect(
        ReaderColors.of(tester.element(find.byType(LibraryScreen))),
        ReaderColors.dark,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
      store = await LibraryStore.open(path);
      await launch();
      expect((await store.all()).single.starred, true);
      expect(
        ReaderColors.of(tester.element(find.byType(LibraryScreen))),
        ReaderColors.dark,
      );
      await chooseMenu(
        tester,
        'Add reading',
        'Import file',
      ); // Same EPUB resumes, rather than duplicates.
      expect(
        find.text('${saved.position + 1} of ${saved.wordCount} words'),
        findsOneWidget,
      );
      expect(
        (await store.document(saved.id)).tokens[saved.position].text,
        word,
      );
      expect((await store.all()).length, 1);
      await tapIcon(tester, 'Back');
      await tester.pumpAndSettle();
      picker.next = XFile.fromData(
        Uint8List.fromList('A fresh text file.'.codeUnits),
        path: 'fresh.txt',
      );
      await chooseMenu(tester, 'Add reading', 'Import file');
      expect(find.byType(WordContextView), findsOneWidget);
      expect((await store.all()).length, 2);
      expect(tester.takeException(), isNull);
    } finally {
      FileSelectorPlatform.instance = originalPicker;
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
      await deleteDatabase(path);
    }
  });
}
