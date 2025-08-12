import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/date_formatter.dart';
import '../models/fishing_record.dart';
import '../providers/map_state_provider.dart';

/// 지도 위젯 - 현재 위치 및 기록 위치 표시
class MapWidget extends StatefulWidget {
  final Position? currentPosition;
  final List<FishingRecord>? records;
  final bool showCurrentLocation;
  final bool showRecords;
  final double initialZoom;
  final Function(FishingRecord)? onRecordTap;
  final MapController? mapController;  // 외부에서 전달받을 수 있도록 추가
  final List<Map<String, dynamic>>? customMarkers;  // 커스텀 마커 추가
  final Function(double lat, double lng)? onMapTap;  // 지도 탭 콜백 추가
  final Function(Map<String, dynamic>)? onMarkerTap;  // 마커 탭 콜백 추가
  final Function(int id, double lat, double lng)? onMarkerDragEnd;  // 마커 드래그 완료 콜백

  const MapWidget({
    super.key,
    this.currentPosition,
    this.records,
    this.showCurrentLocation = true,
    this.showRecords = true,
    this.initialZoom = 13.0,
    this.onRecordTap,
    this.mapController,
    this.customMarkers,
    this.onMapTap,
    this.onMarkerTap,
    this.onMarkerDragEnd,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late MapController _mapController;
  int? _draggingMarkerId;  // 현재 드래그 중인 마커 ID
  bool _isDragging = false;  // 드래그 상태
  
  @override
  void initState() {
    super.initState();
    // 외부에서 전달받은 MapController가 있으면 사용, 없으면 새로 생성
    _mapController = widget.mapController ?? MapController();
  }
  
  @override
  Widget build(BuildContext context) {
    // 기본 위치 (서울)
    final defaultCenter = LatLng(37.5665, 126.9780);
    
    // 현재 위치 또는 기본 위치
    final center = widget.currentPosition != null
        ? LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          )
        : defaultCenter;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: widget.initialZoom,
          minZoom: 5.0,
          maxZoom: 18.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
          onTap: (tapPosition, latLng) {
            // 드래그 중일 때는 드래그 완료
            if (_isDragging) {
              _finishDragging();
            } else if (widget.onMapTap != null) {
              widget.onMapTap!(latLng.latitude, latLng.longitude);
            }
          },
          onPositionChanged: (position, hasGesture) {
            // 드래그 중일 때는 실시간 업데이트하지 않음 (성능상 이유)
            // 최종 위치는 탭으로 확정할 때 업데이트
          },
        ),
        children: [
          // OpenStreetMap 타일 레이어
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.species_gps',
            retinaMode: true,
          ),
          
          // 마커 레이어
          MarkerLayer(
            markers: _buildMarkers(),
          ),
          
          // 현재 위치 정확도 원
          if (widget.showCurrentLocation && widget.currentPosition != null)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: LatLng(
                    widget.currentPosition!.latitude,
                    widget.currentPosition!.longitude,
                  ),
                  radius: widget.currentPosition!.accuracy,
                  color: AppColors.info.withOpacity(0.2),
                  borderColor: AppColors.info,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
          
          // 현재 위치로 이동 버튼 - 우측 하단
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Container(
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
                    onTap: widget.currentPosition != null ? () {
                      _mapController.move(
                        LatLng(
                          widget.currentPosition!.latitude,
                          widget.currentPosition!.longitude,
                        ),
                        15.0,
                      );
                      // 시각적 피드백
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('현재 위치로 이동'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } : null,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        Icons.my_location,
                        color: widget.currentPosition != null 
                            ? AppColors.white 
                            : AppColors.white.withValues(alpha: 0.5),
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // 줌 컨트롤 - 현재 위치 버튼 위에 배치
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(
                right: AppDimensions.paddingL,
                bottom: 120, // 현재 위치 버튼 위에 위치
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 줌 인 버튼 - 네모 모양
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        onTap: () {
                          final currentZoom = _mapController.camera.zoom;
                          if (currentZoom < 18) {
                            _mapController.move(
                              _mapController.camera.center,
                              currentZoom + 1,
                            );
                          }
                        },
                        child: const Icon(
                          Icons.add,
                          color: AppColors.textPrimary,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  // 구분선
                  Container(
                    width: 50,
                    height: 1,
                    color: AppColors.divider,
                  ),
                  // 줌 아웃 버튼 - 네모 모양
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        onTap: () {
                          final currentZoom = _mapController.camera.zoom;
                          if (currentZoom > 5) {
                            _mapController.move(
                              _mapController.camera.center,
                              currentZoom - 1,
                            );
                          }
                        },
                        child: const Icon(
                          Icons.remove,
                          color: AppColors.textPrimary,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 드래그 모드 크로스헤어
          if (_isDragging)
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.error,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.drag_indicator,
                  color: AppColors.error,
                  size: 30,
                ),
              ),
            ),
          
          // 저작권 표시
          const Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.paddingXS),
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                ),
                child: Text('© OpenStreetMap contributors'),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    
    // 현재 위치 마커
    if (widget.showCurrentLocation && widget.currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.info,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.info.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_pin,
              color: AppColors.white,
              size: 20,
            ),
          ),
        ),
      );
    }
    
    // 커스텀 마커들 추가
    if (widget.customMarkers != null) {
      for (final markerData in widget.customMarkers!) {
        final markerId = markerData['id'] as int;
        final isDraggingThis = _draggingMarkerId == markerId;
        
        markers.add(
          Marker(
            point: LatLng(markerData['lat'], markerData['lng']),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                // 드래그 중이 아닐 때만 탭 이벤트 처리
                if (!_isDragging) {
                  if (widget.onMarkerTap != null) {
                    widget.onMarkerTap!(markerData);
                  } else {
                    _showMarkerOptions(markerData);
                  }
                }
              },
              onLongPress: () {
                // 롱프레스로 드래그 모드 시작
                _startDragging(markerId, markerData['lat'], markerData['lng']);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isDraggingThis ? AppColors.error : AppColors.warning,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white,
                    width: isDraggingThis ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDraggingThis ? AppColors.error : AppColors.warning)
                          .withValues(alpha: 0.5),
                      blurRadius: isDraggingThis ? 12 : 8,
                      spreadRadius: isDraggingThis ? 2 : 1,
                    ),
                  ],
                ),
                child: Icon(
                  isDraggingThis ? Icons.drag_indicator : Icons.flag,
                  color: AppColors.white,
                  size: isDraggingThis ? 22 : 20,
                ),
              ),
            ),
          ),
        );
      }
    }
    
    // 기록 위치 마커들
    if (widget.showRecords && widget.records != null) {
      for (final record in widget.records!) {
        markers.add(
          Marker(
            point: LatLng(record.latitude, record.longitude),
            width: 35,
            height: 35,
            child: GestureDetector(
              onTap: () {
                if (widget.onRecordTap != null) {
                  widget.onRecordTap!(record);
                } else {
                  _showRecordDetails(record);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.secondaryGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryGreen.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        );
      }
    }
    
    return markers;
  }
  
  void _startDragging(int markerId, double lat, double lng) {
    setState(() {
      _draggingMarkerId = markerId;
      _isDragging = true;
    });
    
    // 마커 위치로 지도 중심 이동
    _mapController.move(LatLng(lat, lng), _mapController.camera.zoom);
    
    // 진동 피드백 (가능한 경우)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.drag_indicator, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('마커를 드래그하여 이동하세요. 탭하면 완료됩니다.'),
            ],
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: '완료',
            textColor: Colors.white,
            onPressed: () => _finishDragging(),
          ),
        ),
      );
    }
  }
  
  void _finishDragging() {
    if (_isDragging && _draggingMarkerId != null) {
      final center = _mapController.camera.center;
      
      // 위치 업데이트 콜백 호출
      if (widget.onMarkerDragEnd != null) {
        widget.onMarkerDragEnd!(_draggingMarkerId!, center.latitude, center.longitude);
      }
      
      setState(() {
        _isDragging = false;
        _draggingMarkerId = null;
      });
      
      // 완료 피드백
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('마커 위치가 업데이트되었습니다.'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  void _showMarkerOptions(Map<String, dynamic> markerData) {
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
          children: [
            // 핸들 바
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            
            // 마커 정보
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flag,
                    color: AppColors.warning,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        markerData['memo'] ?? '마커',
                        style: AppTextStyles.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '위도: ${markerData['lat'].toStringAsFixed(6)}',
                        style: AppTextStyles.bodySmall,
                      ),
                      Text(
                        '경도: ${markerData['lng'].toStringAsFixed(6)}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingL),
            
            // 삭제 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // MapStateProvider를 통해 삭제
                  if (context.mounted) {
                    try {
                      final mapState = context.read<MapStateProvider>();
                      mapState.removeMarker(markerData['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('마커가 삭제되었습니다'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      // Provider not found
                    }
                  }
                },
                icon: const Icon(Icons.delete),
                label: const Text('마커 삭제'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
  
  void _showRecordDetails(FishingRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Icon(
                  Icons.anchor,
                  color: AppColors.primaryBlue,
                  size: 28,
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.species,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      Text(
                        DateFormatter.formatDateTime(record.timestamp),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingL),
            
            // 상세 정보
            _buildDetailRow(Icons.format_list_numbered, '수량', '${record.count}마리'),
            _buildDetailRow(Icons.location_on, '위치', record.location),
            if (record.accuracy != null)
              _buildDetailRow(Icons.gps_fixed, '정확도', '±${record.accuracy!.toStringAsFixed(1)}m'),
            if (record.notes != null && record.notes!.isNotEmpty)
              _buildDetailRow(Icons.note, '메모', record.notes!),
            if (record.photoPath != null)
              _buildDetailRow(Icons.camera_alt, '사진', '첨부됨'),
            if (record.audioPath != null)
              _buildDetailRow(Icons.mic, '음성', '녹음 첨부됨'),
            
            const SizedBox(height: AppDimensions.paddingL),
            
            // 액션 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openInExternalMap(record.latitude, record.longitude);
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('외부 지도'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Text('확인'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppDimensions.paddingM),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _openInExternalMap(double latitude, double longitude) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}