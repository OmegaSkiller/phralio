import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../core/document.dart';
import '../../core/settings.dart';

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
        version: 1,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE documents (id INTEGER PRIMARY KEY, title TEXT NOT NULL, content TEXT NOT NULL, position INTEGER NOT NULL DEFAULT 0, opened INTEGER NOT NULL DEFAULT 0)',
          );
          await db.execute(
            'CREATE TABLE preferences (id INTEGER PRIMARY KEY CHECK(id=1), value TEXT NOT NULL)',
          );
        },
      ),
    );
    return LibraryStore._(db);
  }

  Future<List<ReaderDocument>> all() async =>
      (await database.query('documents', orderBy: 'opened DESC, id DESC'))
          .map(
            (r) => ReaderDocument(
              id: r['id'] as int,
              title: r['title'] as String,
              text: r['content'] as String,
              position: r['position'] as int,
              openedAt: r['opened'] as int,
            ),
          )
          .toList();
  Future<int> add(String title, String text) async {
    final input = TextImport.validate(title, text);
    return database.insert('documents', {
      'title': input.title,
      'content': input.text,
      'opened': DateTime.now().millisecondsSinceEpoch,
    });
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
