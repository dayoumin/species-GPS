# Species GPS 프로젝트 가이드

## 프로젝트 개요
해양 수산생명자원 확보 현장에서 실시간으로 어획 정보를 기록하는 Flutter 앱

## 최근 작업 내역 (2025.01.13)

### 오늘 완료된 기능
1. **영상 녹화 기능 추가**
   - 사진 촬영과 영상 녹화 선택 가능
   - GPS 메타데이터 자동 포함
   - 녹화 상태 UI 표시

2. **음성→텍스트 변환 입력**
   - 종 이름, 메모 실시간 음성 입력
   - 한국어 음성 인식 지원 (speech_to_text)
   - 입력 필드별 독립적 음성 인식

3. **날짜 필터링 개선**
   - 어제/오늘 기록 분리 표시
   - 샘플 데이터 날짜 분산 생성
   - 정확한 날짜별 카운트

4. **UI/UX 개선**
   - 필수 입력 항목 명확한 표시 (*, 헬퍼 텍스트)
   - 홈 화면 앱바 중앙 정렬 및 높이 조정 (150px)
   - 저장 버튼 디자인 차별화 (72px 높이, 그라데이션)
   - 버튼 간격 조정 (3배 간격)

5. **코드 품질 향상**
   - record → flutter_sound 패키지 변경
   - AudioException 클래스 추가
   - deprecated API 수정 (withOpacity → withValues)
   - 불필요한 imports 제거
   - BuildContext async gaps 수정

6. **테스트 코드 작성**
   - 11개 유닛 테스트 작성 및 통과
   - FishingRecord 모델 테스트
   - DateFormatter 유틸리티 테스트
   - 데이터 검증 테스트

### 이전 작업 (2025.01.12)
- 음성 메모 기록 기능
- 어종 동향 분석 화면 (fl_chart)
- XLSX 내보내기 기능
- 날짜 범위 필터, 어종 검색
- 안전 삭제 확인

## 프로젝트 구조
```
species_gps/
├── lib/
│   ├── screens/
│   │   ├── home_screen_v2.dart          # 메인 홈 화면
│   │   ├── records_list_screen_v2.dart  # 기록 조회 (목록/통계)
│   │   ├── species_trend_screen.dart    # 어종 동향 분석
│   │   ├── add_record_screen_v3.dart    # 기록 추가 (영상/음성인식)
│   │   └── map_screen.dart               # 지도 화면
│   ├── services/
│   │   ├── audio_service.dart           # 음성 녹음/인식 (flutter_sound)
│   │   ├── camera_service_v2.dart       # 카메라/영상 서비스
│   │   ├── export_service.dart          # CSV/PDF/XLSX 내보내기
│   │   └── storage_service.dart         # 플랫폼별 저장소
│   ├── providers/
│   │   ├── app_state_provider.dart      # 전역 상태 관리
│   │   └── map_state_provider.dart      # 지도 상태 관리
│   └── test/
│       ├── unit_test.dart               # 유닛 테스트
│       ├── provider_test.dart           # Provider 테스트
│       └── service_test.dart            # 서비스 테스트
```

## 기술 스택
- **Framework**: Flutter 3.32.6
- **Language**: Dart 3.8.1
- **State Management**: Provider
- **Audio**: flutter_sound ^9.2.13
- **Speech**: speech_to_text ^6.5.1
- **Map**: flutter_map ^6.1.0
- **Chart**: fl_chart ^0.68.0
- **Export**: pdf, excel, csv

## 개발 환경 설정
```bash
# 패키지 설치
flutter pub get

# 웹에서 테스트
flutter run -d chrome --web-port=8081

# Android 테스트 (USB 디버깅)
flutter devices
flutter run

# 빌드
flutter build web
flutter build apk --debug  # minSdkVersion 24 필요
```

## 플랫폼별 요구사항

### Android
- minSdkVersion: 24 (Android 7.0+)
- 권한: GPS, 카메라, 마이크, 저장소
- build.gradle.kts에서 minSdk = 24 설정

### Web
- 브라우저: Chrome 권장
- 샘플 데이터 자동 생성
- 메모리 저장 (세션 기반)

## 테스트
```bash
# 모든 테스트 실행
flutter test

# 특정 테스트 실행
flutter test test/unit_test.dart
```

## Git 작업
```bash
# 큰 파일 제외 (.gitignore 설정됨)
git add .
git commit -m "feat: 기능 설명"
git push origin main
```

## 알려진 이슈
1. **APK 빌드**: Kotlin 컴파일 캐시 문제
   - 해결: `flutter clean && flutter pub get`
2. **USB 테더링**: 저장소 접근 불가
   - 대안: 파일 전송 모드 또는 무선 디버깅

## 향후 개발 계획
- [ ] 클라우드 서버 동기화
- [ ] 다중 사용자 협업
- [ ] 오프라인/온라인 자동 동기화
- [ ] 데이터 백업 및 복원
- [ ] iOS 지원

## 참고 문서
- [README.md](README.md) - 프로젝트 소개
- [TEST_CHECKLIST.md](species_gps/TEST_CHECKLIST.md) - 테스트 체크리스트

---
*최종 업데이트: 2025.01.13*