import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../providers/app_state_provider.dart';
import '../providers/map_state_provider.dart';
import '../widgets/map_widget.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/date_formatter.dart';
import '../core/utils/ui_helpers.dart';

/// 지도 화면 - 현재 위치와 기록된 위치들을 지도에 표시
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _showRecords = true;
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  final MapController _mapController = MapController();
  final ScreenshotController _screenshotController = ScreenshotController();
  
  @override
  void initState() {
    super.initState();
    // 위치 스트림 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppStateProvider>();
      provider.startLocationStream();
      provider.loadRecords();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final mapState = context.watch<MapStateProvider>();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('위치 지도 (마커: ${mapState.markerCount}개)'),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        actions: [
          // 검색 토글
          IconButton(
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
              });
            },
            icon: const Icon(Icons.search),
            tooltip: '장소 검색',
          ),
          
          // 필터 메뉴 (기록 표시, 날짜)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'toggle_records') {
                setState(() {
                  _showRecords = !_showRecords;
                });
              } else if (value == 'select_date') {
                _showDatePicker();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_records',
                child: Row(
                  children: [
                    Icon(
                      _showRecords ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(_showRecords ? '기록 숨기기' : '기록 표시'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'select_date',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20),
                    SizedBox(width: 8),
                    Text('날짜 선택'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.filter_list),
            tooltip: '필터',
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          final records = _selectedDate != null
              ? provider.getFilteredRecords(date: _selectedDate)
              : provider.records;
          
          return Stack(
            children: [
              // 지도 - Screenshot으로 감싸기
              Screenshot(
                controller: _screenshotController,
                child: MapWidget(
                  currentPosition: provider.currentPosition,
                  records: _showRecords ? records : null,
                  showCurrentLocation: true,
                  showRecords: _showRecords,
                  mapController: _mapController,  // MapController 전달
                  customMarkers: mapState.customMarkers,  // Provider에서 마커 가져오기
                  onRecordTap: (record) {
                    _showRecordBottomSheet(record);
                  },
                  onMapTap: (lat, lng) {
                    // 지도를 탭했을 때 마커 추가
                    _addMarkerAtLocation(lat, lng);
                  },
                  onMarkerTap: (markerData) {
                    // 마커를 탭했을 때 수정 다이얼로그 열기
                    _addMarkerAtLocation(
                      markerData['lat'],
                      markerData['lng'],
                      existingMarker: markerData,
                    );
                  },
                  onMarkerDragEnd: (id, lat, lng) {
                    // 마커 드래그 완료 시 위치 업데이트
                    final mapState = context.read<MapStateProvider>();
                    mapState.updateMarkerPosition(id, lat, lng);
                  },
                ),
              ),
              
              // 상단 정보 패널
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 검색 바
                      if (_showSearch)
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.paddingM),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.divider,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: '장소를 검색하세요 (예: 부산항, 제주도)',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: AppDimensions.paddingM,
                                      vertical: AppDimensions.paddingS,
                                    ),
                                  ),
                                  onSubmitted: (value) => _searchLocation(value),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.paddingS),
                              IconButton(
                                onPressed: () => _searchLocation(_searchController.text),
                                icon: const Icon(Icons.search),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // 현재 위치 정보
                      if (provider.currentPosition != null)
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.paddingM),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppDimensions.paddingS),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                                ),
                                child: const Icon(
                                  Icons.my_location,
                                  color: AppColors.info,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.paddingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '현재 위치',
                                      style: AppTextStyles.labelMedium,
                                    ),
                                    Text(
                                      '위도: ${provider.currentPosition!.latitude.toStringAsFixed(6)}',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                    Text(
                                      '경도: ${provider.currentPosition!.longitude.toStringAsFixed(6)}',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (provider.currentPosition!.accuracy != null)
                                Chip(
                                  label: Text(
                                    '±${provider.currentPosition!.accuracy.toStringAsFixed(0)}m',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                  backgroundColor: AppColors.success.withOpacity(0.1),
                                  side: BorderSide.none,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                        ),
                      
                      // 필터 정보
                      if (_selectedDate != null || _showRecords)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingM,
                            vertical: AppDimensions.paddingS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.05),
                            border: Border(
                              top: BorderSide(
                                color: AppColors.divider,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (_selectedDate != null) ...[
                                Icon(
                                  Icons.filter_alt,
                                  size: 16,
                                  color: AppColors.primaryBlue,
                                ),
                                const SizedBox(width: AppDimensions.paddingXS),
                                Text(
                                  DateFormatter.formatDate(_selectedDate!),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.paddingS),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedDate = null;
                                    });
                                    context.read<AppStateProvider>().loadRecords();
                                  },
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: AppColors.error,
                                  ),
                                ),
                                const Spacer(),
                              ],
                              if (_showRecords && _selectedDate != null)
                                Text(
                                  '${records.length}개 기록',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // 로딩 인디케이터
              if (provider.isLocationLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
              
              // 하단 플로팅 버튼 그룹 - 아이콘만
              Positioned(
                bottom: 20,
                left: 20,
                child: Row(
                  children: [
                    // 마커 추가 버튼
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondaryGreen.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _addMarkerAtCurrentLocation,
                          child: const Icon(
                            Icons.add_location_alt,
                            color: AppColors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 공유 버튼
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.oceanGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _captureAndShare,
                          child: const Icon(
                            Icons.share,
                            color: AppColors.white,
                            size: 28,
                          ),
                        ),
                      ),
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
  
  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      if (mounted) {
        context.read<AppStateProvider>().loadRecords(
          startDate: picked,
          endDate: picked.add(const Duration(days: 1)),
        );
      }
    }
  }
  
  void _showRecordBottomSheet(record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.radiusL),
            topRight: Radius.circular(AppDimensions.radiusL),
          ),
        ),
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들 바
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            
            // 기록 정보
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Icon(
                    Icons.phishing,
                    color: AppColors.secondaryGreen,
                    size: 30,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.species ?? '기록',
                        style: AppTextStyles.headlineSmall,
                      ),
                      Text(
                        '수량: ${record.count}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingL),
            
            // 위치 정보
            _buildInfoRow(
              Icons.location_on,
              '위치',
              '${record.latitude.toStringAsFixed(6)}, ${record.longitude.toStringAsFixed(6)}',
            ),
            const SizedBox(height: AppDimensions.paddingM),
            
            // 시간 정보
            _buildInfoRow(
              Icons.access_time,
              '기록 시간',
              DateFormatter.formatFullDateTime(record.timestamp),
            ),
            
            // 메모
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.paddingM),
              _buildInfoRow(
                Icons.note,
                '메모',
                record.notes!,
              ),
            ],
            
            // 음성 메모
            if (record.audioPath != null) ...[
              const SizedBox(height: AppDimensions.paddingM),
              _buildInfoRow(
                Icons.mic,
                '음성 메모',
                '녹음 파일 있음',
              ),
            ],
            
            const SizedBox(height: AppDimensions.paddingL),
            
            // 액션 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // 상세 화면으로 이동
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('상세 보기'),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // 외부 지도에서 열기
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('지도에서 열기'),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppDimensions.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // 장소 검색 기능
  void _searchLocation(String query) {
    if (query.isEmpty) return;
    
    // 한국의 주요 항구와 낚시터 좌표
    final Map<String, LatLng> knownLocations = {
      '부산항': LatLng(35.1028, 129.0403),
      '부산': LatLng(35.1796, 129.0756),
      '제주도': LatLng(33.4996, 126.5312),
      '제주': LatLng(33.4996, 126.5312),
      '서귀포': LatLng(33.2541, 126.5601),
      '인천항': LatLng(37.4563, 126.7052),
      '인천': LatLng(37.4563, 126.7052),
      '평택항': LatLng(36.9665, 126.8227),
      '평택': LatLng(36.9665, 126.8227),
      '목포': LatLng(34.7936, 126.3886),
      '목포항': LatLng(34.7936, 126.3886),
      '여수': LatLng(34.7604, 127.6622),
      '여수항': LatLng(34.7604, 127.6622),
      '통영': LatLng(34.8544, 128.4330),
      '통영항': LatLng(34.8544, 128.4330),
      '포항': LatLng(36.0190, 129.3435),
      '포항항': LatLng(36.0190, 129.3435),
      '울산': LatLng(35.5384, 129.3114),
      '울산항': LatLng(35.5384, 129.3114),
      '강릉': LatLng(37.7519, 128.8760),
      '강릉항': LatLng(37.7519, 128.8760),
      '속초': LatLng(38.2070, 128.5918),
      '속초항': LatLng(38.2070, 128.5918),
      '동해': LatLng(37.5070, 129.1243),
      '동해항': LatLng(37.5070, 129.1243),
      '서해': LatLng(36.7667, 126.1333),
      '남해': LatLng(34.8378, 128.4347),
    };
    
    // 검색어를 소문자로 변환하여 비교
    final searchLower = query.toLowerCase();
    LatLng? targetLocation;
    
    // 알려진 위치에서 검색
    for (final entry in knownLocations.entries) {
      if (entry.key.contains(query) || query.contains(entry.key)) {
        targetLocation = entry.value;
        break;
      }
    }
    
    if (targetLocation != null) {
      // 지도를 해당 위치로 이동
      _mapController.move(targetLocation, 13.0);
      
      UIHelpers.showSnackBar(
        context,
        message: '$query(으)로 이동했습니다',
        type: SnackBarType.success,
      );
    } else {
      UIHelpers.showSnackBar(
        context,
        message: '"검색 결과를 찾을 수 없습니다. 한국의 주요 항구나 도시명을 입력해주세요"',
        type: SnackBarType.warning,
      );
    }
  }
  
  // 현재 위치에 마커 추가
  void _addMarkerAtCurrentLocation() {
    final provider = context.read<AppStateProvider>();
    
    if (provider.currentPosition == null) {
      UIHelpers.showSnackBar(
        context,
        message: 'GPS 위치를 확인할 수 없습니다',
        type: SnackBarType.warning,
      );
      return;
    }
    
    _addMarkerAtLocation(
      provider.currentPosition!.latitude,
      provider.currentPosition!.longitude,
    );
  }
  
  // 특정 위치에 마커 추가 또는 수정
  void _addMarkerAtLocation(double lat, double lng, {Map<String, dynamic>? existingMarker}) {
    final mapState = context.read<MapStateProvider>();
    final isEdit = existingMarker != null;
    
    // 간단한 메모 입력 다이얼로그
    showDialog(
      context: context,
      builder: (dialogContext) {
        final TextEditingController memoController = TextEditingController(
          text: isEdit ? (existingMarker['memo'] ?? '') : '',
        );
        
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          scrollable: true,  // 키보드가 올라왔을 때 스크롤 가능
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_location_alt,
                  color: AppColors.secondaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEdit ? '마커 수정' : '마커 추가',
                style: AppTextStyles.headlineSmall,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 위치 정보 카드
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '위도: ${lat.toStringAsFixed(6)}',
                            style: AppTextStyles.bodySmall,
                          ),
                          Text(
                            '경도: ${lng.toStringAsFixed(6)}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 메모 입력 필드
              TextField(
                controller: memoController,
                decoration: InputDecoration(
                  labelText: '메모 (선택)',
                  hintText: '예: 좋은 낚시터, 많이 잡힌 곳',
                  prefixIcon: const Icon(Icons.note_add),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
                maxLines: 2,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            Column(
              children: [
                // 수정 모드일 때 삭제 버튼을 별도 행으로
                if (isEdit) ...[
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        mapState.removeMarker(existingMarker['id']);
                        Navigator.pop(dialogContext);
                        UIHelpers.showSnackBar(
                          context,
                          message: '마커가 삭제되었습니다',
                          type: SnackBarType.info,
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          side: BorderSide(
                            color: AppColors.error,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '마커 삭제',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // 취소와 추가/수정 버튼
                Row(
                  children: [
                    // 취소 버튼
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                            side: BorderSide(
                              color: AppColors.divider,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          '취소',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // 저장/추가 버튼
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (isEdit) {
                            // 기존 마커 삭제 후 새로 추가 (수정)
                            mapState.removeMarker(existingMarker['id']);
                            mapState.addMarker(
                              lat: lat,
                              lng: lng,
                              memo: memoController.text.isEmpty ? null : memoController.text,
                            );
                            UIHelpers.showSnackBar(
                              context,
                              message: '마커가 수정되었습니다',
                              type: SnackBarType.success,
                            );
                          } else {
                            // 새 마커 추가
                            mapState.addMarker(
                              lat: lat,
                              lng: lng,
                              memo: memoController.text.isEmpty ? null : memoController.text,
                            );
                            UIHelpers.showSnackBar(
                              context,
                              message: '마커가 추가되었습니다 (총 ${mapState.markerCount + 1}개)',
                              type: SnackBarType.success,
                            );
                          }
                          
                          // 다이얼로그 닫기
                          Navigator.pop(dialogContext);
                          
                          // 마커 위치로 지도 이동
                          _mapController.move(LatLng(lat, lng), _mapController.camera.zoom);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          ),
                        ),
                        child: Text(
                          isEdit ? '수정' : '추가',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
  
  // 스크린샷 캡처 및 공유
  Future<void> _captureAndShare() async {
    try {
      // 스크린샷 캡처
      final Uint8List? image = await _screenshotController.capture(
        delay: const Duration(milliseconds: 100),
      );
      
      if (image != null) {
        // 웹에서는 직접 Blob으로 공유
        if (Theme.of(context).platform == TargetPlatform.android || 
            Theme.of(context).platform == TargetPlatform.iOS) {
          // 모바일: 파일로 저장 후 공유
          try {
            final directory = await getApplicationDocumentsDirectory();
            final imagePath = '${directory.path}/map_screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
            final imageFile = File(imagePath);
            await imageFile.writeAsBytes(image);
            
            await Share.shareXFiles(
              [XFile(imagePath)],
              text: '수산생명자원 GPS - ${_selectedDate != null ? DateFormatter.formatDate(_selectedDate!) : DateFormatter.formatDate(DateTime.now())} 기록',
              subject: '낚시 지도 공유',
            );
            
            // 임시 파일 삭제
            if (await imageFile.exists()) {
              await imageFile.delete();
            }
          } catch (e) {
            // 파일 저장 실패 시 바이트 배열로 직접 공유
            await Share.shareXFiles(
              [XFile.fromData(image, name: 'map_screenshot.png', mimeType: 'image/png')],
              text: '수산생명자원 GPS - 지도 캡처',
            );
          }
        } else {
          // 웹: 바이트 배열로 직접 공유
          await Share.shareXFiles(
            [XFile.fromData(image, name: 'map_screenshot.png', mimeType: 'image/png')],
            text: '수산생명자원 GPS - 지도 캡처',
          );
        }
      }
      
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          message: '지도가 캡처되었습니다',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          message: '캡처 실패: $e',
          type: SnackBarType.error,
        );
      }
    }
  }
}