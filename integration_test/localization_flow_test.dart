import 'controls.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:phralio/app/providers.dart';
import 'package:phralio/app/reader_app.dart';
import 'package:phralio/core/settings.dart';
import 'package:phralio/features/library/library_store.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('selected language changes live and survives app restart', (
    tester,
  ) async {
    final path = '${await getDatabasesPath()}/integration-locale.sqlite';
    await deleteDatabase(path);
    var store = await LibraryStore.open(path);
    try {
      await store.saveSettings(ReaderSettings(language: AppLanguage.ru));
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
      expect(find.text('Главная'), findsWidgets);
      await tapTab(tester, 'Настройки');
      await tester.pumpAndSettle();
      expect(find.text('Язык'), findsOneWidget);
      await tester.tap(find.text('Язык'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Español'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();
      expect(find.text('Ajustes'), findsWidgets);
      expect((await store.settings()).language, AppLanguage.es);

      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
      store = await LibraryStore.open(path);
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
      expect(find.text('Inicio'), findsWidgets);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
      await deleteDatabase(path);
    }
  });
}
