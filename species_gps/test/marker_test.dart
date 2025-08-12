import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Marker List Test', () {
    test('마커 리스트 추가 테스트', () {
      List<Map<String, dynamic>> customMarkers = [];
      
      // 첫 번째 마커 추가
      customMarkers.add({
        'lat': 35.1796,
        'lng': 129.0756,
        'memo': '첫 번째 마커',
        'timestamp': DateTime.now(),
      });
      expect(customMarkers.length, 1);
      print('첫 번째 마커 추가 후: ${customMarkers.length}개');
      
      // 두 번째 마커 추가
      customMarkers.add({
        'lat': 35.1800,
        'lng': 129.0760,
        'memo': '두 번째 마커',
        'timestamp': DateTime.now(),
      });
      expect(customMarkers.length, 2);
      print('두 번째 마커 추가 후: ${customMarkers.length}개');
      
      // 세 번째 마커 추가
      customMarkers.add({
        'lat': 35.1810,
        'lng': 129.0770,
        'memo': '세 번째 마커',
        'timestamp': DateTime.now(),
      });
      expect(customMarkers.length, 3);
      print('세 번째 마커 추가 후: ${customMarkers.length}개');
      
      // 전체 마커 출력
      print('전체 마커 목록:');
      for (var i = 0; i < customMarkers.length; i++) {
        print('  마커 ${i + 1}: ${customMarkers[i]}');
      }
    });
    
    test('setState 시뮬레이션 테스트', () {
      // StatefulWidget 시뮬레이션
      var markers = <Map<String, dynamic>>[];
      var stateVersion = 0;
      
      void setState(Function() callback) {
        callback();
        stateVersion++;
        print('setState 호출 - 버전: $stateVersion, 마커 수: ${markers.length}');
      }
      
      // 마커 추가 시뮬레이션
      for (int i = 0; i < 5; i++) {
        setState(() {
          markers.add({
            'lat': 35.1796 + (i * 0.001),
            'lng': 129.0756 + (i * 0.001),
            'memo': '마커 ${i + 1}',
            'timestamp': DateTime.now(),
          });
        });
        
        expect(markers.length, i + 1);
      }
      
      expect(markers.length, 5);
      print('최종 마커 수: ${markers.length}');
    });
  });
}