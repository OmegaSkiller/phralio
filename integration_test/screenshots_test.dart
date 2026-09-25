import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:phralio/app/reader_app.dart';
import 'package:phralio/app/providers.dart';
import 'package:phralio/features/library/library_store.dart';
import 'package:phralio/features/library/library_screen.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('capture native light and dark reading surfaces', (tester) async {
    final file = '${await getDatabasesPath()}/screenshots-reader.sqlite';
    await deleteDatabase(file);
    final store = await LibraryStore.open(file);
    await store.add('A little more room', sampleText);
    await store.savePosition((await store.all()).single, 6);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storeProvider.overrideWithValue(store)],
        child: const ReaderApp(),
      ),
    );
    await tester.pumpAndSettle();
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
    }
    final platform = Platform.isIOS ? 'ios' : 'android';
    await binding.takeScreenshot('$platform-library');
    await tester.scrollUntilVisible(find.text('A little more room'), 160);
    await tester.pumpAndSettle();
    await tester.tap(find.text('A little more room'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('$platform-reader');
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    await binding.takeScreenshot('$platform-reader-dark');
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
    expect(tester.takeException(), isNull);
    // Android surface restoration is registered by the binding at tearDown.
    await tester.pumpWidget(const SizedBox.shrink());
    await store.close();
    await deleteDatabase(file);
  });
}
