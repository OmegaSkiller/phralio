import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import 'providers.dart';
import 'usage_analytics.dart';
import 'design.dart';
import 'identity.dart';
import '../features/library/library_screen.dart';

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
    ThemeData theme(ReaderColors colors, Brightness brightness) => ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.accent,
        brightness: brightness,
        surface: colors.surface,
        primary: colors.accent,
        error: colors.destructive,
      ),
      scaffoldBackgroundColor: colors.background,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    );
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return CupertinoApp(
        title: ProductIdentity.displayName,
        debugShowCheckedModeBanner: false,
        theme: CupertinoThemeData(
          brightness: switch (appearance) {
            Appearance.system => null,
            Appearance.light => Brightness.light,
            Appearance.dark => Brightness.dark,
          },
          primaryContrastingColor: CupertinoDynamicColor.withBrightness(
            color: ReaderColors.light.onAccent,
            darkColor: ReaderColors.dark.onAccent,
          ),
          primaryColor: CupertinoDynamicColor.withBrightness(
            color: ReaderColors.light.accent,
            darkColor: ReaderColors.dark.accent,
          ),
        ),
        home: const LibraryScreen(),
      );
    }
    return MaterialApp(
      title: ProductIdentity.displayName,
      debugShowCheckedModeBanner: false,
      theme: theme(ReaderColors.light, Brightness.light),
      darkTheme: theme(ReaderColors.dark, Brightness.dark),
      themeMode: switch (appearance) {
        Appearance.system => ThemeMode.system,
        Appearance.light => ThemeMode.light,
        Appearance.dark => ThemeMode.dark,
      },
      home: const LibraryScreen(),
    );
  }
}
