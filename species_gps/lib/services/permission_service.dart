import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> checkAndRequestLocationPermission() async {
    final status = await Permission.location.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied || status.isRestricted) {
      final result = await Permission.location.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    
    return false;
  }
  
  static Future<bool> checkAndRequestCameraPermission() async {
    final status = await Permission.camera.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied || status.isRestricted) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    
    return false;
  }
  
  static Future<bool> checkAndRequestStoragePermission() async {
    final status = await Permission.storage.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied || status.isRestricted) {
      final result = await Permission.storage.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    
    return false;
  }
  
  static Future<bool> checkAllPermissions() async {
    final locationGranted = await checkAndRequestLocationPermission();
    final cameraGranted = await checkAndRequestCameraPermission();
    final storageGranted = await checkAndRequestStoragePermission();
    
    return locationGranted && cameraGranted && storageGranted;
  }
}