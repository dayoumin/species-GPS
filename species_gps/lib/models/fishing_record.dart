class FishingRecord {
  int? id;
  String species;
  int count;
  double latitude;
  double longitude;
  double? accuracy;
  String? photoPath;
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
    this.notes,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'species': species,
      'count': count,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'photoPath': photoPath,
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
      notes: map['notes'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}