import 'package:floor/floor.dart';

@Entity(
  tableName: 'notes',
  indices: [Index(value: ['createdAt'])],
)
class Note {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String? title;
  final String? topic;
  final String content;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final int createdAt;
  final int updatedAt;

  Note({
    this.id,
    this.title,
    this.topic,
    required this.content,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

  Note copyWith({
    int? id,
    String? title,
    String? topic,
    String? content,
    double? latitude,
    double? longitude,
    String? locationName,
    bool clearLocation = false,
    int? createdAt,
    int? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      content: content ?? this.content,
      latitude: clearLocation ? null : (latitude ?? this.latitude),
      longitude: clearLocation ? null : (longitude ?? this.longitude),
      locationName: clearLocation ? null : (locationName ?? this.locationName),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
