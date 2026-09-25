import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:phralio/app/providers.dart';
import 'package:phralio/app/reader_app.dart';
import 'package:phralio/core/settings.dart';
import 'package:phralio/features/library/library_screen.dart';
import 'package:phralio/features/library/library_store.dart';
import 'package:phralio/features/reader/word_context_view.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('capture contextual word view in both appearances', (
    tester,
  ) async {
    final file = '${await getDatabasesPath()}/scrolling-screenshots.sqlite';
    await deleteDatabase(file);
    final store = await LibraryStore.open(file);
    final id = await store.add('A little more room', sampleText);
    await store.savePosition(await store.document(id), 25);
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
    await tester.scrollUntilVisible(find.text('A little more room').last, 160);
    await tester.pumpAndSettle();
    await tester.tap(find.text('A little more room').last);
    await tester.pumpAndSettle();
    expect(find.byType(WordContextView), findsOneWidget);
    final platform = Platform.isIOS ? 'ios' : 'android';
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WordContextView)),
    );
    await binding.endOfFrame;
    await binding.takeScreenshot('scrolling-behaviour/$platform-light');
    await container
        .read(settingsProvider.notifier)
        .update(ReaderSettings(appearance: Appearance.dark));
    await tester.pumpAndSettle();
    await binding.endOfFrame;
    await binding.takeScreenshot('scrolling-behaviour/$platform-dark');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await store.close();
    await deleteDatabase(file);
  });
}
