import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'design.dart';
import 'identity.dart';
import '../features/library/library_screen.dart';

class ReaderApp extends StatelessWidget {
  const ReaderApp({super.key});
  @override
  Widget build(BuildContext context) {
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
      home: const LibraryScreen(),
    );
  }
}
