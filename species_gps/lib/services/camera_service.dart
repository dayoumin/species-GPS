import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:geolocator/geolocator.dart';

class CameraService {
  static List<CameraDescription>? _cameras;
  static CameraController? _controller;
  
  static Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras!.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
      }
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }
  
  static CameraController? get controller => _controller;
  
  static Future<File?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      await initialize();
    }
    
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }
    
    try {
      final XFile photo = await _controller!.takePicture();
      
      // 저장 디렉토리 가져오기
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String dirPath = path.join(appDir.path, 'species_photos');
      await Directory(dirPath).create(recursive: true);
      
      // 타임스탬프로 파일명 생성
      final String fileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(dirPath, fileName);
      
      // 파일 복사
      final File savedFile = await File(photo.path).copy(filePath);
      
      return savedFile;
    } catch (e) {
      print('Take picture error: $e');
      return null;
    }
  }
  
  static Future<String?> saveImageWithGPS(File image, Position position) async {
    try {
      // 이미지 파일에 GPS 정보를 추가하는 로직
      // 실제로는 exif 패키지를 사용하여 메타데이터를 추가할 수 있습니다
      // 현재는 파일명에 좌표를 포함시키는 간단한 방법 사용
      
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String dirPath = path.join(appDir.path, 'species_photos');
      await Directory(dirPath).create(recursive: true);
      
      final String fileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}_'
          '${position.latitude.toStringAsFixed(6)}_'
          '${position.longitude.toStringAsFixed(6)}.jpg';
      final String filePath = path.join(dirPath, fileName);
      
      await image.copy(filePath);
      
      return filePath;
    } catch (e) {
      print('Save image with GPS error: $e');
      return null;
    }
  }
  
  static void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}