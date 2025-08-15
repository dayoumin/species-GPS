import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/permission_service.dart';
import '../services/storage_service.dart';
import 'add_record_screen.dart';
import 'records_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? _currentPosition;
  int _totalRecords = 0;
  Map<String, int> _speciesCount = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 권한 확인
    await PermissionService.checkAllPermissions();
    
    // 위치 가져오기
    _currentPosition = await LocationService.getCurrentPosition();
    
    // 데이터베이스 통계 가져오기
    _totalRecords = await StorageService.getTotalCount();
    _speciesCount = await StorageService.getSpeciesCount();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('수산생명자원 GPS'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // GPS 상태 카드
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: _currentPosition != null
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'GPS 상태',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_currentPosition != null) ...[
                            Text('위도: ${_currentPosition!.latitude.toStringAsFixed(6)}'),
                            Text('경도: ${_currentPosition!.longitude.toStringAsFixed(6)}'),
                            Text('정확도: ${_currentPosition!.accuracy.toStringAsFixed(1)}m'),
                          ] else
                            const Text('위치 정보를 가져올 수 없습니다'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 오늘의 기록 요약
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '기록 요약',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('총 기록 수: $_totalRecords'),
                          const SizedBox(height: 4),
                          if (_speciesCount.isNotEmpty) ...[
                            const Text('어종별 개체수:'),
                            ..._speciesCount.entries.map((entry) => 
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Text('${entry.key}: ${entry.value}마리'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // 빠른 기록 버튼들
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddRecordScreen(
                            mode: RecordMode.camera,
                          ),
                        ),
                      );
                      if (result == true) {
                        _initialize(); // 화면 새로고침
                      }
                    },
                    icon: const Icon(Icons.camera_alt, size: 32),
                    label: const Text(
                      '사진으로 빠른 기록',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddRecordScreen(
                            mode: RecordMode.detailed,
                          ),
                        ),
                      );
                      if (result == true) {
                        _initialize(); // 화면 새로고침
                      }
                    },
                    icon: const Icon(Icons.edit, size: 32),
                    label: const Text(
                      '상세 기록 입력',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecordsListScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list, size: 32),
                    label: const Text(
                      '기록 조회',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}