import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/app_state_provider.dart';
import '../widgets/gps_status_card.dart';
import '../widgets/info_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/loading_indicator.dart';
import '../core/utils/ui_helpers.dart';
import '../services/export_service.dart';
import 'add_record_screen_v2.dart';
import 'records_list_screen_v2.dart';

class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({Key? key}) : super(key: key);

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
                      expandedHeight: 200,
                      floating: false,
                      pinned: true,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
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
                          ),
                          const SizedBox(height: AppDimensions.paddingL),
                          
                          // Statistics
                          _buildStatisticsSection(provider),
                          const SizedBox(height: AppDimensions.paddingL),
                          
                          // Quick Export
                          if (provider.totalRecords > 0) ...[
                            _buildQuickExportSection(provider),
                            const SizedBox(height: AppDimensions.paddingL),
                          ],
                          
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
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: _StatCard(
                title: '전체 기록',
                value: provider.totalRecords.toString(),
                icon: Icons.folder,
                color: AppColors.secondaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingM),
        if (provider.speciesCount.isNotEmpty)
          InfoCard(
            title: '어종별 통계',
            icon: Icons.pie_chart,
            type: InfoCardType.info,
            content: Column(
              children: provider.speciesCount.entries.map((entry) {
                final percentage = (entry.value / provider.totalRecords * 100)
                    .toStringAsFixed(1);
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingXS,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(
                            0.7 - (provider.speciesCount.keys.toList()
                                .indexOf(entry.key) * 0.2),
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingS),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      Text(
                        '${entry.value}마리',
                        style: AppTextStyles.labelLarge,
                      ),
                      const SizedBox(width: AppDimensions.paddingS),
                      Text(
                        '($percentage%)',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '빠른 기록',
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: AppDimensions.paddingM),
        PrimaryButton(
          text: '사진으로 빠른 기록',
          icon: Icons.camera_alt,
          onPressed: () => _navigateToAddRecord(
            context,
            RecordMode.camera,
          ),
          variant: ButtonVariant.primary,
        ),
        const SizedBox(height: AppDimensions.paddingM),
        PrimaryButton(
          text: '상세 기록 입력',
          icon: Icons.edit,
          onPressed: () => _navigateToAddRecord(
            context,
            RecordMode.detailed,
          ),
          variant: ButtonVariant.secondary,
        ),
        const SizedBox(height: AppDimensions.paddingM),
        PrimaryButton(
          text: '기록 조회',
          icon: Icons.list_alt,
          onPressed: () => _navigateToRecordsList(context),
          variant: ButtonVariant.outline,
        ),
      ],
    );
  }

  void _navigateToAddRecord(BuildContext context, RecordMode mode) {
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
        builder: (context) => AddRecordScreenV2(mode: mode),
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
  
  Widget _buildQuickExportSection(AppStateProvider provider) {
    return InfoCard(
      title: '빠른 내보내기',
      subtitle: '오늘의 기록을 즉시 내보낼 수 있습니다',
      icon: Icons.file_download,
      type: InfoCardType.info,
      content: Row(
        children: [
          Expanded(
            child: PrimaryButton(
              text: 'CSV',
              icon: Icons.table_chart,
              size: ButtonSize.small,
              variant: ButtonVariant.outline,
              onPressed: () => _quickExport('csv'),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: PrimaryButton(
              text: 'PDF',
              icon: Icons.picture_as_pdf,
              size: ButtonSize.small,
              variant: ButtonVariant.outline,
              onPressed: () => _quickExport('pdf'),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _quickExport(String format) async {
    final provider = context.read<AppStateProvider>();
    final todayRecords = provider.getFilteredRecords(date: DateTime.now());
    
    if (todayRecords.isEmpty) {
      UIHelpers.showSnackBar(
        context,
        message: '오늘 기록이 없습니다',
        type: SnackBarType.warning,
      );
      return;
    }
    
    final result = await UIHelpers.showLoadingDialog<File?>(
      context,
      message: '파일 생성 중...',
      task: () async {
        if (format == 'csv') {
          final result = await ExportService.exportToCSV(todayRecords);
          return result.dataOrNull;
        } else {
          final result = await ExportService.exportToPDF(
            todayRecords,
            title: '오늘의 수산생명자원 기록',
          );
          return result.dataOrNull;
        }
      },
    );
    
    if (result != null) {
      await ExportService.shareFile(
        result,
        subject: '오늘의 수산생명자원 기록',
        text: '${DateFormat('yyyy-MM-dd').format(DateTime.now())} 기록입니다.',
      );
    }
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