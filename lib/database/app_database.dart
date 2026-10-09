import 'dart:async';

import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../models/note.dart';
import 'note_dao.dart';

part 'app_database.g.dart';

final migration1to2 = Migration(1, 2, (database) async {
  final columns = await database.rawQuery('PRAGMA table_info(notes)');
  final hasLocationName = columns.any((col) => col['name'] == 'locationName');
  if (!hasLocationName) {
    await database.execute('ALTER TABLE notes ADD COLUMN locationName TEXT');
  }
});

final migration2to3 = Migration(2, 3, (database) async {
  final columns = await database.rawQuery('PRAGMA table_info(notes)');
  final columnNames = columns.map((col) => col['name'] as String).toSet();
  if (!columnNames.contains('title')) {
    await database.execute('ALTER TABLE notes ADD COLUMN title TEXT');
  }
  if (!columnNames.contains('topic')) {
    await database.execute('ALTER TABLE notes ADD COLUMN topic TEXT');
  }
});

@Database(version: 3, entities: [Note])
abstract class AppDatabase extends FloorDatabase {
  NoteDao get noteDao;
}
