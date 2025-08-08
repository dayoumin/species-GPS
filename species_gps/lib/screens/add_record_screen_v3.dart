import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/app_state_provider.dart';
import '../models/fishing_record.dart';
import '../services/audio_service.dart';
import '../widgets/map_widget.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/ui_helpers.dart';
import '../core/utils/date_formatter.dart';
import '../core/utils/app_logger.dart';

/// 개선된 기록 추가 화면 - 음성 입력 기능 포함
class AddRecordScreenV3 extends StatefulWidget {
  const AddRecordScreenV3({super.key});

  @override
  State<AddRecordScreenV3> createState() => _AddRecordScreenV3State();
}

class _AddRecordScreenV3State extends State<AddRecordScreenV3> {
  final _formKey = GlobalKey<FormState>();
  final _speciesController = TextEditingController();
  final _countController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  
  final AudioService _audioService = AudioService();
  
  String? _photoPath;
  String? _audioPath;
  bool _isListening = false;
  bool _isRecording = false;
  bool _showMap = false;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    // 음성 인식 초기화
    await _audioService.initializeSpeechRecognition();
    
    // 위치 서비스 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppStateProvider>();
      provider.updateLocation();
      provider.initializeCamera();
    });
  }
  
  @override
  void dispose() {
    _speciesController.dispose();
    _countController.dispose();
    _notesController.dispose();
    _audioService.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('새 기록 추가'),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        actions: [
          // 지도 토글 버튼
          IconButton(
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
            icon: Icon(_showMap ? Icons.list : Icons.map),
            tooltip: _showMap ? '입력 폼 보기' : '지도 보기',
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          if (!provider.hasLocation) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_off,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  const Text(
                    'GPS 위치를 확인하는 중...',
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  ElevatedButton.icon(
                    onPressed: provider.updateLocation,
                    icon: const Icon(Icons.refresh),
                    label: const Text('위치 새로고침'),
                  ),
                ],
              ),
            );
          }
          
          return _showMap ? _buildMapView(provider) : _buildFormView(provider);
        },
      ),
    );
  }
  
  Widget _buildMapView(AppStateProvider provider) {
    return Stack(
      children: [
        // 지도
        MapWidget(
          currentPosition: provider.currentPosition,
          showCurrentLocation: true,
          showRecords: false,
          initialZoom: 15.0,
        ),
        
        // 하단 정보 패널
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusL),
                topRight: Radius.circular(AppDimensions.radiusL),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 위치 정보
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.info,
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
                        ),
                        backgroundColor: AppColors.success.withOpacity(0.1),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingL),
                
                // 기록 추가 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showMap = false;
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('이 위치에서 기록 추가'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.paddingM,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFormView(AppStateProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 위치 카드
            _buildLocationCard(provider),
            const SizedBox(height: AppDimensions.paddingL),
            
            // 종 정보 입력 (음성 입력 가능)
            _buildSpeciesInput(),
            const SizedBox(height: AppDimensions.paddingL),
            
            // 수량 입력
            TextFormField(
              controller: _countController,
              decoration: InputDecoration(
                labelText: '수량',
                prefixIcon: const Icon(Icons.numbers),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        final count = int.tryParse(_countController.text) ?? 0;
                        if (count > 1) {
                          _countController.text = (count - 1).toString();
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    IconButton(
                      onPressed: () {
                        final count = int.tryParse(_countController.text) ?? 0;
                        _countController.text = (count + 1).toString();
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '수량을 입력해주세요';
                }
                if (int.tryParse(value) == null) {
                  return '올바른 숫자를 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingL),
            
            // 메모 입력 (음성 입력 가능)
            _buildNotesInput(),
            const SizedBox(height: AppDimensions.paddingL),
            
            // 사진 촬영
            _buildPhotoSection(provider),
            const SizedBox(height: AppDimensions.paddingL),
            
            // 음성 녹음
            _buildAudioSection(),
            const SizedBox(height: AppDimensions.paddingXL),
            
            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveRecord(provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingL,
                  ),
                ),
                child: const Text(
                  '기록 저장',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLocationCard(AppStateProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _showMap = true;
          });
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
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
                  Icons.location_on,
                  color: AppColors.info,
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
              const Icon(
                Icons.map,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSpeciesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _speciesController,
          decoration: InputDecoration(
            labelText: '종 이름',
            prefixIcon: const Icon(Icons.phishing),
            suffixIcon: IconButton(
              onPressed: _toggleSpeechToText,
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? AppColors.error : null,
              ),
              tooltip: '음성으로 입력',
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '종 이름을 입력해주세요';
            }
            return null;
          },
        ),
        if (_isListening)
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.paddingS),
            child: Text(
              '음성 인식 중... 말씀해주세요',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: '메모 (선택)',
            prefixIcon: const Icon(Icons.note),
            suffixIcon: IconButton(
              onPressed: _toggleNoteSpeechToText,
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? AppColors.error : null,
              ),
              tooltip: '음성으로 입력',
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
  
  Widget _buildPhotoSection(AppStateProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '사진',
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: AppDimensions.paddingS),
        if (_photoPath != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                child: Image.file(
                  File(_photoPath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _photoPath = null;
                    });
                  },
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ),
            ],
          )
        else
          OutlinedButton.icon(
            onPressed: () => _takePicture(provider),
            icon: const Icon(Icons.camera_alt),
            label: const Text('사진 촬영'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
      ],
    );
  }
  
  Widget _buildAudioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '음성 메모',
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: AppDimensions.paddingS),
        if (_audioPath != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.audiotrack, color: AppColors.info),
              title: const Text('음성 녹음 완료'),
              subtitle: Text('파일: ${_audioPath!.split('/').last}'),
              trailing: IconButton(
                onPressed: () {
                  setState(() {
                    _audioPath = null;
                  });
                },
                icon: const Icon(Icons.delete, color: AppColors.error),
              ),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: _toggleAudioRecording,
            icon: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: _isRecording ? AppColors.error : null,
            ),
            label: Text(_isRecording ? '녹음 중지' : '음성 녹음'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(
                color: _isRecording ? AppColors.error : AppColors.primaryBlue,
              ),
            ),
          ),
        if (_isRecording)
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.paddingS),
            child: LinearProgressIndicator(
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
            ),
          ),
      ],
    );
  }
  
  Future<void> _toggleSpeechToText() async {
    if (_isListening) {
      final result = await _audioService.stopListening();
      if (result.isSuccess && result.data!.isNotEmpty) {
        _speciesController.text = result.data!;
      }
      setState(() {
        _isListening = false;
      });
    } else {
      setState(() {
        _isListening = true;
      });
      
      final result = await _audioService.startListening(
        onResult: (text) {
          setState(() {
            _speciesController.text = text;
          });
        },
        onFinalResult: (finalText) {
          setState(() {
            _isListening = false;
          });
        },
      );
      
      if (result.isFailure) {
        setState(() {
          _isListening = false;
        });
        if (mounted) {
          UIHelpers.showSnackBar(
            context,
            '음성 인식을 시작할 수 없습니다',
            type: SnackBarType.error,
          );
        }
      }
    }
  }
  
  Future<void> _toggleNoteSpeechToText() async {
    if (_isListening) {
      final result = await _audioService.stopListening();
      if (result.isSuccess && result.data!.isNotEmpty) {
        _notesController.text = result.data!;
      }
      setState(() {
        _isListening = false;
      });
    } else {
      setState(() {
        _isListening = true;
      });
      
      final result = await _audioService.startListening(
        onResult: (text) {
          setState(() {
            _notesController.text = text;
          });
        },
        onFinalResult: (finalText) {
          setState(() {
            _isListening = false;
          });
        },
      );
      
      if (result.isFailure) {
        setState(() {
          _isListening = false;
        });
        if (mounted) {
          UIHelpers.showSnackBar(
            context,
            '음성 인식을 시작할 수 없습니다',
            type: SnackBarType.error,
          );
        }
      }
    }
  }
  
  Future<void> _toggleAudioRecording() async {
    if (_isRecording) {
      final result = await _audioService.stopRecording();
      if (result.isSuccess) {
        setState(() {
          _audioPath = result.data;
          _isRecording = false;
        });
        if (mounted) {
          UIHelpers.showSnackBar(
            context,
            '음성 녹음이 완료되었습니다',
            type: SnackBarType.success,
          );
        }
      } else {
        setState(() {
          _isRecording = false;
        });
        if (mounted) {
          UIHelpers.showSnackBar(
            context,
            '녹음 중지 실패',
            type: SnackBarType.error,
          );
        }
      }
    } else {
      final result = await _audioService.startRecording();
      if (result.isSuccess) {
        setState(() {
          _isRecording = true;
        });
      } else {
        if (mounted) {
          UIHelpers.showSnackBar(
            context,
            '녹음을 시작할 수 없습니다',
            type: SnackBarType.error,
          );
        }
      }
    }
  }
  
  Future<void> _takePicture(AppStateProvider provider) async {
    final result = await provider.takePictureWithGPS();
    if (result.isSuccess) {
      setState(() {
        _photoPath = result.data;
      });
    } else {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          '사진 촬영 실패',
          type: SnackBarType.error,
        );
      }
    }
  }
  
  Future<void> _saveRecord(AppStateProvider provider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final record = FishingRecord(
      species: _speciesController.text,
      count: int.parse(_countController.text),
      latitude: provider.currentPosition!.latitude,
      longitude: provider.currentPosition!.longitude,
      accuracy: provider.currentPosition!.accuracy,
      photoPath: _photoPath,
      audioPath: _audioPath,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      timestamp: DateTime.now(),
    );
    
    final result = await provider.addRecord(record);
    
    if (result.isSuccess) {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          '기록이 저장되었습니다',
          type: SnackBarType.success,
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          '기록 저장 실패',
          type: SnackBarType.error,
        );
      }
    }
  }
}