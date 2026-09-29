import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/design.dart';
import '../../app/adaptive_layout.dart';
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
  final _hiddenStars = <int>{};
  final _hiddenBookmarks = <(int, int)>{};

  Future<void> _removeStar(int id) async {
    setState(() => _hiddenStars.add(id));
    try {
      await ref.read(storeProvider).setStarred(id, false);
      ref.read(usageAnalyticsProvider).record(UsageEvent.starRemoved);
      ref.invalidate(savedProvider);
      ref.invalidate(libraryProvider);
    } catch (_) {
      if (mounted) {
        setState(() => _hiddenStars.remove(id));
        showProblem(context, context.l10n.readingUnavailable);
      }
    }
  }

  Future<void> _removeBookmark(int documentId, int position) async {
    final key = (documentId, position);
    setState(() => _hiddenBookmarks.add(key));
    try {
      await ref.read(storeProvider).removeBookmark(documentId, position);
      ref.read(usageAnalyticsProvider).record(UsageEvent.bookmarkRemoved);
      ref.invalidate(savedProvider);
    } catch (_) {
      if (mounted) {
        setState(() => _hiddenBookmarks.remove(key));
        showProblem(context, context.l10n.bookmarkSaveFailed);
      }
    }
  }

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
    ref.listen(savedProvider, (_, next) {
      if (next.isLoading) return;
      final data = next.asData?.value;
      if (data == null) return;
      // Hide dismissed rows only until the store acknowledges their removal.
      // Later additions of the same star or bookmark must be visible again.
      final stars = data.starred.map((book) => book.id).toSet();
      final bookmarks = data.bookmarks
          .map((mark) => (mark.documentId, mark.position))
          .toSet();
      _hiddenStars.removeWhere((id) => !stars.contains(id));
      _hiddenBookmarks.removeWhere((key) => !bookmarks.contains(key));
    });
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
            ReaderLayout.bottomInset(context),
          ),
          children: [
            SectionLabel(context.l10n.starredReadings),
            if (data.starred
                .where((book) => !_hiddenStars.contains(book.id))
                .isEmpty)
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
                    if (!_hiddenStars.contains(book.id))
                      Dismissible(
                        key: ValueKey('star-${book.id}'),
                        direction: DismissDirection.endToStart,
                        background: ColoredBox(
                          color: ReaderColors.of(context).elevated,
                        ),
                        onDismissed: (_) => _removeStar(book.id),
                        child: SettingRow(
                          title: book.title,
                          icon: LucideIcons.bookOpen,
                          subtitle:
                              '${book.format} · ${context.l10n.percentRead((book.progress * 100).floor())}',
                          onTap: () => _open(context, ref, book.id),
                        ),
                      ),
                ],
              ),
            SectionLabel(context.l10n.bookmarks),
            if (data.bookmarks
                .where(
                  (mark) => !_hiddenBookmarks.contains((
                    mark.documentId,
                    mark.position,
                  )),
                )
                .isEmpty)
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
                    if (!_hiddenBookmarks.contains((
                      mark.documentId,
                      mark.position,
                    )))
                      Dismissible(
                        key: ValueKey(
                          'bookmark-${mark.documentId}-${mark.position}',
                        ),
                        direction: DismissDirection.endToStart,
                        background: ColoredBox(
                          color: ReaderColors.of(context).elevated,
                        ),
                        onDismissed: (_) =>
                            _removeBookmark(mark.documentId, mark.position),
                        child: SettingRow(
                          title: mark.title,
                          icon: LucideIcons.bookmark,
                          subtitle: mark.word,
                          value: context.l10n.wordOfWords(
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
                      ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
