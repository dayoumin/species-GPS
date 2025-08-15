import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state_provider.dart';
import 'services/storage_service.dart';
import 'models/fishing_record.dart';
import 'models/marine_category.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 스토리지 초기화
  await StorageService.init();
  
  // 기존 데이터 삭제
  await StorageService.deleteAllRecords();
  
  // 테스트 데이터 추가
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  
  print('📅 테스트 시작: ${now.toString()}');
  print('오늘 날짜: ${today.toString()}');
  print('어제 날짜: ${yesterday.toString()}\n');
  
  // 어제 기록 추가
  await StorageService.addRecord(
    FishingRecord(
      category: MarineCategory.fish,
      species: '어제_고등어',
      count: 5,
      latitude: 35.1796,
      longitude: 129.0756,
      timestamp: yesterday.add(const Duration(hours: 15)),
    ),
  );
  print('✅ 어제 기록 추가: 어제_고등어 (${yesterday.add(const Duration(hours: 15))})');
  
  // 오늘 새벽 기록
  await StorageService.addRecord(
    FishingRecord(
      category: MarineCategory.mollusk,
      species: '오늘_새벽_전복',
      count: 3,
      latitude: 35.1800,
      longitude: 129.0760,
      timestamp: today.add(const Duration(hours: 3)),
    ),
  );
  print('✅ 오늘 새벽 기록 추가: 오늘_새벽_전복 (${today.add(const Duration(hours: 3))})');
  
  // 오늘 오후 기록
  await StorageService.addRecord(
    FishingRecord(
      category: MarineCategory.cephalopod,
      species: '오늘_오후_오징어',
      count: 10,
      latitude: 35.1810,
      longitude: 129.0770,
      timestamp: today.add(const Duration(hours: 14)),
    ),
  );
  print('✅ 오늘 오후 기록 추가: 오늘_오후_오징어 (${today.add(const Duration(hours: 14))})');
  
  // 오늘 저녁 기록
  await StorageService.addRecord(
    FishingRecord(
      category: MarineCategory.crustacean,
      species: '오늘_저녁_꽃게',
      count: 7,
      latitude: 35.1820,
      longitude: 129.0780,
      timestamp: today.add(const Duration(hours: 20)),
    ),
  );
  print('✅ 오늘 저녁 기록 추가: 오늘_저녁_꽃게 (${today.add(const Duration(hours: 20))})\n');
  
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStateProvider()..loadRecords(),
      child: MaterialApp(
        title: '오늘 기록 테스트',
        home: TestScreen(),
      ),
    );
  }
}

class TestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘 기록 및 UI 여백 테스트'),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📊 기록 통계', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Text('오늘 기록: ${provider.todayRecordCount}개', style: TextStyle(fontSize: 16, color: provider.todayRecordCount > 0 ? Colors.green : Colors.grey)),
                        Text('전체 기록: ${provider.totalRecords}개', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📝 전체 기록 목록', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        FutureBuilder<List<FishingRecord>>(
                          future: StorageService.getRecords(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return CircularProgressIndicator();
                            
                            final records = snapshot.data!;
                            return Column(
                              children: records.map((record) {
                                final isToday = record.timestamp.year == today.year &&
                                               record.timestamp.month == today.month &&
                                               record.timestamp.day == today.day;
                                               
                                return Container(
                                  margin: EdgeInsets.symmetric(vertical: 4),
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isToday ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isToday ? Colors.green : Colors.grey,
                                      width: isToday ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isToday ? Icons.today : Icons.calendar_today,
                                        color: isToday ? Colors.green : Colors.grey,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${record.category.korean} - ${record.species} (${record.count}마리)',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              '${record.timestamp.toString().substring(0, 19)}',
                                              style: TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                            if (isToday)
                                              Text(
                                                '✅ 오늘 기록',
                                                style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // UI 여백 테스트용 카드들
                Text('📐 UI 여백 일치 테스트', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                
                // GPS 상태 카드 스타일
                Card(
                  elevation: 2,
                  margin: EdgeInsets.zero,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Text('GPS 상태 카드 (기준)'),
                  ),
                ),
                
                SizedBox(height: 10),
                
                // 통계 카드 스타일 (Row)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Text('오늘 기록'),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Text('전체 기록'),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 10),
                
                // InfoCard 스타일 (자원별 통계)
                Card(
                  elevation: 2,
                  margin: EdgeInsets.zero, // InfoCard와 동일
                  child: Container(
                    padding: EdgeInsets.all(16), // paddingM과 동일
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('자원별 통계 (InfoCard)', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('좌우 여백이 위 카드들과 일치해야 함'),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // 여백 측정 결과
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('✅ 체크 사항:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Text('1. 오늘 기록이 0개가 아닌 3개로 표시되는지'),
                        Text('2. 녹색 테두리로 표시된 기록이 3개인지'),
                        Text('3. GPS 카드와 자원별 통계 카드의 좌우 여백이 일치하는지'),
                        Text('4. 모든 카드의 왼쪽 정렬이 동일한지'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}