import 'package:intl/intl.dart';

/// 날짜 포맷팅 유틸리티 클래스
class DateFormatter {
  DateFormatter._();
  
  // 날짜/시간 포맷터 인스턴스 (재사용을 위해 static으로 선언)
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _dateOnlyFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeOnlyFormat = DateFormat('HH:mm');
  static final DateFormat _groupDateFormat = DateFormat('yyyy년 MM월 dd일');
  static final DateFormat _monthYearFormat = DateFormat('yyyy년 MM월');
  static final DateFormat _fullDateTimeFormat = DateFormat('yyyy년 MM월 dd일 HH시 mm분');
  static final DateFormat _shortDateFormat = DateFormat('MM/dd');
  static final DateFormat _exportDateFormat = DateFormat('yyyyMMdd_HHmmss');
  
  /// 기본 날짜/시간 포맷 (yyyy-MM-dd HH:mm)
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }
  
  /// 날짜만 포맷 (yyyy-MM-dd)
  static String formatDate(DateTime date) {
    return _dateOnlyFormat.format(date);
  }
  
  /// 시간만 포맷 (HH:mm)
  static String formatTime(DateTime time) {
    return _timeOnlyFormat.format(time);
  }
  
  /// 그룹 날짜 포맷 (yyyy년 MM월 dd일)
  static String formatGroupDate(DateTime date) {
    return _groupDateFormat.format(date);
  }
  
  /// 월/년 포맷 (yyyy년 MM월)
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }
  
  /// 전체 날짜/시간 포맷 (yyyy년 MM월 dd일 HH시 mm분)
  static String formatFullDateTime(DateTime dateTime) {
    return _fullDateTimeFormat.format(dateTime);
  }
  
  /// 짧은 날짜 포맷 (MM/dd)
  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }
  
  /// 파일 내보내기용 날짜 포맷 (yyyyMMdd_HHmmss)
  static String formatForExport(DateTime dateTime) {
    return _exportDateFormat.format(dateTime);
  }
  
  /// 상대적 시간 표시 (방금 전, n분 전, n시간 전, 어제, n일 전 등)
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks주 전';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months개월 전';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years년 전';
    }
  }
  
  /// 오늘인지 확인
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
  
  /// 어제인지 확인
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }
  
  /// 이번 주인지 확인
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
           date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }
  
  /// 이번 달인지 확인
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }
  
  /// 날짜 범위 포맷팅
  static String formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year) {
      if (start.month == end.month) {
        if (start.day == end.day) {
          return formatDate(start);
        } else {
          return '${start.day}일 - ${end.day}일, ${formatMonthYear(start)}';
        }
      } else {
        return '${DateFormat('MM월 dd일').format(start)} - ${DateFormat('MM월 dd일').format(end)}, ${start.year}년';
      }
    } else {
      return '${formatDate(start)} - ${formatDate(end)}';
    }
  }
  
  /// 커스텀 포맷 적용
  static String formatCustom(DateTime dateTime, String pattern) {
    return DateFormat(pattern).format(dateTime);
  }
}