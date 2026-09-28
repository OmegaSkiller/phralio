import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/document.dart';
import '../features/library/library_screen.dart';
import '../features/library/paste_screen.dart';
import '../features/library/url_screen.dart';
import '../features/library/saved_screen.dart';
import '../features/reader/reader_screen.dart';
import '../features/reader/settings_screen.dart';
import '../l10n/l10n.dart';
import 'adaptive_layout.dart';
import 'design.dart';
import 'native_controls.dart';
import 'providers.dart';

class ReaderShell extends ConsumerStatefulWidget {
  const ReaderShell({super.key});
  @override
  ConsumerState<ReaderShell> createState() => _ReaderShellState();
}

class _ReaderShellState extends ConsumerState<ReaderShell> {
  static const _desktop = MethodChannel('phralio/desktop');
  bool get _isMac =>
      NativeControl.available && defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    if (_isMac) {
      _desktop.setMethodCallHandler((call) async {
        if (!mounted || call.method != 'select') return;
        final command = call.arguments as String;
        final index = int.tryParse(command);
        if (index != null && index >= 0 && index < 4) {
          _select(index);
        } else if (command == 'text' || command == 'url') {
          _select(0);
          _navigator.currentState?.push(
            CupertinoPageRoute<void>(
              builder: (_) =>
                  command == 'text' ? const PasteScreen() : const UrlScreen(),
            ),
          );
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isMac) {
      final l = context.l10n;
      _desktop.invokeMethod<void>('configure', {
        'title': l.read,
        'dark': ReaderColors.of(context).isDark,
        'labels': [l.home, l.read, l.saved, l.settings, l.addText, l.readUrl],
      });
    }
  }

  @override
  void dispose() {
    if (_isMac) {
      _desktop.setMethodCallHandler(null);
      _desktop.invokeMethod<void>('disable');
    }
    super.dispose();
  }

  final _navigator = GlobalKey<NavigatorState>();
  int _selected = 0;
  bool _immersive = false;
  bool _detailRoute = false;
  late final _observer = _ShellObserver((detail) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _detailRoute != detail) {
        setState(() => _detailRoute = detail);
      }
    });
  });
  Future<ReaderDocument?>? _recent;

  void _select(int index) {
    _navigator.currentState?.popUntil((route) => route.isFirst);
    setState(() {
      _selected = index;
      _immersive = false;
      if (index == 1) _recent = _loadRecent();
    });
  }

  void _focusChanged(bool value) {
    if (mounted && _immersive != value) setState(() => _immersive = value);
  }

  Future<ReaderDocument?> _loadRecent() async {
    final store = ref.read(storeProvider);
    final books = await store.all();
    return books.isEmpty ? null : store.document(books.first.id);
  }

  Widget _page() => switch (_selected) {
    0 => const LibraryScreen(),
    1 => FutureBuilder<ReaderDocument?>(
      future: _recent,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return PlatformPage(
            title: context.l10n.read,
            child: Center(child: Text(context.l10n.readingCouldNotOpen)),
          );
        }
        if (!snapshot.hasData) {
          return PlatformPage(
            title: context.l10n.read,
            child: Center(
              child: Text(
                snapshot.connectionState == ConnectionState.done
                    ? context.l10n.addReadingToBegin
                    : context.l10n.openingReading,
              ),
            ),
          );
        }
        return ReaderScreen(
          key: ValueKey(snapshot.data!.id),
          document: snapshot.data!,
        );
      },
    ),
    2 => const SavedScreen(),
    _ => const SettingsScreen(),
  };

  Widget _navigation(NavigationLayout layout) {
    final colors = ReaderColors.of(context);
    final labels = [
      context.l10n.home,
      context.l10n.read,
      context.l10n.saved,
      context.l10n.settings,
    ];
    const icons = [
      LucideIcons.house,
      LucideIcons.bookOpen,
      LucideIcons.bookmark,
      LucideIcons.settings2,
    ];
    final vertical = layout != NavigationLayout.tabs;
    final compact = layout == NavigationLayout.rail;
    if (NativeControl.available) {
      return NativeControl(
        configuration: nativeStyle(context, ref)
          ..addAll({
            'kind': 'tabs',
            'selected': '$_selected',
            'vertical': vertical,
            'compact': compact,
            'items': [
              for (var i = 0; i < labels.length; i++)
                {'id': '$i', 'label': labels[i], 'icon': icons[i].codePoint},
            ],
          }),
        onSelect: (id) {
          final index = int.tryParse(id);
          if (index != null && index >= 0 && index < labels.length) {
            _select(index);
          }
        },
      );
    }
    return GlassSurface(
      radius: vertical ? 24 : 36,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Flex(
          direction: vertical ? Axis.vertical : Axis.horizontal,
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Semantics(
                  selected: i == _selected,
                  child: Tooltip(
                    message: labels[i],
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _select(i),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: vertical && !compact ? 14 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: i == _selected
                              ? colors.accent.withValues(alpha: .1)
                              : null,
                          borderRadius: BorderRadius.circular(
                            vertical ? 18 : 30,
                          ),
                        ),
                        child: vertical && !compact
                            ? Row(
                                children: [
                                  Icon(
                                    icons[i],
                                    size: 22,
                                    color: i == _selected
                                        ? colors.accent
                                        : colors.secondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      labels[i],
                                      style: ReaderTypography.body(
                                        color: i == _selected
                                            ? colors.accent
                                            : colors.text,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    icons[i],
                                    size: 23,
                                    color: i == _selected
                                        ? colors.accent
                                        : colors.secondary,
                                  ),
                                  if (!compact) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      labels[i],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: i == _selected
                                            ? colors.accent
                                            : colors.secondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final layout = NavigationLayout.forSize(
        constraints.maxWidth,
        constraints.maxHeight,
      );
      final wide = layout != NavigationLayout.tabs;
      final page = _page();
      final navigator = NavigatorPopHandler(
        onPopWithResult: (_) => _navigator.currentState?.maybePop(),
        child: Navigator(
          key: _navigator,
          observers: [_observer],
          pages: [
            isApple(context)
                ? CupertinoPage<void>(
                    key: const ValueKey('shell-root'),
                    child: page,
                  )
                : MaterialPage<void>(
                    key: const ValueKey('shell-root'),
                    child: page,
                  ),
          ],
          onDidRemovePage: (_) {},
        ),
      );
      final content = _immersive || (!wide && _detailRoute)
          ? navigator
          : wide
          ? SafeArea(
              top: false,
              right: false,
              bottom: false,
              child: Row(
                children: [
                  SizedBox(
                    width: layout == NavigationLayout.sidebar ? 240 : 88,
                    child: SafeArea(
                      right: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 26, 10, 16),
                        child: Column(
                          children: [
                            if (layout == NavigationLayout.sidebar)
                              const BrandLockup()
                            else
                              const BrandMark(size: 32),
                            const SizedBox(height: 28),
                            Flexible(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 224,
                                ),
                                child: _navigation(layout),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: navigator),
                ],
              ),
            )
          : Stack(
              children: [
                Positioned.fill(child: navigator),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: MediaQuery.paddingOf(context).bottom + 110,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            ReaderColors.of(context).background
                                .withValues(alpha: 0),
                            ReaderColors.of(context).background
                                .withValues(alpha: .94),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.paddingOf(context).bottom + 8,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: SizedBox(height: 76, child: _navigation(layout)),
                    ),
                  ),
                ),
              ],
            );
      final shortcuts = <ShortcutActivator, VoidCallback>{
        for (final (index, key) in [
          LogicalKeyboardKey.digit1,
          LogicalKeyboardKey.digit2,
          LogicalKeyboardKey.digit3,
          LogicalKeyboardKey.digit4,
        ].indexed) ...{
          SingleActivator(key, meta: true): () => _select(index),
          SingleActivator(key, control: true): () => _select(index),
        },
      };
      return ReaderLayout(
        navigation: layout,
        onImmersiveChanged: _focusChanged,
        hasBottomTabs: !wide && !_detailRoute && !_immersive,
        child: CallbackShortcuts(
          bindings: shortcuts,
          child: Focus(
            autofocus: true,
            child: isApple(context)
                ? CupertinoPageScaffold(child: content)
                : Scaffold(body: content),
          ),
        ),
      );
    },
  );
}

class _ShellObserver extends NavigatorObserver {
  _ShellObserver(this.onChanged);
  final ValueChanged<bool> onChanged;
  @override
  void didChangeTop(
    Route<dynamic> topRoute,
    Route<dynamic>? previousTopRoute,
  ) => onChanged(!topRoute.isFirst);
}
