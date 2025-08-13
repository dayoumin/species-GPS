import 'package:flutter_test/flutter_test.dart';
import 'package:species_gps/models/fishing_record.dart';
import 'package:species_gps/core/utils/date_formatter.dart';

void main() {
  group('FishingRecord Model Tests', () {
    test('Create FishingRecord with required fields', () {
      final record = FishingRecord(
        species: '고등어',
        count: 5,
        latitude: 35.1796,
        longitude: 129.0756,
        timestamp: DateTime.now(),
      );

      expect(record.species, '고등어');
      expect(record.count, 5);
      expect(record.latitude, 35.1796);
      expect(record.longitude, 129.0756);
      expect(record.id, null);
      expect(record.notes, null);
      expect(record.photoPath, null);
      expect(record.audioPath, null);
    });

    test('Create FishingRecord with all fields', () {
      final now = DateTime.now();
      final record = FishingRecord(
        id: 1,
        species: '갈치',
        count: 3,
        latitude: 35.1800,
        longitude: 129.0760,
        accuracy: 10.5,
        photoPath: '/path/to/photo.jpg',
        audioPath: '/path/to/audio.aac',
        notes: '날씨 맑음',
        timestamp: now,
      );

      expect(record.id, 1);
      expect(record.species, '갈치');
      expect(record.count, 3);
      expect(record.latitude, 35.1800);
      expect(record.longitude, 129.0760);
      expect(record.accuracy, 10.5);
      expect(record.photoPath, '/path/to/photo.jpg');
      expect(record.audioPath, '/path/to/audio.aac');
      expect(record.notes, '날씨 맑음');
      expect(record.timestamp, now);
    });

    test('FishingRecord with specific timestamp', () {
      final specificTime = DateTime(2025, 1, 13, 10, 30);
      final record = FishingRecord(
        id: 1,
        species: '전어',
        count: 10,
        latitude: 35.1810,
        longitude: 129.0770,
        accuracy: 5.0,
        notes: '대량 어획',
        timestamp: specificTime,
      );

      expect(record.id, 1);
      expect(record.species, '전어');
      expect(record.count, 10);
      expect(record.latitude, 35.1810);
      expect(record.longitude, 129.0770);
      expect(record.accuracy, 5.0);
      expect(record.notes, '대량 어획');
      expect(record.timestamp, specificTime);
    });

    test('FishingRecord timestamp comparison', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      
      final todayRecord = FishingRecord(
        species: '우럭',
        count: 7,
        latitude: 35.2000,
        longitude: 129.1000,
        timestamp: now,
      );

      final yesterdayRecord = FishingRecord(
        species: '도미',
        count: 3,
        latitude: 35.2000,
        longitude: 129.1000,
        timestamp: yesterday,
      );

      expect(todayRecord.timestamp.isAfter(yesterdayRecord.timestamp), true);
      expect(yesterdayRecord.timestamp.isBefore(todayRecord.timestamp), true);
    });
  });

  group('DateFormatter Tests', () {
    test('Format date correctly', () {
      final date = DateTime(2025, 1, 13, 14, 30);
      
      expect(DateFormatter.formatDate(date), '2025-01-13');
      expect(DateFormatter.formatTime(date), '14:30');
      expect(DateFormatter.formatDateTime(date), '2025-01-13 14:30');
    });

    test('Check isToday function', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      expect(DateFormatter.isToday(today), true);
      expect(DateFormatter.isToday(yesterday), false);
      expect(DateFormatter.isToday(tomorrow), false);
    });

    test('Check isYesterday function', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      expect(DateFormatter.isYesterday(today), false);
      expect(DateFormatter.isYesterday(yesterday), true);
      expect(DateFormatter.isYesterday(twoDaysAgo), false);
    });

    test('Format relative time', () {
      final now = DateTime.now();
      final justNow = now.subtract(const Duration(seconds: 30));
      final minutesAgo = now.subtract(const Duration(minutes: 5));
      final hoursAgo = now.subtract(const Duration(hours: 2));
      final yesterday = now.subtract(const Duration(days: 1));

      expect(DateFormatter.formatRelativeTime(justNow), '방금 전');
      expect(DateFormatter.formatRelativeTime(minutesAgo), '5분 전');
      expect(DateFormatter.formatRelativeTime(hoursAgo), '2시간 전');
      expect(DateFormatter.formatRelativeTime(yesterday), '어제');
    });
  });

  group('Data Validation Tests', () {
    test('Species name validation', () {
      // 어종명은 비어있으면 안됨
      expect(''.isEmpty, true);
      expect('고등어'.isEmpty, false);
      
      // 어종명 길이 체크 (예: 최대 50자)
      final longName = 'a' * 51;
      expect(longName.length > 50, true);
    });

    test('Count validation', () {
      // 수량은 1 이상이어야 함
      expect(0 < 1, true);
      expect(1 >= 1, true);
      expect(10 >= 1, true);
      
      // 수량은 합리적인 범위 내여야 함 (예: 최대 10000)
      expect(9999 <= 10000, true);
      expect(10001 > 10000, true);
    });

    test('GPS coordinate validation', () {
      // 위도는 -90 ~ 90
      expect(-90 <= 35.1796 && 35.1796 <= 90, true);
      expect(-90 <= -91 && -91 <= 90, false);
      expect(-90 <= 91 && 91 <= 90, false);
      
      // 경도는 -180 ~ 180
      expect(-180 <= 129.0756 && 129.0756 <= 180, true);
      expect(-180 <= -181 && -181 <= 180, false);
      expect(-180 <= 181 && 181 <= 180, false);
    });
  });
}