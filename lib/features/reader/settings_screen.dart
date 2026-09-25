import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design.dart';
import '../../app/providers.dart';
import '../../app/usage_analytics.dart';
import '../../core/settings.dart';
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final analytics = ref.watch(usageAnalyticsProvider);
    Future<void> update(ReaderSettings next, {UsageEvent? event}) async {
      final turningSharingOff = settings.shareUsage && !next.shareUsage;
      if (turningSharingOff) analytics.enabled = false;
      try {
        await ref.read(settingsProvider.notifier).update(next);
        if (event != null) {
          analytics.record(event, screen: UsageScreen.settings);
        }
      } catch (_) {
        if (turningSharingOff) analytics.enabled = true;
        if (context.mounted) {
          showProblem(
            context,
            'Your settings could not be saved. Please try again.',
          );
        }
      }
    }

    return PlatformPage(
      title: 'Reading settings',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Find your cadence.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: ReaderColors.of(context).text,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Start at a comfortable pace. Speed is a control, not a measure of comprehension.',
          ),
          const SizedBox(height: 32),
          const Text(
            'Appearance',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          GlassSurface(
            child: Wrap(
              spacing: 4,
              children: [
                for (final appearance in Appearance.values)
                  ActionButton(
                    label: switch (appearance) {
                      Appearance.system => 'System',
                      Appearance.light => 'Light',
                      Appearance.dark => 'Dark',
                    },
                    icon: switch (appearance) {
                      Appearance.system => LucideIcons.monitor,
                      Appearance.light => LucideIcons.sun,
                      Appearance.dark => LucideIcons.moon,
                    },
                    selected: settings.appearance == appearance,
                    onPressed: () => update(
                      settings.copyWith(appearance: appearance),
                      event: UsageEvent.appearanceChanged,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Text('Reduce transparency')),
              Semantics(
                label: 'Reduce transparency',
                child: isApple(context)
                    ? CupertinoSwitch(
                        value: settings.reduceTransparency,
                        onChanged: (v) => update(
                          settings.copyWith(reduceTransparency: v),
                          event: UsageEvent.transparencyChanged,
                        ),
                      )
                    : Switch(
                        value: settings.reduceTransparency,
                        onChanged: (v) => update(
                          settings.copyWith(reduceTransparency: v),
                          event: UsageEvent.transparencyChanged,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Use solid controls instead of glass. High contrast also uses solid surfaces.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 32),
          const Text(
            'Smart pauses',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Give punctuation, paragraphs, numbers, and longer words more time.',
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 12),
          for (final pause in SmartPauses.values)
            ActionButton(
              label: '${pause.name[0].toUpperCase()}${pause.name.substring(1)}',
              selected: settings.pauses == pause,
              icon: settings.pauses == pause ? LucideIcons.check : null,
              onPressed: () => update(
                settings.copyWith(pauses: pause),
                event: UsageEvent.smartPausesChanged,
              ),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Text('Highlight focal character')),
              isApple(context)
                  ? CupertinoSwitch(
                      value: settings.highlight,
                      onChanged: (v) => update(
                        settings.copyWith(highlight: v),
                        event: UsageEvent.focalHighlightChanged,
                      ),
                    )
                  : Switch(
                      value: settings.highlight,
                      onChanged: (v) => update(
                        settings.copyWith(highlight: v),
                        event: UsageEvent.focalHighlightChanged,
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Reader type size · ${settings.fontSize.round()}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconAction(
                label: 'Smaller reader type',
                icon: LucideIcons.minus,
                onPressed: settings.fontSize <= 24
                    ? null
                    : () => update(
                        settings.copyWith(fontSize: settings.fontSize - 2),
                        event: UsageEvent.readerTypeSizeChanged,
                      ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Aa',
                    style: TextStyle(fontSize: settings.fontSize),
                  ),
                ),
              ),
              IconAction(
                label: 'Larger reader type',
                icon: LucideIcons.plus,
                onPressed: settings.fontSize >= 72
                    ? null
                    : () => update(
                        settings.copyWith(fontSize: settings.fontSize + 2),
                        event: UsageEvent.readerTypeSizeChanged,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'The reader honors text scaling and fits long words to keep their focal character in view.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          const Text(
            'Usage statistics',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('Share usage statistics')),
              Semantics(
                label: 'Share usage statistics',
                child: isApple(context)
                    ? CupertinoSwitch(
                        value: settings.shareUsage && analytics.available,
                        onChanged: analytics.available
                            ? (v) => update(
                                settings.copyWith(shareUsage: v),
                                event: v ? UsageEvent.usageEnabled : null,
                              )
                            : null,
                      )
                    : Switch(
                        value: settings.shareUsage && analytics.available,
                        onChanged: analytics.available
                            ? (v) => update(
                                settings.copyWith(shareUsage: v),
                                event: v ? UsageEvent.usageEnabled : null,
                              )
                            : null,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            analytics.available
                ? 'Optional. Shares screen visits and app actions with Umami. Never sends book text, titles, file names or your reading position. Umami receives your network address and device details.'
                : 'Available when an Umami server is configured for this build.',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          ActionButton(
            label: 'Open-source licenses',
            onPressed: () => pushPage(context, const LicensesScreen()),
          ),
        ],
      ),
    );
  }
}
