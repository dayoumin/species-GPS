import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import '../core/utils/result.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/app_logger.dart';

/// 음성 녹음 및 음성 인식 서비스 (flutter_sound 버전)
class AudioService {
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final SpeechToText _speechToText = SpeechToText();
  
  bool _isRecording = false;
  bool _isSpeechEnabled = false;
  bool _isRecorderInitialized = false;
  String _recordingPath = '';
  String _recognizedText = '';
  
  // Getters
  bool get isRecording => _isRecording;
  bool get isSpeechEnabled => _isSpeechEnabled;
  String get recognizedText => _recognizedText;
  
  /// 레코더 초기화
  Future<Result<void>> _initializeRecorder() async {
    if (_isRecorderInitialized) return Result.success(null);
    
    try {
      await _audioRecorder.openRecorder();
      _isRecorderInitialized = true;
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        AudioException(
          message: '오디오 레코더 초기화 실패',
          originalError: e,
        ),
      );
    }
  }
  
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
          AudioException(
            message: '음성 인식 기능을 사용할 수 없습니다',
          ),
        );
      }
    } catch (e) {
      return Result.failure(
        AudioException(
          message: '음성 인식 초기화 실패',
          originalError: e,
        ),
      );
    }
  }
  
  /// 음성 녹음 시작
  Future<Result<void>> startRecording() async {
    try {
      // 권한 확인
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return Result.failure(
          AudioException(message: '마이크 권한이 거부되었습니다'),
        );
      }
      
      // 레코더 초기화
      final initResult = await _initializeRecorder();
      if (initResult.isFailure) return initResult;
      
      // 저장 경로 설정
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = path.join(
        directory.path,
        'recording_$timestamp.aac',
      );
      
      // 녹음 시작
      await _audioRecorder.startRecorder(
        toFile: _recordingPath,
        codec: Codec.aacADTS,
      );
      
      _isRecording = true;
      AppLogger.info('Recording started: $_recordingPath');
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        AudioException(
          message: '녹음 시작 실패',
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
          AudioException(message: '녹음 중이 아닙니다'),
        );
      }
      
      await _audioRecorder.stopRecorder();
      _isRecording = false;
      
      AppLogger.info('Recording stopped: $_recordingPath');
      
      // 파일 존재 확인
      final file = File(_recordingPath);
      if (await file.exists()) {
        return Result.success(_recordingPath);
      } else {
        return Result.failure(
          AudioException(message: '녹음 파일을 찾을 수 없습니다'),
        );
      }
    } catch (e) {
      _isRecording = false;
      return Result.failure(
        AudioException(
          message: '녹음 중지 실패',
          originalError: e,
        ),
      );
    }
  }
  
  /// 음성을 텍스트로 변환 시작
  Future<Result<void>> startListening({
    required Function(String) onResult,
    Function(String)? onFinalResult,
  }) async {
    try {
      if (!_isSpeechEnabled) {
        final initResult = await initializeSpeechRecognition();
        if (initResult.isFailure) return initResult;
      }
      
      await _speechToText.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          onResult(_recognizedText);
          
          if (result.finalResult && onFinalResult != null) {
            onFinalResult(_recognizedText);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'ko_KR',
      );
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        AudioException(
          message: '음성 인식 시작 실패',
          originalError: e,
        ),
      );
    }
  }
  
  /// 음성 인식 중지
  Future<Result<String>> stopListening() async {
    try {
      await _speechToText.stop();
      final result = _recognizedText;
      _recognizedText = '';
      return Result.success(result);
    } catch (e) {
      return Result.failure(
        AudioException(
          message: '음성 인식 중지 실패',
          originalError: e,
        ),
      );
    }
  }
  
  /// 녹음 파일 저장 (영구 저장소로 이동)
  Future<Result<String>> saveRecording(String fileName) async {
    try {
      if (_recordingPath.isEmpty) {
        return Result.failure(
          AudioException(message: '저장할 녹음 파일이 없습니다'),
        );
      }
      
      // 앱 문서 디렉토리 가져오기
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory(path.join(directory.path, 'audio'));
      
      // 디렉토리가 없으면 생성
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      
      // 파일 이동
      final tempFile = File(_recordingPath);
      final newPath = path.join(audioDir.path, fileName);
      final newFile = await tempFile.copy(newPath);
      
      // 임시 파일 삭제
      await tempFile.delete();
      
      _recordingPath = '';
      
      return Result.success(newFile.path);
    } catch (e) {
      return Result.failure(
        AudioException(
          message: '녹음 파일 저장 실패',
          originalError: e,
        ),
      );
    }
  }
  
  /// 리소스 정리
  void dispose() {
    if (_isRecording) {
      _audioRecorder.stopRecorder();
    }
    if (_isRecorderInitialized) {
      _audioRecorder.closeRecorder();
    }
    _speechToText.stop();
  }
}