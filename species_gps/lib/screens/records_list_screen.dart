import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fishing_record.dart';
import '../services/database_service.dart';

class RecordsListScreen extends StatefulWidget {
  const RecordsListScreen({super.key});

  @override
  State<RecordsListScreen> createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends State<RecordsListScreen> {
  List<FishingRecord> _records = [];
  bool _isLoading = true;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final records = await DatabaseService.getRecords();
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터 로드 실패: $e')),
      );
    }
  }

  Future<void> _deleteRecord(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.deleteRecord(id);
      _loadRecords();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기록이 삭제되었습니다')),
      );
    }
  }

  void _showRecordDetail(FishingRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.species),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (record.photoPath != null && File(record.photoPath!).existsSync())
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(record.photoPath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Text('개체수: ${record.count}마리'),
              const SizedBox(height: 8),
              Text('위치: ${record.latitude.toStringAsFixed(6)}, ${record.longitude.toStringAsFixed(6)}'),
              if (record.accuracy != null)
                Text('정확도: ${record.accuracy!.toStringAsFixed(1)}m'),
              const SizedBox(height: 8),
              Text('기록 시간: ${_dateFormat.format(record.timestamp)}'),
              if (record.notes != null && record.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('메모:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(record.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRecord(record.id!);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기록 조회'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecords,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(
                  child: Text(
                    '아직 기록이 없습니다',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: record.photoPath != null && File(record.photoPath!).existsSync()
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(record.photoPath!),
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              ),
                        title: Text(
                          record.species,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${record.count}마리'),
                            Text(
                              _dateFormat.format(record.timestamp),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteRecord(record.id!),
                        ),
                        onTap: () => _showRecordDetail(record),
                      ),
                    );
                  },
                ),
    );
  }
}