import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lottie/lottie.dart';
import 'package:sqflite/sqflite.dart';
import 'package:phralio/app/providers.dart';
import 'package:phralio/app/reader_app.dart';
import 'package:phralio/app/startup_screen.dart';
import 'package:phralio/core/settings.dart';
import 'package:phralio/features/library/library_store.dart';
import 'package:phralio/features/library/library_screen.dart';
import 'package:phralio/features/reader/word_context_view.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  Future<void> capture(String name) async {
    await binding.endOfFrame;
    await binding.takeScreenshot(name);
  }

  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('short startup and stationary paused reader on device', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      StartupScreen(reduceMotion: false, onFinished: () => completed = true),
    );
    for (var frame = 0; frame < 120; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      final animation = tester
          .widget<LottieBuilder>(find.byType(LottieBuilder))
          .controller!;
      if ((animation as AnimationController).duration != null) break;
    }
    final animation = tester
        .widget<LottieBuilder>(find.byType(LottieBuilder))
        .controller!;
    expect(
      (animation as AnimationController).duration,
      const Duration(seconds: 1),
    );
    // Capture actual composition frames in the simulator renderer. Stop the
    // clock while screenshots are transferred so elapsed I/O cannot skip one.
    final controller = animation;
    controller.stop();
    for (final progress in [.1, .6, .9]) {
      controller.value = progress;
      await tester.pump();
      await capture('reader-refinements/startup-${(progress * 100).round()}');
    }
    controller.forward(from: 0);
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());

    final file = '${await getDatabasesPath()}/reader-refinements.sqlite';
    await deleteDatabase(file);
    final store = await LibraryStore.open(file);
    final id = await store.add('A little more room', sampleText);
    await store.savePosition(await store.document(id), 25);
    try {
      for (final landscape in [false, true]) {
        await SystemChrome.setPreferredOrientations(
          landscape
              ? [DeviceOrientation.landscapeLeft]
              : [DeviceOrientation.portraitUp],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storeProvider.overrideWithValue(store),
              initialSettingsProvider.overrideWithValue(
                ReaderSettings(onboardingComplete: true),
              ),
            ],
            child: const ReaderApp(),
          ),
        );
        for (var frame = 0; frame < 120; frame++) {
          if ((tester.view.physicalSize.width >
                  tester.view.physicalSize.height) ==
              landscape) {
            break;
          }
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(
          tester.view.physicalSize.width > tester.view.physicalSize.height,
          landscape,
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('open-reading-$id')),
          160,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('open-reading-$id')));
        final canvas = find.byType(WordContextView);
        for (var frame = 0; frame < 120 && canvas.evaluate().isEmpty; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.pumpAndSettle();
        expect(canvas, findsOneWidget);
        final title = find.text('A little more room');
        final play = find.bySemanticsLabel('Play reading');
        final titleRect = tester.getRect(title);
        final playRect = tester.getRect(play);
        final position = tester.widget<WordContextView>(canvas).position;
        await tester.drag(title, const Offset(0, -60));
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: tester.getCenter(play),
            scrollDelta: const Offset(0, 120),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.widget<WordContextView>(canvas).position, position);
        await tester.drag(canvas, const Offset(0, -40));
        await tester.pumpAndSettle();
        expect(tester.widget<WordContextView>(canvas).position, position + 1);
        expect(tester.getRect(title), titleRect);
        expect(tester.getRect(play), playRect);
        final orientation = landscape ? 'landscape' : 'portrait';
        await capture('reader-refinements/ios-$orientation-light');
        final container = ProviderScope.containerOf(tester.element(canvas));
        await container
            .read(settingsProvider.notifier)
            .update(
              container
                  .read(settingsProvider)
                  .copyWith(appearance: Appearance.dark),
            );
        await tester.pumpAndSettle();
        await capture('reader-refinements/ios-$orientation-dark');
        await tester.tap(play);
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('immersive-reader')), findsOneWidget);
        await capture('reader-refinements/ios-$orientation-focus');
        await tester.tap(find.byKey(const ValueKey('immersive-reader')));
        await tester.pumpAndSettle();
        final paused = tester.widget<WordContextView>(canvas).position;
        expect(paused, greaterThan(position + 1));
        expect((await store.document(id)).position, paused);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
      await deleteDatabase(file);
      await SystemChrome.setPreferredOrientations([]);
    }
  });
}
