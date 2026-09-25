import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/document.dart';
import '../../core/file_import.dart';
import '../../core/settings.dart';

ReaderDocument _decodeDocument(Map<String, Object?> row) => ReaderDocument(
  id: row['id'] as int,
  title: row['title'] as String,
  text: row['content'] as String,
  position: row['position'] as int,
  openedAt: row['opened'] as int,
);
int _countWords(String text) =>
    RegExp(r'\S+', unicode: true).allMatches(text).length;

class LibraryStore {
  LibraryStore._(this.database);
  final Database database;
  static Future<LibraryStore> open(
    String path, {
    DatabaseFactory? factory,
  }) async {
    final db = await (factory ?? databaseFactory).openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE documents (id INTEGER PRIMARY KEY, title TEXT NOT NULL, content TEXT NOT NULL, position INTEGER NOT NULL DEFAULT 0, opened INTEGER NOT NULL DEFAULT 0, word_count INTEGER NOT NULL DEFAULT 0, starred INTEGER NOT NULL DEFAULT 0, format TEXT NOT NULL DEFAULT \'Text\', author TEXT NOT NULL DEFAULT \'\', fingerprint TEXT)',
          );
          await db.execute(
            'CREATE UNIQUE INDEX imported_fingerprint ON documents(fingerprint)',
          );
          await db.execute(
            'CREATE TABLE preferences (id INTEGER PRIMARY KEY CHECK(id=1), value TEXT NOT NULL)',
          );
        },
        onUpgrade: (db, old, _) async {
          if (old < 2) {
            await db.execute(
              'ALTER TABLE documents ADD COLUMN word_count INTEGER NOT NULL DEFAULT 0',
            );
            await db.execute(
              'ALTER TABLE documents ADD COLUMN starred INTEGER NOT NULL DEFAULT 0',
            );
            await db.execute(
              "ALTER TABLE documents ADD COLUMN format TEXT NOT NULL DEFAULT 'Text'",
            );
            await db.execute(
              "ALTER TABLE documents ADD COLUMN author TEXT NOT NULL DEFAULT ''",
            );
            await db.execute(
              'ALTER TABLE documents ADD COLUMN fingerprint TEXT',
            );
            // Existing pasted duplicates remain separate, with null fingerprints.
            await db.execute(
              'CREATE UNIQUE INDEX imported_fingerprint ON documents(fingerprint)',
            );
            final ids = await db.query('documents', columns: ['id']);
            for (final row in ids) {
              final book = (await db.query(
                'documents',
                columns: ['content'],
                where: 'id=?',
                whereArgs: [row['id']],
              )).single;
              final count = await compute(
                _countWords,
                book['content'] as String,
              );
              await db.update(
                'documents',
                {'word_count': count},
                where: 'id=?',
                whereArgs: [row['id']],
              );
            }
          }
        },
      ),
    );
    return LibraryStore._(db);
  }

  Future<List<LibraryEntry>> all() async => (await database.query(
    'documents',
    columns: [
      'id',
      'title',
      'position',
      'opened',
      'word_count',
      'starred',
      'format',
      'author',
    ],
    orderBy: 'opened DESC, id DESC',
  )).map(LibraryEntry.fromRow).toList();

  Future<ReaderDocument> document(int id) async {
    final rows = await database.query(
      'documents',
      where: 'id=?',
      whereArgs: [id],
    );
    if (rows.isEmpty) throw StateError('Reading no longer exists.');
    final document = await compute(_decodeDocument, rows.single);
    await database.update(
      'documents',
      {'opened': DateTime.now().millisecondsSinceEpoch},
      where: 'id=?',
      whereArgs: [id],
    );
    return document;
  }

  Future<int> add(String title, String text) async {
    final input = TextImport.validate(title, text);
    return database.insert('documents', {
      'title': input.title,
      'content': input.text,
      'word_count': await compute(_countWords, input.text),
      'opened': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<int> importReading(ImportedReading book) =>
      database.transaction((txn) async {
        final existing = await txn.query(
          'documents',
          columns: ['id'],
          where: 'fingerprint=?',
          whereArgs: [book.fingerprint],
        );
        final now = DateTime.now().millisecondsSinceEpoch;
        if (existing.isNotEmpty) {
          final id = existing.single['id'] as int;
          await txn.update(
            'documents',
            {'opened': now},
            where: 'id=?',
            whereArgs: [id],
          );
          return id;
        }
        return txn.insert('documents', {
          'title': book.title,
          'content': book.text,
          'word_count': book.wordCount,
          'format': book.format,
          'author': book.author,
          'fingerprint': book.fingerprint,
          'opened': now,
        });
      });

  Future<void> setStarred(int id, bool value) async {
    await database.update(
      'documents',
      {'starred': value ? 1 : 0},
      where: 'id=?',
      whereArgs: [id],
    );
  }

  Future<void> savePosition(ReaderDocument document, int position) async {
    await database.update(
      'documents',
      {
        'position': position.clamp(0, document.tokens.length),
        'opened': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<ReaderSettings> settings() async {
    final rows = await database.query('preferences', where: 'id=1');
    if (rows.isEmpty) return ReaderSettings();
    return ReaderSettings.fromJson(
      jsonDecode(rows.single['value'] as String) as Map<String, dynamic>,
    );
  }

  Future<void> saveSettings(ReaderSettings value) async {
    await database.insert('preferences', {
      'id': 1,
      'value': jsonEncode(value.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> close() => database.close();
}
