import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart';
import 'package:fake_async/fake_async.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phralio/core/document.dart';
import 'package:phralio/core/file_import.dart';
import 'package:phralio/core/playback.dart';
import 'package:phralio/core/remote_import.dart';
import 'package:phralio/core/settings.dart';
import 'package:phralio/features/library/library_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/lNsAAAAASUVORK5CYII=',
);

void main() {
  test('Markdown creates readable headings and image frames', () {
    final source =
        '# First chapter\nHello **kind** world.\n\n![A diagram](data:image/png;base64,${base64Encode(tinyPng)})\n\n## Next\nAgain.';
    final book = FileImport.parse((
      name: 'story.md',
      bytes: Uint8List.fromList(utf8.encode(source)),
    ));
    expect(book.format, 'Markdown');
    expect(book.text, contains('Hello kind world.'));
    expect(book.headings.map((h) => h.title), ['First chapter', 'Next']);
    expect(book.images, hasLength(1));
    expect(
      book.text.split(RegExp(r'\s+'))[book.images.single.position],
      imageMarker,
    );
    final engine = Playback(
      tokenize(book.text),
      settings: ReaderSettings(imageSeconds: 7),
      position: book.images.single.position,
    );
    expect(
      const TimingPolicy().duration(engine.current!, engine.settings),
      const Duration(seconds: 7),
    );
    engine.dispose();
  });

  test('playback holds an image for its separate viewing time', () {
    fakeAsync((clock) {
      final engine = Playback(
        tokenize('Before $imageMarker After'),
        settings: ReaderSettings(
          wpm: 300,
          pauses: SmartPauses.off,
          imageSeconds: 2,
        ),
        now: () => clock.elapsed,
      );
      engine.play();
      clock.elapse(const Duration(milliseconds: 200));
      expect(engine.current!.isImage, true);
      clock.elapse(const Duration(milliseconds: 1999));
      expect(engine.current!.isImage, true);
      clock.elapse(const Duration(milliseconds: 1));
      expect(engine.current!.text, 'After');
      engine.dispose();
    });
  });

  test('EPUB spine records chapter headings and embedded images', () {
    final archive = Archive()
      ..add(ArchiveFile.string('mimetype', 'application/epub+zip'))
      ..add(
        ArchiveFile.string(
          'META-INF/container.xml',
          '<container><rootfiles><rootfile full-path="OPS/book.opf"/></rootfiles></container>',
        ),
      )
      ..add(
        ArchiveFile.string(
          'OPS/book.opf',
          '<package xmlns:dc="http://purl.org/dc/elements/1.1/"><metadata><dc:title>Picture book</dc:title></metadata><manifest><item id="one" href="chapter.xhtml" media-type="application/xhtml+xml"/></manifest><spine><itemref idref="one"/></spine></package>',
        ),
      )
      ..add(
        ArchiveFile.string(
          'OPS/chapter.xhtml',
          '<html><body><h1>First</h1><p>Before image.</p><img src="picture.png" alt="Tiny picture"/><h2>After</h2><p>Last words.</p></body></html>',
        ),
      )
      ..add(ArchiveFile('OPS/picture.png', tinyPng.length, tinyPng));
    final book = FileImport.parse((
      name: 'picture.epub',
      bytes: Uint8List.fromList(ZipEncoder().encode(archive)),
    ));
    expect(book.headings.map((heading) => heading.title), ['First', 'After']);
    expect(book.images.single.bytes, tinyPng);
    expect(
      book.text.split(RegExp(r'\s+'))[book.images.single.position],
      imageMarker,
    );
  });

  test(
    'HTTPS article drops chrome and scripts and stores bounded same-host image',
    () async {
      final requests = <Uri>[];
      final importer = RemoteImport(
        client: MockClient((request) async {
          requests.add(request.url);
          if (request.url.path == '/image.png') {
            return http.Response.bytes(
              tinyPng,
              200,
              headers: {'content-type': 'image/png'},
            );
          }
          return http.Response(
            '<html><head><title>Example story</title></head><body><nav>Skip</nav><article><h1>Opening</h1><p>Useful words.</p><img src="/image.png" alt="Diagram"><script>bad()</script><h2>Later</h2><p>More text.</p></article></body></html>',
            200,
            headers: {'content-type': 'text/html'},
          );
        }),
      );
      final book = await importer.page('https://example.org/story');
      expect(book.title, 'Example story');
      expect(book.text, isNot(contains('Skip')));
      expect(book.text, isNot(contains('bad()')));
      expect(book.headings.map((h) => h.title), ['Opening', 'Later']);
      expect(book.images.single.bytes, isNotNull);
      expect(requests.map((u) => u.host).toSet(), {'example.org'});
      importer.close();
    },
  );

  test(
    'remote import rejects private and non-HTTPS URLs and oversized bodies',
    () async {
      for (final url in [
        'http://example.org',
        'https://localhost/x',
        'https://127.0.0.1/',
        'https://user:pass@example.org/',
      ]) {
        expect(() => RemoteImport.validate(url), throwsFormatException);
      }
      final importer = RemoteImport(
        client: MockClient(
          (_) async => http.Response(
            'x' * (RemoteImport.maxPageBytes + 1),
            200,
            headers: {'content-type': 'text/plain'},
          ),
        ),
      );
      await expectLater(
        importer.page('https://example.org/large'),
        throwsFormatException,
      );
      importer.close();
    },
  );

  test(
    'headings, images, bookmarks and image time survive SQLite restart',
    () async {
      sqfliteFfiInit();
      final dir = await Directory.systemTemp.createTemp('reader-rich-');
      final path = '${dir.path}/library.sqlite';
      var store = await LibraryStore.open(path, factory: databaseFactoryFfi);
      try {
        final book = ImportedReading(
          title: 'Rich reading',
          text: 'Start $imageMarker End',
          format: 'Markdown',
          headings: const [ReadingHeading('Start', 0, 1)],
          images: [ReadingImage(position: 1, alt: 'Diagram', bytes: tinyPng)],
        );
        final id = await store.importReading(book);
        expect(await store.toggleBookmark(id, 1), true);
        await store.saveSettings(ReaderSettings(imageSeconds: 9));
        await store.close();
        store = await LibraryStore.open(path, factory: databaseFactoryFfi);
        final document = await store.document(id);
        expect(document.headings.single.position, 0);
        expect(document.images.single.bytes, tinyPng);
        expect(await store.bookmarksFor(id), [1]);
        expect((await store.bookmarks()).single.title, 'Rich reading');
        expect((await store.settings()).imageSeconds, 9);
        expect(await store.toggleBookmark(id, 1), false);
        expect(await store.bookmarksFor(id), isEmpty);
      } finally {
        await store.close();
        await dir.delete(recursive: true);
      }
    },
  );

  test('schema 2 library upgrades without losing reading or star', () async {
    sqfliteFfiInit();
    final dir = await Directory.systemTemp.createTemp('reader-schema2-');
    final path = '${dir.path}/library.sqlite';
    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) async {
          await db.execute(
            "CREATE TABLE documents (id INTEGER PRIMARY KEY, title TEXT NOT NULL, content TEXT NOT NULL, position INTEGER NOT NULL DEFAULT 0, opened INTEGER NOT NULL DEFAULT 0, word_count INTEGER NOT NULL DEFAULT 0, starred INTEGER NOT NULL DEFAULT 0, format TEXT NOT NULL DEFAULT 'Text', author TEXT NOT NULL DEFAULT '', fingerprint TEXT)",
          );
          await db.execute(
            'CREATE UNIQUE INDEX imported_fingerprint ON documents(fingerprint)',
          );
          await db.execute(
            'CREATE TABLE preferences (id INTEGER PRIMARY KEY CHECK(id=1), value TEXT NOT NULL)',
          );
          await db.insert('documents', {
            'title': 'Old book',
            'content': 'one two three',
            'position': 1,
            'opened': 123,
            'word_count': 3,
            'starred': 1,
          });
        },
      ),
    );
    await old.close();
    final store = await LibraryStore.open(path, factory: databaseFactoryFfi);
    try {
      final row = (await store.all()).single;
      expect(row.starred, true);
      expect(row.progress, closeTo(1 / 3, 0.001));
      final document = await store.document(row.id);
      expect(document.text, 'one two three');
      expect(document.headings, isEmpty);
      expect(await store.toggleBookmark(row.id, 1), true);
      expect(await store.bookmarksFor(row.id), [1]);
    } finally {
      await store.close();
      await dir.delete(recursive: true);
    }
  });
}
