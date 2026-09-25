import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import 'providers.dart';
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
    final appearance = ref.watch(settingsProvider.select((s) => s.appearance));
    final language = ref.watch(settingsProvider.select((s) => s.language));
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
        }),
        home: const ReaderShell(),
      );
    }
    return MaterialApp(
      title: ProductIdentity.displayName,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: appLocalizationDelegates,
      theme: ReaderTheme.material(Brightness.light),
      darkTheme: ReaderTheme.material(Brightness.dark),
      themeMode: switch (appearance) {
        Appearance.system => ThemeMode.system,
        Appearance.light => ThemeMode.light,
        Appearance.dark => ThemeMode.dark,
      },
      home: const ReaderShell(),
    );
  }
}
