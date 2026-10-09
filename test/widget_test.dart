// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/models/note.dart';

void main() {
  test('Note model initializes and copies correctly', () {
    final note = Note(
      id: 1,
      title: 'Project meeting',
      topic: 'Work',
      content: 'Discuss sprint backlog',
      latitude: 30.0,
      longitude: 31.0,
      locationName: 'Cairo',
      createdAt: 1000,
      updatedAt: 1000,
    );

    expect(note.title, 'Project meeting');
    expect(note.topic, 'Work');
    expect(note.hasLocation, true);
    expect(note.locationName, 'Cairo');

    final updated = note.copyWith(title: 'Updated meeting', clearLocation: true);
    expect(updated.title, 'Updated meeting');
    expect(updated.topic, 'Work');
    expect(updated.hasLocation, false);
    expect(updated.locationName, null);
  });
}
