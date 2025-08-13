import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/app_state_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import 'gps_status_card.dart';

/// 최적화된 홈 화면 컨텐츠 위젯
/// Selector를 사용하여 필요한 부분만 리빌드
class OptimizedHomeContent extends StatelessWidget {
  const OptimizedHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final provider = context.read<AppStateProvider>();
        await provider.updateLocation();
        await provider.loadRecords();
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar - 상태와 무관하게 고정
          const _HomeAppBar(),
          
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // GPS Status Card - 위치 정보만 구독
                const _OptimizedGpsCard(),
                const SizedBox(height: AppDimensions.paddingL),
                
                // Statistics - 통계 정보만 구독
                const _OptimizedStatisticsSection(),
                const SizedBox(height: AppDimensions.paddingL),
                
                // Quick Export - 레코드 수만 구독
                const _OptimizedQuickExportSection(),
                
                // Quick Actions - 상태와 무관
                _buildQuickActions(context),
                const SizedBox(height: AppDimensions.paddingXL),
              ]),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '빠른 실행',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add_circle_outline,
                title: '새 기록',
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(context, '/add_record'),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.list_alt,
                title: '기록 목록',
                color: AppColors.secondary,
                onTap: () => Navigator.pushNamed(context, '/records'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 홈 화면 앱바 (상태 독립적)
class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 150,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          '수산생명자원 GPS',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.oceanGradient,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 최적화된 GPS 카드 (위치 정보만 구독)
class _OptimizedGpsCard extends StatelessWidget {
  const _OptimizedGpsCard();

  @override
  Widget build(BuildContext context) {
    return Selector<AppStateProvider, ({Position? position, bool isLoading, bool hasLocation})>(
      selector: (_, provider) => (
        position: provider.currentPosition,
        isLoading: provider.isLocationLoading,
        hasLocation: provider.hasLocation,
      ),
      builder: (context, data, _) {
        return GpsStatusCard(
          position: data.position,
          status: data.isLoading
              ? GpsStatus.searching
              : data.hasLocation
                  ? GpsStatus.active
                  : GpsStatus.inactive,
          onRefresh: () => context.read<AppStateProvider>().updateLocation(),
        );
      },
    );
  }
}

/// 최적화된 통계 섹션 (통계 정보만 구독)
class _OptimizedStatisticsSection extends StatelessWidget {
  const _OptimizedStatisticsSection();

  @override
  Widget build(BuildContext context) {
    return Selector<AppStateProvider, ({int totalRecords, int todayRecords, int yesterdayRecords, Map<String, int> speciesCount})>(
      selector: (_, provider) => (
        totalRecords: provider.totalRecords,
        todayRecords: provider.todayRecordCount,
        yesterdayRecords: provider.yesterdayRecordCount,
        speciesCount: provider.speciesCount,
      ),
      builder: (context, data, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '통계',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: '전체 기록',
                    value: '${data.totalRecords}',
                    icon: Icons.storage,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: _StatCard(
                    title: '오늘 기록',
                    value: '${data.todayRecords}',
                    icon: Icons.today,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: _StatCard(
                    title: '어제 기록',
                    value: '${data.yesterdayRecords}',
                    icon: Icons.event,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: '종 수',
                    value: '${data.speciesCount.length}',
                    icon: Icons.category,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// 최적화된 빠른 내보내기 섹션 (레코드 수만 구독)
class _OptimizedQuickExportSection extends StatelessWidget {
  const _OptimizedQuickExportSection();

  @override
  Widget build(BuildContext context) {
    return Selector<AppStateProvider, int>(
      selector: (_, provider) => provider.totalRecords,
      builder: (context, totalRecords, _) {
        if (totalRecords == 0) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '빠른 내보내기',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: ListTile(
                leading: const Icon(Icons.download, color: AppColors.primary),
                title: const Text('데이터 내보내기'),
                subtitle: Text('총 $totalRecords개의 기록'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // 내보내기 기능 구현
                },
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
          ],
        );
      },
    );
  }
}

/// 통계 카드 위젯
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// 빠른 실행 카드 위젯
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}