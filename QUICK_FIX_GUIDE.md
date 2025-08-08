# 🚀 Species GPS - 빠른 수정 가이드

## 🔥 즉시 해결해야 할 컴파일 에러 (5분 소요)

### 1. Result 클래스 data getter 추가
**파일**: `lib/core/utils/result.dart`

```dart
// 기존 Result 클래스에 추가
T? get data => isSuccess ? _data : null;
```

### 2. UIHelpers.showSnackBar 수정
**파일**: `lib/core/utils/ui_helpers.dart`

```dart
static void showSnackBar(
  BuildContext context,
  String message, {
  SnackBarType type = SnackBarType.info,
}) {
  // 구현
}
```

### 3. AppException 인스턴스화 문제
**파일**: `lib/services/audio_service.dart`

모든 `AppException(` 을 다음으로 변경:
- 권한 관련 → `PermissionException(`
- 저장 관련 → `StorageException(`
- 위치 관련 → `LocationException(`

### 4. RecordMode enum 추가
**파일**: `lib/screens/home_screen_v2.dart` 상단에 추가

```dart
enum RecordMode { 
  camera,    // 사진만
  detailed,  // 상세 입력
  voice      // 음성 입력
}
```

## 📱 테스트 명령어

```bash
# 1. 패키지 설치
cd species_gps
flutter pub get

# 2. 분석 실행 (에러 확인)
flutter analyze

# 3. 웹에서 테스트
flutter run -d chrome

# 4. 실제 기기에서 테스트
flutter run
```

## ✅ 체크리스트

- [ ] Result 클래스 수정
- [ ] UIHelpers 수정
- [ ] AppException → 구체적 Exception 변경
- [ ] RecordMode enum 추가
- [ ] flutter pub get 실행
- [ ] flutter analyze 에러 0개 확인
- [ ] 웹 빌드 성공 확인
- [ ] 실기기 테스트

## 🎯 예상 결과

수정 후:
- 컴파일 에러: 0개
- 경고: 10개 이하
- 정보: 50개 이하

## 💬 문제 발생 시

1. `flutter clean` 실행
2. `flutter pub get` 재실행
3. IDE 재시작
4. 그래도 안되면 GitHub Issues에 문의

---
*5분 안에 해결 가능한 수정사항입니다!*