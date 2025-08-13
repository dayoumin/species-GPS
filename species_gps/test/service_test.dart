import 'package:flutter_test/flutter_test.dart';
import 'package:species_gps/core/utils/result.dart';
import 'package:species_gps/core/utils/date_formatter.dart';
import 'package:species_gps/core/utils/file_helpers.dart';

void main() {
  group('Result Type Tests', () {
    test('Result.success contains data', () {
      final result = Result.success('test data');
      
      expect(result.isSuccess, true);
      expect(result.isFailure, false);
      expect(result.data, 'test data');
      expect(result.error, null);
    });

    test('Result.failure contains error', () {
      final error = Exception('Test error');
      final result = Result.failure(error);
      
      expect(result.isSuccess, false);
      expect(result.isFailure, true);
      expect(result.data, null);
      expect(result.error, error);
    });

    test('Result fold works correctly', () {
      final successResult = Result.success(42);
      final failureResult = Result.failure(Exception('Error'));

      final successValue = successResult.fold(
        onSuccess: (data) => data * 2,
        onFailure: (error) => -1,
      );

      final failureValue = failureResult.fold(
        onSuccess: (data) => data * 2,
        onFailure: (error) => -1,
      );

      expect(successValue, 84);
      expect(failureValue, -1);
    });
  });

  group('DateFormatter Tests', () {
    test('formatDate formats correctly', () {
      final date = DateTime(2025, 1, 13, 14, 30);
      final formatted = DateFormatter.formatDate(date);
      
      expect(formatted, '2025-01-13');
    });

    test('formatTime formats correctly', () {
      final date = DateTime(2025, 1, 13, 14, 30, 45);
      final formatted = DateFormatter.formatTime(date);
      
      expect(formatted, '14:30');
    });

    test('formatDateTime formats correctly', () {
      final date = DateTime(2025, 1, 13, 14, 30);
      final formatted = DateFormatter.formatDateTime(date);
      
      expect(formatted, '2025-01-13 14:30');
    });

    test('formatDateWithDay includes day of week', () {
      final date = DateTime(2025, 1, 13); // Monday
      final formatted = DateFormatter.formatDateWithDay(date);
      
      expect(formatted.contains('월'), true);
    });

    test('formatRelativeTime shows correct relative times', () {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final yesterday = now.subtract(const Duration(days: 1));
      final lastWeek = now.subtract(const Duration(days: 7));

      final hourFormatted = DateFormatter.formatRelativeTime(oneHourAgo);
      final yesterdayFormatted = DateFormatter.formatRelativeTime(yesterday);
      final weekFormatted = DateFormatter.formatRelativeTime(lastWeek);

      expect(hourFormatted.contains('시간'), true);
      expect(yesterdayFormatted.contains('어제'), true);
      expect(weekFormatted.contains('일'), true);
    });

    test('isSameDay correctly identifies same day', () {
      final date1 = DateTime(2025, 1, 13, 10, 30);
      final date2 = DateTime(2025, 1, 13, 15, 45);
      final date3 = DateTime(2025, 1, 14, 10, 30);

      expect(DateFormatter.isSameDay(date1, date2), true);
      expect(DateFormatter.isSameDay(date1, date3), false);
    });

    test('isToday correctly identifies today', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      expect(DateFormatter.isToday(today), true);
      expect(DateFormatter.isToday(yesterday), false);
    });

    test('isYesterday correctly identifies yesterday', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      expect(DateFormatter.isYesterday(yesterday), true);
      expect(DateFormatter.isYesterday(today), false);
      expect(DateFormatter.isYesterday(twoDaysAgo), false);
    });
  });

  group('FileHelpers Tests', () {
    test('generateFileName creates unique names', () {
      final fileName1 = FileHelpers.generateFileName('test', 'jpg');
      final fileName2 = FileHelpers.generateFileName('test', 'jpg');
      
      expect(fileName1, isNot(fileName2));
      expect(fileName1.endsWith('.jpg'), true);
      expect(fileName1.startsWith('test_'), true);
    });

    test('formatFileSize formats bytes correctly', () {
      expect(FileHelpers.formatFileSize(500), '500 B');
      expect(FileHelpers.formatFileSize(1024), '1.0 KB');
      expect(FileHelpers.formatFileSize(1048576), '1.0 MB');
      expect(FileHelpers.formatFileSize(1073741824), '1.0 GB');
    });

    test('getFileExtension extracts extension correctly', () {
      expect(FileHelpers.getFileExtension('/path/to/file.jpg'), 'jpg');
      expect(FileHelpers.getFileExtension('document.pdf'), 'pdf');
      expect(FileHelpers.getFileExtension('no_extension'), '');
      expect(FileHelpers.getFileExtension('/path/to/.hidden'), 'hidden');
    });

    test('sanitizeFileName removes invalid characters', () {
      final sanitized = FileHelpers.sanitizeFileName('file:name/with\\invalid*chars?.txt');
      
      expect(sanitized.contains(':'), false);
      expect(sanitized.contains('/'), false);
      expect(sanitized.contains('\\'), false);
      expect(sanitized.contains('*'), false);
      expect(sanitized.contains('?'), false);
    });
  });
}