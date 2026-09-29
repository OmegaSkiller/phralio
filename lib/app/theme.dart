import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design.dart';
import 'accent.dart';
import '../core/settings.dart';

/// One palette/type owner for app routes, sheets, and startup recovery.
abstract final class ReaderTheme {
  static ThemeData material(
    Brightness brightness, [
    AccentColor preset = AccentColor.vermilion,
  ]) {
    final c =
        (brightness == Brightness.dark ? ReaderColors.dark : ReaderColors.light)
            .withAccent(
              brightness == Brightness.dark ? preset.dark : preset.light,
            );
    final scheme =
        ColorScheme.fromSeed(
          seedColor: c.accent,
          brightness: brightness,
          surface: c.surface,
          onSurface: c.text,
          primary: c.accent,
          onPrimary: c.onAccent,
          secondary: c.accent,
          onSecondary: c.onAccent,
          error: c.destructive,
          onError: c.onAccent,
          outline: c.secondary,
          outlineVariant: c.separator,
        ).copyWith(
          surfaceContainerLowest: c.background,
          surfaceContainerLow: c.surface,
          surfaceContainer: c.surface,
          surfaceContainerHigh: c.elevated,
          surfaceContainerHighest: c.elevated,
          onSurfaceVariant: c.secondary,
          primaryContainer: c.elevated,
          onPrimaryContainer: c.text,
          secondaryContainer: c.elevated,
          onSecondaryContainer: c.text,
        );
    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: ReaderTypography.ui,
      fontFamilyFallback: ReaderTypography.fallbacks(),
      scaffoldBackgroundColor: c.background,
      cupertinoOverrideTheme: cupertino(brightness, preset),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: overlay(brightness),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: ReaderTypography.body(size: 16)
              .copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: ReaderTypography.body(size: 16)
              .copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: ReaderTypography.body(color: c.secondary),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: c.accent, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.accent,
        thumbColor: c.accent,
        inactiveTrackColor: c.separator,
      ),
    );
  }

  static CupertinoThemeData cupertino(
    Brightness? brightness, [
    AccentColor preset = AccentColor.vermilion,
  ]) {
    const text = CupertinoDynamicColor.withBrightness(
      color: Color(0xFF101010),
      darkColor: Color(0xFFFFFFFF),
    );
    final accent = CupertinoDynamicColor.withBrightness(
      color: preset.light,
      darkColor: preset.dark,
    );
    const background = CupertinoDynamicColor.withBrightness(
      color: Color(0xFFFFFFFF),
      darkColor: Color(0xFF000000),
    );
    final body = ReaderTypography.body(color: text);
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: accent,
      primaryContrastingColor: const CupertinoDynamicColor.withBrightness(
        color: Color(0xFFFFFFFF),
        darkColor: Color(0xFF000000),
      ),
      scaffoldBackgroundColor: background,
      barBackgroundColor: background,
      textTheme: CupertinoTextThemeData(
        textStyle: body,
        actionTextStyle: body.copyWith(
          color: accent,
          fontWeight: FontWeight.w500,
        ),
        navActionTextStyle: body.copyWith(
          color: accent,
          fontWeight: FontWeight.w500,
        ),
        navTitleTextStyle: body.copyWith(fontWeight: FontWeight.w500),
        navLargeTitleTextStyle: body.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w500,
        ),
        tabLabelTextStyle: body.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        pickerTextStyle: body.copyWith(fontSize: 21),
        dateTimePickerTextStyle: body.copyWith(fontSize: 21),
      ),
    );
  }

  static SystemUiOverlayStyle overlay(Brightness brightness) =>
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: brightness,
        statusBarIconBrightness: brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: brightness == Brightness.dark
            ? const Color(0xFF000000)
            : const Color(0xFFFFFFFF),
        systemNavigationBarIconBrightness: brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      );
}
