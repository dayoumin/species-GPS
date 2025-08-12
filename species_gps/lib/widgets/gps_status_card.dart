import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';

enum GpsStatus { active, inactive, searching }

class GpsStatusCard extends StatelessWidget {
  final Position? position;
  final GpsStatus status;
  final VoidCallback? onRefresh;
  final VoidCallback? onMapTap;

  const GpsStatusCard({
    super.key,
    this.position,
    this.status = GpsStatus.inactive,
    this.onRefresh,
    this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();
    final statusIcon = _getStatusIcon();

    return Container(
      constraints: BoxConstraints(
        minHeight: AppDimensions.gpsCardHeight,
        maxHeight: AppDimensions.gpsCardHeight + 40,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.oceanGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: null,  // 전체 카드 클릭 비활성화
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Row(
              children: [
                // GPS 상태 표시 아이콘
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: AppDimensions.iconXXL,
                      height: AppDimensions.iconXXL,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            status == GpsStatus.active 
                                ? Icons.gps_fixed
                                : status == GpsStatus.searching
                                    ? Icons.gps_not_fixed
                                    : Icons.gps_off,
                            color: AppColors.white,
                            size: AppDimensions.iconL,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GPS',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppDimensions.paddingL),
                
                // GPS Information
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            statusIcon,
                            color: AppColors.white,
                            size: AppDimensions.iconS,
                          ),
                          const SizedBox(width: AppDimensions.paddingXS),
                          Flexible(
                            child: Text(
                              statusText,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingXS),
                      if (position != null) ...[
                        Text(
                          '위도: ${position!.latitude.toStringAsFixed(6)}',
                          style: AppTextStyles.gpsCoordinate.copyWith(
                            color: AppColors.white,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '경도: ${position!.longitude.toStringAsFixed(6)}',
                          style: AppTextStyles.gpsCoordinate.copyWith(
                            color: AppColors.white,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '정확도: ±${position!.accuracy.toStringAsFixed(1)}m',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.white.withOpacity(0.8),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ] else
                        Text(
                          '위치 정보를 가져올 수 없습니다',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                
                // Map & Refresh buttons
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Map button - 클릭 가능
                    if (onMapTap != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: onMapTap,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.map,
                                  color: AppColors.white,
                                  size: 28,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '지도',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (onRefresh != null) ...[
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: onRefresh,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.refresh,
                              color: AppColors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case GpsStatus.active:
        return AppColors.gpsActive;
      case GpsStatus.inactive:
        return AppColors.gpsInactive;
      case GpsStatus.searching:
        return AppColors.gpsSearching;
    }
  }

  String _getStatusText() {
    switch (status) {
      case GpsStatus.active:
        return 'GPS 활성';
      case GpsStatus.inactive:
        return 'GPS 비활성';
      case GpsStatus.searching:
        return 'GPS 검색 중...';
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case GpsStatus.active:
        return Icons.gps_fixed;
      case GpsStatus.inactive:
        return Icons.gps_off;
      case GpsStatus.searching:
        return Icons.gps_not_fixed;
    }
  }
}