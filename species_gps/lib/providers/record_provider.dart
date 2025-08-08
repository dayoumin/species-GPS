import 'package:flutter/material.dart';
import '../models/fishing_record.dart';
import '../services/database_service.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/result.dart';

/// 기록 데이터 상태 관리 Provider
class RecordProvider extends ChangeNotifier {
  List<FishingRecord> _records = [];
  bool _isRecordsLoading = false;
  Map<String, int> _speciesCount = {};
  int _totalRecords = 0;
  
  // 페이징 관련
  static const int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMoreData = true;
  
  // Getters
  List<FishingRecord> get records => List.unmodifiable(_records);
  bool get isRecordsLoading => _isRecordsLoading;
  Map<String, int> get speciesCount => Map.unmodifiable(_speciesCount);
  int get totalRecords => _totalRecords;
  bool get hasMoreData => _hasMoreData;
  
  /// 기록 데이터 로드 (전체)
  Future<void> loadRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isRecordsLoading = true;
    notifyListeners();
    
    try {
      _records = await DatabaseService.getRecords(
        startDate: startDate,
        endDate: endDate,
      );
      
      // 통계 업데이트
      await _updateStatistics();
      
      // 페이징 초기화
      _currentPage = 0;
      _hasMoreData = _records.length >= _pageSize;
    } catch (e) {
      // 에러 로깅 필요
    } finally {
      _isRecordsLoading = false;
      notifyListeners();
    }
  }
  
  /// 페이징된 기록 데이터 로드
  Future<void> loadRecordsPaged({
    DateTime? startDate,
    DateTime? endDate,
    bool refresh = false,
  }) async {
    if (_isRecordsLoading || (!_hasMoreData && !refresh)) return;
    
    if (refresh) {
      _currentPage = 0;
      _records.clear();
    }
    
    _isRecordsLoading = true;
    notifyListeners();
    
    try {
      final newRecords = await DatabaseService.getRecordsPaged(
        offset: _currentPage * _pageSize,
        limit: _pageSize,
        startDate: startDate,
        endDate: endDate,
      );
      
      if (newRecords.length < _pageSize) {
        _hasMoreData = false;
      }
      
      if (refresh) {
        _records = newRecords;
      } else {
        _records.addAll(newRecords);
      }
      
      _currentPage++;
      
      // 통계 업데이트
      await _updateStatistics();
    } catch (e) {
      // 에러 로깅 필요
    } finally {
      _isRecordsLoading = false;
      notifyListeners();
    }
  }
  
  /// 새 기록 추가
  Future<Result<int>> addRecord(FishingRecord record) async {
    try {
      final id = await DatabaseService.insertRecord(record);
      
      // 로컬 상태 업데이트 (DB 재조회 대신)
      final newRecord = record.copyWith(id: id);
      _records.insert(0, newRecord);
      _totalRecords++;
      
      // 종별 카운트 업데이트
      _speciesCount[record.species] = 
          (_speciesCount[record.species] ?? 0) + 1;
      
      notifyListeners();
      return Result.success(id);
    } catch (e) {
      return Result.failure(
        DatabaseException.insertFailed(e),
      );
    }
  }
  
  /// 기록 삭제
  Future<Result<void>> deleteRecord(int id) async {
    try {
      await DatabaseService.deleteRecord(id);
      
      // 로컬 상태 업데이트
      final index = _records.indexWhere((r) => r.id == id);
      if (index != -1) {
        final deletedRecord = _records[index];
        _records.removeAt(index);
        _totalRecords--;
        
        // 종별 카운트 업데이트
        final count = _speciesCount[deletedRecord.species] ?? 0;
        if (count > 1) {
          _speciesCount[deletedRecord.species] = count - 1;
        } else {
          _speciesCount.remove(deletedRecord.species);
        }
      }
      
      notifyListeners();
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        DatabaseException.deleteFailed(e),
      );
    }
  }
  
  /// 통계 업데이트
  Future<void> _updateStatistics() async {
    try {
      _totalRecords = await DatabaseService.getTotalCount();
      _speciesCount = await DatabaseService.getSpeciesCount();
    } catch (e) {
      // 통계 업데이트 실패는 무시
    }
  }
  
  /// 필터링된 기록 반환
  List<FishingRecord> getFilteredRecords({
    String? species,
    DateTime? date,
  }) {
    return _records.where((record) {
      if (species != null && record.species != species) return false;
      if (date != null) {
        final recordDate = DateTime(
          record.timestamp.year,
          record.timestamp.month,
          record.timestamp.day,
        );
        final filterDate = DateTime(date.year, date.month, date.day);
        if (recordDate != filterDate) return false;
      }
      return true;
    }).toList();
  }
  
  /// 오늘의 기록 개수
  int get todayRecordCount {
    final today = DateTime.now();
    return getFilteredRecords(date: today).length;
  }
  
  /// 기록 초기화
  void clearRecords() {
    _records.clear();
    _speciesCount.clear();
    _totalRecords = 0;
    _currentPage = 0;
    _hasMoreData = true;
    notifyListeners();
  }
}