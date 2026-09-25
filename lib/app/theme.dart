import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design.dart';

/// One palette/type owner for app routes, sheets, and startup recovery.
abstract final class ReaderTheme {
  static ThemeData material(Brightness brightness) {
    final c = brightness == Brightness.dark
        ? ReaderColors.dark
        : ReaderColors.light;
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
      cupertinoOverrideTheme: cupertino(brightness),
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

  static CupertinoThemeData cupertino(Brightness? brightness) {
    const text = CupertinoDynamicColor.withBrightness(
      color: ReaderColors.ink,
      darkColor: ReaderColors.paper,
    );
    const accent = CupertinoDynamicColor.withBrightness(
      color: ReaderColors.brick,
      darkColor: ReaderColors.ember,
    );
    const background = CupertinoDynamicColor.withBrightness(
      color: ReaderColors.paper,
      darkColor: ReaderColors.ink,
    );
    final body = ReaderTypography.body(color: text);
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: accent,
      primaryContrastingColor: const CupertinoDynamicColor.withBrightness(
        color: ReaderColors.paper,
        darkColor: ReaderColors.ink,
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
            ? ReaderColors.ink
            : ReaderColors.paper,
        systemNavigationBarIconBrightness: brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      );
}
