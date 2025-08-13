import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import '../errors/app_exception.dart';

class FileHelpers {
  static const String _photoDirName = 'species_photos';
  static const String _videoDirName = 'species_videos';
  static const String _metadataDirName = 'metadata';
  
  /// 안전한 파일명 생성 (GPS 정보 노출하지 않음)
  static String generateSecureFileName({
    required String prefix,
    required String extension,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = timestamp.remainder(10000);
    return '${prefix}_${timestamp}_$randomSuffix.$extension';
  }
  
  /// 사진 저장 디렉토리 가져오기
  static Future<Directory> getPhotoDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory(path.join(appDir.path, _photoDirName));
    
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    
    return photoDir;
  }
  
  /// 메타데이터 저장 디렉토리 가져오기
  static Future<Directory> getMetadataDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final metaDir = Directory(path.join(appDir.path, _metadataDirName));
    
    if (!await metaDir.exists()) {
      await metaDir.create(recursive: true);
    }
    
    return metaDir;
  }
  
  /// 비디오 저장 디렉토리 가져오기
  static Future<Directory> getVideoDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final videoDir = Directory(path.join(appDir.path, _videoDirName));
    
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }
    
    return videoDir;
  }
  
  /// 사진과 GPS 메타데이터를 안전하게 저장
  static Future<String> savePhotoWithMetadata({
    required File photo,
    required Position position,
  }) async {
    try {
      // 안전한 파일명 생성
      final fileName = generateSecureFileName(
        prefix: 'IMG',
        extension: 'jpg',
      );
      
      // 사진 저장
      final photoDir = await getPhotoDirectory();
      final photoPath = path.join(photoDir.path, fileName);
      await photo.copy(photoPath);
      
      // GPS 메타데이터를 별도 파일로 저장
      final metadataDir = await getMetadataDirectory();
      final metadataPath = path.join(
        metadataDir.path,
        '${path.basenameWithoutExtension(fileName)}.json',
      );
      
      final metadata = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'timestamp': position.timestamp.toIso8601String(),
      };
      
      final metadataFile = File(metadataPath);
      await metadataFile.writeAsString(
        jsonEncode(metadata),
      );
      
      return photoPath;
    } catch (e) {
      throw StorageException.saveFailed(e);
    }
  }
  
  /// 비디오와 GPS 메타데이터를 안전하게 저장
  static Future<String> saveVideoWithMetadata({
    required File video,
    required Position position,
  }) async {
    try {
      // 안전한 파일명 생성
      final fileName = generateSecureFileName(
        prefix: 'VID',
        extension: 'mp4',
      );
      
      // 비디오 저장
      final videoDir = await getVideoDirectory();
      final videoPath = path.join(videoDir.path, fileName);
      await video.copy(videoPath);
      
      // GPS 메타데이터를 별도 파일로 저장
      final metadataDir = await getMetadataDirectory();
      final metadataPath = path.join(
        metadataDir.path,
        '${path.basenameWithoutExtension(fileName)}.json',
      );
      
      final metadata = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'timestamp': position.timestamp.toIso8601String(),
        'type': 'video',
      };
      
      final metadataFile = File(metadataPath);
      await metadataFile.writeAsString(
        jsonEncode(metadata),
      );
      
      return videoPath;
    } catch (e) {
      throw StorageException.saveFailed(e);
    }
  }
  
  /// 파일명에서 메타데이터 파일 경로 가져오기
  static Future<Map<String, dynamic>?> getPhotoMetadata(String photoPath) async {
    try {
      final photoName = path.basenameWithoutExtension(photoPath);
      final metadataDir = await getMetadataDirectory();
      final metadataPath = path.join(metadataDir.path, '$photoName.json');
      
      final metadataFile = File(metadataPath);
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// 파일 크기를 읽기 쉬운 형식으로 변환
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// 데이터베이스 백업
  static Future<String> backupDatabase() async {
    try {
      final dbPath = await sqflite.getDatabasesPath();
      final sourcePath = path.join(dbPath, 'fishing_records.db');
      
      final backupDir = await getApplicationDocumentsDirectory();
      final backupPath = path.join(
        backupDir.path,
        'backups',
        'backup_${DateTime.now().millisecondsSinceEpoch}.db',
      );
      
      final backupFile = File(backupPath);
      await backupFile.parent.create(recursive: true);
      
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(backupPath);
      }
      
      return backupPath;
    } catch (e) {
      throw StorageException.saveFailed(e);
    }
  }
  
  /// 오래된 파일 정리
  static Future<void> cleanupOldFiles({
    required int daysToKeep,
  }) async {
    try {
      final photoDir = await getPhotoDirectory();
      final metadataDir = await getMetadataDirectory();
      
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      // 사진 파일 정리
      await _cleanupDirectory(photoDir, cutoffDate);
      
      // 메타데이터 파일 정리
      await _cleanupDirectory(metadataDir, cutoffDate);
    } catch (e) {
      // 정리 실패는 무시
    }
  }
  
  static Future<void> _cleanupDirectory(Directory dir, DateTime cutoffDate) async {
    if (!await dir.exists()) return;
    
    await for (final entity in dir.list()) {
      if (entity is File) {
        final stat = await entity.stat();
        if (stat.modified.isBefore(cutoffDate)) {
          await entity.delete();
        }
      }
    }
  }
}