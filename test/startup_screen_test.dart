import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:phralio/app/startup_screen.dart';

void main() {
  testWidgets('startup plays only source seconds 3–4 and completes once', (
    tester,
  ) async {
    final composition = await tester.runAsync(
      () => AssetLottie('assets/brand/phralio-logo-motion.json').load(),
    );
    expect(composition!.startFrame, 180);
    expect(composition.endFrame, closeTo(240, .02));
    expect(composition.frameRate, 60);
    expect(composition.duration, const Duration(seconds: 1));
    var completions = 0;
    await tester.pumpWidget(
      StartupScreen(reduceMotion: false, onFinished: () => completions++),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(completions, 1);
    expect(
      tester
          .widget<LottieBuilder>(find.byType(LottieBuilder))
          .controller!
          .value,
      1,
    );
    await tester.tapAt(const Offset(100, 100));
    expect(completions, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('startup tap skips and reduced motion does not animate', (
    tester,
  ) async {
    var completions = 0;
    await tester.pumpWidget(
      StartupScreen(reduceMotion: false, onFinished: () => completions++),
    );
    await tester.tapAt(const Offset(100, 100));
    await tester.pumpAndSettle();
    expect(completions, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      StartupScreen(reduceMotion: true, onFinished: () => completions++),
    );
    expect(completions, 2);
    expect(find.byType(LottieBuilder), findsNothing);
    await tester.pumpAndSettle();
    expect(completions, 2);
  });
}
