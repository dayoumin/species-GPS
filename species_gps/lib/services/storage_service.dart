import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/fishing_record.dart';
import '../models/marine_category.dart';

/// 플랫폼별 저장소 서비스 (Isar 기반)
class StorageService {
  static Isar? _isar;
  
  // 웹 개발용 메모리 저장소
  static final List<FishingRecord> _memoryRecords = [];
  static int _nextWebId = 1;

  /// Isar 초기화
  static Future<void> init() async {
    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open(
        [FishingRecordSchema],
        directory: dir.path,
      );
    }
  }

  /// Isar 인스턴스 가져오기
  static Isar? get isar => _isar;

  /// 레코드 추가
  static Future<int> addRecord(FishingRecord record) async {
    if (kIsWeb) {
      // 웹: 메모리에 저장 (개발용)
      final newRecord = record.copyWith(id: _nextWebId++);
      _memoryRecords.add(newRecord);
      return newRecord.id;
    } else {
      // 모바일: Isar 사용
      if (_isar == null) await init();
      return await _isar!.writeTxn(() async {
        return await _isar!.fishingRecords.put(record);
      });
    }
  }

  /// 레코드 조회
  static Future<List<FishingRecord>> getRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (kIsWeb) {
      // 웹: 메모리에서 조회
      List<FishingRecord> results = List.from(_memoryRecords);
      
      // 날짜 필터링
      if (startDate != null) {
        results = results.where((r) => r.timestamp.isAfter(startDate)).toList();
      }
      if (endDate != null) {
        results = results.where((r) => r.timestamp.isBefore(endDate)).toList();
      }
      
      // 최신순 정렬
      results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return results;
    } else {
      // 모바일: Isar 사용
      if (_isar == null) await init();
      
      if (startDate != null && endDate != null) {
        return await _isar!.fishingRecords
            .where()
            .timestampBetween(startDate, endDate)
            .sortByTimestampDesc()
            .findAll();
      } else if (startDate != null) {
        return await _isar!.fishingRecords
            .where()
            .timestampGreaterThan(startDate)
            .sortByTimestampDesc()
            .findAll();
      } else if (endDate != null) {
        return await _isar!.fishingRecords
            .where()
            .timestampLessThan(endDate)
            .sortByTimestampDesc()
            .findAll();
      } else {
        return await _isar!.fishingRecords
            .where()
            .sortByTimestampDesc()
            .findAll();
      }
    }
  }

  /// 레코드 삭제
  static Future<void> deleteRecord(int id) async {
    if (kIsWeb) {
      // 웹: 메모리에서 삭제
      _memoryRecords.removeWhere((r) => r.id == id);
    } else {
      // 모바일: Isar 사용
      if (_isar == null) await init();
      await _isar!.writeTxn(() async {
        await _isar!.fishingRecords.delete(id);
      });
    }
  }

  /// 모든 레코드 삭제
  static Future<void> deleteAllRecords() async {
    if (kIsWeb) {
      // 웹: 메모리 초기화
      _memoryRecords.clear();
    } else {
      // 모바일: Isar 사용
      if (_isar == null) await init();
      await _isar!.writeTxn(() async {
        await _isar!.fishingRecords.clear();
      });
    }
  }

  /// 레코드 업데이트
  static Future<void> updateRecord(FishingRecord record) async {
    if (kIsWeb) {
      // 웹: 메모리에서 업데이트
      final index = _memoryRecords.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _memoryRecords[index] = record;
      }
    } else {
      // 모바일: Isar 사용
      if (_isar == null) await init();
      await _isar!.writeTxn(() async {
        await _isar!.fishingRecords.put(record);
      });
    }
  }

  /// 특정 ID로 레코드 조회
  static Future<FishingRecord?> getRecordById(int id) async {
    if (kIsWeb) {
      // 웹: 메모리에서 조회
      try {
        return _memoryRecords.firstWhere((r) => r.id == id);
      } catch (_) {
        return null;
      }
    } else {
      // 모바일: Isar 사용
      if (_isar == null) await init();
      return await _isar!.fishingRecords.get(id);
    }
  }

  /// 어종별 통계 조회
  static Future<Map<String, int>> getSpeciesStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final records = await getRecords(startDate: startDate, endDate: endDate);
    final Map<String, int> stats = {};
    
    for (final record in records) {
      stats[record.species] = (stats[record.species] ?? 0) + record.count;
    }
    
    return stats;
  }

  /// 어종별 개체수 조회 (DatabaseService 호환성을 위한 별칭)
  static Future<Map<String, int>> getSpeciesCount() async {
    return await getSpeciesStatistics();
  }

  /// 전체 레코드 개수 조회
  static Future<int> getTotalCount() async {
    if (kIsWeb) {
      return _memoryRecords.length;
    } else {
      if (_isar == null) await init();
      return await _isar!.fishingRecords.count();
    }
  }

  /// 페이징된 레코드 조회
  static Future<List<FishingRecord>> getRecordsPaged({
    required int offset,
    required int limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (kIsWeb) {
      // 웹: 메모리에서 페이징 처리
      List<FishingRecord> results = List.from(_memoryRecords);
      
      // 날짜 필터링
      if (startDate != null) {
        results = results.where((r) => r.timestamp.isAfter(startDate)).toList();
      }
      if (endDate != null) {
        results = results.where((r) => r.timestamp.isBefore(endDate)).toList();
      }
      
      // 최신순 정렬
      results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // 페이징 적용
      final start = offset;
      final end = offset + limit;
      if (start >= results.length) return [];
      
      return results.sublist(start, end > results.length ? results.length : end);
    } else {
      // 모바일: Isar 사용
      if (_isar == null) await init();
      
      if (startDate != null && endDate != null) {
        return await _isar!.fishingRecords
            .where()
            .timestampBetween(startDate, endDate)
            .sortByTimestampDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      } else if (startDate != null) {
        return await _isar!.fishingRecords
            .where()
            .timestampGreaterThan(startDate)
            .sortByTimestampDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      } else if (endDate != null) {
        return await _isar!.fishingRecords
            .where()
            .timestampLessThan(endDate)
            .sortByTimestampDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      } else {
        return await _isar!.fishingRecords
            .where()
            .sortByTimestampDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      }
    }
  }

  /// 테스트용 샘플 데이터 추가
  static Future<void> addSampleData() async {
    if (kIsWeb) {
      // 이미 샘플 데이터가 있는지 확인 (중복 방지)
      if (_memoryRecords.any((r) => r.notes?.contains('[DUMMY_DATA]') ?? false)) {
        return; // 이미 더미 데이터가 있으면 추가하지 않음
      }
      
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final twoDaysAgo = now.subtract(const Duration(days: 2));
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      final fiveDaysAgo = now.subtract(const Duration(days: 5));
      final weekAgo = now.subtract(const Duration(days: 7));
      
      final sampleRecords = [
        // 오늘 기록 - 다양한 분류군
        FishingRecord(
          category: MarineCategory.fish,
          species: '고등어',
          count: 120,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: DateTime(now.year, now.month, now.day, 9, 30),
          notes: '[DUMMY_DATA] 오늘 대량 어획',
        ),
        FishingRecord(
          category: MarineCategory.cephalopod,
          species: '오징어',
          count: 80,
          latitude: 35.1800,
          longitude: 129.0760,
          timestamp: DateTime(now.year, now.month, now.day, 10, 15),
          notes: '[DUMMY_DATA] 오징어 풍년',
        ),
        FishingRecord(
          category: MarineCategory.crustacean,
          species: '대하',
          count: 40,
          latitude: 35.1810,
          longitude: 129.0770,
          timestamp: DateTime(now.year, now.month, now.day, 11, 0),
          notes: '[DUMMY_DATA] 새우 조업',
        ),
        FishingRecord(
          category: MarineCategory.fish,
          species: '갈치',
          count: 35,
          latitude: 35.1820,
          longitude: 129.0780,
          timestamp: DateTime(now.year, now.month, now.day, 14, 30),
          notes: '[DUMMY_DATA] 오후 갈치',
        ),
        
        // 어제 기록
        FishingRecord(
          category: MarineCategory.mollusk,
          species: '전복',
          count: 25,
          latitude: 35.1830,
          longitude: 129.0790,
          timestamp: DateTime(yesterday.year, yesterday.month, yesterday.day, 8, 0),
          notes: '[DUMMY_DATA] 전복 채취',
        ),
        FishingRecord(
          category: MarineCategory.mollusk,
          species: '소라',
          count: 15,
          latitude: 35.1840,
          longitude: 129.0800,
          timestamp: DateTime(yesterday.year, yesterday.month, yesterday.day, 9, 30),
          notes: '[DUMMY_DATA] 소라 수확',
        ),
        FishingRecord(
          category: MarineCategory.fish,
          species: '참돔',
          count: 12,
          latitude: 35.1850,
          longitude: 129.0810,
          timestamp: DateTime(yesterday.year, yesterday.month, yesterday.day, 15, 0),
          notes: '[DUMMY_DATA] 참돔 낚시',
        ),
        
        // 2일 전 기록
        FishingRecord(
          category: MarineCategory.echinoderm,
          species: '성게',
          count: 30,
          latitude: 35.1860,
          longitude: 129.0820,
          timestamp: DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day, 7, 30),
          notes: '[DUMMY_DATA] 성게 채취',
        ),
        FishingRecord(
          category: MarineCategory.seaweed,
          species: '미역',
          count: 50,
          latitude: 35.1870,
          longitude: 129.0830,
          timestamp: DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day, 10, 0),
          notes: '[DUMMY_DATA] 미역 수확',
        ),
        
        // 3일 전 기록
        FishingRecord(
          category: MarineCategory.fish,
          species: '전갱이',
          count: 45,
          latitude: 35.1880,
          longitude: 129.0840,
          timestamp: DateTime(threeDaysAgo.year, threeDaysAgo.month, threeDaysAgo.day, 6, 0),
          notes: '[DUMMY_DATA] 새벽 조업',
        ),
        FishingRecord(
          category: MarineCategory.cephalopod,
          species: '문어',
          count: 8,
          latitude: 35.1890,
          longitude: 129.0850,
          timestamp: DateTime(threeDaysAgo.year, threeDaysAgo.month, threeDaysAgo.day, 14, 0),
          notes: '[DUMMY_DATA] 문어 통발',
        ),
        
        // 5일 전 기록
        FishingRecord(
          category: MarineCategory.crustacean,
          species: '꽃게',
          count: 20,
          latitude: 35.1900,
          longitude: 129.0860,
          timestamp: DateTime(fiveDaysAgo.year, fiveDaysAgo.month, fiveDaysAgo.day, 11, 0),
          notes: '[DUMMY_DATA] 꽃게 조업',
        ),
        FishingRecord(
          category: MarineCategory.fish,
          species: '조기',
          count: 60,
          latitude: 35.1910,
          longitude: 129.0870,
          timestamp: DateTime(fiveDaysAgo.year, fiveDaysAgo.month, fiveDaysAgo.day, 16, 0),
          notes: '[DUMMY_DATA] 조기 떼',
        ),
        
        // 일주일 전 기록
        FishingRecord(
          category: MarineCategory.seaweed,
          species: '김',
          count: 100,
          latitude: 35.1920,
          longitude: 129.0880,
          timestamp: DateTime(weekAgo.year, weekAgo.month, weekAgo.day, 8, 0),
          notes: '[DUMMY_DATA] 김 양식 수확',
        ),
        FishingRecord(
          category: MarineCategory.other,
          species: '해삼',
          count: 18,
          latitude: 35.1930,
          longitude: 129.0890,
          timestamp: DateTime(weekAgo.year, weekAgo.month, weekAgo.day, 13, 0),
          notes: '[DUMMY_DATA] 해삼 채취',
        ),
      ];
      
      for (final record in sampleRecords) {
        await addRecord(record);
      }
    }
  }
  
  /// 더미 데이터 삭제
  static Future<void> deleteDummyData() async {
    if (kIsWeb) {
      // [DUMMY_DATA] 태그가 있는 모든 레코드 삭제
      _memoryRecords.removeWhere((record) => 
        record.notes?.contains('[DUMMY_DATA]') ?? false
      );
    } else {
      if (_isar == null) await init();
      // 모바일에서도 더미 데이터 삭제
      final dummyRecords = await _isar!.fishingRecords
          .where()
          .filter()
          .notesContains('[DUMMY_DATA]')
          .findAll();
      
      await _isar!.writeTxn(() async {
        for (final record in dummyRecords) {
          await _isar!.fishingRecords.delete(record.id);
        }
      });
    }
  }
  
  /// 더미 데이터 존재 여부 확인
  static bool hasDummyData() {
    if (kIsWeb) {
      return _memoryRecords.any((r) => r.notes?.contains('[DUMMY_DATA]') ?? false);
    }
    return false; // 모바일에서는 false 반환 (실제 구현 시 Isar 쿼리 필요)
  }

  /// Isar 종료
  static Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
    }
  }
}