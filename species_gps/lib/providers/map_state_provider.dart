import 'package:flutter/material.dart';

/// 지도 상태를 전역으로 관리하는 Provider
class MapStateProvider extends ChangeNotifier {
  // 사용자가 추가한 커스텀 마커들
  final List<Map<String, dynamic>> _customMarkers = [];
  
  List<Map<String, dynamic>> get customMarkers => List.unmodifiable(_customMarkers);
  
  /// 마커 추가
  void addMarker({
    required double lat,
    required double lng,
    String? memo,
  }) {
    _customMarkers.add({
      'id': DateTime.now().millisecondsSinceEpoch,
      'lat': lat,
      'lng': lng,
      'memo': memo,
      'timestamp': DateTime.now(),
    });
    
    print('MapStateProvider - 마커 추가됨: 총 ${_customMarkers.length}개');
    notifyListeners();
  }
  
  /// 마커 제거
  void removeMarker(int id) {
    _customMarkers.removeWhere((marker) => marker['id'] == id);
    notifyListeners();
  }
  
  /// 마커 위치 업데이트
  void updateMarkerPosition(int id, double lat, double lng) {
    final markerIndex = _customMarkers.indexWhere((marker) => marker['id'] == id);
    if (markerIndex != -1) {
      _customMarkers[markerIndex]['lat'] = lat;
      _customMarkers[markerIndex]['lng'] = lng;
      _customMarkers[markerIndex]['lastModified'] = DateTime.now();
      
      print('MapStateProvider - 마커 위치 업데이트됨: ID=$id, 위도=$lat, 경도=$lng');
      notifyListeners();
    }
  }
  
  /// 모든 마커 제거
  void clearMarkers() {
    _customMarkers.clear();
    notifyListeners();
  }
  
  /// 마커 개수
  int get markerCount => _customMarkers.length;
}