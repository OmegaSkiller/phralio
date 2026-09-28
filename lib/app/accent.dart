import 'package:flutter/widgets.dart';

import '../core/settings.dart';

/// Functional shades for Paper and Ink. Stable IDs live in ReaderSettings.
extension AccentColors on AccentColor {
  Color get light => switch (this) {
    AccentColor.vermilion => const Color(0xFFA73E2A),
    AccentColor.terracotta => const Color(0xFF934E35),
    AccentColor.rose => const Color(0xFF9B3D58),
    AccentColor.plum => const Color(0xFF784471),
    AccentColor.indigo => const Color(0xFF514D96),
    AccentColor.blue => const Color(0xFF315F90),
    AccentColor.teal => const Color(0xFF246A69),
    AccentColor.forest => const Color(0xFF3E654A),
    AccentColor.olive => const Color(0xFF62632D),
    AccentColor.ochre => const Color(0xFF825B20),
  };

  Color get dark => switch (this) {
    AccentColor.vermilion => const Color(0xFFF29C82),
    AccentColor.terracotta => const Color(0xFFE9B18F),
    AccentColor.rose => const Color(0xFFEAA3B8),
    AccentColor.plum => const Color(0xFFD6ACD2),
    AccentColor.indigo => const Color(0xFFB9B4EE),
    AccentColor.blue => const Color(0xFF9ABFE6),
    AccentColor.teal => const Color(0xFF8DCFC8),
    AccentColor.forest => const Color(0xFFA5CBA7),
    AccentColor.olive => const Color(0xFFC9CE8E),
    AccentColor.ochre => const Color(0xFFE4C282),
  };
}

/// Keeps route and native-control colors in sync without coupling widgets to
/// preference persistence. Standalone widgets retain the original brand accent.
class AccentPalette extends InheritedWidget {
  const AccentPalette({super.key, required this.accent, required super.child});

  final AccentColor accent;

  static AccentColor of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AccentPalette>()?.accent ??
      AccentColor.vermilion;

  @override
  bool updateShouldNotify(AccentPalette oldWidget) =>
      accent != oldWidget.accent;
}
