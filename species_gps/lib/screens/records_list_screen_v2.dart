import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/fishing_record.dart';
import '../models/marine_category.dart';
import '../providers/app_state_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/ui_helpers.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/primary_button.dart';
import '../services/export_service.dart';

class RecordsListScreenV2 extends StatefulWidget {
  const RecordsListScreenV2({super.key});

  @override
  State<RecordsListScreenV2> createState() => _RecordsListScreenV2State();
}

class _RecordsListScreenV2State extends State<RecordsListScreenV2> 
    with SingleTickerProviderStateMixin {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  final DateFormat _groupDateFormat = DateFormat('yyyy년 MM월 dd일');
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  String? _selectedSpecies;
  DateTime? _selectedDate;
  String _selectedPeriod = '전체'; // 전체, 주간, 월별, 분기, 년도
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String _speciesSearchQuery = '';
  final TextEditingController _speciesSearchController = TextEditingController();
  bool _showCategoryView = false; // 분류군별 통계 보기

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _speciesSearchController.dispose();
    super.dispose();
  }


  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<FishingRecord> _applySearch(List<FishingRecord> records) {
    var filteredRecords = records;
    
    // 텍스트 검색 적용
    if (_searchQuery.isNotEmpty) {
      filteredRecords = filteredRecords.where((record) {
        return record.species.toLowerCase().contains(_searchQuery) ||
               (record.notes?.toLowerCase().contains(_searchQuery) ?? false) ||
               _dateFormat.format(record.timestamp).contains(_searchQuery);
      }).toList();
    }
    
    // 날짜 범위 필터 적용
    if (_startDate != null) {
      filteredRecords = filteredRecords.where((record) {
        return record.timestamp.isAfter(
          DateTime(_startDate!.year, _startDate!.month, _startDate!.day),
        ) || record.timestamp.isAtSameMomentAs(
          DateTime(_startDate!.year, _startDate!.month, _startDate!.day),
        );
      }).toList();
    }
    
    if (_endDate != null) {
      filteredRecords = filteredRecords.where((record) {
        return record.timestamp.isBefore(
          DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59),
        );
      }).toList();
    }
    
    return filteredRecords;
  }


  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '내보내기 형식 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // XLSX 옵션
            ListTile(
              leading: const Icon(Icons.table_view, color: Colors.green),
              title: const Text('XLSX 파일'),
              subtitle: const Text('엑셀에서 열기 가능한 파일'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showActionOptions('xlsx');
              },
            ),
            
            // CSV 옵션
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.blue),
              title: const Text('CSV 파일'),
              subtitle: const Text('범용 데이터 파일'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showActionOptions('csv');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showActionOptions(String fileType) {
    final String fileTypeName = fileType == 'xlsx' ? 'XLSX' : 'CSV';
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$fileTypeName 파일 처리 방법',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 다운로드 옵션
            ListTile(
              leading: const Icon(Icons.download, color: Colors.indigo),
              title: const Text('다운로드'),
              subtitle: const Text('기기에 파일로 저장'),
              onTap: () {
                Navigator.pop(context);
                _handleExport(fileType, isShare: false);
              },
            ),
            
            // 공유 옵션
            ListTile(
              leading: const Icon(Icons.share, color: Colors.orange),
              title: const Text('공유하기'),
              subtitle: const Text('카카오톡, 이메일 등으로 공유'),
              onTap: () {
                Navigator.pop(context);
                _handleExport(fileType, isShare: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordDetail(FishingRecord record) {
    showDialog(
      context: context,
      builder: (context) => _RecordDetailDialog(record: record),
    );
  }

  Future<void> _handleExport(String format, {bool isShare = false}) async {
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
    
    // 파일 형식에 따른 메시지
    String fileTypeName = format == 'xlsx' ? 'XLSX' : 'CSV';
    String actionName = isShare ? '공유 준비' : '다운로드 준비';
    
    // 로딩 다이얼로그
    final result = await UIHelpers.showLoadingDialog<File?>(
      context,
      message: '$fileTypeName 파일 $actionName 중...',
      task: () async {
        if (format == 'xlsx') {
          final result = await ExportService.exportToXLSX(records);
          return result.dataOrNull;
        } else if (format == 'csv') {
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
      if (isShare) {
        // 공유 실행
        final shareResult = await ExportService.shareFile(
          result,
          subject: '수산생명자원 기록 ($fileTypeName)',
          text: '${_dateFormat.format(DateTime.now())} 기준 수산생명자원 기록입니다.',
        );
        
        shareResult.fold(
          onSuccess: (_) {
            UIHelpers.showSnackBar(
              context,
              message: '파일이 공유되었습니다',
              type: SnackBarType.success,
            );
          },
          onFailure: (error) {
            UIHelpers.showErrorSnackBar(context, error);
          },
        );
      } else {
        // 다운로드 완료 메시지
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
    if (record.id == null) return;

    // 안전한 삭제를 위한 어종명 입력 확인
    final confirmed = await _showSafeDeleteDialog(record);
    if (!confirmed) return;

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

  Future<bool> _showSafeDeleteDialog(FishingRecord record) async {
    final TextEditingController confirmController = TextEditingController();
    bool isValid = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning,
                color: AppColors.error,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text('삭제 확인'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '정말로 이 기록을 삭제하시겠습니까?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '삭제할 기록 정보:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('자원: ${record.species}'),
                    Text('개체수: ${record.count}마리'),
                    Text('날짜: ${_dateFormat.format(record.timestamp)}'),
                    if (record.notes?.isNotEmpty == true)
                      Text('메모: ${record.notes}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  children: [
                    const TextSpan(text: '실수 방지를 위해 자원명 '),
                    TextSpan(
                      text: '"${record.species}"',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const TextSpan(text: '을(를) 정확히 입력해주세요:'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                onChanged: (value) {
                  setState(() {
                    isValid = value.trim() == record.species;
                  });
                },
                decoration: InputDecoration(
                  hintText: record.species,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isValid ? Colors.green : AppColors.error,
                      width: 2,
                    ),
                  ),
                  suffixIcon: isValid
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
                autofocus: true,
              ),
              if (!isValid && confirmController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '자원명이 일치하지 않습니다',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                confirmController.dispose();
                Navigator.of(context).pop(false);
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: isValid
                  ? () {
                      confirmController.dispose();
                      Navigator.of(context).pop(true);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('삭제'),
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기록 조회'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,           // 활성 탭 색상 (흰색)
          unselectedLabelColor: AppColors.white.withOpacity(0.7),  // 비활성 탭 색상 (반투명 흰색)
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(
              text: '목록', 
              icon: Icon(Icons.list, size: 24),
            ),
            Tab(
              text: '통계', 
              icon: Icon(Icons.bar_chart, size: 24),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportOptions(),
            tooltip: '내보내기',
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          if (provider.isRecordsLoading) {
            return const LoadingIndicator();
          }

          final filteredRecords = _applySearch(provider.getFilteredRecords(
            species: _selectedSpecies,
            date: _selectedDate,
          ));

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
    return Column(
      children: [
        // 검색 섹션
        _buildSearchSection(),
        
        // 목록 내용
        Expanded(
          child: _buildListContent(records),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 검색 입력 필드
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: '자원명, 메모, 날짜 검색...',
              hintStyle: TextStyle(
                color: AppColors.textHint,
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.primaryBlue,
                size: 24,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          // 날짜 범위 선택 섹션
          _buildDateRangeFilter(),
        ],
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          color: AppColors.primaryBlue,
          size: 20,
        ),
        const SizedBox(width: 8),
        const Text(
          '날짜:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              // 시작일
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectStartDate(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _startDate != null
                          ? DateFormat('MM/dd').format(_startDate!)
                          : '시작일',
                      style: TextStyle(
                        color: _startDate != null 
                            ? AppColors.textPrimary 
                            : AppColors.textHint,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('~', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              // 종료일
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectEndDate(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _endDate != null
                          ? DateFormat('MM/dd').format(_endDate!)
                          : '종료일',
                      style: TextStyle(
                        color: _endDate != null 
                            ? AppColors.textPrimary 
                            : AppColors.textHint,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              // 초기화 버튼
              if (_startDate != null || _endDate != null)
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: _endDate ?? DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }


  Widget _buildListContent(List<FishingRecord> records) {
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
              _searchQuery.isNotEmpty 
                  ? '검색 결과가 없습니다'
                  : '기록이 없습니다',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                '"$_searchQuery"에 해당하는 기록을 찾을 수 없습니다',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.paddingM),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                child: const Text('검색 초기화'),
              ),
            ] else if (_selectedSpecies != null || _selectedDate != null) ...[
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
    // 기간별 필터링 적용
    final allRecords = provider.getFilteredRecords(
      species: _selectedSpecies,
      date: _selectedDate,
    );
    
    final records = _applyPeriodFilter(allRecords);

    return Column(
      children: [
        // 통계 필터 섹션
        _buildStatisticsFilterSection(provider),
        
        // 통계 내용
        Expanded(
          child: _buildStatisticsContent(records),
        ),
      ],
    );
  }

  Widget _buildStatisticsFilterSection(AppStateProvider provider) {
    // records에서 직접 어종 목록 추출
    final availableSpecies = provider.records
        .map((record) => record.species)
        .toSet()
        .toList()
      ..sort();

    return Container(
      width: double.infinity,
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
      child: Column(
        children: [
          // 기간 선택
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '기간:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['전체', '주간', '월별', '분기', '년도'].map((period) {
                      final isSelected = _selectedPeriod == period;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(period),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedPeriod = period;
                            });
                          },
                          selectedColor: AppColors.primaryBlue,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          // 어종 검색 (통계용)
          _buildSpeciesSearchDropdown(availableSpecies),
        ],
      ),
    );
  }

  Widget _buildSpeciesSearchDropdown(List<String> availableSpecies) {
    return Row(
      children: [
        Icon(
          Icons.pets,
          color: AppColors.primaryBlue,
          size: 20,
        ),
        const SizedBox(width: 8),
        const Text(
          '자원:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RawAutocomplete<String>(
            textEditingController: _speciesSearchController,
            focusNode: FocusNode(),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return ['전체 자원', ...availableSpecies];
              }
              
              // 검색어로 필터링
              final searchLower = textEditingValue.text.toLowerCase();
              final filtered = availableSpecies.where((species) {
                return species.toLowerCase().contains(searchLower);
              }).toList();
              
              // 전체 옵션도 검색 가능하게
              if ('전체'.contains(searchLower) || '전체 자원'.contains(searchLower)) {
                return ['전체 자원', ...filtered];
              }
              
              return filtered;
            },
            onSelected: (String selection) {
              setState(() {
                if (selection == '전체 자원') {
                  _selectedSpecies = null;
                  _speciesSearchController.clear();
                } else {
                  _selectedSpecies = selection;
                  _speciesSearchController.text = selection;
                }
              });
            },
            fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: '자원 검색/선택... (입력 후 엔터 또는 목록에서 선택)',
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  suffixIcon: textEditingController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedSpecies = null;
                              _speciesSearchController.clear();
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                onSubmitted: (value) {
                  // 엔터키를 눌렀을 때 처리
                  if (value.isNotEmpty) {
                    // 정확히 일치하는 어종이 있는지 확인
                    final exactMatch = availableSpecies.firstWhere(
                      (species) => species.toLowerCase() == value.toLowerCase(),
                      orElse: () => '',
                    );
                    
                    if (exactMatch.isNotEmpty) {
                      // 정확히 일치하는 어종이 있으면 선택
                      setState(() {
                        _selectedSpecies = exactMatch;
                        _speciesSearchController.text = exactMatch;
                      });
                    } else {
                      // 부분 일치하는 첫 번째 어종 선택
                      final searchLower = value.toLowerCase();
                      final partialMatch = availableSpecies.firstWhere(
                        (species) => species.toLowerCase().contains(searchLower),
                        orElse: () => '',
                      );
                      
                      if (partialMatch.isNotEmpty) {
                        setState(() {
                          _selectedSpecies = partialMatch;
                          _speciesSearchController.text = partialMatch;
                        });
                      }
                    }
                  } else if (value.isEmpty) {
                    // 빈 값으로 엔터를 치면 전체 선택
                    setState(() {
                      _selectedSpecies = null;
                      _speciesSearchController.clear();
                    });
                  }
                },
                onChanged: (value) {
                  // 입력중일 때 실시간으로 필터링을 위해 상태 업데이트
                  setState(() {
                    if (value.isEmpty) {
                      _selectedSpecies = null;
                    }
                  });
                },
              );
            },
            optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);
                        final isAll = option == '전체 자원';
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            isAll ? Icons.all_inclusive : Icons.pets,
                            size: 20,
                            color: isAll ? AppColors.primaryBlue : AppColors.textSecondary,
                          ),
                          title: Text(
                            option,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isAll ? FontWeight.bold : FontWeight.normal,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          onTap: () {
                            onSelected(option);
                          },
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsContent(List<FishingRecord> records) {
    if (records.isEmpty) {
      return const Center(
        child: Text('선택한 기간에 표시할 통계가 없습니다'),
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
                        label: '자원 수',
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
          
          // 자원별 통계
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showCategoryView ? '분류군별 개체수' : '자원별 개체수',
                style: AppTextStyles.headlineMedium,
              ),
              IconButton(
                icon: Icon(
                  _showCategoryView ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.primaryBlue,
                ),
                onPressed: () {
                  setState(() {
                    _showCategoryView = !_showCategoryView;
                  });
                },
                tooltip: _showCategoryView ? '자원별 보기' : '분류군별 보기',
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),
          
          // 분류군별 또는 자원별 통계 표시
          _showCategoryView 
              ? _buildCategoryStatistics(records, totalCount)
              : _buildSpeciesStatistics(sortedSpecies, totalCount),
        ],
      ),
    );
  }

  Widget _buildSpeciesStatistics(List<MapEntry<String, int>> sortedSpecies, int totalCount) {
    return Column(
      children: sortedSpecies.map((entry) {
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
      }).toList(),
    );
  }

  Widget _buildCategoryStatistics(List<FishingRecord> records, int totalCount) {
    // 분류군별 통계 계산
    final categoryStats = <MarineCategory, int>{};
    final categorySpeciesStats = <MarineCategory, Map<String, int>>{};
    
    for (final record in records) {
      // 분류군별 개체수
      categoryStats[record.category] = 
          (categoryStats[record.category] ?? 0) + record.count;
      
      // 분류군별 종별 개체수
      if (!categorySpeciesStats.containsKey(record.category)) {
        categorySpeciesStats[record.category] = {};
      }
      categorySpeciesStats[record.category]![record.species] = 
          (categorySpeciesStats[record.category]![record.species] ?? 0) + record.count;
    }
    
    final sortedCategories = categoryStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedCategories.map((categoryEntry) {
        final category = categoryEntry.key;
        final categoryCount = categoryEntry.value;
        final percentage = (categoryCount / totalCount * 100);
        final speciesInCategory = categorySpeciesStats[category] ?? {};
        
        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.paddingS,
              ),
              childrenPadding: const EdgeInsets.only(
                left: AppDimensions.paddingL,
                right: AppDimensions.paddingM,
                bottom: AppDimensions.paddingM,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 24,
                ),
              ),
              title: Text(
                category.korean,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${speciesInCategory.length}종',
                style: AppTextStyles.labelSmall,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${categoryCount}마리',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(category),
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              ),
              children: speciesInCategory.entries.map((speciesEntry) {
                final speciesPercentage = (speciesEntry.value / categoryCount * 100);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingXS),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: AppDimensions.paddingS),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category).withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          speciesEntry.key,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      Text(
                        '${speciesEntry.value}마리',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(width: AppDimensions.paddingS),
                      Text(
                        '(${speciesPercentage.toStringAsFixed(1)}%)',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(MarineCategory category) {
    switch (category) {
      case MarineCategory.fish:
        return AppColors.primaryBlue;
      case MarineCategory.mollusk:
        return const Color(0xFFFF9800);
      case MarineCategory.cephalopod:
        return const Color(0xFF9C27B0);
      case MarineCategory.crustacean:
        return AppColors.secondaryGreen;
      case MarineCategory.echinoderm:
        return const Color(0xFF00BCD4);
      case MarineCategory.seaweed:
        return const Color(0xFF4CAF50);
      case MarineCategory.other:
        return AppColors.textSecondary;
    }
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
  
  // 기간별 필터링 적용
  List<FishingRecord> _applyPeriodFilter(List<FishingRecord> records) {
    if (_selectedPeriod == '전체') return records;
    
    final now = DateTime.now();
    DateTime? startDate;
    
    switch (_selectedPeriod) {
      case '주간':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '월별':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case '분기':
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case '년도':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        return records;
    }
    
    if (startDate == null) return records;
    
    return records.where((record) {
      return record.timestamp.isAfter(startDate!);
    }).toList();
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