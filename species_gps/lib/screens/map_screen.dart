import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/map_widget.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/date_formatter.dart';

/// 지도 화면 - 현재 위치와 기록된 위치들을 지도에 표시
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _showRecords = true;
  DateTime? _selectedDate;
  
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('위치 지도'),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        actions: [
          // 기록 표시 토글
          IconButton(
            onPressed: () {
              setState(() {
                _showRecords = !_showRecords;
              });
            },
            icon: Icon(
              _showRecords ? Icons.visibility : Icons.visibility_off,
            ),
            tooltip: _showRecords ? '기록 숨기기' : '기록 표시',
          ),
          
          // 날짜 필터
          IconButton(
            onPressed: _showDatePicker,
            icon: const Icon(Icons.calendar_today),
            tooltip: '날짜 선택',
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
              // 지도
              MapWidget(
                currentPosition: provider.currentPosition,
                records: _showRecords ? records : null,
                showCurrentLocation: true,
                showRecords: _showRecords,
                onRecordTap: (record) {
                  _showRecordBottomSheet(record);
                },
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
                              if (_showRecords)
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
}