import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/app_state_provider.dart';
import '../providers/map_state_provider.dart';
import '../models/fishing_record.dart';
import '../services/audio_service.dart';
import '../widgets/map_widget.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/ui_helpers.dart';
import '../core/utils/date_formatter.dart';
import '../core/utils/app_logger.dart';
import 'map_screen.dart';

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
  bool _isListeningSpecies = false;  // 종 이름 음성 인식 상태
  bool _isListeningNotes = false;    // 메모 음성 인식 상태
  bool _isRecording = false;
  
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
          // 지도 화면으로 이동
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MapScreen(),
                ),
              );
            },
            icon: const Icon(Icons.map),
            tooltip: '지도 보기',
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
          
          return _buildFormView(provider);
        },
      ),
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
            
            // 종 정보 입력 (실시간 음성→텍스트 변환)
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
            
            // 메모 입력 (실시간 음성→텍스트 변환)
            _buildNotesInput(),
            const SizedBox(height: AppDimensions.paddingL),
            
            // 사진 촬영 (GPS 메타데이터 포함)
            _buildPhotoSection(provider),
            const SizedBox(height: AppDimensions.paddingL),
            
            // 음성 파일 녹음 (별도 파일로 저장)
            _buildAudioSection(),
            const SizedBox(height: AppDimensions.paddingXL),
            
            // 전체 기록 저장 (위의 모든 데이터를 하나의 기록으로 저장)
            Container(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _saveRecord(provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.save,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '기록 저장',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MapScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _speciesController,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: '종 이름',
                  labelStyle: const TextStyle(fontSize: 16),
                  prefixIcon: const Icon(Icons.phishing, size: 28),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingL,
                    vertical: AppDimensions.paddingL,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '종 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            // 음성 입력 버튼 - 통일된 디자인
            _buildVoiceInputButton(
              onTap: _toggleSpeechToText,
              isListening: _isListeningSpecies,
            ),
          ],
        ),
        if (_isListeningSpecies)
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.paddingM),
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.mic, color: AppColors.error, size: 20),
                  const SizedBox(width: AppDimensions.paddingS),
                  Text(
                    '음성 인식 중... 말씀해주세요',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _notesController,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: '메모 (선택)',
                  labelStyle: const TextStyle(fontSize: 16),
                  prefixIcon: const Icon(Icons.note, size: 28),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingL,
                    vertical: AppDimensions.paddingL,
                  ),
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            // 음성 입력 버튼 - 통일된 디자인
            _buildVoiceInputButton(
              onTap: _toggleNoteSpeechToText,
              isListening: _isListeningNotes,
            ),
          ],
        ),
        if (_isListeningNotes)
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.paddingM),
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.mic, color: AppColors.error, size: 20),
                  const SizedBox(width: AppDimensions.paddingS),
                  Text(
                    '메모 음성 인식 중... 말씀해주세요',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
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
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.oceanGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _takePicture(provider),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingXL,
                    vertical: AppDimensions.paddingL,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt,
                        color: AppColors.white,
                        size: 32,
                      ),
                      const SizedBox(width: AppDimensions.paddingM),
                      Text(
                        '사진 촬영',
                        style: AppTextStyles.buttonLarge.copyWith(
                          color: AppColors.white,
                          fontSize: 18,
                        ),
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
  
  Widget _buildAudioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '음성 파일 녹음',
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
          Container(
            decoration: BoxDecoration(
              color: _isRecording ? AppColors.error : AppColors.secondaryGreen,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (_isRecording ? AppColors.error : AppColors.secondaryGreen)
                      .withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _toggleAudioRecording,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingXL,
                    vertical: AppDimensions.paddingL,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: AppColors.white,
                        size: 32,
                      ),
                      const SizedBox(width: AppDimensions.paddingM),
                      Text(
                        _isRecording ? '파일 녹음 중지' : '음성 파일 녹음',
                        style: AppTextStyles.buttonLarge.copyWith(
                          color: AppColors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
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
  
  /// 공통 음성 입력 버튼 위젯
  Widget _buildVoiceInputButton({
    required VoidCallback onTap,
    required bool isListening,
  }) {
    return Container(
      height: 56, // TextFormField와 동일한 높이
      width: 56,  // 정사각형 버튼
      decoration: BoxDecoration(
        color: isListening ? AppColors.error : AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isListening ? AppColors.error : AppColors.primaryBlue)
                .withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Icon(
            isListening ? Icons.mic : Icons.mic_none,
            color: AppColors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
  
  Future<void> _toggleSpeechToText() async {
    // 메모 음성 인식이 작동 중이면 중지
    if (_isListeningNotes) {
      await _audioService.stopListening();
      setState(() {
        _isListeningNotes = false;
      });
    }
    
    if (_isListeningSpecies) {
      final result = await _audioService.stopListening();
      if (result.isSuccess && result.data!.isNotEmpty) {
        _speciesController.text = result.data!;
      }
      setState(() {
        _isListeningSpecies = false;
      });
    } else {
      setState(() {
        _isListeningSpecies = true;
      });
      
      final result = await _audioService.startListening(
        onResult: (text) {
          setState(() {
            _speciesController.text = text;
          });
        },
        onFinalResult: (finalText) {
          setState(() {
            _isListeningSpecies = false;
          });
        },
      );
      
      if (result.isFailure) {
        setState(() {
          _isListeningSpecies = false;
        });
        if (mounted) {
          UIHelpers.showSnackBar(
            context,
            message: '음성 인식을 시작할 수 없습니다',
            type: SnackBarType.error,
          );
        }
      }
    }
  }
  
  Future<void> _toggleNoteSpeechToText() async {
    // 종 이름 음성 인식이 작동 중이면 중지
    if (_isListeningSpecies) {
      await _audioService.stopListening();
      setState(() {
        _isListeningSpecies = false;
      });
    }
    
    if (_isListeningNotes) {
      final result = await _audioService.stopListening();
      if (result.isSuccess && result.data!.isNotEmpty) {
        _notesController.text = result.data!;
      }
      setState(() {
        _isListeningNotes = false;
      });
    } else {
      setState(() {
        _isListeningNotes = true;
      });
      
      final result = await _audioService.startListening(
        onResult: (text) {
          setState(() {
            _notesController.text = text;
          });
        },
        onFinalResult: (finalText) {
          setState(() {
            _isListeningNotes = false;
          });
        },
      );
      
      if (result.isFailure) {
        setState(() {
          _isListeningNotes = false;
        });
        if (mounted) {
          UIHelpers.showSnackBar(
            context,
            message: '음성 인식을 시작할 수 없습니다',
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
            message: '음성 녹음이 완료되었습니다',
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
            message: '녹음 중지 실패',
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
            message: '녹음을 시작할 수 없습니다',
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
          message: '사진 촬영 실패',
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
      // 기록 저장 성공시 지도에 마커도 추가
      final mapProvider = context.read<MapStateProvider>();
      mapProvider.addMarker(
        lat: record.latitude,
        lng: record.longitude,
        memo: '${record.species} ${record.count}마리',
      );
      
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          message: '기록과 지도 마커가 저장되었습니다',
          type: SnackBarType.success,
        );
        Navigator.pop(context, true);  // 성공 시 true 반환
      }
    } else {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          message: '기록 저장 실패',
          type: SnackBarType.error,
        );
      }
    }
  }
}