import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import '../features/onboarding/onboarding_screen.dart';
import 'providers.dart';
import 'accent.dart';
import 'usage_analytics.dart';
import 'theme.dart';
import 'identity.dart';
import 'reader_shell.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';

class ReaderApp extends ConsumerStatefulWidget {
  const ReaderApp({super.key});
  @override
  ConsumerState<ReaderApp> createState() => _ReaderAppState();
}

class _ReaderAppState extends ConsumerState<ReaderApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(usageAnalyticsProvider).record(UsageEvent.appForeground);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(usageAnalyticsProvider).record(UsageEvent.appForeground);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboarded = ref.watch(
      settingsProvider.select((s) => s.onboardingComplete),
    );
    final appearance = ref.watch(settingsProvider.select((s) => s.appearance));
    final language = ref.watch(settingsProvider.select((s) => s.language));
    final accent = ref.watch(settingsProvider.select((s) => s.accent));
    final locale = language == AppLanguage.system
        ? null
        : Locale(language.name);
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return CupertinoApp(
        title: ProductIdentity.displayName,
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: appLocalizationDelegates,
        theme: ReaderTheme.cupertino(switch (appearance) {
          Appearance.system => null,
          Appearance.light => Brightness.light,
          Appearance.dark => Brightness.dark,
        }, accent),
        builder: (context, child) =>
            AccentPalette(accent: accent, child: child!),
        home: onboarded ? const ReaderShell() : const OnboardingScreen(),
      );
    }
    return MaterialApp(
      title: ProductIdentity.displayName,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: appLocalizationDelegates,
      theme: ReaderTheme.material(Brightness.light, accent),
      darkTheme: ReaderTheme.material(Brightness.dark, accent),
      builder: (context, child) => AccentPalette(accent: accent, child: child!),
      themeMode: switch (appearance) {
        Appearance.system => ThemeMode.system,
        Appearance.light => ThemeMode.light,
        Appearance.dark => ThemeMode.dark,
      },
      home: onboarded ? const ReaderShell() : const OnboardingScreen(),
    );
  }
}
