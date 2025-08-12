import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../providers/app_state_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';

/// 디버그용 간단한 지도 화면
class MapScreenDebug extends StatefulWidget {
  const MapScreenDebug({super.key});

  @override
  State<MapScreenDebug> createState() => _MapScreenDebugState();
}

class _MapScreenDebugState extends State<MapScreenDebug> {
  final MapController _mapController = MapController();
  final List<Map<String, dynamic>> _markers = [];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('지도 디버그 (마커: ${_markers.length}개)'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Column(
        children: [
          // 디버그 정보
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('마커 수: ${_markers.length}'),
                Text('마커 목록:'),
                ..._markers.asMap().entries.map((entry) => 
                  Text('  ${entry.key + 1}. ${entry.value['memo'] ?? '메모 없음'}')
                ),
              ],
            ),
          ),
          
          // 지도
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(35.1796, 129.0756),
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                MarkerLayer(
                  markers: _markers.map((markerData) {
                    return Marker(
                      point: LatLng(markerData['lat'], markerData['lng']),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            markerData['id'].toString(),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // 마커 추가 버튼
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _addMarker,
              child: const Text('마커 추가'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _addMarker() {
    setState(() {
      final newMarker = {
        'id': _markers.length + 1,
        'lat': 35.1796 + (_markers.length * 0.002),
        'lng': 129.0756 + (_markers.length * 0.002),
        'memo': '마커 ${_markers.length + 1}',
        'timestamp': DateTime.now(),
      };
      _markers.add(newMarker);
      print('마커 추가됨: $newMarker');
      print('전체 마커: $_markers');
    });
    
    // 새 마커 위치로 이동
    if (_markers.isNotEmpty) {
      final lastMarker = _markers.last;
      _mapController.move(
        LatLng(lastMarker['lat'], lastMarker['lng']),
        13.0,
      );
    }
  }
}