import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'providers.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class Measures {
  static const page = 24.0;
  static const gap = 16.0;
  static const target = 48.0;
  static const radius = 16.0;
  static const anchor = 0.42;
}

class ReaderColors {
  const ReaderColors({
    required this.background,
    required this.surface,
    required this.elevated,
    required this.text,
    required this.secondary,
    required this.subtle,
    required this.accent,
    required this.onAccent,
    required this.separator,
    required this.disabled,
    required this.positive,
    required this.warning,
    required this.destructive,
  });
  final Color background,
      surface,
      elevated,
      text,
      secondary,
      subtle,
      accent,
      onAccent,
      separator,
      disabled,
      positive,
      warning,
      destructive;
  Color get focal => accent;
  Color get interactive => accent;
  static const light = ReaderColors(
    background: Color(0xFFF5F8F8),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFE8F0EF),
    text: Color(0xFF152B2B),
    secondary: Color(0xFF47615F),
    subtle: Color(0xFF59716F),
    accent: Color(0xFF006A60),
    onAccent: Color(0xFFFFFFFF),
    separator: Color(0xFFCADAD7),
    disabled: Color(0xFF92A5A1),
    positive: Color(0xFF236733),
    warning: Color(0xFF795700),
    destructive: Color(0xFFB32636),
  );
  static const dark = ReaderColors(
    background: Color(0xFF101D1D),
    surface: Color(0xFF172828),
    elevated: Color(0xFF223737),
    text: Color(0xFFE6F0ED),
    secondary: Color(0xFFB2C8C2),
    subtle: Color(0xFF98B2AC),
    accent: Color(0xFF71DCC4),
    onAccent: Color(0xFF101D1D),
    separator: Color(0xFF34504A),
    disabled: Color(0xFF607A72),
    positive: Color(0xFF9AD29A),
    warning: Color(0xFFE6C675),
    destructive: Color(0xFFFFB2B8),
  );
  static ReaderColors of(BuildContext context) =>
      (isApple(context)
              ? CupertinoTheme.brightnessOf(context)
              : Theme.of(context).brightness) ==
          Brightness.dark
      ? dark
      : light;
}

bool isApple(BuildContext context) =>
    Theme.of(context).platform == TargetPlatform.iOS ||
    Theme.of(context).platform == TargetPlatform.macOS;

/// Navigation remains owned by the platform. Brand treatments stay in content.
class PlatformPage extends ConsumerWidget {
  const PlatformPage({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });
  final String title;
  final Widget child;
  final Widget? trailing;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ReaderColors.of(context);
    final solid =
        ref.watch(settingsProvider).reduceTransparency ||
        MediaQuery.highContrastOf(context);
    final back = Navigator.canPop(context)
        ? IconAction(
            label: 'Back',
            icon: LucideIcons.arrowLeft,
            onPressed: () => Navigator.maybePop(context),
          )
        : null;
    if (isApple(context)) {
      return CupertinoPageScaffold(
        backgroundColor: colors.background,
        navigationBar: CupertinoNavigationBar(
          middle: Text(title),
          automaticallyImplyLeading: false,
          leading: back,
          trailing: trailing,
          backgroundColor: solid
              ? colors.surface
              : colors.surface.withValues(alpha: .88),
          enableBackgroundFilterBlur: !solid,
          border: Border(
            bottom: BorderSide(color: colors.separator.withValues(alpha: .5)),
          ),
        ),
        child: SafeArea(child: child),
      );
    }
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
        leading: back,
        backgroundColor: Colors.transparent,
        flexibleSpace: const GlassSurface(radius: 0, child: SizedBox.expand()),
        actions: [?trailing],
      ),
      body: SafeArea(child: child),
    );
  }
}

Future<T?> pushPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(
      isApple(context)
          ? CupertinoPageRoute(builder: (_) => page)
          : MaterialPageRoute(builder: (_) => page),
    );

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.selected,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool? selected;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final content = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Flexible(child: Text(label)),
            ],
          );
    Widget button;
    if (isApple(context)) {
      button = primary
          ? CupertinoButton.filled(onPressed: onPressed, child: content)
          : CupertinoButton(onPressed: onPressed, child: content);
    } else {
      button = primary
          ? FilledButton(onPressed: onPressed, child: content)
          : TextButton(onPressed: onPressed, child: content);
    }
    return Semantics(
      selected: selected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected == true
              ? ReaderColors.of(context).accent.withValues(alpha: .12)
              : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: button,
      ),
    );
  }
}

class IconAction extends StatelessWidget {
  const IconAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.selected,
  });
  final String label;
  final IconData icon;
  final bool? selected;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    selected: selected,
    button: true,
    enabled: onPressed != null,
    onTap: onPressed,
    child: ExcludeSemantics(
      child: SizedBox(
        width: Measures.target,
        height: Measures.target,
        child: isApple(context)
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onPressed,
                child: Icon(icon),
              )
            : IconButton(
                tooltip: label,
                onPressed: onPressed,
                icon: Icon(icon),
              ),
      ),
    ),
  );
}

Future<void> showProblem(BuildContext context, String message) async {
  if (isApple(context)) {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Could not finish'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  } else {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Could not finish'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BrandPainter(ReaderColors.of(context).accent),
      ),
    ),
  );
}

class _BrandPainter extends CustomPainter {
  _BrandPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    final paint = Paint()..color = color;
    for (final r in [
      const Rect.fromLTWH(5, 20, 12, 8),
      const Rect.fromLTWH(21, 10, 6, 28),
      const Rect.fromLTWH(31, 20, 12, 8),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(3)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BrandPainter old) => old.color != color;
}

/// Restrained Flutter glass, inspired by Apple materials (not UIGlassEffect).
/// A near-opaque tint keeps controls legible over arbitrary scrolled content.
class GlassSurface extends ConsumerWidget {
  const GlassSurface({super.key, required this.child, this.radius = 24});
  final Widget child;
  final double radius;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ReaderColors.of(context);
    final solid =
        ref.watch(settingsProvider).reduceTransparency ||
        MediaQuery.highContrastOf(context);
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surface.withValues(alpha: solid ? 1 : .94),
            colors.elevated.withValues(alpha: solid ? 1 : .88),
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: colors.separator.withValues(alpha: solid ? 1 : .65),
        ),
      ),
      child: child,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: solid
          ? surface
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: surface,
            ),
    );
  }
}
