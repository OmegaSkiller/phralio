import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'app/design.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'app/providers.dart';
import 'app/reader_app.dart';
import 'features/library/library_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Lucide icons (upstream)',
    ], await rootBundle.loadString('third_party/licenses/lucide-upstream.txt'));
  });
  await launchReader();
}

Future<void> launchReader() async {
  LibraryStore? store;
  try {
    store = await LibraryStore.open(
      path.join(await getDatabasesPath(), 'reader.sqlite'),
    );
    final settings = await store.settings();
    runApp(
      ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(store),
          initialSettingsProvider.overrideWithValue(settings),
        ],
        child: const ReaderApp(),
      ),
    );
  } catch (_) {
    await store?.close();
    final recovery = PlatformPage(
      title: 'Local library',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your local library could not be opened. No data has been removed.',
              ),
              ActionButton(label: 'Try again', onPressed: launchReader),
            ],
          ),
        ),
      ),
    );
    runApp(
      ProviderScope(
        child:
            defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS
            ? CupertinoApp(home: recovery)
            : MaterialApp(home: recovery),
      ),
    );
  }
}
