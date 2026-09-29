import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design.dart';
import '../../app/adaptive_layout.dart';
import '../../app/providers.dart';
import '../../app/usage_analytics.dart';
import '../../core/document.dart';
import '../../core/playback.dart';
import '../../core/settings.dart';
import '../library/library_store.dart';
import 'focal_word.dart';
import 'word_context_view.dart';
import 'contents_screen.dart';
import 'settings_screen.dart';
import '../../l10n/l10n.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.document,
    this.onImmersiveChanged,
  });
  final ReaderDocument document;
  final ValueChanged<bool>? onImmersiveChanged;
  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  late final Playback _engine;
  late final LibraryStore _store;
  late final StreamSubscription<void> _subscription;
  Future<void> _writes = Future.value();
  bool _playing = false;
  bool _saveFailed = false;
  bool _completionReported = false;
  bool _seeking = false;
  bool _scrolling = false;
  bool _immersive = false;
  Set<int> _bookmarks = {};
  int _lastCheckpoint = -1;
  ValueChanged<bool>? _shellFocusChanged;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shellFocusChanged = ReaderLayout.maybeOf(context)?.onImmersiveChanged;
  }

  void _reportImmersive() {
    _shellFocusChanged?.call(_immersive);
    widget.onImmersiveChanged?.call(_immersive);
  }

  int get _percentRead =>
      _engine.completed ? 100 : (_engine.progress * 100).floor();
  @override
  void initState() {
    super.initState();
    _store = ref.read(storeProvider);
    _engine = Playback(
      widget.document.tokens,
      settings: ref.read(settingsProvider),
      position: widget.document.position,
    );
    _completionReported = _engine.completed;
    unawaited(_loadBookmarks());
    ref.read(usageAnalyticsProvider).view(UsageScreen.reader);
    WidgetsBinding.instance.addObserver(this);
    _subscription = _engine.changes.listen((_) {
      if (_engine.completed && !_completionReported && _playing && !_seeking) {
        _completionReported = true;
        ref
            .read(usageAnalyticsProvider)
            .record(UsageEvent.readingFinished, screen: UsageScreen.reader);
      } else if (!_engine.completed) {
        _completionReported = false;
      }
      if (_engine.completed && _immersive) {
        _leaveImmersive();
      }
      if (_playing != _engine.playing && mounted) {
        setState(() => _playing = _engine.playing);
      }
      if (!_scrolling &&
          (!_engine.playing ||
              (_engine.position - _lastCheckpoint).abs() >= 10)) {
        unawaited(_save());
      }
    });
  }

  Future<void> _save({bool refreshLibrary = false}) {
    final position = _engine.position;
    _lastCheckpoint = position;
    _writes = _writes
        .then((_) => _store.savePosition(widget.document, position))
        .then((_) {
          if (mounted && refreshLibrary) ref.invalidate(libraryProvider);
          if (mounted && _saveFailed) setState(() => _saveFailed = false);
        })
        .catchError((Object _) {
          if (mounted && !_saveFailed) setState(() => _saveFailed = true);
        });
    return _writes;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _engine.pause();
      if (_immersive) _leaveImmersive();
      unawaited(_save());
    }
  }

  @override
  void dispose() {
    if (_immersive) {
      final notify = _shellFocusChanged;
      WidgetsBinding.instance.addPostFrameCallback((_) => notify?.call(false));
    }
    WidgetsBinding.instance.removeObserver(this);
    _subscription.cancel();
    unawaited(_save());
    _engine.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    final wasPlaying = _engine.playing;
    wasPlaying ? _engine.pause() : _engine.play();
    if (wasPlaying != _engine.playing) {
      setState(() => _immersive = _engine.playing);
      _reportImmersive();
      ref
          .read(usageAnalyticsProvider)
          .record(
            wasPlaying ? UsageEvent.readingPaused : UsageEvent.readingStarted,
            screen: UsageScreen.reader,
          );
    }
  }

  void _leaveImmersive() {
    if (!mounted) return;
    setState(() => _immersive = false);
    _reportImmersive();
  }

  Future<void> _loadBookmarks() async {
    final values = await _store.bookmarksFor(widget.document.id);
    if (mounted) setState(() => _bookmarks = values.toSet());
  }

  Future<void> _toggleBookmark() async {
    final position = _engine.position.clamp(0, _engine.tokens.length - 1);
    final wasSaved = _bookmarks.contains(position);
    setState(() {
      _bookmarks = {..._bookmarks};
      if (wasSaved) {
        _bookmarks.remove(position);
      } else {
        _bookmarks.add(position);
      }
    });
    try {
      await _store.toggleBookmark(widget.document.id, position);
      ref
          .read(usageAnalyticsProvider)
          .record(
            wasSaved ? UsageEvent.bookmarkRemoved : UsageEvent.bookmarkAdded,
            screen: UsageScreen.reader,
          );
      ref.invalidate(savedProvider);
    } catch (_) {
      if (mounted) {
        setState(() {
          if (wasSaved) {
            _bookmarks.add(position);
          } else {
            _bookmarks.remove(position);
          }
        });
        showProblem(context, context.l10n.bookmarkSaveFailed);
      }
    }
  }

  Future<void> _contents() async {
    ref
        .read(usageAnalyticsProvider)
        .record(UsageEvent.contentsOpened, screen: UsageScreen.reader);
    final position = await pushPage<int>(
      context,
      ContentsScreen(
        headings: widget.document.headings,
        bookmarks: _bookmarks.toList()..sort(),
      ),
    );
    if (position == null || !mounted) return;
    _seek(position);
  }

  Widget _wordOrImage(BuildContext context) {
    final token = _engine.current;
    if (token == null) {
      return Center(child: Text(context.l10n.goodPlaceToPause));
    }
    if (!token.isImage) {
      return FocalWord(
        token: token,
        fontSize: _engine.settings.fontSize,
        readingFont: _engine.settings.readingFont,
        highlight: _engine.settings.highlight,
      );
    }
    ReadingImage? image;
    for (final candidate in widget.document.images) {
      if (candidate.position == _engine.position) {
        image = candidate;
        break;
      }
    }
    if (image?.bytes case final bytes?) {
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        height: 260,
        errorBuilder: (_, _, _) => Text(context.l10n.imageUnavailable),
      );
    }
    return Center(
      child: Text(
        image?.alt.isNotEmpty == true
            ? image!.alt
            : context.l10n.imageUnavailable,
      ),
    );
  }

  Widget _focusedField(BuildContext context, BoxConstraints constraints) {
    final colors = ReaderColors.of(context);
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final focalX = width * Measures.anchor;
    final centerY = height / 2;
    final scaledWordSize = MediaQuery.textScalerOf(context)
        .scale(_engine.settings.fontSize);
    const markHeight = 16.0;
    final availableOffset = centerY - markHeight / 2 - 32;
    final showScope =
        _engine.current?.isImage == false &&
        availableOffset > scaledWordSize * .65 + 12;
    final markOffset = math.min(scaledWordSize * .65 + 22, availableOffset);
    final progressTop = showScope
        ? centerY + markOffset + markHeight / 2 + 18
        : height - 29;
    final meterWidth = math.min(240.0, math.max(0.0, width - 48));
    final meterLeft = (focalX - meterWidth / 2)
        .clamp(24.0, math.max(24.0, width - meterWidth - 24))
        .toDouble();
    final percentRead = context.l10n.percentRead(_percentRead);

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(child: _wordOrImage(context)),
        if (showScope) ...[
          Positioned(
            left: focalX - 1,
            top: centerY - markOffset - markHeight / 2,
            child: SizedBox(
              key: const ValueKey('scope-mark-top'),
              width: 2,
              height: markHeight,
              child: ColoredBox(color: colors.accent),
            ),
          ),
          Positioned(
            left: focalX - 1,
            top: centerY + markOffset - markHeight / 2,
            child: SizedBox(
              key: const ValueKey('scope-mark-bottom'),
              width: 2,
              height: markHeight,
              child: ColoredBox(color: colors.accent),
            ),
          ),
        ],
        Positioned(
          left: meterLeft,
          top: progressTop,
          width: meterWidth,
          child: Semantics(
            label: context.l10n.readingPosition,
            value: percentRead,
            child: ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: SizedBox(
                  key: const ValueKey('focused-progress-track'),
                  width: meterWidth,
                  height: 2,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(color: colors.separator),
                      ),
                      SizedBox(
                        key: const ValueKey('focused-progress-fill'),
                        width: meterWidth * _engine.progress,
                        height: 2,
                        child: ColoredBox(color: colors.accent),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _seek(int position) {
    if (position.clamp(0, _engine.tokens.length) == _engine.position) return;
    _scrub(position);
    ref
        .read(usageAnalyticsProvider)
        .record(UsageEvent.readingSeeked, screen: UsageScreen.reader);
  }

  void _scrub(int position) {
    if (position.clamp(0, _engine.tokens.length) == _engine.position) return;
    _seeking = true;
    try {
      _engine.seek(position);
      if (mounted && !_engine.playing) setState(() {});
    } finally {
      _seeking = false;
    }
  }

  void _sentence(int direction) {
    final position = _engine.position;
    _seeking = true;
    _engine.sentence(direction);
    _seeking = false;
    setState(() {});
    if (_engine.position != position) {
      ref
          .read(usageAnalyticsProvider)
          .record(UsageEvent.readingSeeked, screen: UsageScreen.reader);
    }
  }

  Future<void> _persistSettings(ReaderSettings settings) async {
    try {
      await ref.read(settingsProvider.notifier).update(settings);
      ref
          .read(usageAnalyticsProvider)
          .record(UsageEvent.readingSpeedChanged, screen: UsageScreen.reader);
    } catch (_) {
      if (mounted) {
        showProblem(context, context.l10n.paceSaveFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.space): _toggle,
      const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
          _seek(_engine.position + 1),
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
          _seek(_engine.position - 1),
      const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): () =>
          _sentence(1),
      const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): () =>
          _sentence(-1),
      const SingleActivator(LogicalKeyboardKey.arrowUp): () => _changeSpeed(25),
      const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
          _changeSpeed(-25),
      const SingleActivator(LogicalKeyboardKey.keyB, meta: true):
          _toggleBookmark,
      const SingleActivator(LogicalKeyboardKey.keyB, control: true):
          _toggleBookmark,
      const SingleActivator(LogicalKeyboardKey.escape): () {
        if (_immersive) {
          _engine.pause();
          _leaveImmersive();
        }
      },
    },
    child: Focus(autofocus: true, child: _buildReader(context)),
  );

  void _changeSpeed(int delta) {
    final next = _engine.settings.copyWith(wpm: _engine.settings.wpm + delta);
    _engine.configure(next);
    setState(() {});
    unawaited(_persistSettings(next));
  }

  Widget _buildReader(BuildContext context) {
    final colors = ReaderColors.of(context);
    ref.listen(settingsProvider, (_, next) {
      _engine.configure(next);
      setState(() {});
    });
    if (_immersive) {
      final focus = GestureDetector(
        key: const ValueKey('immersive-reader'),
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: LayoutBuilder(
          builder: (context, constraints) => StreamBuilder<void>(
            stream: _engine.changes,
            builder: (context, _) => _focusedField(context, constraints),
          ),
        ),
      );
      return isApple(context)
          ? CupertinoPageScaffold(
              backgroundColor: colors.background,
              child: SafeArea(child: focus),
            )
          : Scaffold(
              backgroundColor: colors.background,
              body: SafeArea(child: focus),
            );
    }
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _engine.pause();
          unawaited(_save(refreshLibrary: true));
        }
      },
      child: PlatformPage(
        title: context.l10n.read,
        contentWidth: 1120,
        centerInWindow: true,
        largeTitle: false,
        trailing: ActionMenu(
          label: context.l10n.readingActions,
          choices: [
            MenuChoice(
              _bookmarks.contains(_engine.position)
                  ? context.l10n.removeBookmark
                  : context.l10n.bookmarkThisWord,
              LucideIcons.bookmark,
              _toggleBookmark,
              selected: _bookmarks.contains(_engine.position),
            ),
            MenuChoice(context.l10n.contents, LucideIcons.list, _contents),
            MenuChoice(
              context.l10n.previousSentence,
              LucideIcons.skipBack,
              () => _sentence(-1),
            ),
            MenuChoice(
              context.l10n.nextSentence,
              LucideIcons.skipForward,
              () => _sentence(1),
            ),
            MenuChoice(
              context.l10n.readerSettings,
              LucideIcons.slidersHorizontal,
              () async {
                _engine.pause();
                await _save();
                if (context.mounted) {
                  await pushPage(context, const SettingsScreen());
                  if (mounted) {
                    ref.read(usageAnalyticsProvider).view(UsageScreen.reader);
                  }
                }
              },
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottom = ReaderLayout.bottomInset(context);
            final sideBySide =
                constraints.maxWidth >= 500 && constraints.maxHeight < 620;
            final availableHeight = constraints.maxHeight - bottom - 12;
            final compact =
                availableHeight < 600 ||
                MediaQuery.textScalerOf(context).scale(16) > 24;
            final playSize = compact ? 56.0 : 76.0;
            final passage = Column(
              children: [
                Text(
                  widget.document.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _engine.completed
                      ? context.l10n.finishedRestart
                      : context.l10n.positionOfWords(
                          _engine.position + 1,
                          _engine.tokens.length,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: colors.secondary),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, canvas) => Center(
                      child: WordContextView(
                        document: widget.document,
                        position: _engine.position,
                        fontSize: _engine.settings.fontSize,
                        readingFont: _engine.settings.readingFont,
                        highlight: _engine.settings.highlight,
                        height: math.min(460, canvas.maxHeight),
                        image: _engine.current?.isImage == true
                            ? _wordOrImage(context)
                            : null,
                        onTap: _toggle,
                        onStep: (delta) => _scrub(_engine.position + delta),
                        onScrollStart: () => _scrolling = true,
                        onScrollEnd: () {
                          _scrolling = false;
                          unawaited(_save());
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
            final controls = <Widget>[
              StreamBuilder<void>(
                stream: _engine.changes,
                builder: (context, _) {
                  return Semantics(
                    label: context.l10n.readingPosition,
                    value: context.l10n.percentRead(_percentRead),
                    child: isApple(context)
                        ? SizedBox(
                            width: double.infinity,
                            child: CupertinoSlider(
                              value: _engine.progress,
                              onChanged: (v) =>
                                  _scrub((v * _engine.tokens.length).round()),
                              onChangeEnd: (_) => ref
                                  .read(usageAnalyticsProvider)
                                  .record(
                                    UsageEvent.readingSeeked,
                                    screen: UsageScreen.reader,
                                  ),
                            ),
                          )
                        : Slider(
                            value: _engine.progress,
                            onChanged: (v) =>
                                _scrub((v * _engine.tokens.length).round()),
                            onChangeEnd: (_) => ref
                                .read(usageAnalyticsProvider)
                                .record(
                                  UsageEvent.readingSeeked,
                                  screen: UsageScreen.reader,
                                ),
                          ),
                  );
                },
              ),
              SizedBox(height: compact ? 4 : 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconAction(
                    label: context.l10n.backTenWords,
                    icon: LucideIcons.rotateCcw,
                    onPressed: () => _seek(_engine.position - 10),
                  ),
                  const SizedBox(width: 32),
                  Semantics(
                    button: true,
                    label: context.l10n.playReading,
                    onTap: _toggle,
                    child: ExcludeSemantics(
                      child: SizedBox(
                        width: playSize,
                        height: playSize,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          color: colors.accent,
                          borderRadius: BorderRadius.circular(38),
                          onPressed: _toggle,
                          child: Icon(
                            LucideIcons.play,
                            color: colors.onAccent,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  IconAction(
                    label: context.l10n.forwardTenWords,
                    icon: LucideIcons.rotateCw,
                    onPressed: () => _seek(_engine.position + 10),
                  ),
                ],
              ),
              SizedBox(height: compact ? 4 : 18),
              Center(
                child: Semantics(
                  label: context.l10n.speedValue(_engine.settings.wpm),
                  button: true,
                  child: CupertinoButton(
                    onPressed: _speedSheet,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      context.l10n.speedValue(_engine.settings.wpm),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.accent),
                    ),
                  ),
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 12),
                Text(
                  context.l10n.tapToReadHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: colors.subtle),
                ),
              ],
              if (_saveFailed)
                ActionButton(
                  label: context.l10n.placeNotSaved,
                  onPressed: () => _save(),
                ),
            ];
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, bottom),
              child: sideBySide
                  ? Row(
                      children: [
                        Expanded(
                          child: KeyedSubtree(
                            key: const ValueKey('landscape-passage'),
                            child: passage,
                          ),
                        ),
                        const SizedBox(width: 28),
                        SizedBox(
                          width: constraints.maxWidth >= 900
                              ? 320
                              : constraints.maxWidth >= 700
                              ? 280
                              : 240,
                          child: Column(
                            key: const ValueKey('landscape-controls'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: controls,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(child: passage),
                        const SizedBox(height: 8),
                        ...controls,
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  void _speedSheet() {
    showReaderSheet(
      context,
      context.l10n.readingSpeed,
      (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Column(
          children: [
            Text(
              '${_engine.settings.wpm}',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w600),
            ),
            Text(context.l10n.wordsPerMinute),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Semantics(
                label: context.l10n.readingSpeed,
                child: CupertinoSlider(
                  value: _engine.settings.wpm.toDouble(),
                  min: 100,
                  max: 1500,
                  divisions: 140,
                  onChanged: (v) {
                    _engine.configure(
                      _engine.settings.copyWith(wpm: v.round()),
                    );
                    setSheetState(() {});
                    setState(() {});
                  },
                  onChangeEnd: (_) => _persistSettings(_engine.settings),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.comfortablePace,
              style: TextStyle(
                fontSize: 14,
                color: ReaderColors.of(context).secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
