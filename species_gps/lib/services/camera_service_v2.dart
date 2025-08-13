import 'dart:io';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../core/errors/app_exception.dart' as app_errors;
import '../core/utils/result.dart';
import '../core/utils/file_helpers.dart';
import 'image_compression_service.dart';

/// 개선된 카메라 서비스
/// - 에러 처리 개선
/// - 메모리 관리 개선
/// - 보안 강화 (GPS 정보 분리 저장)
class CameraServiceV2 {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  
  // Singleton pattern
  static final CameraServiceV2 _instance = CameraServiceV2._internal();
  factory CameraServiceV2() => _instance;
  CameraServiceV2._internal();
  
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  CameraController? get controller => _controller;
  
  /// 카메라 초기화
  Future<Result<void>> initialize() async {
    try {
      // 이미 초기화되어 있으면 성공 반환
      if (isInitialized) {
        return Result.success(null);
      }
      
      // 사용 가능한 카메라 가져오기
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        return Result.failure(app_errors.CameraException.notAvailable());
      }
      
      // 후면 카메라 우선, 없으면 첫 번째 카메라 사용
      final camera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      
      // 컨트롤러 생성 및 초기화
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _controller!.initialize();
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(app_errors.CameraException.initializationFailed(e));
    }
  }
  
  /// 사진 촬영
  Future<Result<XFile>> takePicture() async {
    try {
      if (!isInitialized) {
        final initResult = await initialize();
        if (initResult.isFailure) {
          return Result.failure(initResult.errorOrNull!);
        }
      }
      
      if (!isInitialized) {
        return Result.failure(app_errors.CameraException.notAvailable());
      }
      
      final photo = await _controller!.takePicture();
      return Result.success(photo);
    } catch (e) {
      return Result.failure(app_errors.CameraException.captureFailed(e));
    }
  }
  
  /// 사진 촬영 및 GPS 정보와 함께 저장
  Future<Result<String>> takePictureWithGPS(Position position) async {
    try {
      // 사진 촬영
      final photoResult = await takePicture();
      if (photoResult.isFailure) {
        return Result.failure(photoResult.errorOrNull!);
      }
      
      final photo = photoResult.dataOrNull!;
      final photoFile = File(photo.path);
      
      // 이미지 압축 확인
      final needsCompression = await ImageCompressionService.needsCompression(
        photoFile,
        maxSizeInMB: 2,
      );
      
      File finalPhotoFile = photoFile;
      
      if (needsCompression) {
        // 이미지 압축
        final compressionResult = await ImageCompressionService.compressImage(
          photoFile,
          quality: 85,
        );
        
        if (compressionResult.isSuccess) {
          finalPhotoFile = compressionResult.dataOrNull!;
        }
      }
      
      // 안전하게 저장 (GPS 정보 분리)
      final savedPath = await FileHelpers.savePhotoWithMetadata(
        photo: finalPhotoFile,
        position: position,
      );
      
      // 썸네일 생성
      await ImageCompressionService.createThumbnail(File(savedPath));
      
      // 임시 파일 삭제 (압축된 파일과 다른 경우만)
      if (finalPhotoFile.path != savedPath) {
        await finalPhotoFile.delete();
      }
      
      return Result.success(savedPath);
    } catch (e) {
      return Result.failure(
        app_errors.StorageException.saveFailed(e),
      );
    }
  }
  
  /// 카메라 방향 전환
  Future<Result<void>> switchCamera() async {
    try {
      if (_cameras == null || _cameras!.length < 2) {
        return Result.failure(
          app_errors.CameraException(message: '다른 카메라를 사용할 수 없습니다.'),
        );
      }
      
      final currentDirection = _controller!.description.lensDirection;
      final newCamera = _cameras!.firstWhere(
        (cam) => cam.lensDirection != currentDirection,
      );
      
      await _controller!.dispose();
      
      _controller = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _controller!.initialize();
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        app_errors.CameraException(
          message: '카메라 전환에 실패했습니다.',
          originalError: e,
        ),
      );
    }
  }
  
  /// 플래시 모드 설정
  Future<Result<void>> setFlashMode(FlashMode mode) async {
    try {
      if (!isInitialized) {
        return Result.failure(app_errors.CameraException.notAvailable());
      }
      
      await _controller!.setFlashMode(mode);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        app_errors.CameraException(
          message: '플래시 설정에 실패했습니다.',
          originalError: e,
        ),
      );
    }
  }
  
  /// 비디오 녹화 상태
  bool _isRecording = false;
  bool get isRecording => _isRecording;
  
  /// 비디오 녹화 시작
  Future<Result<void>> startVideoRecording() async {
    try {
      if (!isInitialized) {
        final initResult = await initialize();
        if (initResult.isFailure) {
          return Result.failure(initResult.errorOrNull!);
        }
      }
      
      if (_isRecording) {
        return Result.failure(
          app_errors.CameraException(message: '이미 녹화 중입니다.'),
        );
      }
      
      // 오디오 포함 여부를 위해 컨트롤러 재초기화
      if (!_controller!.value.isRecordingVideo) {
        await _controller!.prepareForVideoRecording();
      }
      
      await _controller!.startVideoRecording();
      _isRecording = true;
      
      return Result.success(null);
    } catch (e) {
      _isRecording = false;
      return Result.failure(
        app_errors.CameraException(
          message: '비디오 녹화 시작에 실패했습니다.',
          originalError: e,
        ),
      );
    }
  }
  
  /// 비디오 녹화 중지 및 GPS 정보와 함께 저장
  Future<Result<String>> stopVideoRecordingWithGPS(Position position) async {
    try {
      if (!_isRecording) {
        return Result.failure(
          app_errors.CameraException(message: '녹화 중이 아닙니다.'),
        );
      }
      
      final video = await _controller!.stopVideoRecording();
      _isRecording = false;
      
      final videoFile = File(video.path);
      
      // 비디오 파일 저장 (GPS 정보와 함께)
      final savedPath = await FileHelpers.saveVideoWithMetadata(
        video: videoFile,
        position: position,
      );
      
      // 임시 파일 삭제
      if (videoFile.path != savedPath) {
        await videoFile.delete();
      }
      
      return Result.success(savedPath);
    } catch (e) {
      _isRecording = false;
      return Result.failure(
        app_errors.CameraException(
          message: '비디오 녹화 중지에 실패했습니다.',
          originalError: e,
        ),
      );
    }
  }
  
  /// 녹화 시간 제한 설정 (초 단위)
  Future<Result<String>> recordVideoWithDuration({
    required Position position,
    required int maxDurationInSeconds,
  }) async {
    try {
      final startResult = await startVideoRecording();
      if (startResult.isFailure) {
        return Result.failure(startResult.errorOrNull!);
      }
      
      // 지정된 시간 후 자동 중지
      await Future.delayed(Duration(seconds: maxDurationInSeconds));
      
      if (_isRecording) {
        return await stopVideoRecordingWithGPS(position);
      }
      
      return Result.failure(
        app_errors.CameraException(message: '녹화가 중단되었습니다.'),
      );
    } catch (e) {
      _isRecording = false;
      return Result.failure(
        app_errors.CameraException(
          message: '비디오 녹화에 실패했습니다.',
          originalError: e,
        ),
      );
    }
  }
  
  /// 리소스 정리
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}