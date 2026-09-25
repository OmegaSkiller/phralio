import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phralio/app/providers.dart';
import 'package:phralio/app/reader_app.dart';
import 'package:phralio/core/settings.dart';
import 'package:phralio/features/library/library_store.dart';
import 'package:phralio/l10n/app_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _TestSettingsController extends SettingsController {
  @override
  ReaderSettings build() => ReaderSettings();

  @override
  Future<void> update(ReaderSettings value) async => state = value;
}

void main() {
  test('all requested catalogs have the same messages and placeholders', () {
    final base = jsonDecode(
      File('lib/l10n/app_en.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    final keys = base.keys.where((key) => !key.startsWith('@')).toSet();
    final locales = AppLocalizations.supportedLocales
        .map((locale) => locale.languageCode)
        .toSet();
    expect(locales, {
      'en',
      'ru',
      'es',
      'pt',
      'zh',
      'ja',
      'pl',
      'de',
      'fr',
      'it',
    });
    final placeholder = RegExp(r'\{(\w+)\}');
    for (final locale in locales) {
      final values = jsonDecode(
        File('lib/l10n/app_$locale.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(values.keys.where((key) => !key.startsWith('@')).toSet(), keys);
      for (final key in keys) {
        final original = (base[key] as String);
        final translated = (values[key] as String);
        expect(translated.trim(), isNotEmpty, reason: '$locale:$key');
        expect(
          placeholder.allMatches(translated).map((m) => m.group(1)).toList()
            ..sort(),
          placeholder.allMatches(original).map((m) => m.group(1)).toList()
            ..sort(),
          reason: '$locale:$key',
        );
      }
    }
  });

  test('language setting round trips and unknown values use the device', () {
    final settings = ReaderSettings(language: AppLanguage.ja);
    expect(ReaderSettings.fromJson(settings.toJson()).language, AppLanguage.ja);
    expect(ReaderSettings.fromJson({}).language, AppLanguage.system);
    expect(
      ReaderSettings.fromJson({'language': 'not-supported'}).language,
      AppLanguage.system,
    );
  });

  test('selected language survives SQLite reopen', () async {
    sqfliteFfiInit();
    final dir = await Directory.systemTemp.createTemp('reader-locale-');
    final path = '${dir.path}/library.sqlite';
    var store = await LibraryStore.open(path, factory: databaseFactoryFfi);
    try {
      await store.saveSettings(ReaderSettings(language: AppLanguage.pl));
      await store.close();
      store = await LibraryStore.open(path, factory: databaseFactoryFfi);
      expect((await store.settings()).language, AppLanguage.pl);
    } finally {
      await store.close();
      await dir.delete(recursive: true);
    }
  });

  testWidgets('language selection updates navigation immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryProvider.overrideWith((ref) async => []),
          settingsProvider.overrideWith(_TestSettingsController.new),
        ],
        child: const ReaderApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Device language'), findsOneWidget);
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    expect(find.text('Español'), findsOneWidget);
    await tester.ensureVisible(find.text('Español'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();
    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Ajustes'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('device language is used when no language is selected', (
    tester,
  ) async {
    tester.platformDispatcher.localeTestValue = const Locale('ru');
    tester.platformDispatcher.localesTestValue = const [Locale('ru')];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [libraryProvider.overrideWith((ref) async => [])],
        child: const ReaderApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Главная'), findsWidgets);
    expect(find.text('Настройки'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'settings and language sheet fit every locale at double text size',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final language in AppLanguage.values.where(
        (l) => l != AppLanguage.system,
      )) {
        final l = await AppLocalizations.delegate.load(Locale(language.name));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              libraryProvider.overrideWith((ref) async => []),
              initialSettingsProvider.overrideWithValue(
                ReaderSettings(language: language),
              ),
            ],
            child: const ReaderApp(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.settings).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.language));
        await tester.pumpAndSettle();
        expect(find.text('English'), findsWidgets);
        expect(tester.takeException(), isNull, reason: language.name);
        await tester.tap(find.bySemanticsLabel(l.close));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
}
