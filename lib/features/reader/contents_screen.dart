import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/design.dart';
import '../../core/document.dart';

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
    title: 'Contents',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (headings.isEmpty) const Text('This reading has no headings.'),
        for (final heading in headings)
          Padding(
            padding: EdgeInsets.only(left: (heading.level - 1) * 12.0),
            child: ActionButton(
              icon: LucideIcons.list,
              label: heading.title,
              onPressed: () => Navigator.pop(context, heading.position),
            ),
          ),
        if (bookmarks.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Bookmarks'),
          for (final position in bookmarks)
            ActionButton(
              icon: LucideIcons.bookmark,
              label: 'Word ${position + 1}',
              onPressed: () => Navigator.pop(context, position),
            ),
        ],
      ],
    ),
  );
}
