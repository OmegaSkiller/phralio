import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import 'document.dart';

class ImportedReading {
  ImportedReading({
    required this.title,
    required this.text,
    required this.format,
    this.author = '',
  }) : wordCount = RegExp(r'\S+', unicode: true).allMatches(text).length,
       fingerprint = sha256.convert(utf8.encode(text)).toString();
  final String title, text, format, author, fingerprint;
  final int wordCount;
}

/// No archive extraction, networking, or executable markup. Runs in an isolate.
abstract final class FileImport {
  static const maxFileBytes = 32 * 1024 * 1024;
  static const maxExpandedBytes = 64 * 1024 * 1024;
  static const maxEntryBytes = 16 * 1024 * 1024;
  static const maxTextCharacters = 2000000;

  static ImportedReading parse(({String name, Uint8List bytes}) input) {
    if (input.bytes.length > maxFileBytes) {
      throw const FormatException('Choose a file smaller than 32 MB.');
    }
    final extension = p.extension(input.name).toLowerCase();
    final title = p.basenameWithoutExtension(input.name);
    if (extension == '.txt') {
      return _reading(title, decodeText(input.bytes), 'TXT');
    }
    if (extension != '.epub') {
      throw const FormatException('Choose a TXT or EPUB file.');
    }
    try {
      return _epub(input.bytes, title);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
        'This EPUB is damaged or unsupported. Try another copy.',
      );
    }
  }

  static ImportedReading _reading(
    String title,
    String text,
    String format, [
    String author = '',
  ]) {
    final clean = TextImport.validate(
      title,
      text,
      maxCharacters: maxTextCharacters,
    );
    return ImportedReading(
      title: clean.title,
      text: clean.text,
      format: format,
      author: author.trim(),
    );
  }

  /// UTF-8 and BOM-marked UTF-16. Reject invalid sequences rather than losing text.
  static String decodeText(Uint8List bytes) {
    try {
      if (bytes.length >= 2 &&
          ((bytes[0] == 0xff && bytes[1] == 0xfe) ||
              (bytes[0] == 0xfe && bytes[1] == 0xff))) {
        if (bytes.length.isOdd) throw const FormatException();
        final data = ByteData.sublistView(bytes);
        final endian = bytes[0] == 0xff ? Endian.little : Endian.big;
        final units = <int>[];
        for (var i = 2; i < bytes.length; i += 2) {
          final unit = data.getUint16(i, endian);
          if (unit >= 0xd800 && unit <= 0xdbff) {
            if (i + 3 >= bytes.length) throw const FormatException();
            final next = data.getUint16(i + 2, endian);
            if (next < 0xdc00 || next > 0xdfff) throw const FormatException();
            units.addAll([unit, next]);
            i += 2;
          } else {
            if (unit >= 0xdc00 && unit <= 0xdfff) throw const FormatException();
            units.add(unit);
          }
        }
        return String.fromCharCodes(units);
      }
      return utf8.decode(bytes).replaceFirst(RegExp('^\uFEFF'), '');
    } on FormatException {
      throw const FormatException(
        'Text encoding is unsupported. Save the file as UTF-8 or UTF-16 with a BOM.',
      );
    }
  }

  static String _path(String base, String href) {
    final uri = Uri.parse(href);
    if (uri.hasScheme || uri.hasAuthority || uri.path.startsWith('/')) {
      throw const FormatException(
        'This EPUB refers to unsupported external content.',
      );
    }
    final path = p.posix.normalize(
      p.posix.join(base, Uri.decodeComponent(uri.path)),
    );
    if (path == '..' ||
        path.startsWith('../') ||
        path.contains('\\') ||
        path.contains('\u0000')) {
      throw const FormatException(
        'This EPUB contains an invalid resource path.',
      );
    }
    return path;
  }

  static XmlDocument _xml(String value) {
    // EPUB 2 may declare a public XHTML doctype. Do not accept entity definitions.
    if (RegExp(r'<!ENTITY', caseSensitive: false).hasMatch(value)) {
      throw const FormatException(
        'This EPUB contains unsupported XML entities.',
      );
    }
    return XmlDocument.parse(value);
  }

  static Iterable<XmlElement> _elements(XmlNode node, String name) => node
      .descendants
      .whereType<XmlElement>()
      .where((e) => e.name.local == name);

  static ImportedReading _epub(Uint8List bytes, String fallbackTitle) {
    final zip = ZipDirectory()..read(InputMemoryStream(bytes));
    if (zip.fileHeaders.isEmpty || zip.fileHeaders.length > 4096) {
      throw const FormatException(
        'This EPUB is invalid or contains too many resources.',
      );
    }
    var expanded = 0;
    final files = <String, ZipFileHeader>{};
    for (final header in zip.fileHeaders) {
      expanded += header.uncompressedSize;
      if (expanded > maxExpandedBytes) {
        throw const FormatException(
          'This EPUB is too large when unpacked (64 MB limit).',
        );
      }
      final name = _path('', header.filename);
      if (files.containsKey(name)) {
        throw const FormatException('This EPUB has duplicate resources.');
      }
      files[name] = header;
    }
    var bytesRead = 0;
    Uint8List read(String name) {
      final header = files[name];
      if (header == null || header.file == null) {
        throw const FormatException(
          'This EPUB is missing a required resource.',
        );
      }
      if ((header.generalPurposeBitFlag & 1) != 0 ||
          (header.file!.flags & 1) != 0) {
        throw const FormatException(
          'Encrypted EPUB files are not supported. Use a DRM-free copy.',
        );
      }
      if (header.uncompressedSize > maxEntryBytes ||
          ![0, 8].contains(header.compressionMethod)) {
        throw const FormatException(
          'This EPUB contains an oversized or unsupported resource.',
        );
      }
      final output = _LimitedOutput(header.uncompressedSize);
      final raw = header.file!.getRawContent();
      if (header.compressionMethod == 8) {
        // The native archive decoder buffers its output before delivering it.
        // Pure Dart Inflate checks our bound before each write/back-reference.
        Inflate(raw, output: output);
      } else {
        output.writeBytes(raw);
      }
      final content = output.getBytes();
      bytesRead += content.length;
      if (content.length != header.uncompressedSize ||
          getCrc32(content) != header.crc32 ||
          bytesRead > maxExpandedBytes) {
        throw const FormatException(
          'This EPUB is damaged or exceeds the import limit.',
        );
      }
      return content;
    }

    String readText(String name) => decodeText(read(name));
    if (readText('mimetype').trim() != 'application/epub+zip') {
      throw const FormatException('This file is not a valid EPUB.');
    }
    final container = _xml(readText('META-INF/container.xml'));
    final roots = _elements(container, 'rootfile');
    if (roots.isEmpty) {
      throw const FormatException('This EPUB has no package document.');
    }
    final packagePath = _path('', roots.first.getAttribute('full-path') ?? '');
    final package = _xml(readText(packagePath));
    final base = p.posix.dirname(packagePath);
    final metadata = _elements(package, 'metadata').first;
    final titles = _elements(metadata, 'title');
    final creators = _elements(metadata, 'creator');
    final manifest = <String, XmlElement>{
      for (final item in _elements(package, 'item'))
        if (item.getAttribute('id') case final String id) id: item,
    };
    final encrypted = <String>{};
    if (files.containsKey('META-INF/encryption.xml')) {
      for (final reference in _elements(
        _xml(readText('META-INF/encryption.xml')),
        'CipherReference',
      )) {
        encrypted.add(_path('', reference.getAttribute('URI') ?? ''));
      }
    }
    final text = StringBuffer();
    for (final reference in _elements(package, 'itemref')) {
      if (reference.getAttribute('linear') == 'no') continue;
      final item = manifest[reference.getAttribute('idref')];
      if (item == null) {
        throw const FormatException(
          'This EPUB has an incomplete reading order.',
        );
      }
      final resource = _path(base, item.getAttribute('href') ?? '');
      if (encrypted.contains(resource)) {
        throw const FormatException(
          'Encrypted EPUB text is not supported. Use a DRM-free copy.',
        );
      }
      if (![
        'application/xhtml+xml',
        'text/html',
      ].contains(item.getAttribute('media-type'))) {
        throw const FormatException(
          'This EPUB uses a reading format that is not supported.',
        );
      }
      final chapter = _plainHtml(readText(resource));
      if (chapter.isNotEmpty) text.writeln('$chapter\n');
      if (text.length > maxTextCharacters) {
        throw const FormatException(
          'This book exceeds the 2 million character text limit.',
        );
      }
    }
    return _reading(
      titles.isEmpty ? fallbackTitle : titles.first.innerText,
      text.toString(),
      'EPUB',
      creators.map((e) => e.innerText).join(', '),
    );
  }

  static String _plainHtml(String source) {
    final body = html.parse(source).body;
    if (body == null) return '';
    for (final element in body.querySelectorAll(
      'script, style, nav, noscript, template, [hidden], [aria-hidden="true"]',
    )) {
      element.remove();
    }
    const blocks = {
      'p',
      'div',
      'section',
      'article',
      'h1',
      'h2',
      'h3',
      'h4',
      'h5',
      'h6',
      'li',
      'blockquote',
      'pre',
      'br',
      'tr',
      'td',
      'th',
      'dt',
      'dd',
      'figcaption',
    };
    final out = StringBuffer();
    // Iterative traversal avoids stack exhaustion from deeply nested markup.
    final pending = <({dom.Node node, bool closing})>[
      (node: body, closing: false),
    ];
    while (pending.isNotEmpty) {
      final entry = pending.removeLast();
      final node = entry.node;
      if (node is dom.Text) {
        out.write(node.data.replaceAll(RegExp(r'\s+'), ' '));
      } else if (node is dom.Element) {
        final block = blocks.contains(node.localName);
        if (block) out.write('\n\n');
        if (!entry.closing) {
          if (block) pending.add((node: node, closing: true));
          for (final child in node.nodes.reversed) {
            pending.add((node: child, closing: false));
          }
        }
      }
    }
    return out
        .toString()
        .replaceAll(RegExp(r'[^\S\n]+\n'), '\n')
        .replaceAll(RegExp(r'\n[^\S\n]+'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}

class _LimitedOutput extends OutputMemoryStream {
  _LimitedOutput(this.limit) : super(size: 1024);
  final int limit;
  void _check(int count) {
    if (count < 0 || length + count > limit) {
      throw const FormatException(
        'This EPUB expands beyond its declared size.',
      );
    }
  }

  @override
  void writeByte(int value) {
    _check(1);
    super.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _check(length ?? bytes.length);
    super.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    _check(stream.length);
    super.writeStream(stream);
  }

  @override
  void writeBackReference(int distance, int count) {
    _check(count);
    super.writeBackReference(distance, count);
  }
}
