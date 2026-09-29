import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

/// The bundled composition is the original motion's 3–4 second excerpt.
/// Completion (or a tap) continues as soon as the library is ready.
class StartupScreen extends StatefulWidget {
  const StartupScreen({
    super.key,
    required this.reduceMotion,
    required this.onFinished,
  });
  final bool reduceMotion;
  final VoidCallback onFinished;

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });
    if (widget.reduceMotion) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    }
  }

  void _finish() {
    if (!mounted || _finished) return;
    _finished = true;
    _controller.stop();
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const paper = Color(0xFFF4F0E7);
    final dark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    final still = SvgPicture.asset(
      'assets/brand/logo-${dark ? 'paper' : 'ink'}.svg',
      width: 180,
    );
    final animation = Lottie.asset(
      'assets/brand/phralio-logo-motion.json',
      controller: _controller,
      onLoaded: (composition) {
        if (_finished) return;
        _controller
          ..duration = composition.duration
          ..forward();
      },
      repeat: false,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
        return Center(child: still);
      },
    );
    // Map the supplied Paper/Ink/Brick artwork to black/white/Ember without
    // changing its frames or split-P geometry. The source asset stays intact.
    const darkMotion = ColorFilter.matrix([
      0.159993,
      -1.428761,
      0,
      0,
      303.864331,
      -0.587641,
      -0.622200,
      0,
      0,
      292.712432,
      -0.813670,
      -0.378356,
      0,
      0,
      289.340928,
      0,
      0,
      0,
      1,
      0,
    ]);
    final content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: ColoredBox(
        color: dark ? const Color(0xFF000000) : paper,
        child: Center(
          child: widget.reduceMotion
              ? still
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: dark
                        ? ColorFiltered(
                            colorFilter: darkMotion,
                            child: animation,
                          )
                        : animation,
                  ),
                ),
        ),
      ),
    );
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return CupertinoApp(
        debugShowCheckedModeBanner: false,
        theme: CupertinoThemeData(
          brightness: dark ? Brightness.dark : Brightness.light,
        ),
        home: CupertinoPageScaffold(child: content),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(body: content),
    );
  }
}
