import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/document.dart';
import '../features/library/library_screen.dart';
import '../features/library/saved_screen.dart';
import '../features/reader/reader_screen.dart';
import '../features/reader/settings_screen.dart';
import 'design.dart';
import 'providers.dart';
import 'native_controls.dart';
import '../l10n/l10n.dart';

class ReaderShell extends ConsumerStatefulWidget {
  const ReaderShell({super.key});
  @override
  ConsumerState<ReaderShell> createState() => _ReaderShellState();
}

class _ReaderShellState extends ConsumerState<ReaderShell> {
  int _selected = 0;
  bool _immersive = false;
  Future<ReaderDocument?>? _recent;

  void _select(int index) {
    if (_selected == index) return;
    setState(() {
      _selected = index;
      _immersive = false;
      if (index == 1) _recent = _loadRecent();
    });
  }

  Future<ReaderDocument?> _loadRecent() async {
    final store = ref.read(storeProvider);
    final books = await store.all();
    return books.isEmpty ? null : store.document(books.first.id);
  }

  @override
  Widget build(BuildContext context) {
    final page = switch (_selected) {
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
            onImmersiveChanged: (value) {
              if (mounted && _immersive != value) {
                setState(() => _immersive = value);
              }
            },
          );
        },
      ),
      2 => const SavedScreen(),
      _ => const SettingsScreen(),
    };
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
    final navigation = NativeControl.available
        ? NativeControl(
            configuration: nativeStyle(context, ref)
              ..addAll({
                'kind': 'tabs',
                'selected': '$_selected',
                'items': [
                  for (var i = 0; i < labels.length; i++)
                    {
                      'id': '$i',
                      'label': labels[i],
                      'icon': icons[i].codePoint,
                    },
                ],
              }),
            onSelect: (id) {
              final index = int.tryParse(id);
              if (index != null && index >= 0 && index < labels.length) {
                _select(index);
              }
            },
          )
        : GlassSurface(
            radius: 36,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: Semantics(
                        selected: i == _selected,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _select(i),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: i == _selected
                                  ? ReaderColors.of(context).accent
                                        .withValues(alpha: .09)
                                  : null,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  icons[i],
                                  size: 23,
                                  color: i == _selected
                                      ? ReaderColors.of(context).accent
                                      : ReaderColors.of(context).secondary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  labels[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: i == _selected
                                        ? ReaderColors.of(context).accent
                                        : ReaderColors.of(context).secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
    final content = Stack(
      children: [
        Positioned.fill(child: page),
        if (!_immersive)
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
                      ReaderColors.of(context).background.withValues(alpha: 0),
                      ReaderColors.of(context).background
                          .withValues(alpha: .94),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (!_immersive)
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.paddingOf(context).bottom + 8,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: SizedBox(height: 76, child: navigation),
              ),
            ),
          ),
      ],
    );
    return isApple(context)
        ? CupertinoPageScaffold(child: content)
        : Scaffold(body: content);
  }
}
