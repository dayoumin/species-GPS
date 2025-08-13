abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  String get displayMessage => message;

  @override
  String toString() => 'AppException: $message ${code != null ? '(Code: $code)' : ''}';
}

class LocationException extends AppException {
  const LocationException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);

  factory LocationException.serviceDisabled() => const LocationException(
        message: '위치 서비스가 비활성화되어 있습니다. 설정에서 활성화해주세요.',
        code: 'LOCATION_SERVICE_DISABLED',
      );

  factory LocationException.permissionDenied() => const LocationException(
        message: '위치 권한이 거부되었습니다. 설정에서 권한을 허용해주세요.',
        code: 'LOCATION_PERMISSION_DENIED',
      );

  factory LocationException.permissionPermanentlyDenied() => const LocationException(
        message: '위치 권한이 영구적으로 거부되었습니다. 앱 설정에서 권한을 허용해주세요.',
        code: 'LOCATION_PERMISSION_PERMANENTLY_DENIED',
      );

  factory LocationException.timeout() => const LocationException(
        message: '위치 정보를 가져오는데 시간이 초과되었습니다.',
        code: 'LOCATION_TIMEOUT',
      );

  factory LocationException.unknown(dynamic error) => LocationException(
        message: '위치 정보를 가져오는 중 오류가 발생했습니다.',
        code: 'LOCATION_UNKNOWN_ERROR',
        originalError: error,
      );
}

class CameraException extends AppException {
  const CameraException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);

  factory CameraException.notAvailable() => const CameraException(
        message: '카메라를 사용할 수 없습니다.',
        code: 'CAMERA_NOT_AVAILABLE',
      );

  factory CameraException.permissionDenied() => const CameraException(
        message: '카메라 권한이 거부되었습니다.',
        code: 'CAMERA_PERMISSION_DENIED',
      );

  factory CameraException.initializationFailed(dynamic error) => CameraException(
        message: '카메라 초기화에 실패했습니다.',
        code: 'CAMERA_INITIALIZATION_FAILED',
        originalError: error,
      );

  factory CameraException.captureFailed(dynamic error) => CameraException(
        message: '사진 촬영에 실패했습니다.',
        code: 'CAMERA_CAPTURE_FAILED',
        originalError: error,
      );
}

class DatabaseException extends AppException {
  const DatabaseException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);

  factory DatabaseException.connectionFailed() => const DatabaseException(
        message: '데이터베이스 연결에 실패했습니다.',
        code: 'DATABASE_CONNECTION_FAILED',
      );

  factory DatabaseException.insertFailed(dynamic error) => DatabaseException(
        message: '데이터 저장에 실패했습니다.',
        code: 'DATABASE_INSERT_FAILED',
        originalError: error,
      );

  factory DatabaseException.queryFailed(dynamic error) => DatabaseException(
        message: '데이터 조회에 실패했습니다.',
        code: 'DATABASE_QUERY_FAILED',
        originalError: error,
      );

  factory DatabaseException.deleteFailed(dynamic error) => DatabaseException(
        message: '데이터 삭제에 실패했습니다.',
        code: 'DATABASE_DELETE_FAILED',
        originalError: error,
      );
  
  factory DatabaseException.updateFailed(dynamic error) => DatabaseException(
        message: '데이터 수정에 실패했습니다.',
        code: 'DATABASE_UPDATE_FAILED',
        originalError: error,
      );
  
  factory DatabaseException.notFound(String message) => DatabaseException(
        message: message,
        code: 'DATABASE_NOT_FOUND',
      );
}

class StorageException extends AppException {
  const StorageException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);

  factory StorageException.insufficientSpace() => const StorageException(
        message: '저장 공간이 부족합니다.',
        code: 'STORAGE_INSUFFICIENT_SPACE',
      );

  factory StorageException.permissionDenied() => const StorageException(
        message: '저장소 권한이 거부되었습니다.',
        code: 'STORAGE_PERMISSION_DENIED',
      );

  factory StorageException.saveFailed(dynamic error) => StorageException(
        message: '파일 저장에 실패했습니다.',
        code: 'STORAGE_SAVE_FAILED',
        originalError: error,
      );
}

/// 권한 관련 예외
class PermissionException extends AppException {
  const PermissionException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
  
  factory PermissionException.denied(String permission) => PermissionException(
        message: '$permission 권한이 거부되었습니다.',
        code: 'PERMISSION_DENIED',
      );
  
  factory PermissionException.permanentlyDenied(String permission) => PermissionException(
        message: '$permission 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.',
        code: 'PERMISSION_PERMANENTLY_DENIED',
      );
}

/// 오디오 관련 예외
class AudioException extends AppException {
  const AudioException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
  
  factory AudioException.recordingFailed(dynamic error) => AudioException(
        message: '녹음에 실패했습니다.',
        code: 'AUDIO_RECORDING_FAILED',
        originalError: error,
      );
  
  factory AudioException.playbackFailed(dynamic error) => AudioException(
        message: '재생에 실패했습니다.',
        code: 'AUDIO_PLAYBACK_FAILED',
        originalError: error,
      );
}