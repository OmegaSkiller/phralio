import 'package:flutter/widgets.dart';

enum NavigationLayout {
  tabs,
  rail,
  sidebar;

  static NavigationLayout forSize(double width, double height) => width >= 1000
      ? sidebar
      : width >= 700 || (width >= 600 && height < 500)
      ? rail
      : tabs;
}

/// Window chrome belongs to the shell, including routes opened from a tab.
class ReaderLayout extends InheritedWidget {
  const ReaderLayout({
    super.key,
    required this.navigation,
    required this.onImmersiveChanged,
    this.hasBottomTabs = true,
    required super.child,
  });

  final NavigationLayout navigation;
  final ValueChanged<bool> onImmersiveChanged;
  final bool hasBottomTabs;

  static ReaderLayout? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ReaderLayout>();

  static double bottomInset(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom +
      (maybeOf(context)?.hasBottomTabs == true ? 110 : 24);

  @override
  bool updateShouldNotify(ReaderLayout oldWidget) =>
      navigation != oldWidget.navigation ||
      hasBottomTabs != oldWidget.hasBottomTabs;
}
