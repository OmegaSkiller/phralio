import 'package:phralio/core/file_import.dart';

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:phralio/features/library/library_store.dart';
import 'package:phralio/core/settings.dart';
import 'package:phralio/core/playback.dart';

void main() {
  test(
    'schema 1 migrates without losing duplicate texts, places or settings',
    () async {
      sqfliteFfiInit();
      final dir = await Directory.systemTemp.createTemp('reader-migration-');
      final path = '${dir.path}/old.sqlite';
      final db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute(
              'CREATE TABLE documents (id INTEGER PRIMARY KEY, title TEXT NOT NULL, content TEXT NOT NULL, position INTEGER NOT NULL DEFAULT 0, opened INTEGER NOT NULL DEFAULT 0)',
            );
            await db.execute(
              'CREATE TABLE preferences (id INTEGER PRIMARY KEY CHECK(id=1), value TEXT NOT NULL)',
            );
            for (var i = 0; i < 2; i++) {
              await db.insert('documents', {
                'title': 'Old reading',
                'content': 'one two three four',
                'position': 2,
                'opened': 123,
              });
            }
            await db.insert('preferences', {'id': 1, 'value': '{"wpm":500}'});
          },
        ),
      );
      await db.close();
      final store = await LibraryStore.open(path, factory: databaseFactoryFfi);
      try {
        final entries = await store.all();
        expect(entries.length, 2);
        expect(entries.first.wordCount, 4);
        expect(entries.first.progress, .5);
        expect(entries.first.openedAt, 123);
        expect((await store.settings()).wpm, 500);
        expect((await store.settings()).appearance, Appearance.system);
        expect(
          (await store.document(entries.first.id)).text,
          'one two three four',
        );
      } finally {
        await store.close();
        await dir.delete(recursive: true);
      }
    },
  );
  test(
    'duplicate imports, stars, recency and appearance survive restart',
    () async {
      sqfliteFfiInit();
      final dir = await Directory.systemTemp.createTemp('reader-library-');
      final path = '${dir.path}/library.sqlite';
      var store = await LibraryStore.open(path, factory: databaseFactoryFfi);
      try {
        final book = ImportedReading(
          title: 'Book',
          text: 'one two three four',
          format: 'EPUB',
        );
        final id = await store.importReading(book);
        final document = await store.document(id);
        await store.savePosition(document, 3);
        await store.setStarred(id, true);
        await store.add('Another', 'new text');
        final ids = await Future.wait([
          store.importReading(book),
          store.importReading(book),
        ]);
        expect(ids, [id, id]);
        await store.saveSettings(
          ReaderSettings(appearance: Appearance.dark, reduceTransparency: true),
        );
        await store.close();
        store = await LibraryStore.open(path, factory: databaseFactoryFfi);
        final entries = await store.all();
        expect(entries.length, 2);
        expect(entries.first.id, id);
        expect(entries.first.starred, true);
        expect(entries.first.progress, .75);
        expect((await store.document(id)).tokens[3].text, 'four');
        expect((await store.settings()).appearance, Appearance.dark);
        expect((await store.settings()).reduceTransparency, true);
      } finally {
        await store.close();
        await dir.delete(recursive: true);
      }
    },
  );

  sqfliteFfiInit();
  test(
    'SQLite survives close/reopen with progress and settings intact',
    () async {
      final directory = await Directory.systemTemp.createTemp('reader-test-');
      final file = '${directory.path}/library.sqlite';
      var store = await LibraryStore.open(file, factory: databaseFactoryFfi);
      try {
        await expectLater(store.add('', '   '), throwsFormatException);
        await store.add("A title's text", 'one two three four');
        final document = await store.document((await store.all()).single.id);
        await store.savePosition(document, 2);
        await store.saveSettings(
          ReaderSettings(
            wpm: 700,
            pauses: SmartPauses.strong,
            highlight: false,
            fontSize: 52,
          ),
        );
        await store.close();
        store = await LibraryStore.open(file, factory: databaseFactoryFfi);
        final restored = await store.document((await store.all()).single.id);
        final settings = await store.settings();
        expect(restored.text, document.text);
        expect(restored.progress, 0.5);
        expect(settings.wpm, 700);
        expect(settings.highlight, isFalse);
        expect(settings.pauses, SmartPauses.strong);
        final engine = Playback(
          restored.tokens,
          settings: settings,
          position: restored.position,
        );
        expect(engine.current!.text, 'three');
        expect(engine.playing, isFalse);
        engine.dispose();
        await store.savePosition(restored, 500);
        expect(
          (await store.document((await store.all()).single.id)).progress,
          1,
        );
      } finally {
        await store.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
