import 'controls.dart';

import 'package:phralio/l10n/l10n.dart';

import 'package:phralio/features/library/paste_screen.dart';
import 'package:phralio/features/library/url_screen.dart';

import 'package:phralio/core/settings.dart';

import 'dart:io';
import 'dart:async';

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
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('capture native light and dark reading surfaces', (tester) async {
    final file = '${await getDatabasesPath()}/screenshots-reader.sqlite';
    await deleteDatabase(file);
    final store = await LibraryStore.open(file);
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
    // Let native surfaces consume a complete rendered frame before PixelCopy /
    // UIKit capture; widget-tree completion alone can capture the prior route.
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      await binding.endOfFrame;
      await binding.takeScreenshot(name);
    }

    final platform = Platform.isIOS ? 'ios' : 'android';
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LibraryScreen)),
    );
    await capture('brandkit/$platform-empty');
    unawaited(
      showProblem(
        tester.element(find.byType(LibraryScreen)),
        'This reading could not be opened. Your library is unchanged.',
      ),
    );
    await tester.pumpAndSettle();
    await capture('brandkit/$platform-error');
    await tester.tap(
      find.text(
        tester
            .element(find.byType(LibraryScreen, skipOffstage: false))
            .l10n
            .okay,
      ),
    );
    await tester.pumpAndSettle();
    final id = await store.add('A little more room', sampleText);
    await store.setStarred(id, true);
    await store.toggleBookmark(id, 6);
    await store.savePosition(
      await store.document((await store.all()).single.id),
      6,
    );
    container.invalidate(libraryProvider);
    await tester.pumpAndSettle();
    await capture('brandkit/$platform-library');
    await chooseMenu(tester, 'Add reading', 'Add text');
    await tester.enterText(find.byType(EditableText).at(0), 'A quiet morning');
    await tester.enterText(
      find.byType(EditableText).at(1),
      'Make a little room for words. Choose a comfortable pace, pause when you need to, and return to the same place.',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.byType(PasteScreen), findsOneWidget);
    await capture('brandkit/$platform-add-text');
    await tapIcon(tester, 'Back');
    await chooseMenu(tester, 'Add reading', 'Read URL');
    expect(find.byType(UrlScreen), findsOneWidget);
    await capture('brandkit/$platform-url');
    await tapIcon(tester, 'Back');

    await container
        .read(settingsProvider.notifier)
        .update(ReaderSettings(appearance: Appearance.dark));
    await tester.pumpAndSettle();
    expect(
      ReaderColors.of(tester.element(find.byType(LibraryScreen))),
      ReaderColors.dark,
    );
    await tester.pump();
    await capture('brandkit/$platform-library-dark');
    await container
        .read(settingsProvider.notifier)
        .update(ReaderSettings(appearance: Appearance.light));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('A little more room').last, 160);
    await tester.pumpAndSettle();
    await tester.tap(find.text('A little more room').last);
    await tester.pumpAndSettle();
    await capture('brandkit/$platform-reader');
    await tester.tap(find.bySemanticsLabel('Play reading'));
    await tester.pumpAndSettle();
    await capture('brandkit/$platform-focus-light');
    await tester.tap(find.byKey(const ValueKey('immersive-reader')));
    await tester.pumpAndSettle();

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
    await capture('brandkit/$platform-reader-dark');
    await tester.tap(find.bySemanticsLabel('Play reading'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('immersive-reader')), findsOneWidget);
    await capture('brandkit/$platform-focus-dark');
    await tester.tap(find.byKey(const ValueKey('immersive-reader')));
    await tester.pumpAndSettle();
    await tapIcon(tester, 'Back');
    await tapTab(tester, 'Saved');
    await capture('brandkit/$platform-saved-dark');
    await tapTab(tester, 'Settings');
    await capture('brandkit/$platform-settings-dark');
    await container
        .read(settingsProvider.notifier)
        .update(ReaderSettings(appearance: Appearance.light));
    await tester.pumpAndSettle();
    await capture('brandkit/$platform-settings-light');
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await capture('brandkit/$platform-language-sheet');
    await tapIcon(tester, 'Close');
    for (final language in [AppLanguage.ja, AppLanguage.ru]) {
      await container
          .read(settingsProvider.notifier)
          .update(ReaderSettings(language: language));
      await tester.pumpAndSettle();
      await binding.takeScreenshot(
        'brandkit/$platform-settings-${language.name}',
      );
    }
    expect(tester.takeException(), isNull);
    // Android surface restoration is registered by the binding at tearDown.
    await tester.pumpWidget(const SizedBox.shrink());
    await store.close();
    await deleteDatabase(file);
  });
}
