import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design.dart';
import '../../app/providers.dart';
import '../../core/document.dart';
import '../../core/playback.dart';
import '../../core/settings.dart';
import '../library/library_store.dart';
import 'focal_word.dart';
import 'settings_screen.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.document});
  final ReaderDocument document;
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
    WidgetsBinding.instance.addObserver(this);
    _subscription = _engine.changes.listen((_) {
      if (_playing != _engine.playing && mounted) {
        setState(() => _playing = _engine.playing);
      }
      if (!_engine.playing ||
          (_engine.position - _lastCheckpoint).abs() >= 10) {
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
      unawaited(_save());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription.cancel();
    unawaited(_save());
    _engine.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    _engine.playing ? _engine.pause() : _engine.play();
  }

  Future<void> _persistSettings(ReaderSettings settings) async {
    try {
      await ref.read(settingsProvider.notifier).update(settings);
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
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _engine.pause();
          unawaited(_save(refreshLibrary: true));
        }
      },
      child: PlatformPage(
        title: 'Focus reader',
        trailing: IconAction(
          label: 'Reader settings',
          icon: isApple(context)
              ? CupertinoIcons.slider_horizontal_3
              : Icons.tune,
          onPressed: () async {
            _engine.pause();
            await _save();
            if (context.mounted) {
              await pushPage(context, const SettingsScreen());
            }
          },
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
                        : 'Settle in. Start when you are ready.',
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
                  ExcludeSemantics(
                    child: Align(
                      alignment: const Alignment(Measures.anchor * 2 - 1, 0),
                      child: Container(
                        width: 2,
                        height: 16,
                        color: colors.accent,
                      ),
                    ),
                  ),
                  StreamBuilder<void>(
                    stream: _engine.changes,
                    builder: (context, _) => _engine.current == null
                        ? const SizedBox(
                            height: 180,
                            child: Center(
                              child: Text(
                                'A good place to pause.',
                                style: TextStyle(fontSize: 24),
                              ),
                            ),
                          )
                        : FocalWord(
                            token: _engine.current!,
                            fontSize: _engine.settings.fontSize,
                            highlight: _engine.settings.highlight,
                          ),
                  ),
                  ExcludeSemantics(
                    child: Align(
                      alignment: const Alignment(Measures.anchor * 2 - 1, 0),
                      child: Container(
                        width: 2,
                        height: 16,
                        color: colors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconAction(
                        label: 'Previous sentence',
                        icon: isApple(context)
                            ? CupertinoIcons.backward_end
                            : Icons.skip_previous,
                        onPressed: () => _engine.sentence(-1),
                      ),
                      IconAction(
                        label: 'Back ten words',
                        icon: isApple(context)
                            ? CupertinoIcons.gobackward_10
                            : Icons.replay_10,
                        onPressed: () => _engine.seek(_engine.position - 10),
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
                                          ? CupertinoIcons.pause_fill
                                          : CupertinoIcons.play_fill,
                                      size: 28,
                                    ),
                                  )
                                : FilledButton(
                                    onPressed: _toggle,
                                    child: Icon(
                                      _playing ? Icons.pause : Icons.play_arrow,
                                      size: 28,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      IconAction(
                        label: 'Forward ten words',
                        icon: isApple(context)
                            ? CupertinoIcons.goforward_10
                            : Icons.forward_10,
                        onPressed: () => _engine.seek(_engine.position + 10),
                      ),
                      IconAction(
                        label: 'Next sentence',
                        icon: isApple(context)
                            ? CupertinoIcons.forward_end
                            : Icons.skip_next,
                        onPressed: () => _engine.sentence(1),
                      ),
                    ],
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
                                  '${(_engine.progress * 100).round()}% read',
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
                                      onChanged: (v) => _engine.seek(
                                        (v * _engine.tokens.length).round(),
                                      ),
                                    ),
                                  )
                                : Slider(
                                    value: _engine.progress,
                                    onChanged: (v) => _engine.seek(
                                      (v * _engine.tokens.length).round(),
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
