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
import 'package:phralio/features/reader/focal_word.dart';
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
      await tester.scrollUntilVisible(find.text(label), 150);
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
      expect(find.byType(FocalWord), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Next sentence'));
      await tester.pumpAndSettle();
      final word = tester.widget<FocalWord>(find.byType(FocalWord)).token.text;
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      final saved = (await store.all()).single;
      expect(saved.wordCount, 8);
      expect(saved.position, greaterThan(0));
      expect(saved.progress, lessThan(1));
      await tester.scrollUntilVisible(
        find.bySemanticsLabel('Star A book & a pause'),
        150,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Star A book & a pause'));
      await tester.pumpAndSettle();
      await tapText('Starred');
      expect(find.text('A book & a pause'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Reading settings'));
      await tester.pumpAndSettle();
      await tapText('Dark');
      expect((await store.settings()).appearance, Appearance.dark);
      await tester.tap(find.bySemanticsLabel('Back'));
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
      await tapText(
        'Import file',
      ); // Same EPUB resumes, rather than duplicates.
      expect(tester.widget<FocalWord>(find.byType(FocalWord)).token.text, word);
      expect((await store.all()).length, 1);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      picker.next = XFile.fromData(
        Uint8List.fromList('A fresh text file.'.codeUnits),
        path: 'fresh.txt',
      );
      await tapText('Import file');
      expect(find.byType(FocalWord), findsOneWidget);
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
