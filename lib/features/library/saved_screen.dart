import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/design.dart';
import '../../app/providers.dart';
import '../../app/usage_analytics.dart';
import '../reader/reader_screen.dart';
import '../../l10n/l10n.dart';

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
        showProblem(context, context.l10n.readingUnavailable);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedProvider);
    return PlatformPage(
      title: context.l10n.saved,
      child: saved.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (_, _) => Center(
          child: ActionButton(
            label: context.l10n.tryAgain,
            onPressed: () => ref.invalidate(savedProvider),
          ),
        ),
        data: (data) => ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.paddingOf(context).bottom + 110,
          ),
          children: [
            SectionLabel(context.l10n.starredReadings),
            if (data.starred.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  context.l10n.starredEmpty,
                  style: TextStyle(color: ReaderColors.of(context).secondary),
                ),
              )
            else
              GroupedRows(
                children: [
                  for (final book in data.starred)
                    SettingRow(
                      title: book.title,
                      icon: LucideIcons.bookOpen,
                      subtitle:
                          '${book.format} · ${context.l10n.percentRead((book.progress * 100).floor())}',
                      onTap: () => _open(context, ref, book.id),
                    ),
                ],
              ),
            SectionLabel(context.l10n.bookmarks),
            if (data.bookmarks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  context.l10n.bookmarkEmpty,
                  style: TextStyle(color: ReaderColors.of(context).secondary),
                ),
              )
            else
              GroupedRows(
                children: [
                  for (final mark in data.bookmarks)
                    SettingRow(
                      title: mark.title,
                      icon: LucideIcons.bookmark,
                      subtitle: context.l10n.wordOfWords(
                        mark.position + 1,
                        mark.wordCount,
                      ),
                      onTap: () => _open(
                        context,
                        ref,
                        mark.documentId,
                        position: mark.position,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
