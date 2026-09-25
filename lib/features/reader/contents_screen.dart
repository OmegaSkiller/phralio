import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/design.dart';
import '../../core/document.dart';
import '../../l10n/l10n.dart';

class ContentsScreen extends StatelessWidget {
  const ContentsScreen({
    super.key,
    required this.headings,
    required this.bookmarks,
  });
  final List<ReadingHeading> headings;
  final List<int> bookmarks;

  @override
  Widget build(BuildContext context) => PlatformPage(
    title: context.l10n.contents,
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (headings.isEmpty) Text(context.l10n.noHeadings),
        if (headings.isNotEmpty)
          GroupedRows(
            children: [
              for (final heading in headings)
                Padding(
                  padding: EdgeInsets.only(left: (heading.level - 1) * 12.0),
                  child: SettingRow(
                    icon: LucideIcons.list,
                    title: heading.title,
                    onTap: () => Navigator.pop(context, heading.position),
                  ),
                ),
            ],
          ),
        if (bookmarks.isNotEmpty) ...[
          const SizedBox(height: 24),
          SectionLabel(context.l10n.bookmarks),
          for (final position in bookmarks)
            SettingRow(
              icon: LucideIcons.bookmark,
              title: context.l10n.wordNumber(position + 1),
              onTap: () => Navigator.pop(context, position),
            ),
        ],
      ],
    ),
  );
}
