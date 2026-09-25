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
            return const PlatformPage(
              title: 'Read',
              child: Center(child: Text('Reading could not be opened.')),
            );
          }
          if (!snapshot.hasData) {
            return PlatformPage(
              title: 'Read',
              child: Center(
                child: Text(
                  snapshot.connectionState == ConnectionState.done
                      ? 'Add a reading from Home to begin.'
                      : 'Opening your reading…',
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
      2 => const SettingsScreen(),
      _ => const SavedScreen(),
    };
    const labels = ['Home', 'Read', 'Settings', 'Saved'];
    const icons = [
      LucideIcons.house,
      LucideIcons.bookOpen,
      LucideIcons.settings2,
      LucideIcons.bookmark,
    ];
    if (isApple(context)) {
      return CupertinoPageScaffold(
        child: Column(
          children: [
            Expanded(child: page),
            if (!_immersive)
              CupertinoTabBar(
                backgroundColor: ReaderColors.of(context).surface,
                currentIndex: _selected,
                onTap: _select,
                items: [
                  for (var i = 0; i < labels.length; i++)
                    BottomNavigationBarItem(
                      icon: Icon(icons[i]),
                      label: labels[i],
                    ),
                ],
              ),
          ],
        ),
      );
    }
    return Scaffold(
      body: page,
      bottomNavigationBar: _immersive
          ? null
          : NavigationBar(
              selectedIndex: _selected,
              onDestinationSelected: _select,
              destinations: [
                for (var i = 0; i < labels.length; i++)
                  NavigationDestination(icon: Icon(icons[i]), label: labels[i]),
              ],
            ),
    );
  }
}
