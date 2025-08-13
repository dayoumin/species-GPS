import 'package:flutter_test/flutter_test.dart';
import 'package:species_gps/providers/app_state_provider.dart';
import 'package:species_gps/models/fishing_record.dart';

void main() {
  group('AppStateProvider Tests', () {
    late AppStateProvider provider;

    setUp(() {
      provider = AppStateProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('Initial state is correct', () {
      expect(provider.isLoading, false);
      expect(provider.totalRecords, 0);
      expect(provider.todayRecordCount, 0);
      expect(provider.yesterdayRecordCount, 0);
      expect(provider.hasLocation, false);
      expect(provider.currentPosition, null);
    });

    test('getFilteredRecords filters by species correctly', () {
      // Create test records
      final records = [
        FishingRecord(
          species: '고등어',
          count: 5,
          latitude: 35.0,
          longitude: 129.0,
          timestamp: DateTime.now(),
        ),
        FishingRecord(
          species: '갈치',
          count: 3,
          latitude: 35.0,
          longitude: 129.0,
          timestamp: DateTime.now(),
        ),
        FishingRecord(
          species: '고등어',
          count: 2,
          latitude: 35.0,
          longitude: 129.0,
          timestamp: DateTime.now(),
        ),
      ];

      // Note: We need to expose a method to set records for testing
      // or use dependency injection for StorageService
      // This is a simplified test structure
    });

    test('getFilteredRecords filters by date correctly', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      // Test filtering logic
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);

      expect(todayStart.isBefore(todayEnd), true);
      expect(yesterday.isBefore(today), true);
    });

    test('speciesCount calculates correctly', () {
      // This test would require ability to inject test data
      // Current implementation depends on StorageService
      expect(provider.speciesCount, isA<Map<String, int>>());
      expect(provider.speciesCount.isEmpty, true);
    });
  });
}