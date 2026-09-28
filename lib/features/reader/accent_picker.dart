import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/accent.dart';
import '../../app/design.dart';
import '../../core/settings.dart';
import '../../l10n/l10n.dart';

class AccentPicker extends StatelessWidget {
  const AccentPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final AccentColor selected;
  final ValueChanged<AccentColor>? onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = ReaderColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 480 ? 3 : 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in AccentColor.values)
              SizedBox(
                width: (constraints.maxWidth - (columns - 1) * 8) / columns,
                child: Semantics(
                  selected: value == selected,
                  child: CupertinoButton(
                    padding: const EdgeInsets.all(12),
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    onPressed: onSelected == null
                        ? null
                        : () => onSelected!(value),
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: colors.isDark ? value.dark : value.light,
                              shape: BoxShape.circle,
                            ),
                            child: value == selected
                                ? Icon(
                                    LucideIcons.check,
                                    size: 18,
                                    color: colors.onAccent,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.l10n.accentName(value),
                            style: ReaderTypography.body(
                              color: colors.text,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
