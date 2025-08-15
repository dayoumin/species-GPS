import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/app_state_provider.dart';
import '../models/marine_category.dart';
import '../widgets/gps_status_card.dart';
import '../widgets/info_card.dart';
import '../widgets/loading_indicator.dart';
import '../core/utils/ui_helpers.dart';
import '../services/storage_service.dart';
import 'add_record_screen_v3.dart';
import 'records_list_screen_v2.dart';
import 'map_screen.dart';

class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showAllSpecies = false; // 모든 종 표시 여부

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    _animationController.forward();
    
    // 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final provider = context.read<AppStateProvider>();
    await provider.updateLocation();
    
    // 웹 환경에서 샘플 데이터 추가 (최초 1회만)
    if (Theme.of(context).platform == TargetPlatform.windows || 
        Theme.of(context).platform == TargetPlatform.linux ||
        Theme.of(context).platform == TargetPlatform.macOS) {
      await StorageService.addSampleData();
    }
    
    await provider.loadRecords();
    provider.startLocationStream();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Consumer<AppStateProvider>(
            builder: (context, provider, child) {
              return RefreshIndicator(
                onRefresh: () async {
                  await provider.updateLocation();
                  await provider.loadRecords();
                },
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // App Bar
                    SliverAppBar(
                      expandedHeight: 120,
                      floating: false,
                      pinned: true,
                      elevation: 0,
                      centerTitle: true,
                      flexibleSpace: FlexibleSpaceBar(
                        centerTitle: true,
                        title: const Text(
                          '수산생명자원 GPS',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: AppColors.oceanGradient,
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -30,
                                top: -30,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.white.withOpacity(0.1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Content
                    SliverPadding(
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // GPS Status Card
                          GpsStatusCard(
                            position: provider.currentPosition,
                            status: provider.isLocationLoading
                                ? GpsStatus.searching
                                : provider.hasLocation
                                    ? GpsStatus.active
                                    : GpsStatus.inactive,
                            onRefresh: provider.updateLocation,
                            onMapTap: () => _navigateToMap(context),
                          ),
                          const SizedBox(height: AppDimensions.paddingL),
                          
                          // Statistics
                          _buildStatisticsSection(provider),
                          const SizedBox(height: AppDimensions.paddingL),
                          
                          
                          // Quick Actions
                          _buildQuickActions(context),
                          const SizedBox(height: AppDimensions.paddingXL),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(AppStateProvider provider) {
    if (provider.isRecordsLoading) {
      return const LoadingIndicator(isFullScreen: false);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기록 현황',
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: '오늘 기록',
                value: provider.todayRecordCount.toString(),
                icon: Icons.today,
                color: AppColors.secondaryGreen,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: _StatCard(
                title: '전체 기록',
                value: provider.totalRecords.toString(),
                icon: Icons.folder,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        if (provider.speciesCount.isNotEmpty || provider.categoryCount.isNotEmpty)
          _buildEnhancedStatisticsCard(provider),
      ],
    );
  }

  Widget _buildEnhancedStatisticsCard(AppStateProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 헤더 및 토글
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.pie_chart,
                      color: AppColors.primaryBlue,
                      size: 24,
                    ),
                    const SizedBox(width: AppDimensions.paddingS),
                    Text(
                      '자원별 통계',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Segmented Button
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSegmentButton(
                            label: '종별',
                            icon: Icons.pets,
                            isSelected: !provider.showCategoryView,
                            onTap: () {
                              if (provider.showCategoryView) {
                                provider.toggleCategoryView();
                              }
                            },
                          ),
                          _buildSegmentButton(
                            label: '분류군',
                            icon: Icons.category,
                            isSelected: provider.showCategoryView,
                            onTap: () {
                              if (!provider.showCategoryView) {
                                provider.toggleCategoryView();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingM),
                // 콘텐츠
                _buildEnhancedStatisticsContent(provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedStatisticsContent(AppStateProvider provider) {
    if (provider.showCategoryView && provider.categoryCount.isNotEmpty) {
      // 분류군별 통계 보기
      final sortedCategories = provider.categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final displayCategories = _showAllSpecies 
          ? sortedCategories 
          : sortedCategories.take(3).toList();

      return Column(
        children: [
          ...displayCategories.map((categoryEntry) {
            final category = categoryEntry.key;
            final totalCount = categoryEntry.value;
            final percentage = (totalCount / provider.totalRecords * 100);
            final categorySpecies = provider.categorySpeciesCount[category] ?? {};
            final index = sortedCategories.indexOf(categoryEntry);
            
            return _buildStatisticItem(
              rank: index < 3 ? index + 1 : null,
              title: category.korean,
              count: totalCount,
              percentage: percentage,
              color: _getCategoryColor(category),
              icon: _getCategoryIcon(category),
              expandedContent: categorySpecies.entries.map((speciesEntry) {
                return Padding(
                  padding: const EdgeInsets.only(
                    left: AppDimensions.paddingL,
                    top: AppDimensions.paddingXS,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category).withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingS),
                      Expanded(
                        child: Text(
                          speciesEntry.key,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '${speciesEntry.value}마리',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }).toList(),
          if (sortedCategories.length > 3 && !_showAllSpecies)
            TextButton(
              onPressed: () {
                setState(() {
                  _showAllSpecies = true;
                });
              },
              child: Text('+ ${sortedCategories.length - 3}개 더보기'),
            ),
          if (_showAllSpecies && sortedCategories.length > 3)
            TextButton(
              onPressed: () {
                setState(() {
                  _showAllSpecies = false;
                });
              },
              child: const Text('접기'),
            ),
        ],
      );
    } else {
      // 종별 통계 보기
      final sortedSpecies = provider.speciesCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final displaySpecies = _showAllSpecies 
          ? sortedSpecies 
          : sortedSpecies.take(3).toList();

      return Column(
        children: [
          ...displaySpecies.asMap().entries.map((entry) {
            final index = entry.key;
            final species = entry.value;
            final percentage = (species.value / provider.totalRecords * 100);
            
            return _buildStatisticItem(
              rank: index < 3 ? index + 1 : null,
              title: species.key,
              count: species.value,
              percentage: percentage,
              color: AppColors.primaryBlue.withOpacity(0.8 - (index * 0.15)),
              icon: Icons.pets,
            );
          }).toList(),
          if (sortedSpecies.length > 3 && !_showAllSpecies)
            TextButton(
              onPressed: () {
                setState(() {
                  _showAllSpecies = true;
                });
              },
              child: Text('+ ${sortedSpecies.length - 3}개 더보기'),
            ),
          if (_showAllSpecies && sortedSpecies.length > 3)
            TextButton(
              onPressed: () {
                setState(() {
                  _showAllSpecies = false;
                });
              },
              child: const Text('접기'),
            ),
        ],
      );
    }
  }

  Widget _buildStatisticItem({
    int? rank,
    required String title,
    required int count,
    required double percentage,
    required Color color,
    required IconData icon,
    List<Widget>? expandedContent,
  }) {
    final bool isExpandable = expandedContent != null && expandedContent.isNotEmpty;
    
    return isExpandable
        ? Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: _buildStatisticItemContent(
                rank: rank,
                title: title,
                count: count,
                percentage: percentage,
                color: color,
                icon: icon,
              ),
              children: expandedContent,
            ),
          )
        : _buildStatisticItemContent(
            rank: rank,
            title: title,
            count: count,
            percentage: percentage,
            color: color,
            icon: icon,
          );
  }

  Widget _buildStatisticItemContent({
    int? rank,
    required String title,
    required int count,
    required double percentage,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
      child: Column(
        children: [
          Row(
            children: [
              // 순위 표시
              if (rank != null)
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: AppDimensions.paddingS),
                  decoration: BoxDecoration(
                    color: rank == 1 
                        ? const Color(0xFFFFD700)
                        : rank == 2 
                            ? const Color(0xFFC0C0C0)
                            : const Color(0xFFCD7F32),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      rank.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              // 아이콘
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              // 이름
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // 개수와 퍼센트
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$count마리',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingS),
          // 프로그레스 바
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(MarineCategory category) {
    switch (category) {
      case MarineCategory.fish:
        return Icons.sailing;
      case MarineCategory.mollusk:
        return Icons.circle;
      case MarineCategory.cephalopod:
        return Icons.scatter_plot;
      case MarineCategory.crustacean:
        return Icons.pest_control;
      case MarineCategory.echinoderm:
        return Icons.star;
      case MarineCategory.seaweed:
        return Icons.grass;
      case MarineCategory.other:
        return Icons.more_horiz;
    }
  }
  
  Color _getCategoryColor(MarineCategory category) {
    switch (category) {
      case MarineCategory.fish:
        return AppColors.primaryBlue;
      case MarineCategory.mollusk:
        return AppColors.warning;
      case MarineCategory.cephalopod:
        return AppColors.error;
      case MarineCategory.crustacean:
        return AppColors.secondaryGreen;
      case MarineCategory.echinoderm:
        return AppColors.info;
      case MarineCategory.seaweed:
        return AppColors.success;
      case MarineCategory.other:
        return AppColors.textSecondary;
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '작업 기록',
          style: AppTextStyles.headlineMedium.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingL),
        
        // 기록 추가 - 하나로 통합
        Container(
          decoration: BoxDecoration(
            gradient: AppColors.oceanGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _navigateToAddRecord(context),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingXL),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_circle,
                        color: AppColors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingXL),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '새 기록 추가',
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '사진, GPS, 음성, 메모 - 필요한 만큼 기록',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.white.withValues(alpha: 0.9),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.white.withValues(alpha: 0.8),
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: AppDimensions.paddingL),
        
        // 기록 조회 버튼
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryBlue.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _navigateToRecordsList(context),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.list_alt,
                        color: AppColors.primaryBlue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingL),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '기록 조회',
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '저장된 기록 보기 및 내보내기',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToAddRecord(BuildContext context) {
    final provider = context.read<AppStateProvider>();
    
    if (!provider.hasLocation) {
      UIHelpers.showSnackBar(
        context,
        message: 'GPS 위치를 먼저 확인해주세요',
        type: SnackBarType.warning,
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddRecordScreenV3(),
      ),
    ).then((success) {
      if (success == true) {
        context.read<AppStateProvider>().loadRecords();
      }
    });
  }

  void _navigateToRecordsList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecordsListScreenV2(),
      ),
    );
  }

  void _navigateToMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapScreen(), // 원래 지도 화면으로 복원
      ),
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
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: AppDimensions.iconL,
            color: color,
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            value,
            style: AppTextStyles.dataValue.copyWith(color: color),
          ),
          const SizedBox(height: AppDimensions.paddingXS),
          Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}