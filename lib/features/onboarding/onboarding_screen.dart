import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/accent.dart';
import '../../app/design.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/document.dart';
import '../../core/file_import.dart';
import '../../core/playback.dart';
import '../../core/remote_import.dart';
import '../../core/settings.dart';
import '../../l10n/l10n.dart';
import '../library/pick_reading_file.dart';
import '../reader/accent_picker.dart';
import '../reader/focal_word.dart';
import '../reader/word_context_view.dart';

/// A disposable practice session. Never writes readings, positions or bookmarks.
/// Only Finish applies explicitly previewed preferences to the current settings.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.replay = false});
  final bool replay;
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  bool _interactive = true, _started = false, _busy = false;
  bool _paused = false, _resumed = false, _demonstrated = false;
  int _step = 0;
  int? _bookmark;
  late ReaderSettings _draft;
  ReaderDocument? _document;
  Playback? _playback;
  StreamSubscription<void>? _subscription;
  final _text = TextEditingController();
  final _url = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _draft = ref.read(settingsProvider).copyWith(wpm: 200);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _playback?.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _playback?.dispose();
    _text.dispose();
    _url.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<String> get _titles {
    final l = context.l10n;
    return [
      l.tourWelcome,
      l.addText,
      l.pauseReading,
      l.readingSpeed,
      l.readingPosition,
      l.readUrl,
      l.importFile,
      l.bookmarks,
      l.appearance,
    ];
  }

  List<String> get _lessons {
    final l = context.l10n;
    return [
      l.tourWelcomeBody,
      l.tourPaste,
      l.tourPlayback,
      l.tourSpeed,
      l.tourScroll,
      l.tourUrl,
      l.tourFile,
      l.tourBookmark,
      l.tourAppearance,
    ];
  }

  static const _icons = [
    LucideIcons.bookOpen,
    LucideIcons.clipboard,
    LucideIcons.play,
    LucideIcons.gauge,
    LucideIcons.mousePointer2,
    LucideIcons.link,
    LucideIcons.fileUp,
    LucideIcons.bookmark,
    LucideIcons.palette,
  ];

  void _load(ReaderDocument document, {bool play = false}) {
    _subscription?.cancel();
    _playback?.dispose();
    _document = document;
    _bookmark = null;
    _playback = Playback(document.tokens, settings: _draft);
    _subscription = _playback!.changes.listen((_) {
      if (mounted) setState(() {});
    });
    final media = MediaQuery.of(context);
    if (play && !media.disableAnimations && !media.accessibleNavigation) {
      _playback!.play();
    }
  }

  void _lesson(int step) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _started = true;
      _step = step;
      _demonstrated = false;
      _paused = false;
      _resumed = false;
      // Each explanation starts at the requested teaching pace and stops at
      // its end. The ordinary engine supplies punctuation pauses unchanged.
      _draft = _draft.copyWith(wpm: 200);
      _load(
        ReaderDocument(id: -1, title: _titles[step], text: _lessons[step]),
        play: _interactive && step != 4 && step != 7 && step != 8,
      );
      if (step == 4 || step == 7) _playback!.seek(2);
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _toggle() {
    final playback = _playback!;
    if (playback.playing) {
      _paused = true;
      playback.pause();
    } else {
      if (_paused) _resumed = true;
      playback.play();
    }
    setState(() => _demonstrated = _step == 2 ? _paused && _resumed : true);
  }

  Future<void> _perform(Future<void> Function() action, String error) async {
    if (_busy) return;
    _playback?.pause();
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) await showProblem(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _accept(ImportedReading reading) {
    if (!mounted) return;
    setState(() {
      _load(
        ReaderDocument(
          id: -1,
          title: reading.title,
          text: reading.text,
          headings: reading.headings,
          images: reading.images,
        ),
      );
      _demonstrated = true;
    });
  }

  Future<void> _finish({bool apply = true}) async {
    await _perform(() async {
      final current = ref.read(settingsProvider);
      await ref
          .read(settingsProvider.notifier)
          .update(
            current.copyWith(
              onboardingComplete: true,
              appearance: apply ? _draft.appearance : current.appearance,
              accent: apply ? _draft.accent : current.accent,
              readingFont: apply ? _draft.readingFont : current.readingFont,
            ),
          );
      if (mounted && widget.replay) Navigator.pop(context);
    }, context.l10n.settingsSaveFailed);
  }

  Widget _reader() {
    final p = _playback!;
    final l = context.l10n;
    return Column(
      children: [
        if (_step == 4 && !p.playing)
          WordContextView(
            document: _document!,
            position: p.position,
            fontSize: 32,
            readingFont: _draft.readingFont,
            highlight: true,
            height: 270,
            onTap: _toggle,
            onStep: (delta) {
              p.seek((p.position + delta).clamp(0, p.tokens.length - 1));
              setState(() => _demonstrated = true);
            },
            onScrollStart: p.pause,
            onScrollEnd: () {},
          )
        else
          Semantics(
            button: true,
            label: p.playing ? l.pauseReading : l.playReading,
            child: GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.opaque,
              child: p.current == null
                  ? SizedBox(
                      height: 140,
                      child: Center(child: Text(l.complete)),
                    )
                  : p.current!.isImage
                  ? SizedBox(
                      height: 140,
                      child: Center(
                        child: Icon(
                          LucideIcons.image,
                          color: ReaderColors.of(context).secondary,
                        ),
                      ),
                    )
                  : FocalWord(
                      token: p.current!,
                      fontSize: 36,
                      readingFont: _draft.readingFont,
                      highlight: true,
                      minimumHeight: 140,
                    ),
            ),
          ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            ActionButton(
              label: p.playing ? l.pauseReading : l.playReading,
              icon: p.playing ? LucideIcons.pause : LucideIcons.play,
              onPressed: _toggle,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.speedValue(_draft.wpm)),
            ),
          ],
        ),
      ],
    );
  }

  void _configure(ReaderSettings value) {
    setState(() {
      _draft = value;
      _playback?.configure(value);
      _demonstrated = true;
    });
  }

  Widget _practice(BuildContext context) {
    final l = context.l10n;
    switch (_step) {
      case 1:
        return Column(
          children: [
            Semantics(
              label: l.textToRead,
              child: ReaderTextField(
                controller: _text,
                label: l.textToRead,
                hint: l.pasteHint,
                lines: 3,
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                ActionButton(
                  label: l.paste,
                  icon: LucideIcons.clipboard,
                  onPressed: () => _perform(() async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text?.trim().isNotEmpty != true) {
                      throw const FormatException();
                    }
                    _text.text = data!.text!;
                  }, l.clipboardEmpty),
                ),
                ActionButton(
                  label: l.tourSample,
                  onPressed: () => _text.text = l.tourWelcomeBody,
                ),
                ActionButton(
                  label: l.read,
                  primary: true,
                  onPressed: () => _perform(() async {
                    final text = TextImport.validate(l.addText, _text.text);
                    _accept(
                      ImportedReading(
                        title: text.title,
                        text: text.text,
                        format: 'TXT',
                      ),
                    );
                  }, l.pasteInvalid),
                ),
              ],
            ),
          ],
        );
      case 3:
        return Semantics(
          label: l.readingSpeed,
          child: CupertinoSlider(
            value: _draft.wpm.toDouble(),
            min: 100,
            max: 600,
            divisions: 20,
            activeColor: ReaderColors.of(context).accent,
            onChanged: (v) => _configure(_draft.copyWith(wpm: v.round())),
          ),
        );
      case 4:
        return Wrap(
          alignment: WrapAlignment.center,
          children: [
            ActionButton(
              label: l.back,
              icon: LucideIcons.arrowLeft,
              onPressed: () {
                _playback!.seek(_playback!.position - 1);
                setState(() => _demonstrated = true);
              },
            ),
            ActionButton(
              label: l.tourNext,
              icon: LucideIcons.arrowRight,
              onPressed: () {
                _playback!.seek(
                  (_playback!.position + 1).clamp(
                    0,
                    _playback!.tokens.length - 1,
                  ),
                );
                setState(() => _demonstrated = true);
              },
            ),
          ],
        );
      case 5:
        return Column(
          children: [
            Semantics(
              label: l.pageUrl,
              child: ReaderTextField(
                controller: _url,
                label: l.pageUrl,
                hint: l.urlPlaceholder,
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                ActionButton(
                  label: l.readUrl,
                  icon: LucideIcons.link,
                  onPressed: () => _perform(() async {
                    final importer = RemoteImport();
                    try {
                      _accept(await importer.page(_url.text));
                    } finally {
                      importer.close();
                    }
                  }, l.urlReadFailed),
                ),
                ActionButton(
                  label: l.tourOffline,
                  onPressed: () => _perform(() async {
                    _url.text = 'https://example.org/article';
                    _accept(
                      FileImport.parseWeb(
                        '<html><nav>Menu</nav><article><h1>Phralio</h1><p>${const HtmlEscape().convert(l.tourWelcomeBody)}</p></article></html>',
                        Uri.parse(_url.text),
                      ),
                    );
                  }, l.urlReadFailed),
                ),
              ],
            ),
            Text(l.urlPrivacy, style: const TextStyle(fontSize: 14)),
          ],
        );
      case 6:
        return Column(
          children: [
            ActionButton(
              label: l.importFile,
              icon: LucideIcons.fileUp,
              onPressed: () => _perform(() async {
                final reading = await pickReadingFile(l);
                if (reading != null) _accept(reading);
              }, l.fileReadFailed),
            ),
            Text(l.tourSample),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (final ext in ['txt', 'md', 'epub'])
                  ActionButton(
                    label: ext.toUpperCase(),
                    onPressed: () => _perform(() async {
                      final bytes = await rootBundle.load(
                        'assets/onboarding/practice.$ext',
                      );
                      _accept(
                        await compute(FileImport.parse, (
                          name: 'practice.$ext',
                          bytes: bytes.buffer.asUint8List(
                            bytes.offsetInBytes,
                            bytes.lengthInBytes,
                          ),
                        )),
                      );
                    }, l.fileReadFailed),
                  ),
              ],
            ),
            if (_demonstrated) ...[
              Text(_document!.title),
              Text(l.wordsCount(_document!.tokens.length)),
              for (final heading in _document!.headings)
                ActionButton(
                  label: heading.title,
                  onPressed: () => _playback!.seek(heading.position),
                ),
            ],
          ],
        );
      case 7:
        return Column(
          children: [
            ActionButton(
              label: l.bookmarkThisWord,
              icon: LucideIcons.bookmark,
              onPressed: () {
                _playback!.pause();
                setState(() {
                  _bookmark = _playback!.position.clamp(
                    0,
                    _playback!.tokens.length - 1,
                  );
                  _demonstrated = true;
                });
              },
            ),
            if (_bookmark != null)
              ActionButton(
                label: l.wordNumber(_bookmark! + 1),
                icon: LucideIcons.bookmarkCheck,
                onPressed: () => _playback!.seek(_bookmark!),
              ),
          ],
        );
      case 8:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GroupedRows(
              children: [
                SettingRow(
                  title: l.readingFont,
                  icon: LucideIcons.type,
                  value: _draft.readingFont.family,
                  onTap: () => showReaderSheet(
                    context,
                    l.readingFont,
                    (sheet) => GroupedRows(
                      children: [
                        for (final font in ReadingFont.values)
                          SettingRow(
                            title: font.family,
                            icon: null,
                            selected: _draft.readingFont == font,
                            onTap: () {
                              _configure(_draft.copyWith(readingFont: font));
                              Navigator.pop(sheet);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SectionLabel(l.appearance),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (final (value, label) in [
                  (Appearance.system, l.system),
                  (Appearance.light, l.light),
                  (Appearance.dark, l.dark),
                ])
                  ActionButton(
                    label: label,
                    selected: value == _draft.appearance,
                    onPressed: () =>
                        _configure(_draft.copyWith(appearance: value)),
                  ),
              ],
            ),
            SectionLabel(l.accentColor),
            AccentPicker(
              selected: _draft.accent,
              onSelected: (v) => _configure(_draft.copyWith(accent: v)),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = switch (_draft.appearance) {
      Appearance.light => Brightness.light,
      Appearance.dark => Brightness.dark,
      Appearance.system => MediaQuery.platformBrightnessOf(context),
    };
    return Theme(
      data: ReaderTheme.material(brightness, _draft.accent),
      child: CupertinoTheme(
        data: ReaderTheme.cupertino(brightness, _draft.accent),
        child: AccentPalette(
          accent: _draft.accent,
          child: Builder(builder: _buildPage),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context) {
    final l = context.l10n;
    final colors = ReaderColors.of(context);
    return PlatformPage(
      title: l.tourTitle,
      contentWidth: 760,
      trailing: ActionButton(
        label: widget.replay ? l.close : l.tourSkip,
        onPressed: _busy
            ? null
            : () {
                if (widget.replay) {
                  Navigator.pop(context);
                } else {
                  _finish(apply: false);
                }
              },
      ),
      child: ListView(
        controller: _scroll,
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.paddingOf(context).bottom + 32,
        ),
        children: [
          if (!_started) ...[
            const Center(child: BrandMark(size: 56)),
            const SizedBox(height: 24),
            Text(
              l.tourWelcome,
              style: ReaderTypography.editorial(context, size: 36),
            ),
            const SizedBox(height: 12),
            Text(l.tourWelcomeBody, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 24),
            GroupedRows(
              children: [
                SettingRow(
                  title: l.tourInteractive,
                  icon: LucideIcons.hand,
                  selected: _interactive,
                  trailing: Icon(
                    _interactive ? LucideIcons.circleCheck : LucideIcons.circle,
                  ),
                  onTap: () => setState(() => _interactive = true),
                ),
                SettingRow(
                  title: l.tourTraditional,
                  icon: LucideIcons.bookOpen,
                  selected: !_interactive,
                  trailing: Icon(
                    !_interactive
                        ? LucideIcons.circleCheck
                        : LucideIcons.circle,
                  ),
                  onTap: () => setState(() => _interactive = false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l.tourPrivacy,
              style: TextStyle(
                color: colors.secondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ActionButton(
              label: l.tourStart,
              primary: true,
              onPressed: () => _lesson(0),
            ),
          ] else ...[
            Text(
              '${_step + 1} / ${_titles.length}',
              style: TextStyle(color: colors.secondary),
            ),
            const SizedBox(height: 16),
            Text(
              _titles[_step],
              style: ReaderTypography.editorial(context, size: 32),
            ),
            const SizedBox(height: 12),
            Text(_lessons[_step], style: const TextStyle(height: 1.5)),
            const SizedBox(height: 16),
            if (_interactive) ...[
              _reader(),
              AbsorbPointer(absorbing: _busy, child: _practice(context)),
              if (_demonstrated)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Semantics(
                    liveRegion: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.check, color: colors.accent),
                        const SizedBox(width: 8),
                        Flexible(child: Text(l.tourDone)),
                      ],
                    ),
                  ),
                ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Icon(_icons[_step], size: 64, color: colors.accent),
              ),
              GroupedRows(
                children: [
                  SettingRow(
                    title: _titles[_step],
                    icon: _icons[_step],
                    value: _step == 3 ? l.speedValue(200) : null,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              children: [
                if (_step > 0)
                  ActionButton(
                    label: l.back,
                    onPressed: _busy ? null : () => _lesson(_step - 1),
                  ),
                ActionButton(
                  key: const ValueKey('tour-next'),
                  label: _busy
                      ? l.opening
                      : _step == 8
                      ? l.tourFinish
                      : l.tourNext,
                  primary: true,
                  onPressed: _busy
                      ? null
                      : () {
                          if (_step == 8) {
                            _finish();
                          } else {
                            _lesson(_step + 1);
                          }
                        },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
