import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/fishing_record.dart';
import '../providers/app_state_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/ui_helpers.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/primary_button.dart';
import '../services/export_service.dart';

class RecordsListScreenV2 extends StatefulWidget {
  const RecordsListScreenV2({Key? key}) : super(key: key);

  @override
  State<RecordsListScreenV2> createState() => _RecordsListScreenV2State();
}

class _RecordsListScreenV2State extends State<RecordsListScreenV2> 
    with SingleTickerProviderStateMixin {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  final DateFormat _groupDateFormat = DateFormat('yyyy년 MM월 dd일');
  
  late TabController _tabController;
  String? _selectedSpecies;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      builder: (context) => _FilterBottomSheet(
        selectedSpecies: _selectedSpecies,
        selectedDate: _selectedDate,
        onApply: (species, date) {
          setState(() {
            _selectedSpecies = species;
            _selectedDate = date;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showRecordDetail(FishingRecord record) {
    showDialog(
      context: context,
      builder: (context) => _RecordDetailDialog(record: record),
    );
  }

  Future<void> _handleExport(String format) async {
    final provider = context.read<AppStateProvider>();
    final records = provider.getFilteredRecords(
      species: _selectedSpecies,
      date: _selectedDate,
    );
    
    if (records.isEmpty) {
      UIHelpers.showSnackBar(
        context,
        message: '내보낼 기록이 없습니다',
        type: SnackBarType.warning,
      );
      return;
    }
    
    // 로딩 다이얼로그
    final result = await UIHelpers.showLoadingDialog<File?>(
      context,
      message: format == 'csv' ? 'CSV 파일 생성 중...' : 'PDF 파일 생성 중...',
      task: () async {
        if (format == 'csv') {
          final result = await ExportService.exportToCSV(records);
          return result.dataOrNull;
        } else {
          final result = await ExportService.exportToPDF(
            records,
            title: '수산생명자원 기록 보고서',
          );
          return result.dataOrNull;
        }
      },
    );
    
    if (result != null) {
      // 공유 다이얼로그
      final share = await UIHelpers.showConfirmDialog(
        context,
        title: '파일 생성 완료',
        message: '파일이 생성되었습니다. 공유하시겠습니까?',
        confirmText: '공유',
        cancelText: '닫기',
      );
      
      if (share) {
        final shareResult = await ExportService.shareFile(
          result,
          subject: '수산생명자원 기록',
          text: '${_dateFormat.format(DateTime.now())} 기준 수산생명자원 기록입니다.',
        );
        
        shareResult.fold(
          onSuccess: (_) {
            // 공유 완료
          },
          onFailure: (error) {
            UIHelpers.showErrorSnackBar(context, error);
          },
        );
      } else {
        UIHelpers.showSnackBar(
          context,
          message: '파일이 저장되었습니다',
          type: SnackBarType.success,
        );
      }
    } else {
      UIHelpers.showSnackBar(
        context,
        message: '파일 생성에 실패했습니다',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _deleteRecord(FishingRecord record) async {
    final confirm = await UIHelpers.showConfirmDialog(
      context,
      title: '삭제 확인',
      message: '이 기록을 삭제하시겠습니까?',
      confirmText: '삭제',
      isDangerous: true,
    );

    if (!confirm || record.id == null) return;

    final provider = context.read<AppStateProvider>();
    final result = await provider.deleteRecord(record.id!);

    result.fold(
      onSuccess: (_) {
        UIHelpers.showSnackBar(
          context,
          message: '기록이 삭제되었습니다',
          type: SnackBarType.success,
        );
      },
      onFailure: (error) {
        UIHelpers.showErrorSnackBar(context, error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기록 조회'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          tabs: const [
            Tab(text: '목록', icon: Icon(Icons.list)),
            Tab(text: '통계', icon: Icon(Icons.bar_chart)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: '필터',
          ),
          PopupMenuButton<String>(
            onSelected: _handleExport,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, size: 20),
                    SizedBox(width: 8),
                    Text('CSV로 내보내기'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 20),
                    SizedBox(width: 8),
                    Text('PDF로 내보내기'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          if (provider.isRecordsLoading) {
            return const LoadingIndicator();
          }

          final filteredRecords = provider.getFilteredRecords(
            species: _selectedSpecies,
            date: _selectedDate,
          );

          return TabBarView(
            controller: _tabController,
            children: [
              // 목록 탭
              _buildListTab(filteredRecords),
              // 통계 탭
              _buildStatisticsTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListTab(List<FishingRecord> records) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              '기록이 없습니다',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (_selectedSpecies != null || _selectedDate != null) ...[
              const SizedBox(height: AppDimensions.paddingS),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedSpecies = null;
                    _selectedDate = null;
                  });
                },
                child: const Text('필터 초기화'),
              ),
            ],
          ],
        ),
      );
    }

    // 날짜별로 그룹화
    final groupedRecords = <String, List<FishingRecord>>{};
    for (final record in records) {
      final dateKey = _groupDateFormat.format(record.timestamp);
      groupedRecords[dateKey] ??= [];
      groupedRecords[dateKey]!.add(record);
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AppStateProvider>().loadRecords(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        itemCount: groupedRecords.length,
        itemBuilder: (context, index) {
          final dateKey = groupedRecords.keys.elementAt(index);
          final dayRecords = groupedRecords[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index > 0)
                const SizedBox(height: AppDimensions.paddingL),
              Text(
                dateKey,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingS),
              ...dayRecords.map((record) => _RecordCard(
                record: record,
                onTap: () => _showRecordDetail(record),
                onDelete: () => _deleteRecord(record),
              )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatisticsTab(AppStateProvider provider) {
    final records = provider.getFilteredRecords(
      species: _selectedSpecies,
      date: _selectedDate,
    );

    if (records.isEmpty) {
      return const Center(
        child: Text('표시할 통계가 없습니다'),
      );
    }

    // 통계 계산
    final totalCount = records.fold<int>(
      0,
      (sum, record) => sum + record.count,
    );
    
    final speciesStats = <String, int>{};
    for (final record in records) {
      speciesStats[record.species] = 
          (speciesStats[record.species] ?? 0) + record.count;
    }
    
    final sortedSpecies = speciesStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 요약 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: '총 기록 수',
                        value: records.length.toString(),
                        icon: Icons.folder,
                      ),
                      _StatItem(
                        label: '총 개체수',
                        value: totalCount.toString(),
                        icon: Icons.pets,
                      ),
                      _StatItem(
                        label: '어종 수',
                        value: speciesStats.length.toString(),
                        icon: Icons.category,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingL),
          
          // 어종별 통계
          Text(
            '어종별 개체수',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          
          ...sortedSpecies.map((entry) {
            final percentage = (entry.value / totalCount * 100);
            return Card(
              margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: AppTextStyles.bodyLarge,
                          ),
                        ),
                        Text(
                          '${entry.value}마리',
                          style: AppTextStyles.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingS),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 8,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingXS),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: AppTextStyles.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// 통계 아이템 위젯
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: AppDimensions.iconL,
          color: AppColors.primaryBlue,
        ),
        const SizedBox(height: AppDimensions.paddingS),
        Text(
          value,
          style: AppTextStyles.dataValue,
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall,
        ),
      ],
    );
  }
}

// 기록 카드 위젯
class _RecordCard extends StatelessWidget {
  final FishingRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RecordCard({
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = record.photoPath != null && 
                     File(record.photoPath!).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              // 썸네일
              Container(
                width: AppDimensions.thumbnailSize,
                height: AppDimensions.thumbnailSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  color: AppColors.divider,
                ),
                child: hasPhoto
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        child: Image.file(
                          File(record.photoPath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.image_not_supported,
                        color: AppColors.textHint,
                      ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.species,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingXXS),
                    Text(
                      '${record.count}마리',
                      style: AppTextStyles.bodyMedium,
                    ),
                    Text(
                      DateFormat('HH:mm').format(record.timestamp),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              
              // 삭제 버튼
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                color: AppColors.error,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 필터 바텀시트
class _FilterBottomSheet extends StatefulWidget {
  final String? selectedSpecies;
  final DateTime? selectedDate;
  final Function(String?, DateTime?) onApply;

  const _FilterBottomSheet({
    this.selectedSpecies,
    this.selectedDate,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  String? _species;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _species = widget.selectedSpecies;
    _date = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppStateProvider>();
    final speciesList = provider.speciesCount.keys.toList();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '필터',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: AppDimensions.paddingL),
          
          // 어종 선택
          DropdownButtonFormField<String?>(
            value: _species,
            decoration: const InputDecoration(
              labelText: '어종',
              prefixIcon: Icon(Icons.pets),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('전체'),
              ),
              ...speciesList.map((species) => DropdownMenuItem(
                value: species,
                child: Text(species),
              )),
            ],
            onChanged: (value) {
              setState(() => _species = value);
            },
          ),
          const SizedBox(height: AppDimensions.paddingM),
          
          // 날짜 선택
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(_date == null 
                ? '날짜 선택' 
                : DateFormat('yyyy-MM-dd').format(_date!)),
            trailing: _date != null 
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _date = null),
                  )
                : null,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _date = picked);
              }
            },
          ),
          const SizedBox(height: AppDimensions.paddingL),
          
          // 버튼
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: '초기화',
                  onPressed: () => widget.onApply(null, null),
                  variant: ButtonVariant.outline,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: PrimaryButton(
                  text: '적용',
                  onPressed: () => widget.onApply(_species, _date),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),
        ],
      ),
    );
  }
}

// 상세 정보 다이얼로그
class _RecordDetailDialog extends StatelessWidget {
  final FishingRecord record;

  const _RecordDetailDialog({required this.record});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = record.photoPath != null && 
                     File(record.photoPath!).existsSync();

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 사진
            if (hasPhoto)
              Container(
                height: 250,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDimensions.radiusL),
                  ),
                  child: Image.file(
                    File(record.photoPath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            // 정보
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.species,
                    style: AppTextStyles.headlineLarge,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  
                  _DetailRow(
                    icon: Icons.numbers,
                    label: '개체수',
                    value: '${record.count}마리',
                  ),
                  _DetailRow(
                    icon: Icons.location_on,
                    label: '위치',
                    value: '${record.latitude.toStringAsFixed(6)}, '
                           '${record.longitude.toStringAsFixed(6)}',
                  ),
                  if (record.accuracy != null)
                    _DetailRow(
                      icon: Icons.gps_fixed,
                      label: '정확도',
                      value: '±${record.accuracy!.toStringAsFixed(1)}m',
                    ),
                  _DetailRow(
                    icon: Icons.access_time,
                    label: '기록 시간',
                    value: DateFormat('yyyy-MM-dd HH:mm').format(record.timestamp),
                  ),
                  
                  if (record.notes != null && record.notes!.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.paddingM),
                    const Divider(),
                    const SizedBox(height: AppDimensions.paddingM),
                    Text(
                      '메모',
                      style: AppTextStyles.labelLarge,
                    ),
                    const SizedBox(height: AppDimensions.paddingS),
                    Text(
                      record.notes!,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            
            // 버튼
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: PrimaryButton(
                text: '닫기',
                onPressed: () => Navigator.pop(context),
                size: ButtonSize.small,
                variant: ButtonVariant.outline,
                isFullWidth: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 상세 정보 행
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppDimensions.iconS,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppDimensions.paddingS),
          Text(
            '$label: ',
            style: AppTextStyles.labelMedium,
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
}