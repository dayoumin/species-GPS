import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../models/fishing_record.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';

enum RecordMode { camera, detailed }

class AddRecordScreen extends StatefulWidget {
  final RecordMode mode;
  
  const AddRecordScreen({super.key, required this.mode});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _speciesController = TextEditingController();
  final _countController = TextEditingController();
  final _notesController = TextEditingController();
  
  Position? _currentPosition;
  File? _imageFile;
  bool _isLoading = false;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 위치 정보 가져오기
    _currentPosition = await LocationService.getCurrentPosition();
    setState(() {});
    
    // 카메라 모드인 경우 카메라 초기화
    if (widget.mode == RecordMode.camera) {
      await CameraService.initialize();
      setState(() {
        _isCameraReady = true;
      });
    }
  }

  @override
  void dispose() {
    _speciesController.dispose();
    _countController.dispose();
    _notesController.dispose();
    if (widget.mode == RecordMode.camera) {
      CameraService.dispose();
    }
    super.dispose();
  }

  Future<void> _takePicture() async {
    final file = await CameraService.takePicture();
    if (file != null && _currentPosition != null) {
      final savedPath = await CameraService.saveImageWithGPS(file, _currentPosition!);
      if (savedPath != null) {
        setState(() {
          _imageFile = File(savedPath);
        });
      }
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 정보를 가져올 수 없습니다')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final record = FishingRecord(
        species: _speciesController.text.trim(),
        count: int.parse(_countController.text),
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        accuracy: _currentPosition!.accuracy,
        photoPath: _imageFile?.path,
        notes: _notesController.text.trim(),
        timestamp: DateTime.now(),
      );

      await StorageService.addRecord(record);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기록이 저장되었습니다')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == RecordMode.camera ? '사진 기록' : '상세 기록'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 카메라 또는 이미지 미리보기
                    if (widget.mode == RecordMode.camera) ...[
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _isCameraReady && CameraService.controller != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CameraPreview(CameraService.controller!),
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                      ),
                      const SizedBox(height: 16),
                      if (_imageFile == null)
                        ElevatedButton.icon(
                          onPressed: _takePicture,
                          icon: const Icon(Icons.camera),
                          label: const Text('사진 촬영'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                    
                    // GPS 정보 표시
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GPS 정보',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_currentPosition != null) ...[
                              Text('위도: ${_currentPosition!.latitude.toStringAsFixed(6)}'),
                              Text('경도: ${_currentPosition!.longitude.toStringAsFixed(6)}'),
                              Text('정확도: ${_currentPosition!.accuracy.toStringAsFixed(1)}m'),
                            ] else
                              const Text('위치 정보를 가져오는 중...'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 입력 필드들
                    TextFormField(
                      controller: _speciesController,
                      decoration: const InputDecoration(
                        labelText: '어종명',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pets),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '어종명을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _countController,
                      decoration: const InputDecoration(
                        labelText: '개체수',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '개체수를 입력해주세요';
                        }
                        if (int.tryParse(value) == null || int.parse(value) <= 0) {
                          return '올바른 숫자를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: '메모 (선택)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    
                    // 저장 버튼
                    ElevatedButton(
                      onPressed: _saveRecord,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        '저장',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}