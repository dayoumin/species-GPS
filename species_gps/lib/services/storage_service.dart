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
      final now = DateTime.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      final fiveDaysAgo = now.subtract(const Duration(days: 5));
      final weekAgo = now.subtract(const Duration(days: 7));
      
      final sampleRecords = [
        // 일주일 전 기록
        FishingRecord(
          category: MarineCategory.fish,
          species: '고등어',
          count: 5,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: DateTime(weekAgo.year, weekAgo.month, weekAgo.day, 14, 30),
          notes: '날씨 맑음, 파도 잔잔',
        ),
        // 5일 전 기록
        FishingRecord(
          category: MarineCategory.fish,
          species: '갈치',
          count: 3,
          latitude: 35.1800,
          longitude: 129.0760,
          timestamp: DateTime(fiveDaysAgo.year, fiveDaysAgo.month, fiveDaysAgo.day, 16, 45),
          notes: '오후 입질 활발',
        ),
        // 3일 전 기록 - 다양한 분류군 추가
        FishingRecord(
          category: MarineCategory.cephalopod,
          species: '오징어',
          count: 10,
          latitude: 35.1810,
          longitude: 129.0770,
          timestamp: DateTime(threeDaysAgo.year, threeDaysAgo.month, threeDaysAgo.day, 10, 15),
          notes: '아침 조황 좋음',
        ),
        FishingRecord(
          category: MarineCategory.mollusk,
          species: '전복',
          count: 7,
          latitude: 35.1820,
          longitude: 129.0780,
          timestamp: DateTime(threeDaysAgo.year, threeDaysAgo.month, threeDaysAgo.day, 11, 30),
        ),
      ];
      
      for (final record in sampleRecords) {
        await addRecord(record);
      }
    }
  }

  /// Isar 종료
  static Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
    }
  }
}