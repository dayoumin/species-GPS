import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../models/fishing_record.dart';
import '../providers/app_state_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/ui_helpers.dart';
import '../widgets/primary_button.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/info_card.dart';

enum RecordMode { camera, detailed }

class AddRecordScreenV2 extends StatefulWidget {
  final RecordMode mode;
  
  const AddRecordScreenV2({
    Key? key,
    required this.mode,
  }) : super(key: key);

  @override
  State<AddRecordScreenV2> createState() => _AddRecordScreenV2State();
}

class _AddRecordScreenV2State extends State<AddRecordScreenV2> {
  final _formKey = GlobalKey<FormState>();
  final _speciesController = TextEditingController();
  final _countController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _photoPath;
  bool _isLoading = false;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    if (widget.mode == RecordMode.camera) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final provider = context.read<AppStateProvider>();
    final result = await provider.initializeCamera();
    
    if (result.isFailure && mounted) {
      UIHelpers.showErrorSnackBar(context, result.errorOrNull!);
    }
  }

  @override
  void dispose() {
    _speciesController.dispose();
    _countController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final provider = context.read<AppStateProvider>();
    
    setState(() => _isLoading = true);
    
    final result = await provider.takePictureWithGPS();
    
    setState(() => _isLoading = false);
    
    result.fold(
      onSuccess: (path) {
        setState(() => _photoPath = path);
        UIHelpers.showSnackBar(
          context,
          message: '사진이 저장되었습니다',
          type: SnackBarType.success,
        );
      },
      onFailure: (error) {
        UIHelpers.showErrorSnackBar(context, error);
      },
    );
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;
    
    final provider = context.read<AppStateProvider>();
    
    if (!provider.hasLocation) {
      UIHelpers.showSnackBar(
        context,
        message: '위치 정보를 가져올 수 없습니다',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    final record = FishingRecord(
      species: _speciesController.text.trim(),
      count: int.parse(_countController.text),
      latitude: provider.currentPosition!.latitude,
      longitude: provider.currentPosition!.longitude,
      accuracy: provider.currentPosition!.accuracy,
      photoPath: _photoPath,
      notes: _notesController.text.trim(),
      timestamp: DateTime.now(),
    );

    final result = await provider.addRecord(record);

    setState(() => _isLoading = false);

    result.fold(
      onSuccess: (_) {
        Navigator.pop(context, true);
        UIHelpers.showSnackBar(
          context,
          message: '기록이 저장되었습니다',
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
        title: Text(
          widget.mode == RecordMode.camera ? '사진 기록' : '상세 기록',
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: '처리 중...')
          : Consumer<AppStateProvider>(
              builder: (context, provider, child) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 카메라 섹션
                        if (widget.mode == RecordMode.camera)
                          _buildCameraSection(provider),
                        
                        // GPS 정보
                        _buildGpsInfoSection(provider),
                        const SizedBox(height: AppDimensions.paddingL),
                        
                        // 입력 필드
                        _buildInputFields(),
                        const SizedBox(height: AppDimensions.paddingXL),
                        
                        // 저장 버튼
                        PrimaryButton(
                          text: '저장',
                          onPressed: _saveRecord,
                          variant: ButtonVariant.primary,
                          icon: Icons.save,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildCameraSection(AppStateProvider provider) {
    return Column(
      children: [
        Container(
          height: AppDimensions.cameraPreviewHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(
              color: AppColors.divider,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL - 2),
            child: _photoPath != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(_photoPath!),
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: AppDimensions.paddingM,
                        right: AppDimensions.paddingM,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(AppDimensions.paddingS),
                          child: const Icon(
                            Icons.check,
                            color: AppColors.white,
                            size: AppDimensions.iconM,
                          ),
                        ),
                      ),
                    ],
                  )
                : provider.isCameraInitialized && 
                  provider.cameraService.controller != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(provider.cameraService.controller!),
                          // 플래시 버튼
                          Positioned(
                            top: AppDimensions.paddingM,
                            right: AppDimensions.paddingM,
                            child: IconButton(
                              onPressed: () async {
                                setState(() {
                                  _flashMode = _flashMode == FlashMode.off
                                      ? FlashMode.torch
                                      : FlashMode.off;
                                });
                                await provider.cameraService
                                    .setFlashMode(_flashMode);
                              },
                              icon: Icon(
                                _flashMode == FlashMode.off
                                    ? Icons.flash_off
                                    : Icons.flash_on,
                                color: AppColors.white,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: LoadingIndicator(
                          isFullScreen: false,
                          message: '카메라 준비 중...',
                        ),
                      ),
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        if (_photoPath == null)
          PrimaryButton(
            text: '사진 촬영',
            onPressed: _takePicture,
            icon: Icons.camera,
            size: ButtonSize.medium,
            isFullWidth: false,
          )
        else
          PrimaryButton(
            text: '다시 촬영',
            onPressed: () {
              setState(() => _photoPath = null);
            },
            icon: Icons.refresh,
            size: ButtonSize.medium,
            variant: ButtonVariant.outline,
            isFullWidth: false,
          ),
        const SizedBox(height: AppDimensions.paddingL),
      ],
    );
  }

  Widget _buildGpsInfoSection(AppStateProvider provider) {
    if (!provider.hasLocation) {
      return InfoCard(
        title: 'GPS 정보 없음',
        subtitle: '위치 정보를 가져올 수 없습니다',
        icon: Icons.location_off,
        type: InfoCardType.warning,
      );
    }

    final position = provider.currentPosition!;
    
    return InfoCard(
      title: 'GPS 정보',
      icon: Icons.location_on,
      type: InfoCardType.success,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCoordinateItem(
                  '위도',
                  position.latitude.toStringAsFixed(6),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: _buildCoordinateItem(
                  '경도',
                  position.longitude.toStringAsFixed(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingS),
          _buildCoordinateItem(
            '정확도',
            '±${position.accuracy.toStringAsFixed(1)}m',
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall,
        ),
        Text(
          value,
          style: AppTextStyles.gpsCoordinate,
        ),
      ],
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        TextFormField(
          controller: _speciesController,
          decoration: InputDecoration(
            labelText: '어종명',
            hintText: '예: 고등어',
            prefixIcon: const Icon(Icons.pets),
            filled: true,
            fillColor: AppColors.white,
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '어종명을 입력해주세요';
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.paddingM),
        
        TextFormField(
          controller: _countController,
          decoration: InputDecoration(
            labelText: '개체수',
            hintText: '예: 5',
            prefixIcon: const Icon(Icons.numbers),
            filled: true,
            fillColor: AppColors.white,
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '개체수를 입력해주세요';
            }
            final count = int.tryParse(value);
            if (count == null || count <= 0) {
              return '올바른 숫자를 입력해주세요';
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.paddingM),
        
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: '메모 (선택)',
            hintText: '추가 정보를 입력하세요',
            prefixIcon: const Icon(Icons.note),
            filled: true,
            fillColor: AppColors.white,
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}