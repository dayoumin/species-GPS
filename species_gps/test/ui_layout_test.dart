import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:species_gps/screens/home_screen_v2.dart';
import 'package:species_gps/providers/app_state_provider.dart';
import 'package:species_gps/services/storage_service.dart';
import 'package:species_gps/models/fishing_record.dart';
import 'package:species_gps/models/marine_category.dart';

void main() {
  group('홈 화면 UI 레이아웃 테스트', () {
    setUp(() async {
      // 스토리지 초기화
      await StorageService.init();
      await StorageService.deleteAllRecords();
    });

    testWidgets('오늘 기록 카드가 항상 표시되는지 확인', (WidgetTester tester) async {
      // Given: 오늘 기록이 없는 상태
      final provider = AppStateProvider();
      
      // When: 홈 화면 렌더링
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: provider,
            child: const HomeScreenV2(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 오늘 기록 카드가 존재하고 0을 표시
      expect(find.text('오늘 기록'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      
      print('✅ 오늘 기록이 없을 때: 카드 표시됨, 값은 0');
    });

    testWidgets('오늘 기록이 있을 때 정확한 개수 표시', (WidgetTester tester) async {
      // Given: 오늘 기록 2개 추가
      final today = DateTime.now();
      await StorageService.addRecord(
        FishingRecord(
          category: MarineCategory.fish,
          species: '고등어',
          count: 5,
          latitude: 35.1796,
          longitude: 129.0756,
          timestamp: today,
        ),
      );
      await StorageService.addRecord(
        FishingRecord(
          category: MarineCategory.mollusk,
          species: '전복',
          count: 3,
          latitude: 35.1800,
          longitude: 129.0760,
          timestamp: today,
        ),
      );

      final provider = AppStateProvider();
      await provider.loadRecords();
      
      // When: 홈 화면 렌더링
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: provider,
            child: const HomeScreenV2(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 오늘 기록 개수가 정확히 표시
      expect(find.text('오늘 기록'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 2개 기록
      expect(find.text('8'), findsOneWidget); // 전체 개수 (5+3)
      
      print('✅ 오늘 기록 2개 있을 때: 정확한 개수 표시');
    });

    testWidgets('카드들의 좌우 여백 일치 확인', (WidgetTester tester) async {
      // Given: 샘플 데이터로 자원별 통계 생성
      await StorageService.addSampleData();
      final provider = AppStateProvider();
      await provider.loadRecords();
      
      // When: 홈 화면 렌더링
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: provider,
            child: const HomeScreenV2(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 각 위젯의 위치와 크기 확인
      // GPS 상태 카드 찾기
      final gpsCard = find.byType(Card).first;
      final gpsCardWidget = tester.widget<Card>(gpsCard);
      final gpsCardRenderBox = tester.renderObject(gpsCard) as RenderBox;
      final gpsCardPosition = gpsCardRenderBox.localToGlobal(Offset.zero);
      
      print('\n📏 위젯 좌우 여백 측정:');
      print('GPS 카드 - X: ${gpsCardPosition.dx}, 너비: ${gpsCardRenderBox.size.width}');
      
      // 통계 카드들 찾기
      final statCards = find.byType(Container).evaluate().where((element) {
        final widget = element.widget as Container;
        return widget.decoration != null && 
               widget.decoration is BoxDecoration &&
               (widget.decoration as BoxDecoration).border != null;
      }).toList();
      
      if (statCards.length >= 2) {
        // 오늘 기록 카드
        final todayCard = statCards[0];
        final todayRenderBox = todayCard.renderObject as RenderBox;
        final todayPosition = todayRenderBox.localToGlobal(Offset.zero);
        print('오늘 기록 카드 - X: ${todayPosition.dx}, 너비: ${todayRenderBox.size.width}');
        
        // 전체 기록 카드
        final totalCard = statCards[1];
        final totalRenderBox = totalCard.renderObject as RenderBox;
        final totalPosition = totalRenderBox.localToGlobal(Offset.zero);
        print('전체 기록 카드 - X: ${totalPosition.dx}, 너비: ${totalRenderBox.size.width}');
      }
      
      // 자원별 통계 카드 찾기 (InfoCard)
      final infoCards = find.byType(Card).evaluate().where((element) {
        final card = element.widget as Card;
        return card.margin == EdgeInsets.zero; // InfoCard는 margin이 0
      }).toList();
      
      if (infoCards.isNotEmpty) {
        final resourceCard = infoCards.first;
        final resourceRenderBox = resourceCard.renderObject as RenderBox;
        final resourcePosition = resourceRenderBox.localToGlobal(Offset.zero);
        print('자원별 통계 카드 - X: ${resourcePosition.dx}, 너비: ${resourceRenderBox.size.width}');
        
        // 좌우 여백 일치 확인
        expect(resourcePosition.dx, equals(gpsCardPosition.dx),
          reason: '자원별 통계 카드의 왼쪽 여백이 GPS 카드와 일치해야 함');
        expect(resourceRenderBox.size.width, equals(gpsCardRenderBox.size.width),
          reason: '자원별 통계 카드의 너비가 GPS 카드와 일치해야 함');
        
        print('\n✅ 자원별 통계 카드 좌우 여백이 다른 카드와 일치함');
      }
      
      // 작업 기록 버튼들 확인
      final actionButtons = find.byType(InkWell).evaluate().where((element) {
        final parent = element.widget.runtimeType.toString();
        return parent.contains('Material');
      }).toList();
      
      if (actionButtons.length >= 2) {
        final addButton = actionButtons[0];
        final addRenderBox = addButton.renderObject as RenderBox;
        final addPosition = addRenderBox.localToGlobal(Offset.zero);
        print('\n새 기록 추가 버튼 - X: ${addPosition.dx}, 너비: ${addRenderBox.size.width}');
        
        final listButton = actionButtons[1];
        final listRenderBox = listButton.renderObject as RenderBox;
        final listPosition = listRenderBox.localToGlobal(Offset.zero);
        print('기록 조회 버튼 - X: ${listPosition.dx}, 너비: ${listRenderBox.size.width}');
      }
    });

    test('오늘 날짜 필터링 로직 검증', () async {
      // Given: 다양한 날짜의 기록
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));
      
      await StorageService.deleteAllRecords();
      
      // 어제 기록
      await StorageService.addRecord(
        FishingRecord(
          category: MarineCategory.fish,
          species: '어제_고등어',
          count: 1,
          latitude: 35.0,
          longitude: 129.0,
          timestamp: yesterday.add(const Duration(hours: 12)),
        ),
      );
      
      // 오늘 자정
      await StorageService.addRecord(
        FishingRecord(
          category: MarineCategory.fish,
          species: '오늘_자정',
          count: 1,
          latitude: 35.0,
          longitude: 129.0,
          timestamp: today,
        ),
      );
      
      // 오늘 낮
      await StorageService.addRecord(
        FishingRecord(
          category: MarineCategory.fish,
          species: '오늘_낮',
          count: 1,
          latitude: 35.0,
          longitude: 129.0,
          timestamp: today.add(const Duration(hours: 12)),
        ),
      );
      
      // 오늘 23:59
      await StorageService.addRecord(
        FishingRecord(
          category: MarineCategory.fish,
          species: '오늘_마지막',
          count: 1,
          latitude: 35.0,
          longitude: 129.0,
          timestamp: today.add(const Duration(hours: 23, minutes: 59)),
        ),
      );
      
      // When: Provider에서 오늘 기록 로드
      final provider = AppStateProvider();
      await provider.loadRecords();
      
      // Then: 오늘 기록만 카운트
      expect(provider.todayRecordCount, equals(3)); // 오늘 자정, 낮, 마지막
      expect(provider.totalRecords, equals(4)); // 전체 4개
      
      print('\n✅ 오늘 날짜 필터링 정확함:');
      print('  - 어제: 제외됨');
      print('  - 오늘 자정: 포함됨');
      print('  - 오늘 낮: 포함됨');
      print('  - 오늘 23:59: 포함됨');
      print('  - 오늘 기록: ${provider.todayRecordCount}개');
      print('  - 전체 기록: ${provider.totalRecords}개');
    });
  });
}