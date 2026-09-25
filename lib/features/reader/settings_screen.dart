import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design.dart';
import '../../app/providers.dart';
import '../../app/usage_analytics.dart';
import '../../core/settings.dart';
import '../../l10n/l10n.dart';
import 'licenses_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(usageAnalyticsProvider).view(UsageScreen.settings);
  }

  Future<bool> _update(ReaderSettings next, UsageEvent event) async {
    final analytics = ref.read(usageAnalyticsProvider);
    final turningOff =
        ref.read(settingsProvider).shareUsage && !next.shareUsage;
    if (turningOff) analytics.enabled = false;
    try {
      await ref.read(settingsProvider.notifier).update(next);
      analytics.record(event, screen: UsageScreen.settings);
      return true;
    } catch (_) {
      if (turningOff) analytics.enabled = true;
      if (mounted) showProblem(context, context.l10n.settingsSaveFailed);
      return false;
    }
  }

  String _languageName(AppLanguage language) => switch (language) {
    AppLanguage.system => context.l10n.deviceLanguage,
    AppLanguage.en => context.l10n.english,
    AppLanguage.ru => context.l10n.russian,
    AppLanguage.es => context.l10n.spanish,
    AppLanguage.pt => context.l10n.portuguese,
    AppLanguage.zh => context.l10n.chinese,
    AppLanguage.ja => context.l10n.japanese,
    AppLanguage.pl => context.l10n.polish,
    AppLanguage.de => context.l10n.german,
    AppLanguage.fr => context.l10n.french,
    AppLanguage.it => context.l10n.italian,
  };
  String _appearanceName(Appearance appearance) => switch (appearance) {
    Appearance.system => context.l10n.system,
    Appearance.light => context.l10n.light,
    Appearance.dark => context.l10n.dark,
  };
  String _pauseName(SmartPauses pause) => switch (pause) {
    SmartPauses.off => context.l10n.off,
    SmartPauses.normal => context.l10n.normal,
    SmartPauses.strong => context.l10n.strong,
  };

  void _choices<T>(
    String title,
    List<T> values,
    T selected,
    String Function(T) label,
    ReaderSettings Function(T) change,
    UsageEvent event,
  ) {
    var saving = false;
    showReaderSheet(
      context,
      title,
      (sheetContext) => GroupedRows(
        separatorInset: 16,
        children: [
          for (final value in values)
            SettingRow(
              title: label(value),
              selected: value == selected,
              icon: null,
              trailing: value == selected
                  ? const Icon(LucideIcons.check, size: 20)
                  : const SizedBox.shrink(),
              onTap: () async {
                if (saving) return;
                saving = true;
                final saved = await _update(change(value), event);
                if (saved && sheetContext.mounted) Navigator.pop(sheetContext);
                if (!saved) saving = false;
              },
            ),
        ],
      ),
    );
  }

  void _slider(
    String title,
    String hint,
    double value,
    double min,
    double max,
    int divisions,
    String Function(double) label,
    ValueChanged<double> save, {
    bool typePreview = false,
  }) {
    var draft = value;
    showReaderSheet(
      context,
      title,
      (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Column(
          children: [
            const SizedBox(height: 12),
            if (typePreview) Text('Aa', style: TextStyle(fontSize: draft)),
            Text(
              label(draft),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Semantics(
                label: title,
                child: isApple(context)
                    ? CupertinoSlider(
                        value: draft,
                        min: min,
                        max: max,
                        divisions: divisions,
                        onChanged: (v) => setSheetState(() => draft = v),
                        onChangeEnd: save,
                      )
                    : Material(
                        color: Colors.transparent,
                        child: Slider(
                          value: draft,
                          min: min,
                          max: max,
                          divisions: divisions,
                          onChanged: (v) => setSheetState(() => draft = v),
                          onChangeEnd: save,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hint,
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

  Widget _toggle(bool value, String label, ValueChanged<bool>? onChanged) =>
      Semantics(
        label: label,
        child: isApple(context)
            ? CupertinoSwitch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: ReaderColors.of(context).accent,
              )
            : Switch(value: value, onChanged: onChanged),
      );

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final analytics = ref.watch(usageAnalyticsProvider);
    final l = context.l10n;
    return PlatformPage(
      title: l.settings,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.paddingOf(context).bottom + 110,
        ),
        children: [
          const SizedBox(height: 16),
          GroupedRows(
            children: [
              SettingRow(
                title: l.language,
                icon: LucideIcons.languages,
                value: _languageName(settings.language),
                onTap: () => _choices(
                  l.language,
                  AppLanguage.values,
                  settings.language,
                  _languageName,
                  (v) => ref.read(settingsProvider).copyWith(language: v),
                  UsageEvent.languageChanged,
                ),
              ),
              SettingRow(
                title: l.appearance,
                icon: LucideIcons.sunMoon,
                value: _appearanceName(settings.appearance),
                onTap: () => _choices(
                  l.appearance,
                  Appearance.values,
                  settings.appearance,
                  _appearanceName,
                  (v) => ref.read(settingsProvider).copyWith(appearance: v),
                  UsageEvent.appearanceChanged,
                ),
              ),
              SettingRow(
                title: l.reduceTransparency,
                icon: LucideIcons.layers2,
                trailing: _toggle(
                  settings.reduceTransparency,
                  l.reduceTransparency,
                  (v) => _update(
                    ref.read(settingsProvider).copyWith(reduceTransparency: v),
                    UsageEvent.transparencyChanged,
                  ),
                ),
              ),
            ],
          ),
          SectionLabel(l.read),
          GroupedRows(
            children: [
              SettingRow(
                title: l.smartPauses,
                icon: LucideIcons.timer,
                value: _pauseName(settings.pauses),
                onTap: () => _choices(
                  l.smartPauses,
                  SmartPauses.values,
                  settings.pauses,
                  _pauseName,
                  (v) => ref.read(settingsProvider).copyWith(pauses: v),
                  UsageEvent.smartPausesChanged,
                ),
              ),
              SettingRow(
                title: l.typeSize,
                icon: LucideIcons.type,
                value: '${settings.fontSize.round()}',
                onTap: () => _slider(
                  l.typeSize,
                  l.typeSizeHint,
                  settings.fontSize,
                  24,
                  72,
                  24,
                  (v) => '${v.round()}',
                  (v) => _update(
                    ref.read(settingsProvider).copyWith(fontSize: v),
                    UsageEvent.readerTypeSizeChanged,
                  ),
                  typePreview: true,
                ),
              ),
              SettingRow(
                title: l.imageDuration,
                icon: LucideIcons.image,
                value: l.secondsCount(settings.imageSeconds),
                onTap: () => _slider(
                  l.imageDuration,
                  l.imageTimeHint,
                  settings.imageSeconds.toDouble(),
                  1,
                  60,
                  59,
                  (v) => l.secondsCount(v.round()),
                  (v) => _update(
                    ref
                        .read(settingsProvider)
                        .copyWith(imageSeconds: v.round()),
                    UsageEvent.imageTimeChanged,
                  ),
                ),
              ),
              SettingRow(
                title: l.highlightFocal,
                icon: LucideIcons.focus,
                trailing: _toggle(
                  settings.highlight,
                  l.highlightFocal,
                  (v) => _update(
                    ref.read(settingsProvider).copyWith(highlight: v),
                    UsageEvent.focalHighlightChanged,
                  ),
                ),
              ),
            ],
          ),
          SectionLabel(l.usageStatistics),
          GroupedRows(
            children: [
              SettingRow(
                title: l.shareUsage,
                icon: LucideIcons.chartNoAxesColumn,
                trailing: _toggle(
                  settings.shareUsage && analytics.available,
                  l.shareUsage,
                  analytics.available
                      ? (v) => _update(
                          ref.read(settingsProvider).copyWith(shareUsage: v),
                          UsageEvent.usageEnabled,
                        )
                      : null,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Text(
              analytics.available ? l.usagePrivacy : l.usageUnavailable,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: ReaderColors.of(context).secondary,
              ),
            ),
          ),
          GroupedRows(
            children: [
              SettingRow(
                title: l.licenses,
                icon: LucideIcons.fileCheck,
                onTap: () => pushPage(context, const LicensesScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
