import 'package:characters/characters.dart';

import 'dart:typed_data';

const imageMarker = '\uFFFC';

class ReadingHeading {
  const ReadingHeading(this.title, this.position, this.level);
  final String title;
  final int position;
  final int level;
}

class ReadingImage {
  const ReadingImage({
    required this.position,
    required this.alt,
    this.bytes,
    this.source,
  });
  final int position;
  final String alt;
  final Uint8List? bytes;
  final String? source;
}

/// UTF-16 source offsets allow future reflow/importers to share a location.
class ReaderToken {
  const ReaderToken(this.text, this.offset, this.paragraphEnd);
  final String text;
  final int offset;
  final bool paragraphEnd;
  bool get isImage => text == imageMarker;
  bool get sentenceEnd => RegExp(r'''[.!?…。！？][”’"')\]]*$''').hasMatch(text);
  int get focalIndex {
    final glyphs = text.characters.toList();
    final letters = <int>[];
    for (var i = 0; i < glyphs.length; i++) {
      if (RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(glyphs[i])) {
        letters.add(i);
      }
    }
    if (letters.isEmpty) return 0;
    final n = letters.length;
    final slot = n <= 1
        ? 0
        : n <= 5
        ? 1
        : n <= 9
        ? 2
        : n <= 13
        ? 3
        : 4;
    return letters[slot.clamp(0, n - 1)];
  }
}

List<ReaderToken> tokenize(String source) {
  final matches = RegExp(r'\S+', unicode: true).allMatches(source).toList();
  return List.unmodifiable([
    for (var i = 0; i < matches.length; i++)
      ReaderToken(
        matches[i].group(0)!,
        matches[i].start,
        i == matches.length - 1 ||
            RegExp(
              r'\r?\n\s*\r?\n',
            ).hasMatch(source.substring(matches[i].end, matches[i + 1].start)),
      ),
  ]);
}

class ReaderDocument {
  ReaderDocument({
    required this.id,
    required this.title,
    required this.text,
    this.position = 0,
    this.openedAt = 0,
    this.headings = const [],
    this.images = const [],
  }) : tokens = tokenize(text);
  final int id;
  final String title;
  final String text;
  final int position;
  final int openedAt;
  final List<ReadingHeading> headings;
  final List<ReadingImage> images;
  final List<ReaderToken> tokens;
  ReaderDocument atPosition(int value) => ReaderDocument(
    id: id,
    title: title,
    text: text,
    position: value,
    openedAt: openedAt,
    headings: headings,
    images: images,
  );
  double get progress =>
      tokens.isEmpty ? 0 : position.clamp(0, tokens.length) / tokens.length;
}

/// The paste boundary is shared by the UI and future plain-text importers.
class TextImport {
  static const maxPasteCharacters = 200000;
  static ({String title, String text}) validate(
    String title,
    String text, {
    int maxCharacters = maxPasteCharacters,
  }) {
    final clean = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (clean.isEmpty) throw const FormatException('Add some text to read.');
    if (clean.length > maxCharacters) {
      throw FormatException(
        'This text exceeds the $maxCharacters character limit.',
      );
    }
    if (clean.contains('\u0000')) {
      throw const FormatException('This content is not plain text.');
    }
    final heading = title.trim();
    return (
      title: heading.isEmpty
          ? 'Untitled reading'
          : heading.characters.take(100).toString(),
      text: clean,
    );
  }
}

/// A shelf row contains no book text or eagerly allocated tokens.
class LibraryEntry {
  const LibraryEntry({
    required this.id,
    required this.title,
    required this.wordCount,
    required this.position,
    required this.openedAt,
    required this.starred,
    required this.format,
    required this.author,
  });
  final int id, wordCount, position, openedAt;
  final String title, format, author;
  final bool starred;
  double get progress =>
      wordCount == 0 ? 0 : position.clamp(0, wordCount) / wordCount;
  factory LibraryEntry.fromRow(Map<String, Object?> row) => LibraryEntry(
    id: row['id'] as int,
    title: row['title'] as String,
    wordCount: row['word_count'] as int,
    position: row['position'] as int,
    openedAt: row['opened'] as int,
    starred: row['starred'] == 1,
    format: row['format'] as String,
    author: row['author'] as String,
  );
}
