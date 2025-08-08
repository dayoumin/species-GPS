import 'dart:io';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../core/utils/result.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/app_logger.dart';

/// 음성 녹음 및 음성 인식 서비스
class AudioService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final SpeechToText _speechToText = SpeechToText();
  
  bool _isRecording = false;
  bool _isSpeechEnabled = false;
  String _recordingPath = '';
  String _recognizedText = '';
  
  // Getters
  bool get isRecording => _isRecording;
  bool get isSpeechEnabled => _isSpeechEnabled;
  String get recognizedText => _recognizedText;
  
  /// 음성 인식 초기화
  Future<Result<void>> initializeSpeechRecognition() async {
    try {
      _isSpeechEnabled = await _speechToText.initialize(
        onError: (error) {
          AppLogger.error('Speech recognition error', error);
        },
        onStatus: (status) {
          AppLogger.debug('Speech recognition status: $status');
        },
      );
      
      if (_isSpeechEnabled) {
        AppLogger.info('Speech recognition initialized successfully');
        return Result.success(null);
      } else {
        return Result.failure(
          AppException(
            message: '음성 인식을 사용할 수 없습니다',
            code: 'SPEECH_INIT_FAILED',
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize speech recognition', e, stackTrace);
      return Result.failure(
        AppException(
          message: '음성 인식 초기화 실패',
          code: 'SPEECH_INIT_ERROR',
          originalError: e,
        ),
      );
    }
  }
  
  /// 음성 녹음 시작
  Future<Result<void>> startRecording() async {
    try {
      // 권한 확인
      if (await _audioRecorder.hasPermission()) {
        // 저장 경로 생성
        final directory = await getApplicationDocumentsDirectory();
        final audioDir = Directory(path.join(directory.path, 'audio_records'));
        if (!await audioDir.exists()) {
          await audioDir.create(recursive: true);
        }
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _recordingPath = path.join(audioDir.path, 'record_$timestamp.m4a');
        
        // 녹음 시작
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _recordingPath,
        );
        
        _isRecording = true;
        
        AppLogger.info('Audio recording started: $_recordingPath');
        return Result.success(null);
      } else {
        return Result.failure(
          PermissionException.denied('마이크'),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to start recording', e, stackTrace);
      return Result.failure(
        AppException(
          message: '녹음 시작 실패',
          code: 'RECORDING_START_FAILED',
          originalError: e,
        ),
      );
    }
  }
  
  /// 음성 녹음 중지
  Future<Result<String>> stopRecording() async {
    try {
      if (!_isRecording) {
        return Result.failure(
          AppException(
            message: '녹음 중이 아닙니다',
            code: 'NOT_RECORDING',
          ),
        );
      }
      
      final path = await _audioRecorder.stop();
      _isRecording = false;
      
      if (path != null) {
        AppLogger.info('Audio recording stopped: $path');
        return Result.success(path);
      } else {
        return Result.failure(
          AppException(
            message: '녹음 파일 저장 실패',
            code: 'RECORDING_SAVE_FAILED',
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to stop recording', e, stackTrace);
      return Result.failure(
        AppException(
          message: '녹음 중지 실패',
          code: 'RECORDING_STOP_FAILED',
          originalError: e,
        ),
      );
    }
  }
  
  /// 실시간 음성 인식 시작
  Future<Result<void>> startListening({
    required Function(String text) onResult,
    Function(String finalText)? onFinalResult,
  }) async {
    try {
      if (!_isSpeechEnabled) {
        final initResult = await initializeSpeechRecognition();
        if (initResult.isFailure) {
          return initResult;
        }
      }
      
      _recognizedText = '';
      
      await _speechToText.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          onResult(_recognizedText);
          
          if (result.finalResult && onFinalResult != null) {
            onFinalResult(_recognizedText);
          }
          
          AppLogger.debug('Speech recognition result: $_recognizedText (final: ${result.finalResult})');
        },
        listenMode: ListenMode.dictation,
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'ko_KR', // 한국어 설정
      );
      
      AppLogger.info('Speech recognition started');
      return Result.success(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to start listening', e, stackTrace);
      return Result.failure(
        AppException(
          message: '음성 인식 시작 실패',
          code: 'LISTENING_START_FAILED',
          originalError: e,
        ),
      );
    }
  }
  
  /// 음성 인식 중지
  Future<Result<String>> stopListening() async {
    try {
      await _speechToText.stop();
      
      final finalText = _recognizedText;
      AppLogger.info('Speech recognition stopped. Final text: $finalText');
      
      return Result.success(finalText);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to stop listening', e, stackTrace);
      return Result.failure(
        AppException(
          message: '음성 인식 중지 실패',
          code: 'LISTENING_STOP_FAILED',
          originalError: e,
        ),
      );
    }
  }
  
  /// 음성 인식 취소
  Future<void> cancelListening() async {
    try {
      await _speechToText.cancel();
      _recognizedText = '';
      AppLogger.info('Speech recognition cancelled');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cancel listening', e, stackTrace);
    }
  }
  
  /// 음성 인식 상태 확인
  bool get isListening => _speechToText.isListening;
  
  /// 사용 가능한 언어 목록 가져오기
  Future<List<LocaleName>> getAvailableLanguages() async {
    try {
      final locales = await _speechToText.locales();
      return locales;
    } catch (e) {
      AppLogger.error('Failed to get available languages', e);
      return [];
    }
  }
  
  /// 리소스 정리
  void dispose() {
    _audioRecorder.dispose();
    _speechToText.cancel();
  }
}