import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import '../providers/app_state_provider.dart';
import '../models/fishing_record.dart';
import '../widgets/map_widget.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/date_formatter.dart';

/// 데이터 분석 화면 - 시간별, 어종별 분포 시각화
class DataAnalysisScreen extends StatefulWidget {
  const DataAnalysisScreen({super.key});

  @override
  State<DataAnalysisScreen> createState() => _DataAnalysisScreenState();
}

class _DataAnalysisScreenState extends State<DataAnalysisScreen> {
  // 필터 옵션
  String? _selectedSpecies;
  DateTimeRange? _selectedDateRange;
  bool _showHeatmap = false;
  bool _showClusters = true;
  
  // 지도 컨트롤러
  final MapController _mapController = MapController();
  
  @override
  void initState() {
    super.initState();
    // 모든 기록 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStateProvider>().loadRecords();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('데이터 분석'),
        backgroundColor: AppColors.primaryBlue,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
            tooltip: '필터',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (value == 'heatmap') {
                  _showHeatmap = !_showHeatmap;
                } else if (value == 'cluster') {
                  _showClusters = !_showClusters;
                }
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'heatmap',
                child: Row(
                  children: [
                    Icon(
                      _showHeatmap ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('히트맵 표시'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'cluster',
                child: Row(
                  children: [
                    Icon(
                      _showClusters ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('클러스터링'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          // 필터링된 데이터
          List<FishingRecord> filteredRecords = _filterRecords(provider.records);
          
          // 통계 계산
          Map<String, int> speciesStats = _calculateSpeciesStats(filteredRecords);
          
          return Column(
            children: [
              // 상단 통계 패널
              Container(
                height: 120,
                color: AppColors.background,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  itemCount: speciesStats.length,
                  itemBuilder: (context, index) {
                    final entry = speciesStats.entries.elementAt(index);
                    return _buildStatCard(entry.key, entry.value, filteredRecords.length);
                  },
                ),
              ),
              
              // 지도
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(35.1796, 129.0756), // 부산
                        initialZoom: 7.0, // 한국 전체가 보이는 줌 레벨
                      ),
                      children: [
                        // 타일 레이어
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.species_gps',
                        ),
                        
                        // 히트맵 레이어 (구현 필요)
                        if (_showHeatmap)
                          _buildHeatmapLayer(filteredRecords),
                        
                        // 클러스터 마커 레이어
                        if (_showClusters)
                          MarkerClusterLayerWidget(
                            options: MarkerClusterLayerOptions(
                              maxClusterRadius: 80,
                              size: const Size(40, 40),
                              markers: _buildMarkers(filteredRecords),
                              builder: (context, markers) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      markers.length.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          MarkerLayer(markers: _buildMarkers(filteredRecords)),
                      ],
                    ),
                    
                    // 타임라인 슬라이더
                    if (_selectedDateRange != null)
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: _buildTimelineSlider(),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // 통계 카드 위젯
  Widget _buildStatCard(String species, int count, int total) {
    final percentage = (count / total * 100).toStringAsFixed(1);
    
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            species,
            style: AppTextStyles.labelLarge,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.primaryBlue,
            ),
          ),
          Text(
            '$percentage%',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
  
  // 마커 생성
  List<Marker> _buildMarkers(List<FishingRecord> records) {
    return records.map((record) {
      return Marker(
        point: LatLng(record.latitude, record.longitude),
        width: 35,
        height: 35,
        child: GestureDetector(
          onTap: () => _showRecordDetails(record),
          child: Container(
            decoration: BoxDecoration(
              color: _getSpeciesColor(record.species),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.location_on,
              color: AppColors.white,
              size: 18,
            ),
          ),
        ),
      );
    }).toList();
  }
  
  // 히트맵 레이어 (임시)
  Widget _buildHeatmapLayer(List<FishingRecord> records) {
    // TODO: flutter_map_heatmap 패키지 사용하여 구현
    return Container();
  }
  
  // 타임라인 슬라이더
  Widget _buildTimelineSlider() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '기간: ${DateFormatter.formatDate(_selectedDateRange!.start)} ~ ${DateFormatter.formatDate(_selectedDateRange!.end)}',
            style: AppTextStyles.labelMedium,
          ),
          // TODO: 실제 슬라이더 구현
        ],
      ),
    );
  }
  
  // 필터 다이얼로그
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('데이터 필터'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 어종 선택
              DropdownButtonFormField<String>(
                value: _selectedSpecies,
                decoration: const InputDecoration(
                  labelText: '어종 선택',
                  border: OutlineInputBorder(),
                ),
                items: _getSpeciesList().map((species) {
                  return DropdownMenuItem(
                    value: species,
                    child: Text(species),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSpecies = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // 날짜 범위 선택
              ElevatedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _selectedDateRange == null
                      ? '날짜 범위 선택'
                      : '${DateFormatter.formatDate(_selectedDateRange!.start)} ~ ${DateFormatter.formatDate(_selectedDateRange!.end)}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedSpecies = null;
                  _selectedDateRange = null;
                });
                Navigator.pop(context);
              },
              child: const Text('초기화'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('적용'),
            ),
          ],
        );
      },
    );
  }
  
  // 날짜 범위 선택
  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }
  
  // 기록 필터링
  List<FishingRecord> _filterRecords(List<FishingRecord> records) {
    List<FishingRecord> filtered = records;
    
    // 어종 필터
    if (_selectedSpecies != null) {
      filtered = filtered.where((r) => r.species == _selectedSpecies).toList();
    }
    
    // 날짜 필터
    if (_selectedDateRange != null) {
      filtered = filtered.where((r) {
        return r.timestamp.isAfter(_selectedDateRange!.start) &&
               r.timestamp.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }
    
    return filtered;
  }
  
  // 어종별 통계 계산
  Map<String, int> _calculateSpeciesStats(List<FishingRecord> records) {
    final stats = <String, int>{};
    for (final record in records) {
      stats[record.species] = (stats[record.species] ?? 0) + record.count;
    }
    return stats;
  }
  
  // 어종별 색상
  Color _getSpeciesColor(String species) {
    final colors = [
      AppColors.primaryBlue,
      AppColors.secondaryGreen,
      AppColors.warning,
      AppColors.error,
      AppColors.info,
    ];
    return colors[species.hashCode % colors.length];
  }
  
  // 어종 목록 가져오기
  List<String> _getSpeciesList() {
    final provider = context.read<AppStateProvider>();
    return provider.records.map((r) => r.species).toSet().toList()..sort();
  }
  
  // 기록 상세 보기
  void _showRecordDetails(FishingRecord record) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.species,
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('수량: ${record.count}'),
              Text('위치: ${record.location}'),
              Text('시간: ${DateFormatter.formatDateTime(record.timestamp)}'),
              if (record.notes != null) Text('메모: ${record.notes}'),
            ],
          ),
        );
      },
    );
  }
}