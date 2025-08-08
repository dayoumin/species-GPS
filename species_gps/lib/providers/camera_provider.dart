import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart' as camera;
import '../services/camera_service_v2.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/result.dart';

/// 카메라 상태 관리 Provider
class CameraProvider extends ChangeNotifier {
  final CameraServiceV2 _cameraService = CameraServiceV2();
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String? _lastPhotoPath;
  
  // Getters
  CameraServiceV2 get cameraService => _cameraService;
  bool get isCameraInitialized => _isCameraInitialized;
  bool get isProcessing => _isProcessing;
  String? get lastPhotoPath => _lastPhotoPath;
  
  /// 카메라 초기화
  Future<Result<void>> initializeCamera() async {
    final result = await _cameraService.initialize();
    _isCameraInitialized = result.isSuccess;
    notifyListeners();
    return result;
  }
  
  /// 사진 촬영
  Future<Result<String>> takePicture() async {
    _isProcessing = true;
    notifyListeners();
    
    try {
      final result = await _cameraService.takePicture();
      if (result.isSuccess) {
        _lastPhotoPath = result.dataOrNull?.path;
      }
      // Convert Result<XFile> to Result<String>
      if (result.isSuccess) {
        return Result<String>.success(result.dataOrNull?.path ?? '');
      } else {
        return Result<String>.failure(result.errorOrNull!);
      }
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  /// 사진 촬영 (GPS 포함)
  Future<Result<String>> takePictureWithGPS(Position position) async {
    _isProcessing = true;
    notifyListeners();
    
    try {
      final result = await _cameraService.takePictureWithGPS(position);
      if (result.isSuccess) {
        _lastPhotoPath = result.dataOrNull;
      }
      return result;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  /// 카메라 전환
  Future<void> switchCamera() async {
    await _cameraService.switchCamera();
    notifyListeners();
  }
  
  /// 플래시 모드 설정
  Future<void> setFlashMode(camera.FlashMode mode) async {
    await _cameraService.setFlashMode(mode);
    notifyListeners();
  }
  
  /// 카메라 초기화 상태 재설정
  void resetCameraState() {
    _isCameraInitialized = false;
    _lastPhotoPath = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
}

// FlashMode is imported from camera package