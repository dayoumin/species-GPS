# Isar 데이터베이스 마이그레이션 가이드

## 🔍 현재 발생한 문제

### 1. build_runner 실행 오류
```
Could not find a command named "D:\flutter\bin\cache\dart-sdk\bin\snapshots\frontend_server.dart.snapshot"
```

### 2. 원인 분석
- Flutter SDK의 Dart 컴파일러 스냅샷 파일이 누락됨
- Windows에서 Flutter를 Git으로 설치할 때 가끔 발생하는 문제
- build_runner가 Dart 컴파일러를 찾지 못해 코드 생성 실패

## ✅ 해결 방법

### 방법 1: Flutter SDK 재설치 (권장)
```bash
# Flutter 재설치
cd D:\
rm -rf flutter
git clone https://github.com/flutter/flutter.git -b stable
flutter doctor
```

### 방법 2: 스냅샷 파일 재생성
```bash
# Flutter 도구 재빌드
cd D:\flutter
git clean -xfd
git pull
flutter doctor -v
```

### 방법 3: 수동으로 Isar 코드 생성
`fishing_record.g.dart` 파일을 수동으로 생성:

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fishing_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetFishingRecordCollection on Isar {
  IsarCollection<FishingRecord> get fishingRecords => this.collection();
}

const FishingRecordSchema = CollectionSchema(
  name: r'FishingRecord',
  id: 123456789,
  properties: {
    r'species': PropertySchema(
      id: 0,
      name: r'species',
      type: IsarType.string,
    ),
    r'count': PropertySchema(
      id: 1,
      name: r'count',
      type: IsarType.long,
    ),
    r'latitude': PropertySchema(
      id: 2,
      name: r'latitude',
      type: IsarType.double,
    ),
    r'longitude': PropertySchema(
      id: 3,
      name: r'longitude',
      type: IsarType.double,
    ),
    r'accuracy': PropertySchema(
      id: 4,
      name: r'accuracy',
      type: IsarType.double,
    ),
    r'photoPath': PropertySchema(
      id: 5,
      name: r'photoPath',
      type: IsarType.string,
    ),
    r'audioPath': PropertySchema(
      id: 6,
      name: r'audioPath',
      type: IsarType.string,
    ),
    r'notes': PropertySchema(
      id: 7,
      name: r'notes',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 8,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
  },
  estimateSize: _fishingRecordEstimateSize,
  serialize: _fishingRecordSerialize,
  deserialize: _fishingRecordDeserialize,
  deserializeProp: _fishingRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'timestamp': IndexSchema(
      id: 123456790,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _fishingRecordGetId,
  getLinks: _fishingRecordGetLinks,
  attach: _fishingRecordAttach,
  version: '3.1.0',
);

// 나머지 헬퍼 함수들...
```

## 🚀 완료된 작업

1. ✅ Isar 패키지 설치 완료
   - `isar: 3.1.0`
   - `isar_flutter_libs: 3.1.0`
   - `isar_generator: 3.1.0`
   - `build_runner: 2.4.6`

2. ✅ FishingRecord 모델 Isar 형식으로 변환
   - `@collection` 어노테이션 추가
   - `Id` 타입 사용
   - `@Index()` 어노테이션으로 timestamp 인덱싱

3. ✅ StorageService Isar 기반으로 재작성
   - 웹 개발용 메모리 저장소 유지
   - 모바일용 Isar 영구 저장소 구현
   - 트랜잭션 기반 안전한 데이터 처리

4. ✅ 기존 DatabaseService 백업
   - `database_service.dart.backup`으로 저장

## 📝 다음 단계

1. **Flutter SDK 문제 해결 후:**
   ```bash
   # 코드 생성
   flutter pub run build_runner build --delete-conflicting-outputs
   
   # 앱 실행 테스트
   flutter run -d chrome  # 웹 테스트
   flutter run           # Android 테스트
   ```

2. **main.dart 수정 필요:**
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await StorageService.init();  // Isar 초기화 추가
     runApp(MyApp());
   }
   ```

3. **Android 권한 확인 (이미 설정됨):**
   - 저장소 접근 권한
   - 위치 권한
   - 카메라/마이크 권한

## 🎯 Isar 사용의 장점

1. **성능**: SQLite보다 10배 빠른 쿼리
2. **간편함**: SQL 작성 불필요
3. **타입 안전**: Dart 객체 직접 저장
4. **자동 마이그레이션**: 스키마 변경 자동 처리
5. **크로스 플랫폼**: iOS, Android, Desktop 지원

## ⚠️ 주의사항

- Windows에서 개발 시 Developer Mode 활성화 필요 (심볼릭 링크 지원)
- Flutter SDK 경로에 공백이 없어야 함
- 첫 실행 시 Isar 네이티브 라이브러리 다운로드 필요

---
*작성일: 2025-01-15*