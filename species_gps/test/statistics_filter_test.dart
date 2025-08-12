import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:species_gps/screens/records_list_screen_v2.dart';
import 'package:species_gps/providers/app_state_provider.dart';
import 'package:species_gps/models/fishing_record.dart';
import 'package:species_gps/core/theme/app_theme.dart';

void main() {
  group('통계 탭 기간별 필터 테스트', () {
    late AppStateProvider provider;

    setUp(() async {
      provider = AppStateProvider();
      // 테스트 데이터 추가
      await provider.addRecord(FishingRecord(
        species: '광어',
        count: 3,
        latitude: 35.1796,
        longitude: 129.0756,
        timestamp: DateTime.now().subtract(Duration(days: 1)),
      ));
      
      await provider.addRecord(FishingRecord(
        species: '우럭',
        count: 2,
        latitude: 35.1800,
        longitude: 129.0760,
        timestamp: DateTime.now().subtract(Duration(days: 5)),
      ));
      
      await provider.addRecord(FishingRecord(
        species: '광어',
        count: 1,
        latitude: 35.1810,
        longitude: 129.0770,
        timestamp: DateTime.now().subtract(Duration(days: 20)),
      ));
    });

    testWidgets('통계 탭에 기간 선택 UI가 표시되는지 테스트', (WidgetTester tester) async {
      print('\n🧪 테스트: 통계 탭 기간 선택 UI 확인');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AppStateProvider>(
            create: (_) => provider,
            child: const RecordsListScreenV2(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 통계 탭 클릭
      final statisticsTab = find.text('통계');
      expect(statisticsTab, findsOneWidget);
      
      await tester.tap(statisticsTab);
      await tester.pumpAndSettle();

      print('   1. 통계 탭으로 전환됨');

      // 기간 선택 헤더 찾기
      final periodHeader = find.text('기간:');
      expect(periodHeader, findsOneWidget);
      print('   ✅ 기간 헤더 발견');

      // ChoiceChip들이 있는지 확인
      final periodChips = ['전체', '주간', '월별', '분기', '년도'];
      for (final period in periodChips) {
        final chip = find.widgetWithText(ChoiceChip, period);
        expect(chip, findsOneWidget);
        print('   ✅ $period 선택 칩 발견');
      }

      // 스케줄 아이콘 확인
      final scheduleIcon = find.byIcon(Icons.schedule);
      expect(scheduleIcon, findsOneWidget);
      print('   ✅ 스케줄 아이콘 발견');

      print('   🎯 통계 탭 기간 선택 UI 모두 정상 표시됨!');
    });

    testWidgets('기간 선택시 통계가 업데이트되는지 테스트', (WidgetTester tester) async {
      print('\n🧪 테스트: 기간 선택시 통계 업데이트');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AppStateProvider>(
            create: (_) => provider,
            child: const RecordsListScreenV2(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 통계 탭으로 이동
      await tester.tap(find.text('통계'));
      await tester.pumpAndSettle();

      print('   1. 통계 탭으로 이동');

      // 전체 데이터 확인 (3개 기록)
      expect(find.text('3'), findsOneWidget); // 총 기록 수
      print('   2. 전체 기록 3개 확인');

      // 주간 선택
      final weeklyChip = find.widgetWithText(ChoiceChip, '주간');
      await tester.tap(weeklyChip);
      await tester.pumpAndSettle();

      print('   3. 주간 필터 선택');

      // 주간 데이터 확인 (최근 7일: 2개 기록)
      expect(find.text('2'), findsOneWidget); // 주간 기록 수
      print('   ✅ 주간 필터링 적용됨 (2개 기록)');

      // 월별 선택
      final monthlyChip = find.widgetWithText(ChoiceChip, '월별');
      await tester.tap(monthlyChip);
      await tester.pumpAndSettle();

      print('   4. 월별 필터 선택');
      print('   ✅ 기간별 필터링 동작 확인 완료!');
    });

    testWidgets('통계 탭 레이아웃 구조 확인', (WidgetTester tester) async {
      print('\n🧪 테스트: 통계 탭 레이아웃 구조');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AppStateProvider>(
            create: (_) => provider,
            child: const RecordsListScreenV2(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 통계 탭으로 이동
      await tester.tap(find.text('통계'));
      await tester.pumpAndSettle();

      // Column 위젯 구조 확인
      final columnWidget = find.byType(Column);
      expect(columnWidget, findsWidgets);
      print('   ✅ Column 레이아웃 발견');

      // Container with decoration 확인 (헤더)
      final headerContainer = find.byWidgetPredicate(
        (widget) => 
          widget is Container && 
          widget.decoration != null &&
          widget.padding == const EdgeInsets.all(16.0),
      );
      expect(headerContainer, findsOneWidget);
      print('   ✅ 기간 선택 헤더 컨테이너 발견');

      // Expanded 위젯 확인 (통계 내용)
      final expandedWidget = find.byType(Expanded);
      expect(expandedWidget, findsWidgets);
      print('   ✅ Expanded 위젯으로 통계 내용 영역 확인');

      print('   🎯 통계 탭 레이아웃 구조 정상!');
    });
  });

  group('다운로드 버튼 테스트', () {
    testWidgets('다운로드 버튼 UI 확인', (WidgetTester tester) async {
      print('\n🧪 테스트: 다운로드 버튼 UI');

      final provider = AppStateProvider();
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AppStateProvider>(
            create: (_) => provider,
            child: const RecordsListScreenV2(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 다운로드 아이콘 버튼 확인
      final downloadButton = find.byIcon(Icons.download);
      expect(downloadButton, findsOneWidget);
      print('   ✅ 다운로드 아이콘 버튼 발견');

      // 다운로드 버튼 클릭
      await tester.tap(downloadButton);
      await tester.pumpAndSettle();

      // 바텀시트 확인
      expect(find.text('CSV로 내보내기'), findsOneWidget);
      expect(find.text('PDF로 내보내기'), findsOneWidget);
      print('   ✅ 다운로드 옵션 바텀시트 표시됨');

      print('   🎯 다운로드 버튼 기능 정상!');
    });
  });
}