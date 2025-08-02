import 'dart:io';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../core/errors/app_exception.dart';
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
        return Result.failure(CameraException.notAvailable());
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
      return Result.failure(CameraException.initializationFailed(e));
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
        return Result.failure(CameraException.notAvailable());
      }
      
      final photo = await _controller!.takePicture();
      return Result.success(photo);
    } catch (e) {
      return Result.failure(CameraException.captureFailed(e));
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
        StorageException.saveFailed(e),
      );
    }
  }
  
  /// 카메라 방향 전환
  Future<Result<void>> switchCamera() async {
    try {
      if (_cameras == null || _cameras!.length < 2) {
        return Result.failure(
          CameraException(message: '다른 카메라를 사용할 수 없습니다.'),
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
        CameraException(
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
        return Result.failure(CameraException.notAvailable());
      }
      
      await _controller!.setFlashMode(mode);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CameraException(
          message: '플래시 설정에 실패했습니다.',
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