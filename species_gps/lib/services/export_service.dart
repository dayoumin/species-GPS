import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import '../models/fishing_record.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/result.dart';

/// 데이터 내보내기 서비스
class ExportService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _fileDateFormat = DateFormat('yyyyMMdd_HHmmss');
  
  /// CSV로 내보내기
  static Future<Result<File>> exportToCSV(
    List<FishingRecord> records, {
    String? fileName,
  }) async {
    try {
      // CSV 데이터 생성
      final List<List<dynamic>> csvData = [
        // 헤더
        [
          '번호',
          '날짜/시간',
          '어종',
          '개체수',
          '위도',
          '경도',
          'GPS정확도(m)',
          '메모',
          '사진경로',
        ],
      ];
      
      // 데이터 추가
      int index = 1;
      for (final record in records) {
        csvData.add([
          index++,
          _dateFormat.format(record.timestamp),
          record.species,
          record.count,
          record.latitude.toStringAsFixed(6),
          record.longitude.toStringAsFixed(6),
          record.accuracy?.toStringAsFixed(1) ?? '',
          record.notes ?? '',
          record.photoPath ?? '',
        ]);
      }
      
      // CSV 문자열로 변환
      final csv = const ListToCsvConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        textEndDelimiter: '"',
      ).convert(csvData);
      
      // 파일 저장
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory(path.join(directory.path, 'exports'));
      await exportDir.create(recursive: true);
      
      final csvFileName = fileName ?? 
          'fishing_records_${_fileDateFormat.format(DateTime.now())}.csv';
      final filePath = path.join(exportDir.path, csvFileName);
      
      final file = File(filePath);
      await file.writeAsString(csv, encoding: utf8);
      
      return Result.success(file);
    } catch (e) {
      return Result.failure(
        StorageException(
          message: 'CSV 내보내기에 실패했습니다.',
          originalError: e,
        ),
      );
    }
  }
  
  /// XLSX로 내보내기
  static Future<Result<File>> exportToXLSX(
    List<FishingRecord> records, {
    String? fileName,
  }) async {
    try {
      // Excel 워크북 생성
      var excel = Excel.createExcel();
      var sheet = excel['기록'];
      
      // 헤더 추가
      sheet.appendRow([
        TextCellValue('번호'),
        TextCellValue('어종'),
        TextCellValue('수량'),
        TextCellValue('위도'),
        TextCellValue('경도'),
        TextCellValue('정확도(m)'),
        TextCellValue('기록시간'),
        TextCellValue('메모'),
        TextCellValue('사진'),
        TextCellValue('음성'),
      ]);
      
      // 헤더 스타일링
      for (int col = 0; col < 10; col++) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue100,
          horizontalAlign: HorizontalAlign.Center,
        );
      }
      
      // 데이터 추가
      for (int i = 0; i < records.length; i++) {
        final record = records[i];
        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(record.species),
          IntCellValue(record.count),
          DoubleCellValue(record.latitude),
          DoubleCellValue(record.longitude),
          DoubleCellValue(record.accuracy ?? 0),
          TextCellValue(_dateFormat.format(record.timestamp)),
          TextCellValue(record.notes ?? ''),
          TextCellValue(record.photoPath != null ? '있음' : '없음'),
          TextCellValue(record.audioPath != null ? '있음' : '없음'),
        ]);
      }
      
      // 열 너비 자동 조정
      for (int col = 0; col < 10; col++) {
        sheet.setColumnAutoFit(col);
      }
      
      // 파일 저장
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory(path.join(directory.path, 'exports'));
      await exportDir.create(recursive: true);
      
      final xlsxFileName = fileName ?? 
          'fishing_records_${_fileDateFormat.format(DateTime.now())}.xlsx';
      final filePath = path.join(exportDir.path, xlsxFileName);
      
      // Excel 파일을 바이트로 변환하여 저장
      var fileBytes = excel.encode();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        return Result.success(file);
      } else {
        return Result.failure(
          StorageException(
            message: 'XLSX 파일 생성에 실패했습니다.',
          ),
        );
      }
    } catch (e) {
      return Result.failure(
        StorageException(
          message: 'XLSX 내보내기에 실패했습니다.',
          originalError: e,
        ),
      );
    }
  }
  
  /// PDF로 내보내기
  static Future<Result<File>> exportToPDF(
    List<FishingRecord> records, {
    String? fileName,
    String? title,
  }) async {
    try {
      final pdf = pw.Document();
      
      // 한글 폰트 로드
      final font = await PdfGoogleFonts.nanumGothicRegular();
      final boldFont = await PdfGoogleFonts.nanumGothicBold();
      
      // 날짜별로 그룹화
      final groupedRecords = <String, List<FishingRecord>>{};
      for (final record in records) {
        final dateKey = DateFormat('yyyy년 MM월 dd일').format(record.timestamp);
        groupedRecords[dateKey] ??= [];
        groupedRecords[dateKey]!.add(record);
      }
      
      // PDF 페이지 생성
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // 제목
            pw.Header(
              level: 0,
              child: pw.Text(
                title ?? '수산생명자원 기록 보고서',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 24,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              '생성일: ${_dateFormat.format(DateTime.now())}',
              style: pw.TextStyle(font: font, fontSize: 12),
            ),
            pw.SizedBox(height: 16),
            
            // 요약 정보
            _buildSummarySection(records, font, boldFont),
            pw.SizedBox(height: 24),
            
            // 상세 기록
            ...groupedRecords.entries.map((entry) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 1,
                  child: pw.Text(
                    entry.key,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 18,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                _buildRecordsTable(entry.value, font),
                pw.SizedBox(height: 16),
              ],
            )),
          ],
        ),
      );
      
      // PDF 저장
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory(path.join(directory.path, 'exports'));
      await exportDir.create(recursive: true);
      
      final pdfFileName = fileName ?? 
          'fishing_report_${_fileDateFormat.format(DateTime.now())}.pdf';
      final filePath = path.join(exportDir.path, pdfFileName);
      
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      return Result.success(file);
    } catch (e) {
      return Result.failure(
        StorageException(
          message: 'PDF 내보내기에 실패했습니다.',
          originalError: e,
        ),
      );
    }
  }
  
  /// 파일 공유
  static Future<Result<void>> shareFile(
    File file, {
    String? subject,
    String? text,
  }) async {
    try {
      final xFile = XFile(file.path);
      
      await Share.shareXFiles(
        [xFile],
        subject: subject,
        text: text,
      );
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        StorageException(
          message: '파일 공유에 실패했습니다.',
          originalError: e,
        ),
      );
    }
  }
  
  /// 여러 파일 공유
  static Future<Result<void>> shareFiles(
    List<File> files, {
    String? subject,
    String? text,
  }) async {
    try {
      final xFiles = files.map((f) => XFile(f.path)).toList();
      
      await Share.shareXFiles(
        xFiles,
        subject: subject,
        text: text,
      );
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        StorageException(
          message: '파일 공유에 실패했습니다.',
          originalError: e,
        ),
      );
    }
  }
  
  /// PDF 요약 섹션 생성
  static pw.Widget _buildSummarySection(
    List<FishingRecord> records,
    pw.Font font,
    pw.Font boldFont,
  ) {
    final totalCount = records.fold<int>(
      0,
      (sum, record) => sum + record.count,
    );
    
    final speciesCount = <String, int>{};
    for (final record in records) {
      speciesCount[record.species] = 
          (speciesCount[record.species] ?? 0) + record.count;
    }
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '요약',
            style: pw.TextStyle(font: boldFont, fontSize: 16),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('총 기록 수:', style: pw.TextStyle(font: font)),
              pw.Text('${records.length}건', style: pw.TextStyle(font: boldFont)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('총 개체수:', style: pw.TextStyle(font: font)),
              pw.Text('$totalCount마리', style: pw.TextStyle(font: boldFont)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('어종 수:', style: pw.TextStyle(font: font)),
              pw.Text('${speciesCount.length}종', style: pw.TextStyle(font: boldFont)),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 기록 테이블 생성
  static pw.Widget _buildRecordsTable(
    List<FishingRecord> records,
    pw.Font font,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(4),
        4: const pw.FlexColumnWidth(3),
      },
      children: [
        // 헤더
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey200,
          ),
          children: [
            _buildTableCell('시간', font, isHeader: true),
            _buildTableCell('어종', font, isHeader: true),
            _buildTableCell('개체수', font, isHeader: true),
            _buildTableCell('위치', font, isHeader: true),
            _buildTableCell('메모', font, isHeader: true),
          ],
        ),
        // 데이터
        ...records.map((record) => pw.TableRow(
          children: [
            _buildTableCell(
              DateFormat('HH:mm').format(record.timestamp),
              font,
            ),
            _buildTableCell(record.species, font),
            _buildTableCell('${record.count}', font),
            _buildTableCell(
              '${record.latitude.toStringAsFixed(4)}, '
              '${record.longitude.toStringAsFixed(4)}',
              font,
              fontSize: 8,
            ),
            _buildTableCell(record.notes ?? '-', font),
          ],
        )),
      ],
    );
  }
  
  /// 테이블 셀 생성
  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
    double fontSize = 10,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: fontSize,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }
}