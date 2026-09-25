import 'dart:convert';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:phralio/app/providers.dart';
import 'package:phralio/app/reader_app.dart';
import 'package:phralio/features/library/library_store.dart';
import 'package:sqflite/sqflite.dart';

class _SelectedFile extends FileSelectorPlatform {
  XFile? file;
  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async => file;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('Markdown contents, image, bookmark, saved tab and clipboard', (
    tester,
  ) async {
    final originalPicker = FileSelectorPlatform.instance;
    final picker = _SelectedFile();
    FileSelectorPlatform.instance = picker;
    final path = '${await getDatabasesPath()}/integration-rich-reading.sqlite';
    await deleteDatabase(path);
    final store = await LibraryStore.open(path);
    try {
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/lNsAAAAASUVORK5CYII=',
      );
      picker.file = XFile.fromData(
        Uint8List.fromList(
          utf8.encode(
            '# Start\nFirst words.\n\n![Picture](data:image/png;base64,${base64Encode(png)})\n\n## Second section\nMore words.',
          ),
        ),
        path: 'sample.md',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [storeProvider.overrideWithValue(store)],
          child: const ReaderApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import file'));
      await tester.pumpAndSettle();
      final book = (await store.all()).single;
      final document = await store.document(book.id);
      expect(document.headings.map((h) => h.title), [
        'Start',
        'Second section',
      ]);
      expect(document.images.single.bytes, png);
      await tester.tap(find.bySemanticsLabel('Contents'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Second section'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          '${document.headings.last.position + 1} of ${book.wordCount} words',
        ),
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsLabel('Bookmark this word'));
      await tester.pumpAndSettle();
      expect(await store.bookmarksFor(book.id), [
        document.headings.last.position,
      ]);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saved').last);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Word ${document.headings.last.position + 1}'),
        findsOneWidget,
      );
      await tester.tap(
        find.textContaining('Word ${document.headings.last.position + 1}'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          '${document.headings.last.position + 1} of ${book.wordCount} words',
        ),
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      await Clipboard.setData(const ClipboardData(text: 'From the clipboard.'));
      await tester.tap(find.text('Read clipboard'));
      await tester.pumpAndSettle();
      expect((await store.all()).length, 2);
      expect(find.text('Clipboard reading'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      FileSelectorPlatform.instance = originalPicker;
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
      await deleteDatabase(path);
    }
  });
}
