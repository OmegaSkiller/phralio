import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design.dart';
import '../../app/providers.dart';
import '../../app/usage_analytics.dart';
import '../../core/document.dart';
import '../../core/playback.dart';
import '../../core/settings.dart';
import '../library/library_store.dart';
import 'focal_word.dart';
import 'contents_screen.dart';
import 'settings_screen.dart';

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
  late final FixedExtentScrollController _wordScroll;
  int _lastCheckpoint = -1;
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
    _wordScroll = FixedExtentScrollController(
      initialItem: _engine.position.clamp(0, _engine.tokens.length - 1),
    );
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
    WidgetsBinding.instance.removeObserver(this);
    _subscription.cancel();
    _wordScroll.dispose();
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
      widget.onImmersiveChanged?.call(_immersive);
      if (!_immersive) _alignPausedWords();
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
    widget.onImmersiveChanged?.call(false);
    _alignPausedWords();
  }

  void _alignPausedWords() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _wordScroll.hasClients) {
        _wordScroll.jumpToItem(
          _engine.position.clamp(0, _engine.tokens.length - 1),
        );
      }
    });
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
        showProblem(context, 'Bookmark could not be saved. Please try again.');
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
      return const Center(child: Text('A good place to pause.'));
    }
    if (!token.isImage) {
      return FocalWord(
        token: token,
        fontSize: _engine.settings.fontSize,
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
        errorBuilder: (_, _, _) => const Text('Image unavailable'),
      );
    }
    return Center(
      child: Text(
        image?.alt.isNotEmpty == true ? image!.alt : 'Image unavailable',
      ),
    );
  }

  Widget _pausedWords(BuildContext context) {
    if (_engine.tokens.isEmpty) return const SizedBox.shrink();
    final colors = ReaderColors.of(context);
    return SizedBox(
      height: 260,
      child: NotificationListener<ScrollEndNotification>(
        onNotification: (_) {
          _scrolling = false;
          unawaited(_save());
          return false;
        },
        child: ListWheelScrollView.useDelegate(
          controller: _wordScroll,
          itemExtent: 48,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            if (index == _engine.position) return;
            _scrolling = true;
            _scrub(index);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: _engine.tokens.length,
            builder: (context, index) {
              final token = _engine.tokens[index];
              final current = index == _engine.position;
              return Center(
                child: Text(
                  token.isImage ? 'Image' : token.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: current ? 24 : 18,
                    fontWeight: current ? FontWeight.w700 : FontWeight.normal,
                    color: current ? colors.accent : colors.secondary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
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
    _seeking = true;
    try {
      _engine.seek(position);
      if (_wordScroll.hasClients &&
          _wordScroll.selectedItem != _engine.position &&
          !_scrolling) {
        _wordScroll.jumpToItem(
          _engine.position.clamp(0, _engine.tokens.length - 1),
        );
      }
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
        showProblem(
          context,
          'This pace works for this session, but could not be saved.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: Center(
          child: StreamBuilder<void>(
            stream: _engine.changes,
            builder: (_, _) => _wordOrImage(context),
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
        title: 'Read',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconAction(
              label: _bookmarks.contains(_engine.position)
                  ? 'Remove bookmark'
                  : 'Bookmark this word',
              icon: LucideIcons.bookmark,
              onPressed: _toggleBookmark,
            ),
            IconAction(
              label: 'Contents',
              icon: LucideIcons.list,
              onPressed: _contents,
            ),
            IconAction(
              label: 'Reader settings',
              icon: LucideIcons.slidersHorizontal,
              onPressed: () async {
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
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.document.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _playing ? colors.secondary : colors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _playing
                        ? 'Follow the fixed point.'
                        : 'Tap to read · Swipe to move one word at a time.',
                    style: TextStyle(fontSize: 14, color: colors.secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              child: Column(
                children: [
                  _pausedWords(context),
                  if (_engine.current?.isImage == true)
                    SizedBox(height: 220, child: _wordOrImage(context)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  GlassSurface(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconAction(
                            label: 'Previous sentence',
                            icon: LucideIcons.skipBack,
                            onPressed: () => _sentence(-1),
                          ),
                          IconAction(
                            label: 'Back ten words',
                            icon: LucideIcons.rotateCcw,
                            onPressed: () => _seek(_engine.position - 10),
                          ),
                          Semantics(
                            button: true,
                            label: _playing ? 'Pause reading' : 'Play reading',
                            onTap: _toggle,
                            child: ExcludeSemantics(
                              child: SizedBox(
                                width: 72,
                                height: 64,
                                child: isApple(context)
                                    ? CupertinoButton.filled(
                                        padding: EdgeInsets.zero,
                                        onPressed: _toggle,
                                        child: Icon(
                                          _playing
                                              ? LucideIcons.pause
                                              : LucideIcons.play,
                                          size: 28,
                                        ),
                                      )
                                    : FilledButton(
                                        onPressed: _toggle,
                                        child: Icon(
                                          _playing
                                              ? LucideIcons.pause
                                              : LucideIcons.play,
                                          size: 28,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          IconAction(
                            label: 'Forward ten words',
                            icon: LucideIcons.rotateCw,
                            onPressed: () => _seek(_engine.position + 10),
                          ),
                          IconAction(
                            label: 'Next sentence',
                            icon: LucideIcons.skipForward,
                            onPressed: () => _sentence(1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    '${_engine.settings.wpm}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: colors.text,
                    ),
                  ),
                  Text(
                    'words per minute',
                    style: TextStyle(fontSize: 13, color: colors.secondary),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: 'Reading speed',
                    value: '${_engine.settings.wpm} words per minute',
                    child: isApple(context)
                        ? SizedBox(
                            width: double.infinity,
                            child: CupertinoSlider(
                              value: _engine.settings.wpm.toDouble(),
                              min: 100,
                              max: 1500,
                              divisions: 140,
                              onChanged: (v) => setState(
                                () => _engine.configure(
                                  _engine.settings.copyWith(wpm: v.round()),
                                ),
                              ),
                              onChangeEnd: (_) =>
                                  _persistSettings(_engine.settings),
                            ),
                          )
                        : Slider(
                            value: _engine.settings.wpm.toDouble(),
                            min: 100,
                            max: 1500,
                            divisions: 140,
                            semanticFormatterCallback: (v) =>
                                '${v.round()} words per minute',
                            onChanged: (v) => setState(
                              () => _engine.configure(
                                _engine.settings.copyWith(wpm: v.round()),
                              ),
                            ),
                            onChangeEnd: (_) =>
                                _persistSettings(_engine.settings),
                          ),
                  ),
                  const SizedBox(height: 18),
                  StreamBuilder<void>(
                    stream: _engine.changes,
                    builder: (context, _) {
                      final seconds =
                          (_engine.remainingTime.inMilliseconds / 1000).ceil();
                      return Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                Text(
                                  '${_engine.completed ? 100 : (_engine.progress * 100).floor()}% read',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.secondary,
                                  ),
                                ),
                                Text(
                                  seconds == 0
                                      ? 'Complete'
                                      : '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')} remaining',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Semantics(
                            label: 'Reading position',
                            child: isApple(context)
                                ? SizedBox(
                                    width: double.infinity,
                                    child: CupertinoSlider(
                                      value: _engine.progress,
                                      onChanged: (v) => _scrub(
                                        (v * _engine.tokens.length).round(),
                                      ),
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
                                    onChanged: (v) => _scrub(
                                      (v * _engine.tokens.length).round(),
                                    ),
                                    onChangeEnd: (_) => ref
                                        .read(usageAnalyticsProvider)
                                        .record(
                                          UsageEvent.readingSeeked,
                                          screen: UsageScreen.reader,
                                        ),
                                  ),
                          ),
                          Text(
                            _engine.completed
                                ? 'Finished. Play again to return to the beginning.'
                                : '${_engine.position + 1} of ${_engine.tokens.length} words',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.subtle,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (_saveFailed)
                    ActionButton(
                      label: 'Place not saved · Retry',
                      onPressed: () => _save(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
