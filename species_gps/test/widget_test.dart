import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:species_gps/main.dart';
import 'package:species_gps/providers/app_state_provider.dart';
import 'package:species_gps/providers/map_state_provider.dart';
import 'package:species_gps/screens/home_screen_v2.dart';

void main() {
  group('Species GPS App Tests', () {
    testWidgets('App starts and shows home screen', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify that home screen is displayed
      expect(find.text('수산생명자원 GPS'), findsOneWidget);
    });

    testWidgets('Navigation bar shows all items', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Check navigation items
      expect(find.text('홈'), findsOneWidget);
      expect(find.text('기록'), findsOneWidget);
      expect(find.text('통계'), findsOneWidget);
      expect(find.text('지도'), findsOneWidget);
    });

    testWidgets('FAB button exists for adding new record', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Find FAB
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  group('Home Screen Tests', () {
    testWidgets('Home screen shows statistics cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppStateProvider()),
            ChangeNotifierProvider(create: (_) => MapStateProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreenV2(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check for statistics labels
      expect(find.text('전체 기록'), findsOneWidget);
      expect(find.text('오늘 기록'), findsOneWidget);
      expect(find.text('어제 기록'), findsOneWidget);
      expect(find.text('종 수'), findsOneWidget);
    });

    testWidgets('GPS status card is displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppStateProvider()),
            ChangeNotifierProvider(create: (_) => MapStateProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreenV2(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check for GPS status elements
      expect(find.text('GPS 상태'), findsOneWidget);
    });
  });

  group('Data Model Tests', () {
    test('FishingRecord can be created with required fields', () {
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
    });

    test('FishingRecord supports optional fields', () {
      final record = FishingRecord(
        species: '갈치',
        count: 3,
        latitude: 35.1800,
        longitude: 129.0760,
        timestamp: DateTime.now(),
        notes: '날씨 맑음',
        photoPath: '/path/to/photo.jpg',
        audioPath: '/path/to/audio.aac',
      );

      expect(record.notes, '날씨 맑음');
      expect(record.photoPath, '/path/to/photo.jpg');
      expect(record.audioPath, '/path/to/audio.aac');
    });
  });
}

// FishingRecord model for testing
class FishingRecord {
  final int? id;
  final String species;
  final int count;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? photoPath;
  final String? audioPath;
  final String? notes;
  final DateTime timestamp;

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
}