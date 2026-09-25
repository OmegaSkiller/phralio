import 'dart:ui';

import 'package:flutter_svg/flutter_svg.dart';

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
  // Exact core tokens from the approved brandkit; supporting shades are
  // neutral Paper/Ink blends, never additional accent families.
  static const ink = Color(0xFF182523);
  static const paper = Color(0xFFF4F0E7);
  static const vermilion = Color(0xFFBA4A32);
  static const mist = Color(0xFFC9D1CB);
  static const brick = Color(0xFFA73E2A);
  static const ember = Color(0xFFF29C82);
  static const light = ReaderColors(
    background: paper,
    surface: Color(0xFFFAF7F0),
    elevated: Color(0xFFE8E7DD),
    text: ink,
    secondary: Color(0xFF53605A),
    subtle: Color(0xFF626B63),
    accent: brick,
    onAccent: paper,
    separator: Color(0xFFD1D2C7),
    disabled: Color(0xFF929A91),
    positive: Color(0xFF356044),
    warning: Color(0xFF795700),
    destructive: brick,
  );
  static const dark = ReaderColors(
    background: ink,
    surface: Color(0xFF23322F),
    elevated: Color(0xFF30413C),
    text: paper,
    secondary: mist,
    subtle: Color(0xFFADB7AE),
    accent: ember,
    onAccent: ink,
    separator: Color(0xFF46554F),
    disabled: Color(0xFF708179),
    positive: Color(0xFFA7CEAB),
    warning: Color(0xFFE6C675),
    destructive: ember,
  );
  static ReaderColors of(BuildContext context) =>
      (isApple(context)
              ? CupertinoTheme.brightnessOf(context)
              : Theme.of(context).brightness) ==
          Brightness.dark
      ? dark
      : light;
}

abstract final class ReaderTypography {
  static const ui = 'IBM Plex Sans';
  static const display = 'Newsreader';
  static List<String> fallbacks([String? language]) => language == null
      ? const ['sans-serif']
      : language == 'ja'
      ? const [
          'Hiragino Sans',
          'Noto Sans CJK JP',
          'Noto Sans JP',
          'sans-serif',
        ]
      : const ['PingFang SC', 'Noto Sans CJK SC', 'Noto Sans SC', 'sans-serif'];
  static List<String> readingFallbacks(String language) => [
    ui,
    'Noto Sans',
    ...fallbacks(language),
  ];
  static TextStyle body({Color? color, double size = 17}) => TextStyle(
    fontFamily: ui,
    fontFamilyFallback: fallbacks(),
    fontSize: size,
    color: color,
    height: 1.4,
  );
  static TextStyle editorial(BuildContext context, {double size = 32}) {
    final language = Localizations.localeOf(context).languageCode;
    return TextStyle(
      fontFamily: ['zh', 'ja', 'ru'].contains(language) ? ui : display,
      fontFamilyFallback: fallbacks(language),
      fontVariations: [FontVariation('opsz', size)],
      fontWeight: FontWeight.w500,
      fontSize: size,
      height: 1.15,
      color: ReaderColors.of(context).text,
    );
  }
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
    this.showBrand = false,
  });
  final String title;
  final Widget child;
  final Widget? trailing;
  final bool? largeTitle;
  final bool showBrand;
  @override
  Widget build(BuildContext context) {
    final colors = ReaderColors.of(context);
    final canPop = Navigator.canPop(context);
    final large = largeTitle ?? !canPop;
    final content = SafeArea(
      bottom: false,
      child: Column(
        children: [
          if (showBrand)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 10, 24, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: BrandLockup(),
              ),
            ),
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
                      fontSize: large ? 32 : 20,
                      letterSpacing: large ? -.6 : 0,
                      fontWeight: FontWeight.w500,
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
            child: DefaultTextStyle(
              style: ReaderTypography.body(color: colors.text),
              child: content,
            ),
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

/// Shared input styling keeps contrast and keyboard focus consistent on both
/// text-entry routes while preserving each platform's editing behavior.
class ReaderTextField extends StatefulWidget {
  const ReaderTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.lines = 1,
    this.keyboardType,
    this.autocorrect = true,
  });
  final TextEditingController controller;
  final String hint;
  final String? label;
  final int lines;
  final TextInputType? keyboardType;
  final bool autocorrect;
  @override
  State<ReaderTextField> createState() => _ReaderTextFieldState();
}

class _ReaderTextFieldState extends State<ReaderTextField> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    final colors = ReaderColors.of(context);
    final style = ReaderTypography.body(color: colors.text).copyWith(
      fontFamilyFallback: ReaderTypography.fallbacks(
        Localizations.localeOf(context).languageCode,
      ),
    );
    if (!isApple(context)) {
      return TextField(
        controller: widget.controller,
        maxLines: widget.lines,
        keyboardType: widget.keyboardType,
        autocorrect: widget.autocorrect,
        style: style,
        decoration: InputDecoration(
          hintText: widget.hint,
          labelText: widget.label,
          filled: true,
          fillColor: colors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: colors.secondary),
          ),
        ),
      );
    }
    return Focus(
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: CupertinoTextField(
        controller: widget.controller,
        placeholder: widget.hint,
        maxLines: widget.lines,
        keyboardType: widget.keyboardType,
        autocorrect: widget.autocorrect,
        style: style,
        placeholderStyle: style.copyWith(color: colors.secondary),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _focused ? colors.accent : colors.secondary,
            width: _focused ? 2 : 1,
          ),
        ),
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
  'accent': ReaderColors.of(context).accent.toARGB32(),
  'text': ReaderColors.of(context).text.toARGB32(),
  'secondary': ReaderColors.of(context).secondary.toARGB32(),
  'surface': ReaderColors.of(context).surface.toARGB32(),
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
    this.titleStyle,
    this.value,
    this.trailing,
    this.onTap,
    this.selected,
  });
  final String title;
  final IconData? icon;
  final String? subtitle, value;
  final TextStyle? titleStyle;
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
                Text(
                  title,
                  style: (titleStyle ?? const TextStyle(fontSize: 16)).copyWith(
                    color: colors.text,
                  ),
                ),
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
          style: ReaderTypography.body(color: colors.text),
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
        title: Text(
          context.l10n.couldNotFinish,
          style: ReaderTypography.body(color: ReaderColors.of(context).text)
              .copyWith(fontWeight: FontWeight.w500),
        ),
        content: Text(
          message,
          style: ReaderTypography.body(
            color: ReaderColors.of(context).text,
            size: 15,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.l10n.okay,
              style: ReaderTypography.body(
                color: ReaderColors.of(context).accent,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  } else {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.l10n.couldNotFinish,
          style: ReaderTypography.body(color: ReaderColors.of(context).text)
              .copyWith(fontWeight: FontWeight.w500),
        ),
        content: Text(
          message,
          style: ReaderTypography.body(
            color: ReaderColors.of(context).text,
            size: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.l10n.okay,
              style: ReaderTypography.body(
                color: ReaderColors.of(context).accent,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Render the supplied SVG masters directly; never approximate their paths.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.asset(
      'assets/brand/mark-${ReaderColors.of(context) == ReaderColors.dark ? 'paper' : 'ink'}.svg',
      width: size * 104 / 120,
      height: size,
    ),
  );
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key});
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/brand/logo-${ReaderColors.of(context) == ReaderColors.dark ? 'paper' : 'ink'}.svg',
    width: 140,
    semanticsLabel: 'Phralio',
  );
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
