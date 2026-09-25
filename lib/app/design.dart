import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'providers.dart';
import 'native_controls.dart';
import '../l10n/l10n.dart';

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
    background: Color(0xFFF4F5F7),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFE9ECF3),
    text: Color(0xFF1B1D24),
    secondary: Color(0xFF626773),
    subtle: Color(0xFF646A76),
    accent: Color(0xFF2959D1),
    onAccent: Color(0xFFFFFFFF),
    separator: Color(0xFFE1E3E9),
    disabled: Color(0xFF92A5A1),
    positive: Color(0xFF236733),
    warning: Color(0xFF795700),
    destructive: Color(0xFFB32636),
  );
  static const dark = ReaderColors(
    background: Color(0xFF101115),
    surface: Color(0xFF1D1F25),
    elevated: Color(0xFF292D36),
    text: Color(0xFFF1F2F7),
    secondary: Color(0xFFB7BCC9),
    subtle: Color(0xFF999FAF),
    accent: Color(0xFF91B6FF),
    onAccent: Color(0xFF101115),
    separator: Color(0xFF323640),
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

/// A quiet header; navigation controls float above an opaque content canvas.
class PlatformPage extends StatelessWidget {
  const PlatformPage({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.largeTitle,
  });
  final String title;
  final Widget child;
  final Widget? trailing;
  final bool? largeTitle;
  @override
  Widget build(BuildContext context) {
    final colors = ReaderColors.of(context);
    final canPop = Navigator.canPop(context);
    final large = largeTitle ?? !canPop;
    final content = SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(large ? 24 : 14, 12, 20, 12),
            child: Row(
              children: [
                if (canPop) ...[
                  IconAction(
                    label: context.l10n.back,
                    icon: LucideIcons.chevronLeft,
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: large ? 34 : 20,
                      letterSpacing: large ? -1 : -.3,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
    return isApple(context)
        ? CupertinoPageScaffold(
            backgroundColor: colors.background,
            child: content,
          )
        : Scaffold(backgroundColor: colors.background, body: content);
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
          ? CupertinoButton.filled(
              borderRadius: BorderRadius.circular(30),
              onPressed: onPressed,
              child: content,
            )
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

class IconAction extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    if (NativeControl.available) {
      return SizedBox(
        width: 48,
        height: 48,
        child: NativeControl(
          configuration: nativeStyle(context, ref)
            ..addAll({
              'kind': 'button',
              'label': label,
              'icon': icon.codePoint,
              'enabled': onPressed != null,
              'selected': selected == true,
            }),
          onSelect: (_) => onPressed?.call(),
        ),
      );
    }
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      enabled: onPressed != null,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: SizedBox(
          width: 48,
          height: 48,
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
}

Map<String, Object?> nativeStyle(BuildContext context, WidgetRef ref) => {
  'dark': ReaderColors.of(context) == ReaderColors.dark,
  'solid':
      ref.watch(settingsProvider.select((s) => s.reduceTransparency)) ||
      MediaQuery.highContrastOf(context),
  'textScale': MediaQuery.textScalerOf(context).scale(14) / 14,
};

class MenuChoice {
  const MenuChoice(
    this.label,
    this.icon,
    this.onSelected, {
    this.selected = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool selected;
}

class ActionMenu extends ConsumerWidget {
  const ActionMenu({
    super.key,
    required this.label,
    required this.choices,
    this.icon = LucideIcons.ellipsis,
    this.enabled = true,
  });
  final String label;
  final IconData icon;
  final bool enabled;
  final List<MenuChoice> choices;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (NativeControl.available) {
      return SizedBox(
        width: 48,
        height: 48,
        child: NativeControl(
          configuration: nativeStyle(context, ref)
            ..addAll({
              'kind': 'menu',
              'label': label,
              'icon': icon.codePoint,
              'enabled': enabled,
              'items': [
                for (var i = 0; i < choices.length; i++)
                  {
                    'id': '$i',
                    'label': choices[i].label,
                    'icon': choices[i].icon.codePoint,
                    'selected': choices[i].selected,
                  },
              ],
            }),
          onSelect: (id) {
            final index = int.tryParse(id);
            if (enabled &&
                index != null &&
                index >= 0 &&
                index < choices.length) {
              choices[index].onSelected();
            }
          },
        ),
      );
    }
    return IconAction(
      label: label,
      icon: icon,
      onPressed: enabled
          ? () => showReaderSheet(
              context,
              label,
              (sheetContext) => GroupedRows(
                children: [
                  for (final choice in choices)
                    SettingRow(
                      title: choice.label,
                      selected: choice.selected,
                      icon: choice.icon,
                      trailing: choice.selected
                          ? const Icon(LucideIcons.check, size: 20)
                          : null,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        choice.onSelected();
                      },
                    ),
                ],
              ),
            )
          : null,
    );
  }
}

class GroupedRows extends StatelessWidget {
  const GroupedRows({
    super.key,
    required this.children,
    this.separatorInset = 56,
  });
  final List<Widget> children;
  final double separatorInset;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: ColoredBox(
      color: ReaderColors.of(context).surface,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Padding(
                padding: EdgeInsets.only(left: separatorInset),
                child: Container(
                  height: .5,
                  color: ReaderColors.of(context).separator,
                ),
              ),
            children[i],
          ],
        ],
      ),
    ),
  );
}

class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.selected,
  });
  final String title;
  final IconData? icon;
  final String? subtitle, value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool? selected;
  @override
  Widget build(BuildContext context) {
    final colors = ReaderColors.of(context);
    final inlineValue =
        value != null &&
        MediaQuery.sizeOf(context).width >= 360 &&
        MediaQuery.textScalerOf(context).scale(16) <= 21;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: colors.secondary),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, color: colors.text)),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 13, color: colors.secondary),
                  ),
                ],
                if (value != null && !inlineValue) ...[
                  const SizedBox(height: 4),
                  Text(
                    value!,
                    style: TextStyle(fontSize: 14, color: colors.secondary),
                  ),
                ],
              ],
            ),
          ),
          if (inlineValue) ...[
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * .4,
              ),
              child: Text(
                value!,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: colors.secondary),
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ] else if (onTap != null) ...[
            const SizedBox(width: 12),
            Icon(LucideIcons.chevronRight, color: colors.subtle, size: 17),
          ],
        ],
      ),
    );
    return onTap == null
        ? content
        : Semantics(
            selected: selected,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onTap,
              child: content,
            ),
          );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 28, 4, 12),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -.3,
        color: ReaderColors.of(context).text,
      ),
    ),
  );
}

Future<T?> showReaderSheet<T>(
  BuildContext context,
  String title,
  WidgetBuilder builder,
) {
  Widget content(BuildContext sheetContext, ScrollController? controller) {
    final colors = ReaderColors.of(sheetContext);
    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        top: false,
        child: DefaultTextStyle(
          style: TextStyle(fontSize: 17, color: colors.text),
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.separator,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconAction(
                      label: sheetContext.l10n.close,
                      icon: LucideIcons.x,
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                builder(sheetContext),
              ],
            ),
          ),
        ),
      ),
    );
  }

  if (isApple(context)) {
    return showCupertinoSheet<T>(
      context: context,
      topGap: .14,
      scrollableBuilder: (context, controller) => content(context, controller),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: content(context, null),
    ),
  );
}

Future<void> showProblem(BuildContext context, String message) async {
  if (isApple(context)) {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(context.l10n.couldNotFinish),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.okay),
          ),
        ],
      ),
    );
  } else {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.couldNotFinish),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.okay),
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
