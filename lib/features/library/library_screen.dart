import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/design.dart';
import '../../app/identity.dart';
import '../../app/providers.dart';
import '../../app/usage_analytics.dart';
import '../../core/document.dart';
import '../../core/file_import.dart';
import '../reader/reader_screen.dart';
import '../reader/settings_screen.dart';
import 'paste_screen.dart';

const sampleText = '''A little more room for words.

Reading can be a place to settle, not another task to race through. Bring a passage here, choose a comfortable pace, and let each word arrive at the same quiet point.

Start slowly. Notice how commas make a small space, and how a full stop gives a thought time to land. You can pause whenever you like, return to a sentence, or change the pace as you go.

The number on the screen is a setting, not a score. Different writing asks for different attention. A familiar story and a difficult argument do not need the same rhythm.

Your reading stays on this device. There is no account to create and no cloud to wait for. When you leave, your place is saved. Come back when you are ready.

One word. Then the next.''';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool _starredOnly = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref.read(usageAnalyticsProvider).view(UsageScreen.library);
  }

  Future<void> _open(int id) async {
    final document = await ref.read(storeProvider).document(id);
    ref.invalidate(libraryProvider);
    if (!mounted) return;
    await pushPage(context, ReaderScreen(document: document));
    if (mounted) {
      ref.invalidate(libraryProvider);
      ref.read(usageAnalyticsProvider).view(UsageScreen.library);
    }
  }

  void _selectFilter(bool starredOnly) {
    if (_starredOnly == starredOnly) return;
    setState(() => _starredOnly = starredOnly);
    ref.read(usageAnalyticsProvider).record(UsageEvent.libraryFilterChanged);
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on FormatException catch (e) {
      if (mounted) await showProblem(context, e.message);
    } catch (_) {
      if (mounted) {
        await showProblem(
          context,
          'The reading could not be opened or saved. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() => _perform(() async {
    final analytics = ref.read(usageAnalyticsProvider);
    analytics.record(UsageEvent.importRequested);
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Books and text',
            extensions: ['txt', 'epub'],
            mimeTypes: ['text/plain', 'application/epub+zip'],
            uniformTypeIdentifiers: [
              'public.plain-text',
              'org.idpf.epub-container',
            ],
          ),
        ],
      );
      if (file == null) {
        analytics.record(UsageEvent.importCancelled);
        return;
      }
      if (!mounted) return;
      if (await file.length() > FileImport.maxFileBytes) {
        throw const FormatException('Choose a file smaller than 32 MB.');
      }
      // Bound the stream too: providers can report a stale or unknown length.
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in file.openRead()) {
        if (bytes.length + chunk.length > FileImport.maxFileBytes) {
          throw const FormatException('Choose a file smaller than 32 MB.');
        }
        bytes.add(chunk);
      }
      final book = await compute(FileImport.parse, (
        name: file.name,
        bytes: bytes.takeBytes(),
      ));
      if (!mounted) return;
      final id = await ref.read(storeProvider).importReading(book);
      analytics.record(
        UsageEvent.importSucceeded,
        source: file.name.toLowerCase().endsWith('.epub')
            ? ReadingSource.epub
            : ReadingSource.txt,
      );
      if (mounted) await _open(id);
    } catch (_) {
      analytics.record(UsageEvent.importFailed);
      rethrow;
    }
  });

  @override
  Widget build(BuildContext context) {
    final colors = ReaderColors.of(context);
    final library = ref.watch(libraryProvider);
    return PlatformPage(
      title: ProductIdentity.displayName,
      trailing: IconAction(
        label: 'Reading settings',
        icon: LucideIcons.slidersHorizontal,
        onPressed: () => pushPage(context, const SettingsScreen()),
      ),
      child: library.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your library could not be loaded.'),
              ActionButton(
                label: 'Try again',
                onPressed: () => ref.invalidate(libraryProvider),
              ),
            ],
          ),
        ),
        data: (all) {
          final documents = _starredOnly
              ? all.where((d) => d.starred).toList()
              : all;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrandMark(size: 40),
                      const SizedBox(height: 20),
                      Text(
                        'Make room\nfor a good read.',
                        style: TextStyle(
                          fontSize: 34,
                          height: 1.12,
                          letterSpacing: -1,
                          fontWeight: FontWeight.w600,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your words. Your pace.',
                        style: TextStyle(fontSize: 17, color: colors.secondary),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionButton(
                            label: 'Import file',
                            primary: true,
                            icon: LucideIcons.fileUp,
                            onPressed: _busy ? null : _import,
                          ),
                          ActionButton(
                            label: 'Add text',
                            icon: LucideIcons.plus,
                            onPressed: _busy
                                ? null
                                : () => pushPage(context, const PasteScreen()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_busy) ...[
                            const CupertinoActivityIndicator(radius: 7),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                _busy
                                    ? 'Opening your reading…'
                                    : 'TXT & EPUB · Saved on this device',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.secondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      GlassSurface(
                        child: Wrap(
                          spacing: 4,
                          children: [
                            ActionButton(
                              label: 'Recent',
                              icon: LucideIcons.clock3,
                              selected: !_starredOnly,
                              onPressed: () => _selectFilter(false),
                            ),
                            ActionButton(
                              label: 'Starred',
                              icon: LucideIcons.star,
                              selected: _starredOnly,
                              onPressed: () => _selectFilter(true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (documents.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _starredOnly
                              ? 'Keep your favorites close.'
                              : 'A quiet shelf, ready for your words.',
                        ),
                        const SizedBox(height: 8),
                        if (_starredOnly)
                          Text(
                            'Tap the star beside a reading to find it here.',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.secondary,
                            ),
                          )
                        else
                          ActionButton(
                            label: 'Try a short reading',
                            onPressed: _busy
                                ? null
                                : () => _perform(() async {
                                    await ref
                                        .read(storeProvider)
                                        .add('A little more room', sampleText);
                                    ref
                                        .read(usageAnalyticsProvider)
                                        .record(
                                          UsageEvent.sampleAdded,
                                          source: ReadingSource.sample,
                                        );
                                    ref.invalidate(libraryProvider);
                                  }),
                          ),
                      ],
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList.builder(
                  itemCount: documents.length,
                  itemBuilder: (context, index) => _entry(documents[index]),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _entry(LibraryEntry document) {
    final colors = ReaderColors.of(context);
    final percent = document.progress == 1
        ? 100
        : (document.progress * 100).floor();
    Widget openButton(Widget child) {
      final onPressed = _busy ? null : () => _perform(() => _open(document.id));
      const padding = EdgeInsets.symmetric(vertical: 22);
      return isApple(context)
          ? CupertinoButton(
              padding: padding,
              onPressed: onPressed,
              child: child,
            )
          : InkWell(
              onTap: onPressed,
              child: Padding(padding: padding, child: child),
            );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.separator)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              child: openButton(
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 58,
                      decoration: BoxDecoration(
                        color: colors.elevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        document.format == 'EPUB'
                            ? LucideIcons.bookOpen
                            : LucideIcons.fileText,
                        color: colors.accent,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colors.text,
                            ),
                          ),
                          if (document.author.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              document.author,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.secondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 7),
                          Text(
                            '${document.format} · ${document.wordCount} words',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.secondary,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            '$percent% read',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.accent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: document.progress,
                              minHeight: 3,
                              color: colors.accent,
                              backgroundColor: colors.separator,
                              semanticsLabel: 'Whole file progress',
                              semanticsValue: '$percent',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconAction(
            label: document.starred
                ? 'Unstar ${document.title}'
                : 'Star ${document.title}',
            selected: document.starred,
            icon: document.starred ? LucideIcons.starOff : LucideIcons.star,
            onPressed: _busy
                ? null
                : () => _perform(() async {
                    await ref
                        .read(storeProvider)
                        .setStarred(document.id, !document.starred);
                    ref
                        .read(usageAnalyticsProvider)
                        .record(
                          document.starred
                              ? UsageEvent.starRemoved
                              : UsageEvent.starAdded,
                        );
                    ref.invalidate(libraryProvider);
                  }),
          ),
        ],
      ),
    );
  }
}
