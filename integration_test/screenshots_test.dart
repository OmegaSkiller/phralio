import 'controls.dart';

import 'package:phralio/core/settings.dart';

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
import 'package:phralio/features/reader/reader_screen.dart';
import 'package:phralio/app/design.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('capture native light and dark reading surfaces', (tester) async {
    final file = '${await getDatabasesPath()}/screenshots-reader.sqlite';
    await deleteDatabase(file);
    final store = await LibraryStore.open(file);
    final id = await store.add('A little more room', sampleText);
    await store.setStarred(id, true);
    await store.toggleBookmark(id, 6);
    await store.savePosition(
      await store.document((await store.all()).single.id),
      6,
    );
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
    await binding.takeScreenshot('redesign/$platform-library');
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LibraryScreen)),
    );
    await container
        .read(settingsProvider.notifier)
        .update(ReaderSettings(appearance: Appearance.dark));
    await tester.pumpAndSettle();
    expect(
      ReaderColors.of(tester.element(find.byType(LibraryScreen))),
      ReaderColors.dark,
    );
    await tester.pump();
    await binding.takeScreenshot('redesign/$platform-library-dark');
    await container
        .read(settingsProvider.notifier)
        .update(ReaderSettings(appearance: Appearance.light));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('A little more room').last, 160);
    await tester.pumpAndSettle();
    await tester.tap(find.text('A little more room').last);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('redesign/$platform-reader');
    await container
        .read(settingsProvider.notifier)
        .update(ReaderSettings(appearance: Appearance.dark));
    await tester.pumpAndSettle();
    expect(
      ReaderColors.of(tester.element(find.byType(ReaderScreen))),
      ReaderColors.dark,
    );
    if (Platform.isIOS) {
      expect(
        tester
            .widgetList<CupertinoPageScaffold>(
              find.byType(CupertinoPageScaffold),
            )
            .any(
              (page) => page.backgroundColor == ReaderColors.dark.background,
            ),
        isTrue,
      );
    }
    await tester.pump();
    await binding.takeScreenshot('redesign/$platform-reader-dark');
    await tester.tap(find.bySemanticsLabel('Play reading'));
    await tester.pump();
    expect(find.byKey(const ValueKey('immersive-reader')), findsOneWidget);
    await binding.takeScreenshot('redesign/$platform-focus-dark');
    await tester.tap(find.byKey(const ValueKey('immersive-reader')));
    await tester.pumpAndSettle();
    await tapIcon(tester, 'Back');
    await tapTab(tester, 'Saved');
    await binding.takeScreenshot('redesign/$platform-saved-dark');
    await tapTab(tester, 'Settings');
    await binding.takeScreenshot('redesign/$platform-settings-dark');
    await container
        .read(settingsProvider.notifier)
        .update(ReaderSettings(appearance: Appearance.light));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('redesign/$platform-settings-light');
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('redesign/$platform-language-sheet');
    await tapIcon(tester, 'Close');
    expect(tester.takeException(), isNull);
    // Android surface restoration is registered by the binding at tearDown.
    await tester.pumpWidget(const SizedBox.shrink());
    await store.close();
    await deleteDatabase(file);
  });
}
