import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'app/design.dart';
import 'app/theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'app/providers.dart';
import 'app/reader_app.dart';
import 'core/settings.dart';
import 'features/library/library_store.dart';
import 'l10n/app_localizations.dart';
import 'l10n/l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Lucide icons (upstream)',
    ], await rootBundle.loadString('third_party/licenses/lucide-upstream.txt'));
  });
  LicenseRegistry.addLicense(() async* {
    for (final font in ReadingFont.values) {
      yield LicenseEntryWithLineBreaks([
        font.family,
      ], await rootBundle.loadString('assets/fonts/${font.assetStem}-OFL.txt'));
    }
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
    final recovery = Builder(
      builder: (context) => PlatformPage(
        title: context.l10n.localLibrary,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.localLibraryFailed),
                ActionButton(
                  label: context.l10n.tryAgain,
                  onPressed: launchReader,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    runApp(
      ProviderScope(
        child:
            defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS
            ? CupertinoApp(
                theme: ReaderTheme.cupertino(null),
                localizationsDelegates: appLocalizationDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: recovery,
              )
            : MaterialApp(
                theme: ReaderTheme.material(Brightness.light),
                darkTheme: ReaderTheme.material(Brightness.dark),
                localizationsDelegates: appLocalizationDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: recovery,
              ),
      ),
    );
  }
}
