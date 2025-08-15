import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/fishing_record.dart';
import '../models/marine_category.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/camera_service_v2.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/result.dart';

/// 앱 전역 상태 관리
class AppStateProvider extends ChangeNotifier {
  // GPS 상태
  Position? _currentPosition;
  bool _isLocationLoading = false;
  String? _locationError;
  StreamSubscription<Position>? _locationStreamSubscription;
  
  // 기록 데이터
  List<FishingRecord> _records = [];
  bool _isRecordsLoading = false;
  Map<String, int> _speciesCount = {};
  int _totalRecords = 0;
  Map<MarineCategory, int> _categoryCount = {};
  Map<MarineCategory, Map<String, int>> _categorySpeciesCount = {};
  bool _showCategoryView = false; // 분류군별 보기 토글
  
  // 카메라 상태
  final CameraServiceV2 _cameraService = CameraServiceV2();
  bool _isCameraInitialized = false;
  
  // Getters
  Position? get currentPosition => _currentPosition;
  bool get isLocationLoading => _isLocationLoading;
  String? get locationError => _locationError;
  List<FishingRecord> get records => List.unmodifiable(_records);
  bool get isRecordsLoading => _isRecordsLoading;
  Map<String, int> get speciesCount => Map.unmodifiable(_speciesCount);
  int get totalRecords => _totalRecords;
  Map<MarineCategory, int> get categoryCount => Map.unmodifiable(_categoryCount);
  Map<MarineCategory, Map<String, int>> get categorySpeciesCount => Map.unmodifiable(_categorySpeciesCount);
  bool get showCategoryView => _showCategoryView;
  bool get hasLocation => _currentPosition != null;
  CameraServiceV2 get cameraService => _cameraService;
  bool get isCameraInitialized => _isCameraInitialized;
  
  /// 위치 정보 업데이트
  Future<void> updateLocation() async {
    _isLocationLoading = true;
    _locationError = null;
    notifyListeners();
    
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        _currentPosition = position;
        _locationError = null;
      } else {
        _locationError = '위치 정보를 가져올 수 없습니다.';
      }
    } catch (e) {
      _locationError = e.toString();
    } finally {
      _isLocationLoading = false;
      notifyListeners();
    }
  }
  
  /// 위치 스트림 시작
  void startLocationStream() {
    // 기존 스트림이 있다면 취소
    _locationStreamSubscription?.cancel();
    
    _locationStreamSubscription = LocationService.getPositionStream().listen(
      (position) {
        _currentPosition = position;
        _locationError = null;
        notifyListeners();
      },
      onError: (error) {
        _locationError = error.toString();
        notifyListeners();
      },
    );
  }
  
  /// 위치 스트림 중지
  void stopLocationStream() {
    _locationStreamSubscription?.cancel();
    _locationStreamSubscription = null;
  }
  
  /// 기록 데이터 로드
  Future<void> loadRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isRecordsLoading = true;
    notifyListeners();
    
    try {
      _records = await StorageService.getRecords(
        startDate: startDate,
        endDate: endDate,
      );
      
      // 통계 업데이트
      await _updateStatistics();
    } catch (e) {
      // 에러 처리
    } finally {
      _isRecordsLoading = false;
      notifyListeners();
    }
  }
  
  /// 새 기록 추가
  Future<Result<int>> addRecord(FishingRecord record) async {
    try {
      final id = await StorageService.addRecord(record);
      
      // 리스트 업데이트
      await loadRecords();
      
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
      await StorageService.deleteRecord(id);
      
      // 리스트 업데이트
      await loadRecords();
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        DatabaseException.deleteFailed(e),
      );
    }
  }
  
  /// 카메라 초기화
  Future<Result<void>> initializeCamera() async {
    final result = await _cameraService.initialize();
    _isCameraInitialized = result.isSuccess;
    notifyListeners();
    return result;
  }
  
  /// 사진 촬영 (GPS 포함)
  Future<Result<String>> takePictureWithGPS() async {
    if (_currentPosition == null) {
      return Result.failure(
        LocationException(message: '위치 정보가 없습니다.'),
      );
    }
    
    return await _cameraService.takePictureWithGPS(_currentPosition!);
  }
  
  /// 비디오 녹화 시작
  Future<Result<void>> startVideoRecording() async {
    return await _cameraService.startVideoRecording();
  }
  
  /// 비디오 녹화 중지 (GPS 포함)
  Future<Result<String>> stopVideoRecordingWithGPS() async {
    if (_currentPosition == null) {
      return Result.failure(
        LocationException(message: '위치 정보가 없습니다.'),
      );
    }
    
    return await _cameraService.stopVideoRecordingWithGPS(_currentPosition!);
  }
  
  /// 비디오 녹화 상태 확인
  bool get isRecordingVideo => _cameraService.isRecording;
  
  /// 통계 업데이트
  Future<void> _updateStatistics() async {
    try {
      _totalRecords = await StorageService.getTotalCount();
      _speciesCount = await StorageService.getSpeciesCount();
      
      // 분류군별 통계 계산
      _categoryCount = {};
      _categorySpeciesCount = {};
      
      for (final record in _records) {
        // 분류군별 개체수
        _categoryCount[record.category] = 
            (_categoryCount[record.category] ?? 0) + record.count;
        
        // 분류군별 종별 개체수
        if (!_categorySpeciesCount.containsKey(record.category)) {
          _categorySpeciesCount[record.category] = {};
        }
        _categorySpeciesCount[record.category]![record.species] = 
            (_categorySpeciesCount[record.category]![record.species] ?? 0) + record.count;
      }
    } catch (e) {
      // 통계 업데이트 실패는 무시
    }
  }
  
  /// 분류군별 보기 토글
  void toggleCategoryView() {
    _showCategoryView = !_showCategoryView;
    notifyListeners();
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
  
  /// 어제의 기록 개수
  int get yesterdayRecordCount {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return getFilteredRecords(date: yesterday).length;
  }
  
  @override
  void dispose() {
    _locationStreamSubscription?.cancel();
    _cameraService.dispose();
    super.dispose();
  }
}