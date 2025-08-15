import 'package:isar/isar.dart';
import 'marine_category.dart';

part 'fishing_record.g.dart';

@collection
class FishingRecord {
  Id id = Isar.autoIncrement;
  
  @enumerated
  late MarineCategory category;  // 분류군
  late String species;  // 종명 (국명 또는 학명, "미정" 가능)
  late int count;
  late double latitude;
  late double longitude;
  double? accuracy;
  String? photoPath;
  String? audioPath;
  String? notes;
  
  @Index()
  late DateTime timestamp;

  FishingRecord({
    this.id = Isar.autoIncrement,
    required this.category,
    required this.species,
    required this.count,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.photoPath,
    this.audioPath,
    this.notes,
    required this.timestamp,
  });

  // Getter for location string representation
  String get location => '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  // Keep these for compatibility with existing code
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.index,
      'species': species,
      'count': count,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'photoPath': photoPath,
      'audioPath': audioPath,
      'notes': notes,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory FishingRecord.fromMap(Map<String, dynamic> map) {
    return FishingRecord(
      id: map['id'] ?? Isar.autoIncrement,
      category: MarineCategory.fromIndex(map['category'] ?? 6), // 기본값: other
      species: map['species'],
      count: map['count'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      accuracy: map['accuracy'],
      photoPath: map['photoPath'],
      audioPath: map['audioPath'],
      notes: map['notes'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  FishingRecord copyWith({
    Id? id,
    MarineCategory? category,
    String? species,
    int? count,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? photoPath,
    String? audioPath,
    String? notes,
    DateTime? timestamp,
  }) {
    return FishingRecord(
      id: id ?? this.id,
      category: category ?? this.category,
      species: species ?? this.species,
      count: count ?? this.count,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      photoPath: photoPath ?? this.photoPath,
      audioPath: audioPath ?? this.audioPath,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}