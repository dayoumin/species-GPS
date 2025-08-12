import '../models/fishing_record.dart';
import '../services/database_service.dart';
import '../core/utils/result.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/app_logger.dart';

/// 기록 데이터 저장소 인터페이스
abstract class IRecordRepository {
  Future<Result<List<FishingRecord>>> getRecords({
    DateTime? startDate,
    DateTime? endDate,
  });
  
  Future<Result<List<FishingRecord>>> getRecordsPaged({
    required int offset,
    required int limit,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  Future<Result<int>> insertRecord(FishingRecord record);
  Future<Result<void>> updateRecord(FishingRecord record);
  Future<Result<void>> deleteRecord(int id);
  Future<Result<int>> getTotalCount();
  Future<Result<Map<String, int>>> getSpeciesCount();
  Future<Result<FishingRecord?>> getRecordById(int id);
  Future<Result<List<FishingRecord>>> searchRecords(String query);
}

/// 기록 데이터 저장소 구현
class RecordRepository implements IRecordRepository {
  static RecordRepository? _instance;
  
  RecordRepository._();
  
  /// 싱글톤 인스턴스 반환
  static RecordRepository get instance {
    _instance ??= RecordRepository._();
    return _instance!;
  }
  
  @override
  Future<Result<List<FishingRecord>>> getRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      final records = await DatabaseService.getRecords(
        startDate: startDate,
        endDate: endDate,
      );
      
      stopwatch.stop();
      
      AppLogger.database(
        operation: 'getRecords',
        table: 'fishing_records',
        parameters: {
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        },
        result: '${records.length} records',
        duration: stopwatch.elapsed,
      );
      
      return Result.success(records);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get records', e, stackTrace);
      return Result.failure(
        DatabaseException.queryFailed(e),
      );
    }
  }
  
  @override
  Future<Result<List<FishingRecord>>> getRecordsPaged({
    required int offset,
    required int limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      final records = await DatabaseService.getRecordsPaged(
        offset: offset,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );
      
      stopwatch.stop();
      
      AppLogger.database(
        operation: 'getRecordsPaged',
        table: 'fishing_records',
        parameters: {
          'offset': offset,
          'limit': limit,
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        },
        result: '${records.length} records',
        duration: stopwatch.elapsed,
      );
      
      return Result.success(records);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get paged records', e, stackTrace);
      return Result.failure(
        DatabaseException.queryFailed(e),
      );
    }
  }
  
  @override
  Future<Result<int>> insertRecord(FishingRecord record) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      final id = await DatabaseService.insertRecord(record);
      
      stopwatch.stop();
      
      AppLogger.database(
        operation: 'insertRecord',
        table: 'fishing_records',
        parameters: record.toMap(),
        result: 'id: $id',
        duration: stopwatch.elapsed,
      );
      
      AppLogger.info('Record inserted successfully with id: $id');
      
      return Result.success(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to insert record', e, stackTrace);
      return Result.failure(
        DatabaseException.insertFailed(e),
      );
    }
  }
  
  @override
  Future<Result<void>> updateRecord(FishingRecord record) async {
    try {
      if (record.id == null) {
        return Result.failure(
          DatabaseException.updateFailed('Record ID is required for update'),
        );
      }
      
      final stopwatch = Stopwatch()..start();
      
      await DatabaseService.updateRecord(record);
      
      stopwatch.stop();
      
      AppLogger.database(
        operation: 'updateRecord',
        table: 'fishing_records',
        parameters: record.toMap(),
        duration: stopwatch.elapsed,
      );
      
      AppLogger.info('Record updated successfully: ${record.id}');
      
      return Result.success(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update record', e, stackTrace);
      return Result.failure(
        DatabaseException.updateFailed(e),
      );
    }
  }
  
  @override
  Future<Result<void>> deleteRecord(int id) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      await DatabaseService.deleteRecord(id);
      
      stopwatch.stop();
      
      AppLogger.database(
        operation: 'deleteRecord',
        table: 'fishing_records',
        parameters: {'id': id},
        duration: stopwatch.elapsed,
      );
      
      AppLogger.info('Record deleted successfully: $id');
      
      return Result.success(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete record', e, stackTrace);
      return Result.failure(
        DatabaseException.deleteFailed(e),
      );
    }
  }
  
  @override
  Future<Result<int>> getTotalCount() async {
    try {
      final count = await DatabaseService.getTotalCount();
      
      AppLogger.database(
        operation: 'getTotalCount',
        table: 'fishing_records',
        result: count,
      );
      
      return Result.success(count);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get total count', e, stackTrace);
      return Result.failure(
        DatabaseException.queryFailed(e),
      );
    }
  }
  
  @override
  Future<Result<Map<String, int>>> getSpeciesCount() async {
    try {
      final counts = await DatabaseService.getSpeciesCount();
      
      AppLogger.database(
        operation: 'getSpeciesCount',
        table: 'fishing_records',
        result: counts,
      );
      
      return Result.success(counts);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get species count', e, stackTrace);
      return Result.failure(
        DatabaseException.queryFailed(e),
      );
    }
  }
  
  @override
  Future<Result<FishingRecord?>> getRecordById(int id) async {
    try {
      final records = await DatabaseService.getRecords();
      final record = records.firstWhere(
        (r) => r.id == id,
        orElse: () => throw DatabaseException.notFound('Record not found: $id'),
      );
      
      AppLogger.database(
        operation: 'getRecordById',
        table: 'fishing_records',
        parameters: {'id': id},
        result: record.toMap(),
      );
      
      return Result.success(record);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get record by id', e, stackTrace);
      
      if (e is DatabaseException) {
        return Result.failure(e);
      }
      
      return Result.failure(
        DatabaseException.queryFailed(e),
      );
    }
  }
  
  @override
  Future<Result<List<FishingRecord>>> searchRecords(String query) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // 모든 레코드를 가져와서 필터링 (간단한 구현)
      final allRecords = await DatabaseService.getRecords();
      
      final filteredRecords = allRecords.where((record) {
        final searchLower = query.toLowerCase();
        return record.species.toLowerCase().contains(searchLower) ||
               (record.notes?.toLowerCase().contains(searchLower) ?? false) ||
               (record.location?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
      
      stopwatch.stop();
      
      AppLogger.database(
        operation: 'searchRecords',
        table: 'fishing_records',
        parameters: {'query': query},
        result: '${filteredRecords.length} records found',
        duration: stopwatch.elapsed,
      );
      
      return Result.success(filteredRecords);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search records', e, stackTrace);
      return Result.failure(
        DatabaseException.queryFailed(e),
      );
    }
  }
}