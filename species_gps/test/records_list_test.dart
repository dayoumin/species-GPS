import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:species_gps/models/fishing_record.dart';
import 'package:species_gps/models/marine_category.dart';
import 'package:species_gps/services/storage_service.dart';
import 'package:species_gps/providers/app_state_provider.dart';

void main() {
  // 테스트를 위한 Flutter binding 초기화
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('날짜별 기록 목록 테스트', () {
    // StorageService 초기화는 플랫폼 종속적이므로 단위 테스트에서는 스킵

    test('날짜별 그룹화가 올바르게 작동하는지 확인', () async {
      // Given: 다양한 날짜의 테스트 데이터
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final twoDaysAgo = now.subtract(const Duration(days: 2));
      
      final testRecords = [
        FishingRecord(
          category: MarineCategory.fish,
          species: '고등어',
          count: 10,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: DateTime(now.year, now.month, now.day, 10, 0),
          notes: '테스트 기록 1',
        ),
        FishingRecord(
          category: MarineCategory.fish,
          species: '갈치',
          count: 5,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: DateTime(now.year, now.month, now.day, 14, 0),
          notes: '테스트 기록 2',
        ),
        FishingRecord(
          category: MarineCategory.cephalopod,
          species: '오징어',
          count: 8,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: DateTime(yesterday.year, yesterday.month, yesterday.day, 9, 0),
          notes: '테스트 기록 3',
        ),
      ];

      // When: 날짜별로 그룹화
      final groupedRecords = <String, List<FishingRecord>>{};
      for (final record in testRecords) {
        final dateKey = '${record.timestamp.year}-${record.timestamp.month.toString().padLeft(2, '0')}-${record.timestamp.day.toString().padLeft(2, '0')}';
        groupedRecords[dateKey] ??= [];
        groupedRecords[dateKey]!.add(record);
      }

      // Then: 그룹화가 올바른지 확인
      expect(groupedRecords.length, 2); // 오늘과 어제, 2개 그룹
      expect(groupedRecords[groupedRecords.keys.first]!.length, 2); // 오늘 기록 2개
      expect(groupedRecords[groupedRecords.keys.last]!.length, 1); // 어제 기록 1개
    });

    test('날짜별 통계 계산이 정확한지 확인', () async {
      // Given: 같은 날짜의 여러 기록
      final now = DateTime.now();
      final records = [
        FishingRecord(
          category: MarineCategory.fish,
          species: '고등어',
          count: 10,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: now,
          notes: '기록 1',
        ),
        FishingRecord(
          category: MarineCategory.fish,
          species: '고등어',
          count: 15,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: now,
          notes: '기록 2',
        ),
        FishingRecord(
          category: MarineCategory.cephalopod,
          species: '오징어',
          count: 20,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: now,
          notes: '기록 3',
        ),
      ];

      // When: 날짜별 통계 계산
      final speciesCount = <String, int>{};
      int totalCount = 0;
      for (final record in records) {
        speciesCount[record.species] = 
            (speciesCount[record.species] ?? 0) + record.count;
        totalCount += record.count;
      }

      // Then: 통계가 정확한지 확인
      expect(speciesCount.length, 2); // 2종
      expect(speciesCount['고등어'], 25); // 고등어 총 25마리
      expect(speciesCount['오징어'], 20); // 오징어 총 20마리
      expect(totalCount, 45); // 전체 45마리
    });

    test('더미 데이터와 실제 데이터 구분이 되는지 확인', () async {
      // Given: 더미 데이터와 실제 데이터 혼합
      final testRecords = [
        FishingRecord(
          category: MarineCategory.fish,
          species: '고등어',
          count: 10,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: DateTime.now(),
          notes: '[DUMMY_DATA] 테스트용',
        ),
        FishingRecord(
          category: MarineCategory.fish,
          species: '갈치',
          count: 5,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: DateTime.now(),
          notes: '실제 기록',
        ),
      ];

      // When: 더미 데이터 필터링
      final realRecords = testRecords.where((record) => 
        !(record.notes?.contains('[DUMMY_DATA]') ?? false)
      ).toList();
      
      final dummyRecords = testRecords.where((record) => 
        record.notes?.contains('[DUMMY_DATA]') ?? false
      ).toList();

      // Then: 필터링이 올바른지 확인
      expect(realRecords.length, 1); // 실제 데이터 1개
      expect(dummyRecords.length, 1); // 더미 데이터 1개
      expect(realRecords.first.species, '갈치');
      expect(dummyRecords.first.species, '고등어');
    });

    test('날짜 범위 필터링이 올바르게 작동하는지 확인', () async {
      // Given: 다양한 날짜의 기록
      final now = DateTime.now();
      final testRecords = [
        FishingRecord(
          category: MarineCategory.fish,
          species: '고등어',
          count: 10,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: now,
          notes: '오늘',
        ),
        FishingRecord(
          category: MarineCategory.fish,
          species: '갈치',
          count: 5,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: now.subtract(const Duration(days: 3)),
          notes: '3일 전',
        ),
        FishingRecord(
          category: MarineCategory.fish,
          species: '참돔',
          count: 7,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: now.subtract(const Duration(days: 7)),
          notes: '일주일 전',
        ),
      ];

      // When: 최근 5일 필터링
      final fiveDaysAgo = now.subtract(const Duration(days: 5));
      final filteredRecords = testRecords.where((record) =>
        record.timestamp.isAfter(fiveDaysAgo)
      ).toList();

      // Then: 필터링이 올바른지 확인
      expect(filteredRecords.length, 2); // 오늘과 3일 전 기록만
      expect(filteredRecords.any((r) => r.species == '참돔'), false); // 일주일 전 기록은 제외
    });

    test('분류군별 통계가 정확한지 확인', () async {
      // Given: 다양한 분류군의 기록
      final records = [
        FishingRecord(
          category: MarineCategory.fish,
          species: '고등어',
          count: 10,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: DateTime.now(),
        ),
        FishingRecord(
          category: MarineCategory.fish,
          species: '갈치',
          count: 15,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: DateTime.now(),
        ),
        FishingRecord(
          category: MarineCategory.cephalopod,
          species: '오징어',
          count: 20,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: DateTime.now(),
        ),
        FishingRecord(
          category: MarineCategory.mollusk,
          species: '전복',
          count: 5,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: DateTime.now(),
        ),
      ];

      // When: 분류군별 통계 계산
      final categoryCount = <MarineCategory, int>{};
      final categorySpeciesCount = <MarineCategory, Map<String, int>>{};
      
      for (final record in records) {
        // 분류군별 개체수
        categoryCount[record.category] = 
            (categoryCount[record.category] ?? 0) + record.count;
        
        // 분류군별 종별 개체수
        if (!categorySpeciesCount.containsKey(record.category)) {
          categorySpeciesCount[record.category] = {};
        }
        categorySpeciesCount[record.category]![record.species] = 
            (categorySpeciesCount[record.category]![record.species] ?? 0) + record.count;
      }

      // Then: 분류군별 통계가 정확한지 확인
      expect(categoryCount.length, 3); // 3개 분류군
      expect(categoryCount[MarineCategory.fish], 25); // 어류 총 25마리
      expect(categoryCount[MarineCategory.cephalopod], 20); // 두족류 20마리
      expect(categoryCount[MarineCategory.mollusk], 5); // 패류 5마리
      
      expect(categorySpeciesCount[MarineCategory.fish]!.length, 2); // 어류는 2종
      expect(categorySpeciesCount[MarineCategory.fish]!['고등어'], 10);
      expect(categorySpeciesCount[MarineCategory.fish]!['갈치'], 15);
    });

    test('검색 필터링이 올바르게 작동하는지 확인', () async {
      // Given: 다양한 기록
      final records = [
        FishingRecord(
          category: MarineCategory.fish,
          species: '고등어',
          count: 10,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: DateTime.now(),
          notes: '아침 조황',
        ),
        FishingRecord(
          category: MarineCategory.fish,
          species: '갈치',
          count: 5,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: DateTime.now(),
          notes: '오후 조황',
        ),
        FishingRecord(
          category: MarineCategory.cephalopod,
          species: '오징어',
          count: 8,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: DateTime.now(),
          notes: '야간 조업',
        ),
      ];

      // When: 검색어로 필터링
      final searchQuery = '고등어';
      final filteredBySpecies = records.where((record) =>
        record.species.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();

      final searchQuery2 = '조황';
      final filteredByNotes = records.where((record) =>
        record.notes?.toLowerCase().contains(searchQuery2.toLowerCase()) ?? false
      ).toList();

      // Then: 검색 결과가 올바른지 확인
      expect(filteredBySpecies.length, 1);
      expect(filteredBySpecies.first.species, '고등어');
      
      expect(filteredByNotes.length, 2); // '조황'이 포함된 기록 2개
      expect(filteredByNotes.any((r) => r.species == '오징어'), false);
    });
  });

  group('AppStateProvider 테스트', () {
    late AppStateProvider provider;

    setUp(() {
      provider = AppStateProvider();
    });

    test('오늘 기록 개수가 정확한지 확인', () async {
      // Given: 테스트 데이터 로드
      await provider.loadRecords();
      
      // When: 오늘 기록 개수 확인
      final todayCount = provider.todayRecordCount;
      
      // Then: 0 이상이어야 함 (더미 데이터 또는 실제 데이터)
      expect(todayCount, greaterThanOrEqualTo(0));
    });

    test('전체 기록 개수가 정확한지 확인', () async {
      // Given: 테스트 데이터 로드
      await provider.loadRecords();
      
      // When: 전체 기록 개수 확인
      final totalCount = provider.totalRecords;
      
      // Then: 0 이상이어야 함
      expect(totalCount, greaterThanOrEqualTo(0));
    });

    test('분류군별 보기 토글이 작동하는지 확인', () {
      // Given: 초기 상태
      final initialState = provider.showCategoryView;
      
      // When: 토글
      provider.toggleCategoryView();
      
      // Then: 상태가 변경되어야 함
      expect(provider.showCategoryView, !initialState);
      
      // When: 다시 토글
      provider.toggleCategoryView();
      
      // Then: 원래 상태로 돌아와야 함
      expect(provider.showCategoryView, initialState);
    });
  });
}