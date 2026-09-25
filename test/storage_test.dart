import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:phralio/features/library/library_store.dart';
import 'package:phralio/core/settings.dart';
import 'package:phralio/core/playback.dart';

void main() {
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
        final document = (await store.all()).single;
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
        final restored = (await store.all()).single;
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
        expect((await store.all()).single.progress, 1);
      } finally {
        await store.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
