import 'controls.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:phralio/app/reader_app.dart';
import 'package:phralio/app/providers.dart';
import 'package:phralio/features/library/library_store.dart';
import 'package:phralio/features/reader/focal_word.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('save text, play, seek, leave and restore native SQLite session', (
    tester,
  ) async {
    final file = '${await getDatabasesPath()}/integration-reader.sqlite';
    await deleteDatabase(file);
    var store = await LibraryStore.open(file);
    Future<void> launch() async {
      final settings = await store.settings();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            initialSettingsProvider.overrideWithValue(settings),
          ],
          child: const ReaderApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    await launch();
    await chooseMenu(tester, 'Add reading', 'Add text');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'A device reading');
    await tester.enterText(
      find.byType(EditableText).at(1),
      List.filled(
        10,
        'One two three four five six seven eight nine ten.',
      ).join(' '),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save and read'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save and read'));
    await tester.pumpAndSettle();
    expect(find.byType(ListWheelScrollView), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Play reading'));
    await tester.pump();
    expect(find.byKey(const ValueKey('immersive-reader')), findsOneWidget);
    expect(find.byType(FocalWord), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 650));
    await tester.tap(find.byKey(const ValueKey('immersive-reader')));
    await tester.pumpAndSettle();
    expect(find.byType(ListWheelScrollView), findsOneWidget);
    await tapIcon(tester, 'Forward ten words');
    await tester.pumpAndSettle();
    await tapIcon(tester, 'Back');
    await tester.pumpAndSettle();
    final saved = (await store.all()).single;
    expect(saved.position, greaterThanOrEqualTo(10));
    final focal = (await store.document(saved.id)).tokens[saved.position].text;
    // Destroy app state and reopen the database: restoration cannot use memory.
    await tester.pumpWidget(const SizedBox.shrink());
    await store.close();
    store = await LibraryStore.open(file);
    await launch();
    await tester.scrollUntilVisible(find.text('A device reading').last, 160);
    await tester.pumpAndSettle();
    await tester.tap(find.text('A device reading').last);
    await tester.pumpAndSettle();
    expect(
      find.text('${saved.position + 1} of ${saved.wordCount} words'),
      findsOneWidget,
    );
    expect((await store.document(saved.id)).tokens[saved.position].text, focal);
    expect(find.bySemanticsLabel('Play reading'), findsOneWidget);
    await chooseMenu(tester, 'Reading actions', 'Reader settings');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Open-source licenses'), 160);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open-source licenses'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Loading licenses'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await store.close();
    await deleteDatabase(file);
  });
}
