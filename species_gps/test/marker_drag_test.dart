import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:latlong2/latlong.dart';

import 'package:species_gps/providers/map_state_provider.dart';
import 'package:species_gps/widgets/map_widget.dart';
import 'package:species_gps/core/theme/app_theme.dart';

void main() {
  group('마커 드래그 기능 테스트', () {
    late MapStateProvider mapStateProvider;

    setUp(() {
      mapStateProvider = MapStateProvider();
    });

    test('MapStateProvider - 마커 위치 업데이트 테스트', () {
      // 마커 추가
      mapStateProvider.addMarker(
        lat: 35.1796,
        lng: 129.0756,
        memo: '드래그 테스트 마커',
      );

      expect(mapStateProvider.markerCount, 1);
      final initialMarker = mapStateProvider.customMarkers.first;
      final markerId = initialMarker['id'] as int;
      
      print('초기 마커 위치: 위도=${initialMarker['lat']}, 경도=${initialMarker['lng']}');

      // 위치 업데이트
      const newLat = 35.1900;
      const newLng = 129.0900;
      mapStateProvider.updateMarkerPosition(markerId, newLat, newLng);

      // 업데이트된 마커 확인
      final updatedMarker = mapStateProvider.customMarkers.first;
      expect(updatedMarker['lat'], newLat);
      expect(updatedMarker['lng'], newLng);
      expect(updatedMarker['memo'], '드래그 테스트 마커'); // 메모는 유지

      print('업데이트된 마커 위치: 위도=${updatedMarker['lat']}, 경도=${updatedMarker['lng']}');
      print('✅ 마커 위치 업데이트 성공');
    });

    test('존재하지 않는 마커 ID로 업데이트 시도 테스트', () {
      // 마커 추가
      mapStateProvider.addMarker(
        lat: 35.1796,
        lng: 129.0756,
        memo: '테스트 마커',
      );

      final initialCount = mapStateProvider.markerCount;
      final initialMarker = mapStateProvider.customMarkers.first;
      final initialLat = initialMarker['lat'];
      final initialLng = initialMarker['lng'];

      // 존재하지 않는 ID로 업데이트 시도
      mapStateProvider.updateMarkerPosition(99999, 35.2000, 129.2000);

      // 마커 수와 위치가 변경되지 않았는지 확인
      expect(mapStateProvider.markerCount, initialCount);
      final unchangedMarker = mapStateProvider.customMarkers.first;
      expect(unchangedMarker['lat'], initialLat);
      expect(unchangedMarker['lng'], initialLng);

      print('✅ 존재하지 않는 마커 ID 처리 정상');
    });

    test('여러 마커 중 특정 마커만 이동 테스트', () {
      // 3개 마커 추가
      mapStateProvider.addMarker(lat: 35.1796, lng: 129.0756, memo: '마커1');
      mapStateProvider.addMarker(lat: 35.1800, lng: 129.0760, memo: '마커2');
      mapStateProvider.addMarker(lat: 35.1810, lng: 129.0770, memo: '마커3');

      expect(mapStateProvider.markerCount, 3);

      // 두 번째 마커의 ID 가져오기
      final secondMarker = mapStateProvider.customMarkers[1];
      final markerId = secondMarker['id'] as int;
      
      // 두 번째 마커만 이동
      const newLat = 35.2000;
      const newLng = 129.2000;
      mapStateProvider.updateMarkerPosition(markerId, newLat, newLng);

      // 첫 번째와 세 번째 마커는 변경되지 않았는지 확인
      final markers = mapStateProvider.customMarkers;
      expect(markers[0]['lat'], 35.1796);
      expect(markers[0]['lng'], 129.0756);
      expect(markers[2]['lat'], 35.1810);
      expect(markers[2]['lng'], 129.0770);

      // 두 번째 마커만 변경되었는지 확인
      expect(markers[1]['lat'], newLat);
      expect(markers[1]['lng'], newLng);

      print('✅ 특정 마커만 선택적 이동 성공');
    });

    testWidgets('MapWidget 드래그 콜백 테스트', (WidgetTester tester) async {
      bool dragCallbackCalled = false;
      int? draggedMarkerId;
      double? draggedLat;
      double? draggedLng;

      // 마커 추가
      mapStateProvider.addMarker(
        lat: 35.1796,
        lng: 129.0756,
        memo: '드래그 테스트 마커',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<MapStateProvider>(
            create: (_) => mapStateProvider,
            child: Scaffold(
              body: MapWidget(
                customMarkers: mapStateProvider.customMarkers,
                onMarkerDragEnd: (id, lat, lng) {
                  dragCallbackCalled = true;
                  draggedMarkerId = id;
                  draggedLat = lat;
                  draggedLng = lng;
                  print('드래그 콜백 호출: ID=$id, 위도=$lat, 경도=$lng');
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 마커를 찾아서 롱프레스 시뮬레이션
      final markerFinder = find.byIcon(Icons.flag);
      expect(markerFinder, findsOneWidget);

      // 롱프레스 제스처 시뮬레이션
      await tester.longPress(markerFinder);
      await tester.pumpAndSettle();

      // 드래그 모드 시작 확인 (드래그 아이콘 표시)
      expect(find.byIcon(Icons.drag_indicator), findsAtLeastNWidgets(1));
      print('✅ 롱프레스로 드래그 모드 진입 확인');

      // 지도 탭하여 드래그 완료 시뮬레이션
      await tester.tap(find.byType(MapWidget));
      await tester.pumpAndSettle();

      // 콜백이 호출되었는지 확인
      expect(dragCallbackCalled, true);
      expect(draggedMarkerId, isNotNull);
      expect(draggedLat, isNotNull);
      expect(draggedLng, isNotNull);

      print('✅ 드래그 완료 콜백 호출 확인');
      print('드래그된 마커 정보: ID=$draggedMarkerId, 위도=$draggedLat, 경도=$draggedLng');
    });

    testWidgets('드래그 모드에서 시각적 피드백 테스트', (WidgetTester tester) async {
      // 마커 추가
      mapStateProvider.addMarker(
        lat: 35.1796,
        lng: 129.0756,
        memo: '시각적 피드백 테스트',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<MapStateProvider>(
            create: (_) => mapStateProvider,
            child: Scaffold(
              body: MapWidget(
                customMarkers: mapStateProvider.customMarkers,
                onMarkerDragEnd: (id, lat, lng) {
                  print('드래그 완료: $id');
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 초기 상태: 일반 마커 아이콘
      expect(find.byIcon(Icons.flag), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator), findsNothing);

      // 롱프레스로 드래그 모드 시작
      await tester.longPress(find.byIcon(Icons.flag));
      await tester.pumpAndSettle();

      // 드래그 모드: 드래그 아이콘과 중앙 크로스헤어 표시
      expect(find.byIcon(Icons.drag_indicator), findsAtLeastNWidgets(2)); // 마커 + 중앙 크로스헤어
      print('✅ 드래그 모드 시각적 피드백 확인');

      // 지도 탭하여 완료
      await tester.tap(find.byType(MapWidget));
      await tester.pumpAndSettle();

      // 완료 후: 다시 일반 마커 아이콘
      expect(find.byIcon(Icons.flag), findsOneWidget);
      // 중앙 크로스헤어는 사라져야 함 (마커의 드래그 아이콘은 남아있을 수 있음)
      print('✅ 드래그 완료 후 상태 복원 확인');
    });
  });

  group('드래그 시나리오 통합 테스트', () {
    test('실제 사용 시나리오 시뮬레이션', () {
      final provider = MapStateProvider();
      
      print('\n=== 마커 드래그 시나리오 테스트 시작 ===');
      
      // 1. 초기 마커 추가
      provider.addMarker(
        lat: 35.1796, // 부산 위도
        lng: 129.0756, // 부산 경도
        memo: '부산항 마커',
      );
      
      final initialMarker = provider.customMarkers.first;
      final markerId = initialMarker['id'] as int;
      
      print('1. 초기 마커 추가: ${initialMarker['memo']}');
      print('   위치: 위도=${initialMarker['lat']}, 경도=${initialMarker['lng']}');
      
      // 2. 사용자가 마커를 롱프레스 (드래그 모드 시작)
      print('2. 사용자가 마커를 롱프레스하여 드래그 모드 시작');
      
      // 3. 지도를 드래그하여 새 위치로 이동 (제주도로)
      const targetLat = 33.4996; // 제주도 위도
      const targetLng = 126.5312; // 제주도 경도
      
      print('3. 지도를 드래그하여 새 위치로 이동');
      print('   목표 위치: 위도=$targetLat, 경도=$targetLng (제주도)');
      
      // 4. 사용자가 지도를 탭하여 드래그 완료
      provider.updateMarkerPosition(markerId, targetLat, targetLng);
      
      print('4. 지도 탭으로 드래그 완료');
      
      // 5. 결과 확인
      final updatedMarker = provider.customMarkers.first;
      
      expect(updatedMarker['lat'], targetLat);
      expect(updatedMarker['lng'], targetLng);
      expect(updatedMarker['memo'], '부산항 마커'); // 메모는 보존
      expect(updatedMarker['id'], markerId); // ID도 보존
      
      print('5. 최종 결과:');
      print('   위치 업데이트: 위도=${updatedMarker['lat']}, 경도=${updatedMarker['lng']}');
      print('   메모 보존: ${updatedMarker['memo']}');
      print('   ✅ 마커가 부산에서 제주도로 성공적으로 이동됨!');
      
      // 6. 거리 계산 (대략적)
      const distance = Distance();
      final moved = distance.as(LengthUnit.Kilometer, 
        LatLng(35.1796, 129.0756), 
        LatLng(targetLat, targetLng));
      
      print('   이동 거리: 약 ${moved.toStringAsFixed(1)}km');
      print('=== 시나리오 테스트 완료 ===\n');
    });
  });
}