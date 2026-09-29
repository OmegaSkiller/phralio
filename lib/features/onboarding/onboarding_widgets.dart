import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/design.dart';

/// A bounded practice surface, shared by the lessons and their source sheets.
class OnboardingCard extends StatelessWidget {
  const OnboardingCard({super.key, required this.child, this.padding = 20});
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final colors = ReaderColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.separator),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    );
  }
}

class OnboardingChoice extends StatelessWidget {
  const OnboardingChoice({
    super.key,
    required this.title,
    required this.icon,
    required this.onPressed,
    this.subtitle,
    this.selected = false,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = ReaderColors.of(context);
    final content = Row(
      children: [
        Icon(icon, size: 24, color: selected ? colors.accent : colors.text),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: ReaderTypography.body(color: colors.text)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: ReaderTypography.body(
                    color: colors.secondary,
                    size: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          selected ? LucideIcons.circleCheck : LucideIcons.chevronRight,
          size: 20,
          color: selected ? colors.accent : colors.secondary,
        ),
      ],
    );
    return Semantics(
      selected: selected,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? colors.elevated : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colors.accent : colors.separator,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: isApple(context)
            ? CupertinoButton(
                padding: const EdgeInsets.all(18),
                onPressed: onPressed,
                child: content,
              )
            : TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: onPressed,
                child: content,
              ),
      ),
    );
  }
}

class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    super.key,
    required this.value,
    required this.label,
  });
  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = ReaderColors.of(context);
    return Semantics(
      label: label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 5,
          color: colors.accent,
          backgroundColor: colors.elevated,
          semanticsLabel: label,
        ),
      ),
    );
  }
}
