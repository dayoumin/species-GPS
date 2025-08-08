import 'dart:io';
import 'dart:ui';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import '../core/errors/app_exception.dart';
import '../core/utils/result.dart';

/// 이미지 압축 서비스
class ImageCompressionService {
  static const int _targetWidth = 1920;
  static const int _targetHeight = 1080;
  static const int _quality = 85;
  static const int _thumbnailSize = 200;
  
  /// 이미지 압축
  static Future<Result<File>> compressImage(
    File imageFile, {
    int quality = _quality,
    int? targetWidth,
    int? targetHeight,
  }) async {
    try {
      final filePath = imageFile.path;
      final fileName = path.basenameWithoutExtension(filePath);
      final extension = path.extension(filePath);
      final directory = path.dirname(filePath);
      
      // 압축된 파일 경로
      final compressedPath = path.join(
        directory,
        '${fileName}_compressed$extension',
      );
      
      // 압축 실행
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        filePath,
        compressedPath,
        quality: quality,
        minWidth: targetWidth ?? _targetWidth,
        minHeight: targetHeight ?? _targetHeight,
        keepExif: false, // EXIF 데이터 제거 (보안)
      );
      
      if (compressedFile == null) {
        return Result.failure(
          StorageException(message: '이미지 압축에 실패했습니다.'),
        );
      }
      
      // 원본 파일 삭제
      await imageFile.delete();
      
      // 압축된 파일을 원본 경로로 이동
      final finalFile = await File(compressedFile.path).rename(filePath);
      
      return Result.success(finalFile);
    } catch (e) {
      return Result.failure(
        StorageException(
          message: '이미지 압축 중 오류가 발생했습니다.',
          originalError: e,
        ),
      );
    }
  }
  
  /// 썸네일 생성
  static Future<Result<File>> createThumbnail(
    File imageFile, {
    int size = _thumbnailSize,
  }) async {
    try {
      final filePath = imageFile.path;
      final fileName = path.basenameWithoutExtension(filePath);
      final directory = path.dirname(filePath);
      
      // 썸네일 경로
      final thumbnailPath = path.join(
        directory,
        'thumbnails',
        '${fileName}_thumb.jpg',
      );
      
      // 썸네일 디렉토리 생성
      await Directory(path.dirname(thumbnailPath)).create(recursive: true);
      
      // 썸네일 생성
      final thumbnailFile = await FlutterImageCompress.compressAndGetFile(
        filePath,
        thumbnailPath,
        quality: 70,
        minWidth: size,
        minHeight: size,
        keepExif: false,
      );
      
      if (thumbnailFile == null) {
        return Result.failure(
          StorageException(message: '썸네일 생성에 실패했습니다.'),
        );
      }
      
      return Result.success(File(thumbnailFile.path));
    } catch (e) {
      return Result.failure(
        StorageException(
          message: '썸네일 생성 중 오류가 발생했습니다.',
          originalError: e,
        ),
      );
    }
  }
  
  /// 이미지 크기 계산
  static Future<ImageInfo> getImageInfo(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final codec = await instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final decodedImage = frame.image;
    
    return ImageInfo(
      width: decodedImage.width,
      height: decodedImage.height,
      sizeInBytes: bytes.length,
    );
  }
  
  /// 파일 크기 확인 및 압축 필요 여부 판단
  static Future<bool> needsCompression(
    File imageFile, {
    int maxSizeInMB = 2,
  }) async {
    final fileSize = await imageFile.length();
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    
    return fileSize > maxSizeInBytes;
  }
}

/// 이미지 정보
class ImageInfo {
  final int width;
  final int height;
  final int sizeInBytes;
  
  const ImageInfo({
    required this.width,
    required this.height,
    required this.sizeInBytes,
  });
  
  double get sizeInMB => sizeInBytes / (1024 * 1024);
  double get aspectRatio => width / height;
}