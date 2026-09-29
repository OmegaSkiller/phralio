import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
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
import '../../core/settings.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../reader/accent_picker.dart';
import '../reader/focal_word.dart';
import '../reader/word_context_view.dart';
import 'onboarding_sources.dart';
import 'onboarding_widgets.dart';

enum OnboardingStep {
  welcome,
  read,
  pace,
  move,
  sources,
  contents,
  images,
  saved,
  resume,
  type,
  style,
  ready;

  static const lessonCount = 10;
}

enum _Preference {
  pace,
  pauses,
  font,
  size,
  highlight,
  appearance,
  accent,
  language,
  transparency,
  images,
}

/// A single disposable lesson journey. Practice never writes library data;
/// Finish merges only deliberately edited preferences into the current settings.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.replay = false});
  final bool replay;
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  OnboardingStep _step = OnboardingStep.welcome;
  final _done = <OnboardingStep>{};
  final _edited = <_Preference>{};
  final _positions = <OnboardingStep, int>{};
  final _scroll = ScrollController();
  late ReaderSettings _draft;
  Playback? _playback;
  StreamSubscription<void>? _subscription;
  ReaderDocument? _document;
  ImportedReading? _imported;
  PracticeSource? _source;
  bool _immersive = false, _busy = false, _more = false;
  bool _starred = false, _everStarred = false, _everBookmarked = false;
  int? _bookmark;
  bool _showLibrary = true, _returnedToLibrary = false;
  int _resumePosition = 3;
  String? _error;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(settingsProvider);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _playback?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _pause() {
    _playback?.pause();
    if (mounted && _immersive) setState(() => _immersive = false);
  }

  void _complete(OnboardingStep step) {
    if (_done.add(step)) {
      HapticFeedback.selectionClick();
      if (mounted) setState(() {});
    }
  }

  void _load(ReaderDocument document, {int? position}) {
    _subscription?.cancel();
    _playback?.dispose();
    _document = document;
    _playback = Playback(
      document.tokens,
      settings: _step == OnboardingStep.read
          ? _draft.copyWith(wpm: 200)
          : _draft,
      position: position ?? _positions[_step] ?? 0,
    );
    _subscription = _playback!.changes.listen((_) {
      if (!mounted) return;
      setState(() {
        if (_playback!.completed) _immersive = false;
      });
    });
  }

  void _go(BuildContext context, OnboardingStep step) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_playback != null) _positions[_step] = _playback!.position;
    _pause();
    final l = context.l10n;
    setState(() {
      _step = step;
      _more = false;
      _error = null;
      var text = l.obSampleText;
      var headings = const <ReadingHeading>[];
      if (step == OnboardingStep.contents) {
        final reading = FileImport.parse((
          name: 'practice.md',
          bytes: utf8.encode(
            '# ${l.obSectionOne}\n\n${l.obSampleText}\n\n'
            '# ${l.obSectionTwo}\n\n${l.obSecondPassage}\n\n'
            '# ${l.obSectionThree}\n\n${l.obSampleText}',
          ),
        ));
        text = reading.text;
        headings = reading.headings;
      }
      if (step == OnboardingStep.images) text = '$imageMarker $text';
      _load(
        ReaderDocument(
          id: -1,
          title: l.obSampleTitle,
          text: text,
          headings: headings,
        ),
        position: step == OnboardingStep.resume
            ? _resumePosition
            : _positions[step] ??
                  (switch (step) {
                    OnboardingStep.move || OnboardingStep.type => 8,
                    OnboardingStep.saved => 5,
                    _ => 0,
                  }),
      );
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  void _next(BuildContext context) =>
      _go(context, OnboardingStep.values[_step.index + 1]);

  void _toggle() {
    final p = _playback!;
    if (p.playing) {
      _pause();
      if (_step == OnboardingStep.read) _complete(_step);
    } else {
      if (_step == OnboardingStep.images) p.seek(0);
      if (_step == OnboardingStep.read) setState(() => _immersive = true);
      p.play();
      if (_step == OnboardingStep.images) _complete(_step);
    }
  }

  void _seek(int position) {
    final p = _playback!;
    p.seek(position.clamp(0, p.tokens.length - 1));
    if (_step == OnboardingStep.move) _complete(_step);
  }

  void _configure(ReaderSettings value, _Preference preference) {
    setState(() {
      _draft = value;
      _edited.add(preference);
      _playback?.configure(value);
    });
    if (_step == OnboardingStep.pace ||
        _step == OnboardingStep.images ||
        _step == OnboardingStep.type ||
        _step == OnboardingStep.style) {
      _complete(_step);
    }
  }

  ReaderSettings _settingsToSave(bool apply) {
    final current = ref.read(settingsProvider);
    bool edited(_Preference p) => apply && _edited.contains(p);
    return current.copyWith(
      onboardingComplete: true,
      wpm: edited(_Preference.pace) ? _draft.wpm : current.wpm,
      pauses: edited(_Preference.pauses) ? _draft.pauses : current.pauses,
      readingFont: edited(_Preference.font)
          ? _draft.readingFont
          : current.readingFont,
      fontSize: edited(_Preference.size) ? _draft.fontSize : current.fontSize,
      highlight: edited(_Preference.highlight)
          ? _draft.highlight
          : current.highlight,
      appearance: edited(_Preference.appearance)
          ? _draft.appearance
          : current.appearance,
      accent: edited(_Preference.accent) ? _draft.accent : current.accent,
      language: edited(_Preference.language)
          ? _draft.language
          : current.language,
      reduceTransparency: edited(_Preference.transparency)
          ? _draft.reduceTransparency
          : current.reduceTransparency,
      imageSeconds: edited(_Preference.images)
          ? _draft.imageSeconds
          : current.imageSeconds,
    );
  }

  Future<void> _finish(BuildContext context, {bool apply = true}) async {
    if (_busy) return;
    _pause();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(settingsProvider.notifier).update(_settingsToSave(apply));
      if (mounted && widget.replay && context.mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted && context.mounted) {
        setState(() => _error = context.l10n.settingsSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _exit(BuildContext context) {
    _pause();
    if (widget.replay) {
      Navigator.pop(context);
    } else {
      _finish(context, apply: false);
    }
  }

  Widget _previewTheme(BuildContext context, Widget child) {
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
          child: Localizations.override(
            context: context,
            locale: _draft.language == AppLanguage.system
                ? basicLocaleListResolution(
                    WidgetsBinding.instance.platformDispatcher.locales,
                    AppLocalizations.supportedLocales,
                  )
                : Locale(_draft.language.name),
            child: child,
          ),
        ),
      ),
    );
  }

  Future<void> _sheet(
    BuildContext context,
    String title,
    WidgetBuilder builder,
  ) async {
    _pause();
    await showReaderSheet<void>(
      context,
      title,
      builder,
      presentation: (child) => _previewTheme(context, child),
    );
  }

  String _languageName(AppLocalizations l, AppLanguage value) =>
      switch (value) {
        AppLanguage.system => l.deviceLanguage,
        AppLanguage.en => l.english,
        AppLanguage.ru => l.russian,
        AppLanguage.es => l.spanish,
        AppLanguage.pt => l.portuguese,
        AppLanguage.zh => l.chinese,
        AppLanguage.ja => l.japanese,
        AppLanguage.pl => l.polish,
        AppLanguage.de => l.german,
        AppLanguage.fr => l.french,
        AppLanguage.it => l.italian,
      };
  String _appearanceName(AppLocalizations l, Appearance value) =>
      switch (value) {
        Appearance.system => l.system,
        Appearance.light => l.light,
        Appearance.dark => l.dark,
      };

  void _languageSheet(BuildContext context) {
    final l = context.l10n;
    _sheet(
      context,
      l.language,
      (sheet) => GroupedRows(
        children: [
          for (final language in AppLanguage.values)
            SettingRow(
              title: _languageName(l, language),
              icon: null,
              selected: language == _draft.language,
              onTap: () {
                _configure(
                  _draft.copyWith(language: language),
                  _Preference.language,
                );
                Navigator.pop(sheet);
              },
            ),
        ],
      ),
    );
  }

  List<Widget> _spaced(List<Widget> children, [double gap = 12]) => [
    for (var i = 0; i < children.length; i++) ...[
      if (i > 0) SizedBox(height: gap),
      children[i],
    ],
  ];

  Widget _scope(BuildContext context, {double height = 16}) => Center(
    child: Container(
      width: 2,
      height: height,
      color: ReaderColors.of(context).accent,
    ),
  );

  Widget _field(
    BuildContext context, {
    bool surrounding = false,
    bool compact = false,
  }) {
    final l = context.l10n;
    final colors = ReaderColors.of(context);
    final p = _playback!;
    if (surrounding && !p.playing && !p.completed && !p.current!.isImage) {
      return WordContextView(
        key: const ValueKey('onboarding-context'),
        document: _document!,
        position: p.position,
        fontSize: _draft.fontSize,
        readingFont: _draft.readingFont,
        highlight: _draft.highlight,
        height: 250,
        onTap: _toggle,
        onStep: (delta) => _seek(p.position + delta),
        onScrollStart: p.pause,
        onScrollEnd: () {},
      );
    }
    return Semantics(
      button: true,
      label: p.playing ? l.pauseReading : l.playReading,
      child: GestureDetector(
        key: const ValueKey('onboarding-reading-field'),
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 12 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (p.current?.isImage == true)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/onboarding/landscape.png',
                    height: 180,
                    fit: BoxFit.cover,
                    semanticLabel: l.obImageAlt,
                  ),
                )
              else ...[
                _scope(context, height: compact ? 10 : 16),
                if (p.completed)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(l.finishedRestart),
                  )
                else
                  FocalWord(
                    token: p.current!,
                    fontSize: _draft.fontSize,
                    readingFont: _draft.readingFont,
                    highlight: _draft.highlight,
                    minimumHeight: compact ? 72 : 108,
                  ),
                _scope(context, height: compact ? 10 : 16),
              ],
              SizedBox(height: compact ? 12 : 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: p.progress,
                    minHeight: 2,
                    color: colors.accent,
                    backgroundColor: colors.separator,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playButton(BuildContext context) => ActionButton(
    key: const ValueKey('onboarding-play'),
    label: _playback!.playing
        ? context.l10n.pauseReading
        : context.l10n.playReading,
    icon: _playback!.playing ? LucideIcons.pause : LucideIcons.play,
    onPressed: _toggle,
  );

  Widget _wordButtons(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconAction(
        label: context.l10n.back,
        icon: LucideIcons.arrowLeft,
        onPressed: () => _seek(_playback!.position - 1),
      ),
      Flexible(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            context.l10n.wordOfWords(
              _playback!.position + 1,
              _playback!.tokens.length,
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
      IconAction(
        label: context.l10n.tourNext,
        icon: LucideIcons.arrowRight,
        onPressed: () => _seek(_playback!.position + 1),
      ),
    ],
  );

  Widget _slider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) => Semantics(
    label: label,
    child: isApple(context)
        ? CupertinoSlider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: ReaderColors.of(context).accent,
            onChanged: onChanged,
          )
        : Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: label,
            onChanged: onChanged,
          ),
  );

  Widget _toggleRow(
    BuildContext context,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) => SettingRow(
    title: title,
    icon: null,
    trailing: Semantics(
      label: title,
      child: isApple(context)
          ? CupertinoSwitch(
              value: value,
              activeTrackColor: ReaderColors.of(context).accent,
              onChanged: onChanged,
            )
          : Switch(value: value, onChanged: onChanged),
    ),
  );

  Widget _welcome(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              _scope(context),
              FocalWord(
                token: ReaderToken(l.read, 0, false),
                fontSize: 64,
                readingFont: ReadingFont.ibmPlexSans,
                highlight: true,
                minimumHeight: 100,
              ),
              _scope(context),
            ],
          ),
        ),
        ..._spaced([
          _overview(context, LucideIcons.focus, l.read, l.obOverviewRead),
          _overview(context, LucideIcons.bookmark, l.saved, l.obOverviewSave),
          _overview(
            context,
            LucideIcons.slidersHorizontal,
            l.settings,
            l.obOverviewStyle,
          ),
        ], 20),
      ],
    );
  }

  Widget _overview(
    BuildContext context,
    IconData icon,
    String title,
    String body,
  ) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 23, color: ReaderColors.of(context).accent),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(
              body,
              style: ReaderTypography.body(
                color: ReaderColors.of(context).secondary,
                size: 15,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _practice(BuildContext context) {
    final l = context.l10n;
    final colors = ReaderColors.of(context);
    final p = _playback;
    switch (_step) {
      case OnboardingStep.welcome:
        return _welcome(context);
      case OnboardingStep.read:
        return Column(
          children: [
            _field(context, surrounding: _done.contains(_step)),
            _playButton(context),
            const SizedBox(height: 12),
            Text(
              l.obFocusHint,
              style: ReaderTypography.body(color: colors.secondary, size: 14),
            ),
          ],
        );
      case OnboardingStep.pace:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(context, compact: true),
            _playButton(context),
            const SizedBox(height: 16),
            ..._spaced([
              for (final speed in [150, 200, 300])
                OnboardingChoice(
                  key: ValueKey('pace-$speed'),
                  title: l.speedValue(speed),
                  icon: LucideIcons.gauge,
                  selected: _draft.wpm == speed,
                  onPressed: () =>
                      _configure(_draft.copyWith(wpm: speed), _Preference.pace),
                ),
            ], 8),
            ActionButton(
              label: l.obMoreControls,
              onPressed: () => setState(() => _more = !_more),
            ),
            if (_more) ...[
              Text(l.speedValue(_draft.wpm), textAlign: TextAlign.center),
              _slider(
                context,
                label: l.readingSpeed,
                value: _draft.wpm.toDouble(),
                min: 100,
                max: 1500,
                divisions: 140,
                onChanged: (v) => _configure(
                  _draft.copyWith(wpm: v.round()),
                  _Preference.pace,
                ),
              ),
              SectionLabel(l.smartPauses),
              Text(l.smartPausesHint),
              Wrap(
                children: [
                  for (final (pause, label) in [
                    (SmartPauses.off, l.off),
                    (SmartPauses.normal, l.normal),
                    (SmartPauses.strong, l.strong),
                  ])
                    ActionButton(
                      label: label,
                      selected: _draft.pauses == pause,
                      onPressed: () => _configure(
                        _draft.copyWith(pauses: pause),
                        _Preference.pauses,
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      case OnboardingStep.move:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(context, surrounding: true),
            _wordButtons(context),
            ActionButton(
              label: l.obMoreControls,
              onPressed: () => setState(() => _more = !_more),
            ),
            if (_more) ...[
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final (delta, title) in [
                    (-10, l.backTenWords),
                    (10, l.forwardTenWords),
                  ])
                    ActionButton(
                      label: title,
                      onPressed: () => _seek(p!.position + delta),
                    ),
                  for (final (direction, title) in [
                    (-1, l.previousSentence),
                    (1, l.nextSentence),
                  ])
                    ActionButton(
                      label: title,
                      onPressed: () {
                        p!.sentence(direction);
                        _complete(_step);
                      },
                    ),
                ],
              ),
              _slider(
                context,
                label: l.readingPosition,
                value: p!.position.clamp(0, p.tokens.length - 1).toDouble(),
                min: 0,
                max: (p.tokens.length - 1).toDouble(),
                divisions: p.tokens.length - 1,
                onChanged: (v) => _seek(v.round()),
              ),
            ],
          ],
        );
      case OnboardingStep.sources:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._spaced([
              for (final (source, title, icon) in [
                (PracticeSource.text, l.addText, LucideIcons.type),
                (
                  PracticeSource.clipboard,
                  l.readClipboard,
                  LucideIcons.clipboard,
                ),
                (PracticeSource.web, l.readUrl, LucideIcons.link),
                (PracticeSource.files, l.importFile, LucideIcons.fileUp),
              ])
                OnboardingChoice(
                  key: ValueKey('source-${source.name}'),
                  title: title,
                  icon: icon,
                  subtitle: source == PracticeSource.files
                      ? 'TXT · EPUB · Markdown'
                      : null,
                  selected: _source == source,
                  onPressed: () => _sheet(
                    context,
                    title,
                    (_) => OnboardingSourceSheet(
                      source: source,
                      onImported: (reading) {
                        setState(() {
                          _imported = reading;
                          _source = source;
                        });
                        _complete(_step);
                      },
                    ),
                  ),
                ),
            ]),
            if (_imported != null) ...[
              const SizedBox(height: 20),
              Text(
                _imported!.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${_imported!.format} · ${l.wordsCount(_imported!.wordCount)}',
              ),
              const SizedBox(height: 8),
              Text(
                _imported!.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.secondary),
              ),
            ],
          ],
        );
      case OnboardingStep.contents:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(context),
            ..._spaced([
              for (final heading in _document!.headings)
                OnboardingChoice(
                  title: heading.title,
                  icon: LucideIcons.list,
                  selected: p!.position == heading.position,
                  onPressed: () {
                    _seek(heading.position);
                    _complete(_step);
                  },
                ),
            ]),
          ],
        );
      case OnboardingStep.images:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(context),
            _playButton(context),
            const SizedBox(height: 16),
            Text(
              l.secondsCount(_draft.imageSeconds),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
            ),
            _slider(
              context,
              label: l.imageDuration,
              value: _draft.imageSeconds.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              onChanged: (v) => _configure(
                _draft.copyWith(imageSeconds: v.round()),
                _Preference.images,
              ),
            ),
            Text(l.imageTimeHint, style: TextStyle(color: colors.secondary)),
          ],
        );
      case OnboardingStep.saved:
        return _savedPractice(context);
      case OnboardingStep.resume:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_showLibrary)
              OnboardingChoice(
                key: const ValueKey('practice-resume'),
                title: l.obSampleTitle,
                subtitle:
                    '${l.continueReading} · ${l.percentRead((_resumePosition / p!.tokens.length * 100).floor())}',
                icon: LucideIcons.bookOpen,
                onPressed: () {
                  setState(() => _showLibrary = false);
                  _seek(_resumePosition);
                  if (_returnedToLibrary) _complete(_step);
                },
              )
            else ...[
              _field(context, surrounding: true),
              _wordButtons(context),
              ActionButton(
                key: const ValueKey('practice-return'),
                label: l.obReturnLibrary,
                icon: LucideIcons.house,
                onPressed: () {
                  _pause();
                  setState(() {
                    _resumePosition = p!.position;
                    _showLibrary = true;
                    _returnedToLibrary = true;
                  });
                },
              ),
            ],
            const SizedBox(height: 24),
            ..._spaced([
              _overview(context, LucideIcons.house, l.home, l.obNavHome),
              _overview(context, LucideIcons.bookOpen, l.read, l.obNavRead),
              _overview(context, LucideIcons.bookmark, l.saved, l.obNavSaved),
              _overview(
                context,
                LucideIcons.settings2,
                l.settings,
                l.obNavSettings,
              ),
            ], 16),
          ],
        );
      case OnboardingStep.type:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(context),
            OnboardingChoice(
              title: l.readingFont,
              subtitle: _draft.readingFont.family,
              icon: LucideIcons.type,
              onPressed: () => _sheet(
                context,
                l.readingFont,
                (sheet) => GroupedRows(
                  children: [
                    for (final font in ReadingFont.values)
                      SettingRow(
                        title: font.family,
                        icon: null,
                        selected: font == _draft.readingFont,
                        titleStyle: TextStyle(
                          fontFamily: font.family,
                          fontSize: 18,
                        ),
                        onTap: () {
                          _configure(
                            _draft.copyWith(readingFont: font),
                            _Preference.font,
                          );
                          Navigator.pop(sheet);
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${l.typeSize} · ${_draft.fontSize.round()}',
              textAlign: TextAlign.center,
            ),
            _slider(
              context,
              label: l.typeSize,
              value: _draft.fontSize,
              min: 24,
              max: 72,
              divisions: 24,
              onChanged: (v) =>
                  _configure(_draft.copyWith(fontSize: v), _Preference.size),
            ),
            _toggleRow(
              context,
              l.highlightFocal,
              _draft.highlight,
              (v) => _configure(
                _draft.copyWith(highlight: v),
                _Preference.highlight,
              ),
            ),
          ],
        );
      case OnboardingStep.style:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._spaced([
              for (final (appearance, icon) in [
                (Appearance.system, LucideIcons.smartphone),
                (Appearance.light, LucideIcons.sun),
                (Appearance.dark, LucideIcons.moon),
              ])
                OnboardingChoice(
                  key: ValueKey('appearance-${appearance.name}'),
                  title: _appearanceName(l, appearance),
                  icon: icon,
                  selected: _draft.appearance == appearance,
                  onPressed: () => _configure(
                    _draft.copyWith(appearance: appearance),
                    _Preference.appearance,
                  ),
                ),
            ], 8),
            const SizedBox(height: 16),
            OnboardingChoice(
              title: l.accentColor,
              subtitle: l.accentName(_draft.accent),
              icon: LucideIcons.palette,
              onPressed: () => _sheet(
                context,
                l.accentColor,
                (sheet) => AccentPicker(
                  selected: _draft.accent,
                  onSelected: (v) {
                    _configure(_draft.copyWith(accent: v), _Preference.accent);
                    Navigator.pop(sheet);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            OnboardingChoice(
              title: l.language,
              subtitle: _languageName(l, _draft.language),
              icon: LucideIcons.languages,
              onPressed: () => _languageSheet(context),
            ),
            const SizedBox(height: 8),
            _toggleRow(
              context,
              l.reduceTransparency,
              _draft.reduceTransparency,
              (v) => _configure(
                _draft.copyWith(reduceTransparency: v),
                _Preference.transparency,
              ),
            ),
            Text(
              l.solidControlsHint,
              style: ReaderTypography.body(color: colors.secondary, size: 14),
            ),
          ],
        );
      case OnboardingStep.ready:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Icon(
                LucideIcons.circleCheck,
                size: 72,
                color: colors.accent,
              ),
            ),
            Text(
              l.obSummary(_done.length, OnboardingStep.lessonCount),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            OnboardingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _spaced([
                  Text(l.speedValue(_settingsToSave(true).wpm)),
                  Text(_settingsToSave(true).readingFont.family),
                  Text(_appearanceName(l, _settingsToSave(true).appearance)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.obPrivacy,
              style: ReaderTypography.body(color: colors.secondary, size: 15),
            ),
          ],
        );
    }
  }

  Widget _savedPractice(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(context, compact: true),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            ActionButton(
              key: const ValueKey('practice-star'),
              label: _starred
                  ? l.unstarTitle(l.obSampleTitle)
                  : l.starTitle(l.obSampleTitle),
              icon: LucideIcons.star,
              selected: _starred,
              onPressed: () {
                _pause();
                setState(() {
                  _starred = !_starred;
                  _everStarred = true;
                });
                if (_everBookmarked) _complete(_step);
              },
            ),
            ActionButton(
              key: const ValueKey('practice-bookmark'),
              label: l.bookmarkThisWord,
              icon: LucideIcons.bookmark,
              selected: _bookmark != null,
              onPressed: () {
                _pause();
                setState(() {
                  _bookmark = _playback!.position.clamp(
                    0,
                    _playback!.tokens.length - 1,
                  );
                  _everBookmarked = true;
                });
                if (_everStarred) _complete(_step);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_starred)
          Dismissible(
            key: const ValueKey('practice-star-row'),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => setState(() => _starred = false),
            background: ColoredBox(color: ReaderColors.of(context).elevated),
            child: OnboardingCard(
              child: _overview(
                context,
                LucideIcons.star,
                l.obSampleTitle,
                l.starred,
              ),
            ),
          ),
        if (_bookmark != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Dismissible(
              key: const ValueKey('practice-bookmark-row'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => setState(() => _bookmark = null),
              background: ColoredBox(color: ReaderColors.of(context).elevated),
              child: OnboardingChoice(
                title: l.obSampleTitle,
                icon: LucideIcons.bookmark,
                subtitle: _document!.tokens[_bookmark!].text,
                onPressed: () => _seek(_bookmark!),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(l.obSwipeHint),
      ],
    );
  }

  (String, String) _copy(AppLocalizations l) => switch (_step) {
    OnboardingStep.welcome => (l.tourWelcome, l.obWelcomeBody),
    OnboardingStep.read => (l.obReadTitle, l.obReadBody),
    OnboardingStep.pace => (l.obPaceTitle, l.obPaceBody),
    OnboardingStep.move => (l.obMoveTitle, l.obMoveBody),
    OnboardingStep.sources => (l.obSourceTitle, l.obSourceBody),
    OnboardingStep.contents => (l.obContentsTitle, l.obContentsBody),
    OnboardingStep.images => (l.obImageTitle, l.obImageBody),
    OnboardingStep.saved => (l.obSaveTitle, l.obSaveBody),
    OnboardingStep.resume => (l.obResumeTitle, l.obResumeBody),
    OnboardingStep.type => (l.obTypeTitle, l.obTypeBody),
    OnboardingStep.style => (l.obStyleTitle, l.obStyleBody),
    OnboardingStep.ready => (l.obReadyTitle, l.obReadyBody),
  };

  String _feedback(AppLocalizations l) => switch (_step) {
    OnboardingStep.read => l.obReadSuccess,
    OnboardingStep.pace => l.speedValue(_draft.wpm),
    OnboardingStep.move => l.wordOfWords(
      _playback!.position + 1,
      _playback!.tokens.length,
    ),
    OnboardingStep.sources =>
      _imported == null ? l.tourDone : l.wordsCount(_imported!.wordCount),
    OnboardingStep.contents => _playback!.current!.text,
    OnboardingStep.images => l.secondsCount(_draft.imageSeconds),
    OnboardingStep.saved => l.obSaveSuccess,
    OnboardingStep.resume => l.obResumeSuccess,
    _ => l.obPreviewSaved,
  };

  Widget _footer(BuildContext context) {
    final l = context.l10n;
    final colors = ReaderColors.of(context);
    final done = _done.contains(_step);
    final optional = _step.index >= OnboardingStep.type.index;
    final canContinue = _step == OnboardingStep.welcome || done || optional;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: TextStyle(color: colors.destructive),
                    ),
                  ),
                ),
              if (done)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.circleCheck,
                          color: colors.accent,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _feedback(l),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 54),
                child: ActionButton(
                  key: const ValueKey('tour-next'),
                  primary: true,
                  label: _busy
                      ? l.opening
                      : _step == OnboardingStep.welcome
                      ? l.obStart
                      : _step == OnboardingStep.ready
                      ? (widget.replay ? l.tourFinish : l.obOpenLibrary)
                      : l.obContinue,
                  onPressed: _busy || !canContinue
                      ? null
                      : () {
                          if (_step == OnboardingStep.ready) {
                            _finish(context);
                          } else {
                            _next(context);
                          }
                        },
                ),
              ),
              if (!canContinue)
                ActionButton(
                  key: const ValueKey('tour-skip-step'),
                  label: l.obSkipStep,
                  onPressed: _busy ? null : () => _next(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      _previewTheme(context, Builder(builder: _buildPage));

  Widget _buildPage(BuildContext context) {
    final l = context.l10n;
    final colors = ReaderColors.of(context);
    final (title, body) = _copy(l);
    final progress = (_step.index / OnboardingStep.lessonCount).clamp(0.0, 1.0);
    final content = _immersive
        ? GestureDetector(
            key: const ValueKey('onboarding-immersive'),
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: _field(context),
              ),
            ),
          )
        : SafeArea(
            child: LayoutBuilder(
              builder: (context, bounds) {
                final flowFooter =
                    bounds.maxHeight < 640 ||
                    MediaQuery.textScalerOf(context).scale(16) > 24;
                final wide =
                    bounds.maxWidth >= 700 &&
                    MediaQuery.textScalerOf(context).scale(16) <= 24;
                final heading = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_step == OnboardingStep.welcome) ...[
                      const BrandMark(size: 36),
                      const SizedBox(height: 24),
                    ] else ...[
                      Text(
                        _step == OnboardingStep.ready
                            ? l.complete
                            : l.obStep(_step.index, OnboardingStep.lessonCount),
                        style: ReaderTypography.body(
                          color: colors.secondary,
                          size: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style:
                            ReaderTypography.body(
                              color: colors.text,
                              size: 34,
                            ).copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.12,
                              letterSpacing: -.8,
                            ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      body,
                      style: ReaderTypography.body(
                        color: colors.secondary,
                        size: 17,
                      ).copyWith(height: 1.45),
                    ),
                    if (_step == OnboardingStep.welcome) ...[
                      const SizedBox(height: 12),
                      Text(
                        l.obScope,
                        style: ReaderTypography.body(
                          color: colors.secondary,
                          size: 14,
                        ),
                      ),
                    ],
                  ],
                );
                final practice = KeyedSubtree(
                  key: ValueKey('onboarding-step-${_step.name}'),
                  child: _practice(context),
                );
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: wide ? 960 : 560,
                      maxHeight: wide ? 800 : double.infinity,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                          child: Row(
                            children: [
                              if (_step != OnboardingStep.welcome)
                                IconAction(
                                  key: const ValueKey('tour-back'),
                                  label: l.back,
                                  icon: LucideIcons.chevronLeft,
                                  onPressed: _busy
                                      ? null
                                      : () => _go(
                                          context,
                                          OnboardingStep.values[_step.index -
                                              1],
                                        ),
                                )
                              else
                                IconAction(
                                  key: const ValueKey('onboarding-language'),
                                  label: l.language,
                                  icon: LucideIcons.languages,
                                  onPressed: () => _languageSheet(context),
                                ),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: ActionButton(
                                    key: const ValueKey('tour-exit'),
                                    label: widget.replay ? l.close : l.tourSkip,
                                    onPressed: _busy
                                        ? null
                                        : () => _exit(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_step != OnboardingStep.welcome)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: OnboardingProgress(
                              value: progress,
                              label: l.obStep(
                                _step.index.clamp(
                                  1,
                                  OnboardingStep.lessonCount,
                                ),
                                OnboardingStep.lessonCount,
                              ),
                            ),
                          ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scroll,
                            key: const ValueKey('onboarding-scroll'),
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (wide)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 4, child: heading),
                                      const SizedBox(width: 48),
                                      Expanded(flex: 5, child: practice),
                                    ],
                                  )
                                else ...[
                                  heading,
                                  const SizedBox(height: 24),
                                  practice,
                                ],
                                if (flowFooter) _footer(context),
                              ],
                            ),
                          ),
                        ),
                        if (!flowFooter) _footer(context),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
    return PopScope(
      canPop: !_immersive && _step == OnboardingStep.welcome && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _busy) return;
        if (_immersive) {
          _pause();
        } else if (_step.index > 0) {
          _go(context, OnboardingStep.values[_step.index - 1]);
        }
      },
      child: DefaultTextStyle(
        style: ReaderTypography.body(color: colors.text),
        child: isApple(context)
            ? CupertinoPageScaffold(
                backgroundColor: colors.background,
                child: content,
              )
            : Scaffold(backgroundColor: colors.background, body: content),
      ),
    );
  }
}
