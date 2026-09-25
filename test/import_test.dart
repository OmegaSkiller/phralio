import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phralio/core/file_import.dart';

Uint8List epub({
  String? encryption,
  String? second,
  String? href,
  bool reverse = false,
}) {
  final archive = Archive();
  final files = <String, String>{
    'mimetype': 'application/epub+zip',
    'META-INF/container.xml': '<container><rootfiles><rootfile full-path="OPS/book.opf"/></rootfiles></container>',
    'OPS/book.opf':
        '''<package xmlns:dc="http://purl.org/dc/elements/1.1/">
      <metadata><dc:title>A book &amp; a pause</dc:title><dc:creator>Test Author</dc:creator></metadata>
      <manifest><item id="a" href="${href ?? 'chapter%20one.xhtml'}" media-type="application/xhtml+xml"/>
      <item id="b" href="two.xhtml" media-type="application/xhtml+xml"/>
      <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"/></manifest>
      <spine>${reverse ? '<itemref idref="b"/><itemref idref="a"/>' : '<itemref idref="a"/><itemref idref="b"/>'}<itemref idref="nav" linear="no"/></spine></package>''',
    // Deliberately insert in an order different from the spine.
    'OPS/two.xhtml':
        second ?? '<html><body><p>Second chapter.</p></body></html>',
    'OPS/chapter one.xhtml': '<html><head><title>Not text</title></head><body><h1>First</h1><p>Hello <em>kind</em> world &amp; friends.</p><script>bad()</script><nav>Navigation</nav><p hidden="">Hidden</p></body></html>',
    'OPS/nav.xhtml': '<html><body>Skip this navigation</body></html>',
    if (encryption != null)
      'META-INF/encryption.xml':
          '<encryption><EncryptedData><CipherData><CipherReference URI="$encryption"/></CipherData></EncryptedData></encryption>',
  };
  files.forEach((name, text) => archive.add(ArchiveFile.string(name, text)));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  ImportedReading txt(List<int> bytes) =>
      FileImport.parse((name: 'reading.TXT', bytes: Uint8List.fromList(bytes)));
  test('TXT normalizes newlines and accepts UTF-8 BOM, UTF-16 LE and BE', () {
    expect(
      txt([0xef, 0xbb, 0xbf, ...utf8.encode('Hello\r\nworld')]).text,
      'Hello\nworld',
    );
    expect(
      txt([0xff, 0xfe, 0x48, 0, 0x69, 0, 0x20, 0, 0x3d, 0xd8, 0, 0xde]).text,
      'Hi 😀',
    );
    expect(txt([0xfe, 0xff, 0, 0x48, 0, 0x69]).text, 'Hi');
    expect(txt(utf8.encode('Здравей свят')).wordCount, 2);
  });
  test('TXT rejects empty, binary, unsupported encoding, unmatched surrogate and size', () {
    for (final bytes in [
      <int>[],
      [0],
      [0xc3, 0x28],
      [0xff, 0xfe, 0, 0xd8],
      [0xff, 0xfe, 65],
    ]) {
      expect(() => txt(bytes), throwsFormatException);
    }
    expect(
      () => txt(Uint8List(FileImport.maxFileBytes + 1)),
      throwsFormatException,
    );
    expect(
      () => txt(utf8.encode('x' * (FileImport.maxTextCharacters + 1))),
      throwsFormatException,
    );
  });
  test('EPUB uses metadata and spine, keeps inline spaces, skips hidden and executable text', () {
    final book = FileImport.parse((name: 'test.epub', bytes: epub()));
    expect(book.title, 'A book & a pause');
    expect(book.author, 'Test Author');
    expect(
      book.text,
      'First\n\nHello kind world & friends.\n\nSecond chapter.',
    );
    expect(book.wordCount, 8);
    expect(book.format, 'EPUB');
    final reversed = FileImport.parse((
      name: 'test.epub',
      bytes: epub(reverse: true),
    ));
    expect(reversed.text, startsWith('Second chapter.'));
  });
  test('EPUB table cells and definition lists retain word boundaries', () {
    final book = FileImport.parse((
      name: 'tables.epub',
      bytes: epub(
        second: '<body><table><tr><td>One</td><td>Two</td></tr></table><dl><dt>Term</dt><dd>Meaning</dd></dl></body>',
      ),
    ));
    expect(book.text, endsWith('One\n\nTwo\n\nTerm\n\nMeaning'));
  });
  test(
    'EPUB rejects encrypted reading content but allows obfuscated fonts',
    () {
      expect(
        () => FileImport.parse((
          name: 'book.epub',
          bytes: epub(encryption: 'OPS/two.xhtml'),
        )),
        throwsFormatException,
      );
      expect(
        FileImport.parse((
          name: 'book.epub',
          bytes: epub(encryption: 'OPS/font.otf'),
        )).wordCount,
        8,
      );
    },
  );
  test(
    'EPUB rejects external, escaping, missing resources and malformed ZIP',
    () {
      for (final href in [
        'https://example.com/book',
        '../../outside.xhtml',
        'missing.xhtml',
      ]) {
        expect(
          () => FileImport.parse((name: 'book.epub', bytes: epub(href: href))),
          throwsFormatException,
        );
      }
      expect(
        () => FileImport.parse((
          name: 'book.epub',
          bytes: Uint8List.fromList([1, 2, 3]),
        )),
        throwsFormatException,
      );
      expect(
        () => FileImport.parse((name: 'book.pdf', bytes: epub())),
        throwsFormatException,
      );
    },
  );
  test(
    'content fingerprint ignores filename and preserves whole book text',
    () {
      final a = FileImport.parse((name: 'one.epub', bytes: epub()));
      final b = FileImport.parse((name: 'renamed.epub', bytes: epub()));
      expect(a.fingerprint, b.fingerprint);
    },
  );
  test('ZIP declared size cannot bypass the decompression bound', () {
    final data = epub(second: '<p>${'hello ' * 1000}</p>');
    final view = ByteData.sublistView(data);
    for (var i = 0; i + 46 < data.length; i++) {
      if (view.getUint32(i, Endian.little) == 0x02014b50) {
        final nameLength = view.getUint16(i + 28, Endian.little);
        if (utf8.decode(data.sublist(i + 46, i + 46 + nameLength)) ==
            'OPS/two.xhtml') {
          view.setUint32(i + 24, 8, Endian.little);
          break;
        }
      }
    }
    expect(
      () => FileImport.parse((name: 'book.epub', bytes: data)),
      throwsFormatException,
    );
  });
  test('ZIP CRC corruption is rejected', () {
    final data = epub();
    final view = ByteData.sublistView(data);
    for (var i = 0; i + 46 < data.length; i++) {
      if (view.getUint32(i, Endian.little) == 0x02014b50) {
        view.setUint32(i + 16, 0, Endian.little);
        break;
      }
    }
    expect(
      () => FileImport.parse((name: 'book.epub', bytes: data)),
      throwsFormatException,
    );
  });
}
