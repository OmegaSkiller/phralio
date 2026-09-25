import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/design.dart';
import '../../app/providers.dart';
import '../../app/usage_analytics.dart';
import '../reader/reader_screen.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(usageAnalyticsProvider).view(UsageScreen.saved);
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    int id, {
    int? position,
  }) async {
    try {
      final document = await ref.read(storeProvider).document(id);
      if (!context.mounted) return;
      await pushPage(
        context,
        ReaderScreen(
          document: position == null ? document : document.atPosition(position),
        ),
      );
      ref.invalidate(savedProvider);
      ref.invalidate(libraryProvider);
    } catch (_) {
      if (context.mounted) {
        showProblem(context, 'This reading could not be opened.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedProvider);
    return PlatformPage(
      title: 'Saved',
      child: saved.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (_, _) => Center(
          child: ActionButton(
            label: 'Try again',
            onPressed: () => ref.invalidate(savedProvider),
          ),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Bookmarks',
              style: TextStyle(
                fontSize: 22,
                color: ReaderColors.of(context).text,
              ),
            ),
            if (data.bookmarks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Save a place from the reader to find it here.'),
              ),
            for (final mark in data.bookmarks)
              ActionButton(
                icon: LucideIcons.bookmark,
                label:
                    '${mark.title} · Word ${mark.position + 1} of ${mark.wordCount}',
                onPressed: () => _open(
                  context,
                  ref,
                  mark.documentId,
                  position: mark.position,
                ),
              ),
            const SizedBox(height: 28),
            Text(
              'Starred readings',
              style: TextStyle(
                fontSize: 22,
                color: ReaderColors.of(context).text,
              ),
            ),
            if (data.starred.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Star a reading from Home to keep it here.'),
              ),
            for (final book in data.starred)
              ActionButton(
                icon: LucideIcons.star,
                label:
                    '${book.title} · ${book.format} · ${(book.progress * 100).floor()}% read',
                onPressed: () => _open(context, ref, book.id),
              ),
          ],
        ),
      ),
    );
  }
}
