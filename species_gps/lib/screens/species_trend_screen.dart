import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../models/fishing_record.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';

/// 어종별 동향 분석 화면
class SpeciesTrendScreen extends StatefulWidget {
  const SpeciesTrendScreen({super.key});

  @override
  State<SpeciesTrendScreen> createState() => _SpeciesTrendScreenState();
}

class _SpeciesTrendScreenState extends State<SpeciesTrendScreen> {
  List<String> _selectedSpecies = [];
  String _timePeriod = '전체'; // 전체, 최근 3개월, 최근 6개월, 최근 1년
  final List<Color> _chartColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('어종별 동향 분석'),
        backgroundColor: AppColors.primaryBlue,
        actions: [
          IconButton(
            onPressed: _showSpeciesSelection,
            icon: const Icon(Icons.tune),
            tooltip: '어종 선택',
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          if (provider.isRecordsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredRecords = _getFilteredRecords(provider.records);
          
          if (_selectedSpecies.isEmpty) {
            return _buildEmptyState();
          }

          if (filteredRecords.isEmpty) {
            return _buildNoDataState();
          }

          return Column(
            children: [
              // 기간 선택 헤더
              _buildPeriodSelector(),
              
              // 선택된 어종 표시
              _buildSelectedSpeciesInfo(),
              
              // 그래프
              Expanded(
                child: _buildTrendChart(filteredRecords),
              ),
              
              // 통계 요약
              _buildStatsSummary(filteredRecords),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '어종을 선택해주세요',
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          const Text('최대 3개까지 선택 가능합니다'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showSpeciesSelection,
            icon: const Icon(Icons.add),
            label: const Text('어종 선택'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text('선택한 기간에 데이터가 없습니다'),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
          const Text('기간:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['전체', '최근 3개월', '최근 6개월', '최근 1년'].map((period) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(period),
                      selected: _timePeriod == period,
                      onSelected: (selected) {
                        setState(() {
                          _timePeriod = period;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedSpeciesInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('선택된 어종:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Text('${_selectedSpecies.length}/3개'),
              const Spacer(),
              TextButton(
                onPressed: _showSpeciesSelection,
                child: const Text('편집'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _selectedSpecies.asMap().entries.map((entry) {
              final index = entry.key;
              final species = entry.value;
              final color = _chartColors[index % _chartColors.length];
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(species),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<FishingRecord> records) {
    final chartData = _generateChartData(records);
    
    if (chartData.isEmpty) {
      return const Center(child: Text('차트 데이터가 없습니다'));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.now().subtract(
                    Duration(days: (chartData.length - value.toInt() - 1) * 7),
                  );
                  return Text(
                    DateFormat('MM/dd').format(date),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[300]!),
          ),
          lineBarsData: chartData,
        ),
      ),
    );
  }

  Widget _buildStatsSummary(List<FishingRecord> records) {
    final stats = _calculateStats(records);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '기간 내 통계',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...stats.entries.map((entry) {
            final index = _selectedSpecies.indexOf(entry.key);
            final color = _chartColors[index % _chartColors.length];
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(entry.key),
                  ),
                  Text(
                    '${entry.value}마리',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showSpeciesSelection() {
    final provider = context.read<AppStateProvider>();
    final availableSpecies = provider.records
        .map((r) => r.species)
        .toSet()
        .toList()
      ..sort();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Text(
                  '어종 선택 (최대 3개)',
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: 16),
                
                // 선택된 어종 표시
                if (_selectedSpecies.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('선택된 어종:'),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _selectedSpecies.map((species) {
                      return Chip(
                        label: Text(species),
                        onDeleted: () {
                          setModalState(() {
                            _selectedSpecies.remove(species);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // 어종 목록
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('사용 가능한 어종:'),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: availableSpecies.length,
                    itemBuilder: (context, index) {
                      final species = availableSpecies[index];
                      final isSelected = _selectedSpecies.contains(species);
                      final canAdd = _selectedSpecies.length < 3;
                      
                      return CheckboxListTile(
                        title: Text(species),
                        value: isSelected,
                        onChanged: (!isSelected && !canAdd) ? null : (value) {
                          setModalState(() {
                            if (value == true) {
                              _selectedSpecies.add(species);
                            } else {
                              _selectedSpecies.remove(species);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                
                // 버튼
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {}); // 메인 화면 업데이트
                          Navigator.pop(context);
                        },
                        child: const Text('적용'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<FishingRecord> _getFilteredRecords(List<FishingRecord> allRecords) {
    var filtered = allRecords.where((r) => _selectedSpecies.contains(r.species)).toList();
    
    // 기간 필터링
    if (_timePeriod != '전체') {
      final now = DateTime.now();
      DateTime? startDate;
      
      switch (_timePeriod) {
        case '최근 3개월':
          startDate = DateTime(now.year, now.month - 3, now.day);
          break;
        case '최근 6개월':
          startDate = DateTime(now.year, now.month - 6, now.day);
          break;
        case '최근 1년':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
      }
      
      if (startDate != null) {
        filtered = filtered.where((r) => r.timestamp.isAfter(startDate!)).toList();
      }
    }
    
    return filtered;
  }

  List<LineChartBarData> _generateChartData(List<FishingRecord> records) {
    final lines = <LineChartBarData>[];
    
    // 주별로 데이터 그룹화
    final weeklyData = <String, Map<String, int>>{};
    
    for (final record in records) {
      // 주차 계산 (간단히 일주일 단위)
      final weekStart = record.timestamp.subtract(
        Duration(days: record.timestamp.weekday - 1),
      );
      final weekKey = DateFormat('yyyy-MM-dd').format(weekStart);
      
      weeklyData[weekKey] ??= {};
      weeklyData[weekKey]![record.species] = 
        (weeklyData[weekKey]![record.species] ?? 0) + record.count;
    }
    
    // 각 어종별 라인 데이터 생성
    for (int i = 0; i < _selectedSpecies.length; i++) {
      final species = _selectedSpecies[i];
      final color = _chartColors[i % _chartColors.length];
      final spots = <FlSpot>[];
      
      int weekIndex = 0;
      for (final weekEntry in weeklyData.entries) {
        final count = weekEntry.value[species] ?? 0;
        spots.add(FlSpot(weekIndex.toDouble(), count.toDouble()));
        weekIndex++;
      }
      
      lines.add(LineChartBarData(
        spots: spots,
        color: color,
        barWidth: 3,
        belowBarData: BarAreaData(
          show: true,
          color: color.withOpacity(0.1),
        ),
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 4,
              color: color,
              strokeColor: Colors.white,
              strokeWidth: 2,
            );
          },
        ),
      ));
    }
    
    return lines;
  }

  Map<String, int> _calculateStats(List<FishingRecord> records) {
    final stats = <String, int>{};
    
    for (final record in records) {
      if (_selectedSpecies.contains(record.species)) {
        stats[record.species] = (stats[record.species] ?? 0) + record.count;
      }
    }
    
    return stats;
  }
}