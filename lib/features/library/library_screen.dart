import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/design.dart';
import '../../app/providers.dart';
import '../../app/usage_analytics.dart';
import '../../core/document.dart';
import '../../core/file_import.dart';
import '../../core/remote_import.dart';
import '../reader/reader_screen.dart';
import 'paste_screen.dart';
import 'url_screen.dart';
import '../../l10n/l10n.dart';

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
        await showProblem(context, context.l10n.readingCouldNotSave);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() => _perform(() async {
    final l10n = context.l10n;
    final analytics = ref.read(usageAnalyticsProvider);
    analytics.record(UsageEvent.importRequested);
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(
            label: l10n.importFile,
            extensions: ['txt', 'epub', 'md', 'markdown'],
            mimeTypes: ['text/plain', 'application/epub+zip', 'text/markdown'],
            uniformTypeIdentifiers: [
              'public.plain-text',
              'net.daringfireball.markdown',
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
        throw FormatException(l10n.fileTooLarge);
      }
      // Bound the stream too: providers can report a stale or unknown length.
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in file.openRead()) {
        if (bytes.length + chunk.length > FileImport.maxFileBytes) {
          throw FormatException(l10n.fileTooLarge);
        }
        bytes.add(chunk);
      }
      var book = await compute(FileImport.parse, (
        name: file.name,
        bytes: bytes.takeBytes(),
      ));
      if (book.format == 'Markdown' && book.images.isNotEmpty) {
        final importer = RemoteImport();
        try {
          book = await importer.hydrateImages(book);
        } finally {
          importer.close();
        }
      }
      if (!mounted) return;
      final id = await ref.read(storeProvider).importReading(book);
      analytics.record(
        UsageEvent.importSucceeded,
        source: switch (book.format) {
          'EPUB' => ReadingSource.epub,
          'Markdown' => ReadingSource.markdown,
          _ => ReadingSource.txt,
        },
      );
      if (mounted) await _open(id);
    } on FormatException catch (error) {
      analytics.record(UsageEvent.importFailed);
      if (l10n.localeName == 'en' || error.message == l10n.fileTooLarge) {
        rethrow;
      }
      throw FormatException(l10n.fileReadFailed);
    } catch (_) {
      analytics.record(UsageEvent.importFailed);
      rethrow;
    }
  });

  Future<void> _clipboard() => _perform(() async {
    final l10n = context.l10n;
    final value = await Clipboard.getData(Clipboard.kTextPlain);
    final text = value?.text;
    if (text == null || text.trim().isEmpty) {
      throw FormatException(l10n.clipboardEmpty);
    }
    final id = await ref.read(storeProvider).add(l10n.clipboardReading, text);
    ref
        .read(usageAnalyticsProvider)
        .record(UsageEvent.importSucceeded, source: ReadingSource.clipboard);
    ref.invalidate(libraryProvider);
    if (mounted) await _open(id);
  });

  List<MenuChoice> get _addChoices => [
    MenuChoice(context.l10n.importFile, LucideIcons.fileUp, _import),
    MenuChoice(
      context.l10n.readUrl,
      LucideIcons.link,
      () => pushPage(context, const UrlScreen()),
    ),
    MenuChoice(context.l10n.readClipboard, LucideIcons.clipboard, _clipboard),
    MenuChoice(
      context.l10n.addText,
      LucideIcons.textCursorInput,
      () => pushPage(context, const PasteScreen()),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = ReaderColors.of(context);
    final library = ref.watch(libraryProvider);
    return PlatformPage(
      title: context.l10n.home,
      trailing: ActionMenu(
        label: context.l10n.addReading,
        icon: LucideIcons.plus,
        enabled: !_busy,
        choices: _addChoices,
      ),
      child: library.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.libraryCouldNotLoad),
              ActionButton(
                label: context.l10n.tryAgain,
                onPressed: () => ref.invalidate(libraryProvider),
              ),
            ],
          ),
        ),
        data: (all) {
          final documents = _starredOnly
              ? all.where((d) => d.starred).toList()
              : all;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              24,
              8,
              24,
              MediaQuery.paddingOf(context).bottom + 110,
            ),
            children: [
              if (_busy)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      const CupertinoActivityIndicator(radius: 8),
                      const SizedBox(width: 10),
                      Text(context.l10n.openingReading),
                    ],
                  ),
                ),
              if (all.isEmpty) ...[
                const SizedBox(height: 56),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: BrandMark(size: 56),
                ),
                const SizedBox(height: 24),
                Text(
                  context.l10n.makeRoom,
                  style: TextStyle(
                    fontSize: 32,
                    height: 1.15,
                    letterSpacing: -.8,
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.quietShelf,
                  style: TextStyle(fontSize: 17, color: colors.secondary),
                ),
                const SizedBox(height: 28),
                ActionButton(
                  label: context.l10n.importFile,
                  primary: true,
                  icon: LucideIcons.plus,
                  onPressed: _busy ? null : _import,
                ),
                const SizedBox(height: 8),
                ActionButton(
                  label: context.l10n.tryShortReading,
                  onPressed: _busy
                      ? null
                      : () => _perform(() async {
                          final id = await ref
                              .read(storeProvider)
                              .add(context.l10n.sampleTitle, sampleText);
                          ref
                              .read(usageAnalyticsProvider)
                              .record(
                                UsageEvent.sampleAdded,
                                source: ReadingSource.sample,
                              );
                          ref.invalidate(libraryProvider);
                          if (mounted) await _open(id);
                        }),
                ),
                const SizedBox(height: 24),
                Text(
                  context.l10n.localFormats,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: colors.secondary),
                ),
              ] else ...[
                if (!_starredOnly) ...[
                  _continuation(all.first),
                  const SizedBox(height: 24),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _starredOnly
                            ? context.l10n.starred
                            : context.l10n.recent,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: colors.text,
                        ),
                      ),
                    ),
                    ActionMenu(
                      label: context.l10n.libraryFilter,
                      icon: LucideIcons.listFilter,
                      choices: [
                        MenuChoice(
                          context.l10n.recent,
                          LucideIcons.clock3,
                          () => _selectFilter(false),
                          selected: !_starredOnly,
                        ),
                        MenuChoice(
                          context.l10n.starred,
                          LucideIcons.star,
                          () => _selectFilter(true),
                          selected: _starredOnly,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (documents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      context.l10n.starredEmpty,
                      style: TextStyle(color: colors.secondary),
                    ),
                  ),
                for (final document in documents) _entry(document),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _continuation(LibraryEntry document) {
    final colors = ReaderColors.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.bookOpen, size: 20, color: colors.accent),
              const SizedBox(width: 10),
              Text(
                context.l10n.continueReading,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            document.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              height: 1.15,
              letterSpacing: -.7,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${document.format} · ${context.l10n.percentRead((document.progress * 100).floor())}',
            style: TextStyle(fontSize: 14, color: colors.secondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ActionButton(
              label: context.l10n.read,
              icon: LucideIcons.play,
              primary: true,
              onPressed: _busy
                  ? null
                  : () => _perform(() => _open(document.id)),
            ),
          ),
        ],
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
      const padding = EdgeInsets.symmetric(vertical: 16);
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
                              fontSize: 17,
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
                            '${document.format} · ${context.l10n.percentRead(percent)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.secondary,
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
                ? context.l10n.unstarTitle(document.title)
                : context.l10n.starTitle(document.title),
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
                    ref.invalidate(savedProvider);
                  }),
          ),
        ],
      ),
    );
  }
}
