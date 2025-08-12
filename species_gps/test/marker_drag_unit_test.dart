import 'package:flutter_test/flutter_test.dart';
import 'package:species_gps/providers/map_state_provider.dart';

/// 마커 드래그 핵심 기능 단위 테스트
void main() {
  group('마커 드래그 핵심 기능 테스트', () {
    late MapStateProvider provider;

    setUp(() {
      provider = MapStateProvider();
    });

    test('✅ 마커 추가 후 위치 업데이트 테스트', () {
      print('\n🧪 테스트: 마커 위치 업데이트');
      
      // 1. 마커 추가
      provider.addMarker(
        lat: 35.1796,
        lng: 129.0756,
        memo: '부산항',
      );
      
      expect(provider.markerCount, 1);
      final marker = provider.customMarkers.first;
      final markerId = marker['id'] as int;
      
      print('   초기 위치: 위도=${marker['lat']}, 경도=${marker['lng']}');
      
      // 2. 위치 업데이트 (부산 → 제주도)
      const newLat = 33.4996;
      const newLng = 126.5312;
      provider.updateMarkerPosition(markerId, newLat, newLng);
      
      // 3. 결과 확인
      final updatedMarker = provider.customMarkers.first;
      expect(updatedMarker['lat'], newLat);
      expect(updatedMarker['lng'], newLng);
      expect(updatedMarker['memo'], '부산항'); // 메모 보존
      
      print('   업데이트 위치: 위도=${updatedMarker['lat']}, 경도=${updatedMarker['lng']}');
      print('   ✅ 마커가 부산에서 제주도로 성공적으로 이동!');
    });

    test('✅ 여러 마커 중 특정 마커만 이동 테스트', () {
      print('\n🧪 테스트: 특정 마커 선택적 이동');
      
      // 1. 여러 마커 추가
      provider.addMarker(lat: 35.1796, lng: 129.0756, memo: '부산');
      provider.addMarker(lat: 37.5665, lng: 126.9780, memo: '서울');
      provider.addMarker(lat: 35.1595, lng: 129.0756, memo: '울산');
      
      expect(provider.markerCount, 3);
      print('   초기 마커 3개 추가');
      
      // 2. 서울 마커만 이동 (서울 → 인천)
      final seoulMarker = provider.customMarkers[1];
      final seoulId = seoulMarker['id'] as int;
      
      const incheonLat = 37.4563;
      const incheonLng = 126.7052;
      provider.updateMarkerPosition(seoulId, incheonLat, incheonLng);
      
      // 3. 결과 확인
      final markers = provider.customMarkers;
      
      // 부산과 울산은 그대로
      expect(markers[0]['lat'], 35.1796);
      expect(markers[0]['lng'], 129.0756);
      expect(markers[2]['lat'], 35.1595);
      expect(markers[2]['lng'], 129.0756);
      
      // 서울만 인천으로 이동
      expect(markers[1]['lat'], incheonLat);
      expect(markers[1]['lng'], incheonLng);
      expect(markers[1]['memo'], '서울'); // 메모는 유지
      
      print('   부산 마커: 그대로 유지 ✓');
      print('   서울 마커: 인천으로 이동 ✓');
      print('   울산 마커: 그대로 유지 ✓');
      print('   ✅ 특정 마커만 선택적으로 이동 성공!');
    });

    test('✅ 존재하지 않는 마커 ID 처리 테스트', () {
      print('\n🧪 테스트: 잘못된 마커 ID 처리');
      
      // 1. 마커 추가
      provider.addMarker(lat: 35.1796, lng: 129.0756, memo: '테스트');
      
      final initialMarker = provider.customMarkers.first;
      final initialLat = initialMarker['lat'];
      final initialLng = initialMarker['lng'];
      
      // 2. 존재하지 않는 ID로 업데이트 시도
      provider.updateMarkerPosition(99999, 40.0, 130.0);
      
      // 3. 변경되지 않았는지 확인
      final unchangedMarker = provider.customMarkers.first;
      expect(unchangedMarker['lat'], initialLat);
      expect(unchangedMarker['lng'], initialLng);
      expect(provider.markerCount, 1);
      
      print('   잘못된 ID로 업데이트 시도');
      print('   마커 위치: 변경되지 않음 ✓');
      print('   마커 개수: 1개 유지 ✓');
      print('   ✅ 잘못된 입력에 대한 안전 처리 성공!');
    });

    test('✅ 드래그 시나리오 통합 테스트', () {
      print('\n🧪 시나리오: 실제 사용자 드래그 시뮬레이션');
      
      // 시나리오: 사용자가 낚시터 마커를 이동하는 상황
      print('   📍 상황: 사용자가 잘못 찍은 낚시터 마커를 올바른 위치로 이동');
      
      // 1. 잘못된 위치에 마커 추가
      provider.addMarker(
        lat: 35.1000, // 잘못된 위치
        lng: 129.1000,
        memo: '좋은 낚시터',
      );
      
      final markerId = provider.customMarkers.first['id'] as int;
      print('   1. 잘못된 위치에 마커 생성');
      
      // 2. 사용자가 롱프레스로 드래그 모드 시작
      print('   2. 사용자가 마커를 롱프레스 (드래그 모드 시작)');
      
      // 3. 지도를 드래그하여 올바른 위치로 이동
      print('   3. 지도를 드래그하여 올바른 낚시터 위치로 이동');
      
      // 4. 올바른 위치에서 탭하여 완료
      const correctLat = 35.1796; // 올바른 낚시터 위치
      const correctLng = 129.0756;
      provider.updateMarkerPosition(markerId, correctLat, correctLng);
      
      print('   4. 올바른 위치에서 탭하여 드래그 완료');
      
      // 5. 결과 확인
      final finalMarker = provider.customMarkers.first;
      expect(finalMarker['lat'], correctLat);
      expect(finalMarker['lng'], correctLng);
      expect(finalMarker['memo'], '좋은 낚시터');
      
      print('   5. 최종 결과 확인:');
      print('      위치: 위도=$correctLat, 경도=$correctLng');
      print('      메모: ${finalMarker['memo']}');
      print('   ✅ 마커 드래그 이동 시나리오 완벽 성공! 🎯');
    });
  });
}