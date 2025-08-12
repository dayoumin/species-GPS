import 'package:flutter/foundation.dart';
import '../models/fishing_record.dart';
import 'database_service.dart';

/// 플랫폼별 저장소 서비스
class StorageService {
  // 메모리 저장소 (웹용)
  static final List<FishingRecord> _memoryRecords = [];
  static int _nextId = 1;
  
  /// 레코드 추가
  static Future<int> addRecord(FishingRecord record) async {
    if (kIsWeb) {
      // 웹: 메모리에 저장
      final newRecord = record.copyWith(id: _nextId++);
      _memoryRecords.add(newRecord);
      print('웹 메모리 저장: ${_memoryRecords.length}개 레코드');
      return newRecord.id!;
    } else {
      // 모바일: SQLite 사용
      return await DatabaseService.insertRecord(record);
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
      
      print('웹 메모리 조회: ${results.length}개 레코드');
      return results;
    } else {
      // 모바일: SQLite 사용
      return await DatabaseService.getRecords(
        startDate: startDate,
        endDate: endDate,
      );
    }
  }
  
  /// 레코드 삭제
  static Future<void> deleteRecord(int id) async {
    if (kIsWeb) {
      // 웹: 메모리에서 삭제
      _memoryRecords.removeWhere((r) => r.id == id);
      print('웹 메모리 삭제: ID $id');
    } else {
      // 모바일: SQLite 사용
      await DatabaseService.deleteRecord(id);
    }
  }
  
  /// 모든 레코드 삭제
  static Future<void> deleteAllRecords() async {
    if (kIsWeb) {
      // 웹: 메모리 초기화
      _memoryRecords.clear();
      print('웹 메모리 전체 삭제');
    } else {
      // 모바일: SQLite 사용 - 모든 레코드 개별 삭제
      final records = await DatabaseService.getRecords();
      for (final record in records) {
        if (record.id != null) {
          await DatabaseService.deleteRecord(record.id!);
        }
      }
    }
  }
  
  /// 테스트용 샘플 데이터 추가
  static Future<void> addSampleData() async {
    if (kIsWeb) {
      final sampleRecords = [
        FishingRecord(
          species: '고등어',
          count: 5,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: DateTime.now().subtract(Duration(hours: 2)),
        ),
        FishingRecord(
          species: '갈치',
          count: 3,
          latitude: 35.1800,
          longitude: 129.0760,
          timestamp: DateTime.now().subtract(Duration(hours: 1)),
        ),
        FishingRecord(
          species: '전어',
          count: 10,
          latitude: 35.1810,
          longitude: 129.0770,
          timestamp: DateTime.now(),
        ),
      ];
      
      for (final record in sampleRecords) {
        await addRecord(record);
      }
      print('샘플 데이터 추가 완료');
    }
  }
}

// FishingRecord에 copyWith 메소드 추가 필요
extension FishingRecordExtension on FishingRecord {
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