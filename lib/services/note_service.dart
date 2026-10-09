import 'package:geolocator/geolocator.dart';

import '../database/note_dao.dart';
import '../models/note.dart';
import 'location_service.dart';

class NoteService {
  static const int maxContentLength = 1000;

  final NoteDao dao;
  final LocationService locationService;

  NoteService(this.dao, this.locationService);

  Stream<List<Note>> watchNotes() => dao.watchAllNotes();

  Future<Note?> getNote(int id) => dao.findNoteById(id);

  Future<int> createNote({
    String? title,
    String? topic,
    required String content,
    required bool useLocation,
    LocationResult? preloadedLocation,
    Future<LocationResult>? pendingLocation,
  }) async {
    final cleanContent = _validateContent(content);
    final cleanTitle = (title != null && title.trim().isNotEmpty) ? title.trim() : null;
    final cleanTopic = (topic != null && topic.trim().isNotEmpty) ? topic.trim() : null;
    final now = DateTime.now().millisecondsSinceEpoch;
    Position? position = preloadedLocation?.position;
    String? locationName = preloadedLocation?.placeName;

    final newId = await dao.insertNote(
      Note(
        title: cleanTitle,
        topic: cleanTopic,
        content: cleanContent,
        latitude: useLocation ? position?.latitude : null,
        longitude: useLocation ? position?.longitude : null,
        locationName: useLocation ? locationName : null,
        createdAt: now,
        updatedAt: now,
      ),
    );

    if (useLocation && position == null) {
      _resolveLocationInBackground(newId, pendingLocation);
    }

    return newId;
  }

  Future<void> updateNote({
    required Note note,
    String? title,
    String? topic,
    required String content,
    required bool useLocation,
    LocationResult? preloadedLocation,
    Future<LocationResult>? pendingLocation,
  }) async {
    final cleanContent = _validateContent(content);
    final cleanTitle = (title != null && title.trim().isNotEmpty) ? title.trim() : null;
    final cleanTopic = (topic != null && topic.trim().isNotEmpty) ? topic.trim() : null;
    final now = DateTime.now().millisecondsSinceEpoch;

    double? latitude = note.latitude;
    double? longitude = note.longitude;
    String? locationName = note.locationName;
    bool needsBackgroundLocation = false;

    if (useLocation) {
      if (preloadedLocation != null) {
        latitude = preloadedLocation.position.latitude;
        longitude = preloadedLocation.position.longitude;
        locationName = preloadedLocation.placeName;
      } else if (latitude == null || longitude == null) {
        needsBackgroundLocation = true;
      }
    } else {
      latitude = null;
      longitude = null;
      locationName = null;
    }

    await dao.updateNote(
      note.copyWith(
        title: cleanTitle,
        topic: cleanTopic,
        content: cleanContent,
        latitude: latitude,
        longitude: longitude,
        updatedAt: now,
        locationName: locationName,
        clearLocation: !useLocation,
      ),
    );

    if (needsBackgroundLocation && note.id != null) {
      _resolveLocationInBackground(note.id!, pendingLocation);
    }
  }

  void _resolveLocationInBackground(int noteId, Future<LocationResult>? pendingLocation) {
    () async {
      try {
        final loc = await (pendingLocation ?? locationService.getCurrentLocation());
        final existing = await dao.findNoteById(noteId);
        if (existing != null) {
          await dao.updateNote(
            existing.copyWith(
              latitude: loc.position.latitude,
              longitude: loc.position.longitude,
              locationName: loc.placeName,
            ),
          );
        }
      } catch (_) {
        // Location resolving failed or cancelled; note content remains saved.
      }
    }();
  }

  Future<void> deleteNote(Note note) => dao.deleteNote(note);

  Future<void> deleteNotes(List<Note> notes) async {
    for (final note in notes) {
      await dao.deleteNote(note);
    }
  }

  Future<void> restoreNote(Note note) => dao.insertNote(note);

  Future<void> restoreNotes(List<Note> notes) async {
    for (final note in notes) {
      await dao.insertNote(note);
    }
  }

  Future<void> deleteAllNotes() => dao.deleteAllNotes();

  Future<int> countNotes() async => await dao.countNotes() ?? 0;

  String _validateContent(String content) {
    final value = content.trim();

    if (value.isEmpty) {
      throw const FormatException('Note cannot be empty.');
    }

    if (value.length > maxContentLength) {
      throw FormatException(
        'Note cannot be longer than $maxContentLength characters.',
      );
    }

    return value;
  }
}
