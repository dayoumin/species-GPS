class FishingRecord {
  int? id;
  String species;
  int count;
  double latitude;
  double longitude;
  double? accuracy;
  String? photoPath;
  String? audioPath;
  String? notes;
  DateTime timestamp;

  FishingRecord({
    this.id,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
      id: map['id'],
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
    int? id,
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