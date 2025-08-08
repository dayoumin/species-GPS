import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../models/fishing_record.dart';

/// 지도 위젯 - 현재 위치 및 기록 위치 표시
class MapWidget extends StatefulWidget {
  final Position? currentPosition;
  final List<FishingRecord>? records;
  final bool showCurrentLocation;
  final bool showRecords;
  final double initialZoom;
  final Function(FishingRecord)? onRecordTap;

  const MapWidget({
    super.key,
    this.currentPosition,
    this.records,
    this.showCurrentLocation = true,
    this.showRecords = true,
    this.initialZoom = 13.0,
    this.onRecordTap,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late MapController _mapController;
  
  @override
  void initState() {
    super.initState();
    _mapController = MapController();
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
          
          // 지도 컨트롤
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 현재 위치로 이동 버튼
                  if (widget.currentPosition != null)
                    FloatingActionButton.small(
                      heroTag: 'currentLocation',
                      onPressed: () {
                        _mapController.move(
                          LatLng(
                            widget.currentPosition!.latitude,
                            widget.currentPosition!.longitude,
                          ),
                          15.0,
                        );
                      },
                      backgroundColor: AppColors.white,
                      child: const Icon(
                        Icons.my_location,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  const SizedBox(height: AppDimensions.paddingS),
                  
                  // 줌 인 버튼
                  FloatingActionButton.small(
                    heroTag: 'zoomIn',
                    onPressed: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(
                        _mapController.camera.center,
                        currentZoom + 1,
                      );
                    },
                    backgroundColor: AppColors.white,
                    child: const Icon(
                      Icons.add,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  
                  // 줌 아웃 버튼
                  FloatingActionButton.small(
                    heroTag: 'zoomOut',
                    onPressed: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(
                        _mapController.camera.center,
                        currentZoom - 1,
                      );
                    },
                    backgroundColor: AppColors.white,
                    child: const Icon(
                      Icons.remove,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
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
                  color: AppColors.info.withOpacity(0.5),
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
                      color: AppColors.secondaryGreen.withOpacity(0.5),
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
  
  void _showRecordDetails(FishingRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.species ?? '기록'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('수량: ${record.count}'),
            Text('위도: ${record.latitude.toStringAsFixed(6)}'),
            Text('경도: ${record.longitude.toStringAsFixed(6)}'),
            if (record.notes != null && record.notes!.isNotEmpty)
              Text('메모: ${record.notes}'),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              '기록 시간: ${record.timestamp.toString().substring(0, 19)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openInExternalMap(record.latitude, record.longitude);
            },
            child: const Text('외부 지도에서 열기'),
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