import 'package:flutter/widgets.dart';

import '../core/settings.dart';

/// Saturated functional shades for white and AMOLED black. Stable IDs live in ReaderSettings.
extension AccentColors on AccentColor {
  Color get light => switch (this) {
    AccentColor.vermilion => const Color(0xFFC73518),
    AccentColor.terracotta => const Color(0xFFB84208),
    AccentColor.rose => const Color(0xFFC51C5A),
    AccentColor.plum => const Color(0xFF9323BF),
    AccentColor.indigo => const Color(0xFF5142DE),
    AccentColor.blue => const Color(0xFF0068D6),
    AccentColor.teal => const Color(0xFF007B79),
    AccentColor.forest => const Color(0xFF13802A),
    AccentColor.olive => const Color(0xFF5B7000),
    AccentColor.ochre => const Color(0xFF8F6000),
  };

  Color get dark => switch (this) {
    AccentColor.vermilion => const Color(0xFFFF6040),
    AccentColor.terracotta => const Color(0xFFFF8A38),
    AccentColor.rose => const Color(0xFFFF5593),
    AccentColor.plum => const Color(0xFFCC69FF),
    AccentColor.indigo => const Color(0xFF9780FF),
    AccentColor.blue => const Color(0xFF459BFF),
    AccentColor.teal => const Color(0xFF16C9BA),
    AccentColor.forest => const Color(0xFF39D667),
    AccentColor.olive => const Color(0xFFA3CC21),
    AccentColor.ochre => const Color(0xFFFFBD24),
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
