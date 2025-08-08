import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// 앱 전역 로거 클래스
class AppLogger {
  static late Logger _logger;
  static bool _initialized = false;
  
  /// 로거 초기화
  static void init({Level logLevel = Level.debug}) {
    if (_initialized) return;
    
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: kDebugMode ? 2 : 0,
        errorMethodCount: kDebugMode ? 8 : 3,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      level: kDebugMode ? logLevel : Level.warning,
      filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
    );
    
    _initialized = true;
  }
  
  /// 디버그 로그
  static void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.d(message, error: error, stackTrace: stackTrace);
  }
  
  /// 정보 로그
  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.i(message, error: error, stackTrace: stackTrace);
  }
  
  /// 경고 로그
  static void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.w(message, error: error, stackTrace: stackTrace);
  }
  
  /// 에러 로그
  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
  
  /// 치명적 에러 로그
  static void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
  
  /// 추적 로그 (매우 상세한 로그)
  static void trace(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.t(message, error: error, stackTrace: stackTrace);
  }
  
  /// 네트워크 요청 로그
  static void network({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
    int? statusCode,
    dynamic response,
    Duration? duration,
  }) {
    _ensureInitialized();
    
    final buffer = StringBuffer();
    buffer.writeln('🌐 Network Request');
    buffer.writeln('  Method: $method');
    buffer.writeln('  URL: $url');
    
    if (headers != null && headers.isNotEmpty) {
      buffer.writeln('  Headers: $headers');
    }
    
    if (body != null) {
      buffer.writeln('  Body: $body');
    }
    
    if (statusCode != null) {
      buffer.writeln('  Status Code: $statusCode');
    }
    
    if (response != null) {
      buffer.writeln('  Response: $response');
    }
    
    if (duration != null) {
      buffer.writeln('  Duration: ${duration.inMilliseconds}ms');
    }
    
    _logger.i(buffer.toString());
  }
  
  /// 데이터베이스 쿼리 로그
  static void database({
    required String operation,
    String? table,
    String? query,
    Map<String, dynamic>? parameters,
    dynamic result,
    Duration? duration,
  }) {
    _ensureInitialized();
    
    final buffer = StringBuffer();
    buffer.writeln('🗄️ Database Operation');
    buffer.writeln('  Operation: $operation');
    
    if (table != null) {
      buffer.writeln('  Table: $table');
    }
    
    if (query != null) {
      buffer.writeln('  Query: $query');
    }
    
    if (parameters != null && parameters.isNotEmpty) {
      buffer.writeln('  Parameters: $parameters');
    }
    
    if (result != null) {
      buffer.writeln('  Result: $result');
    }
    
    if (duration != null) {
      buffer.writeln('  Duration: ${duration.inMilliseconds}ms');
    }
    
    _logger.d(buffer.toString());
  }
  
  /// 성능 측정 로그
  static void performance({
    required String operation,
    required Duration duration,
    Map<String, dynamic>? metadata,
  }) {
    _ensureInitialized();
    
    final buffer = StringBuffer();
    buffer.writeln('⚡ Performance');
    buffer.writeln('  Operation: $operation');
    buffer.writeln('  Duration: ${duration.inMilliseconds}ms');
    
    if (metadata != null && metadata.isNotEmpty) {
      buffer.writeln('  Metadata: $metadata');
    }
    
    if (duration.inMilliseconds > 1000) {
      _logger.w(buffer.toString());
    } else {
      _logger.d(buffer.toString());
    }
  }
  
  /// 사용자 액션 로그
  static void userAction({
    required String action,
    String? screen,
    Map<String, dynamic>? parameters,
  }) {
    _ensureInitialized();
    
    final buffer = StringBuffer();
    buffer.writeln('👤 User Action');
    buffer.writeln('  Action: $action');
    
    if (screen != null) {
      buffer.writeln('  Screen: $screen');
    }
    
    if (parameters != null && parameters.isNotEmpty) {
      buffer.writeln('  Parameters: $parameters');
    }
    
    _logger.i(buffer.toString());
  }
  
  /// 로거 초기화 확인
  static void _ensureInitialized() {
    if (!_initialized) {
      init();
    }
  }
}

/// 개발 환경 로그 필터
class DevelopmentFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}

/// 프로덕션 환경 로그 필터
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // 프로덕션에서는 warning 이상만 로그
    return event.level.index >= Level.warning.index;
  }
}