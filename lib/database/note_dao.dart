import 'package:floor/floor.dart';
import '../models/note.dart';

@dao
abstract class NoteDao {
  @Query('SELECT * FROM notes ORDER BY createdAt DESC')
  Stream<List<Note>> watchAllNotes();

  @Query('SELECT * FROM notes WHERE id = :id LIMIT 1')
  Future<Note?> findNoteById(int id);

  @insert
  Future<int> insertNote(Note note);

  @update
  Future<void> updateNote(Note note);

  @delete
  Future<void> deleteNote(Note note);

  @Query('DELETE FROM notes')
  Future<void> deleteAllNotes();

  @Query('SELECT COUNT(*) FROM notes')
  Future<int?> countNotes();
}
