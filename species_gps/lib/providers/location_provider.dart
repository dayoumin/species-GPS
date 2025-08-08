import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

/// GPS 위치 상태 관리 Provider
class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  bool _isLocationLoading = false;
  String? _locationError;
  StreamSubscription<Position>? _locationStreamSubscription;
  
  // Getters
  Position? get currentPosition => _currentPosition;
  bool get isLocationLoading => _isLocationLoading;
  String? get locationError => _locationError;
  bool get hasLocation => _currentPosition != null;
  
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
  
  /// 위치 정보 초기화
  void clearLocation() {
    _currentPosition = null;
    _locationError = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _locationStreamSubscription?.cancel();
    super.dispose();
  }
}