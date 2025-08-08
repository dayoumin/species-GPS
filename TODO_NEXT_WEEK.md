# Species GPS 앱 - 다음 주 작업 계획

## 📅 작업 일자: 2025년 1월 (2주차)

## 🔴 긴급 수정 사항 (우선순위: 높음)

### 1. 컴파일 에러 해결
- [ ] `Result` 클래스에 `data` getter 추가
  - 파일: `lib/core/utils/result.dart`
  - 문제: `Result<T>` 클래스에 data 프로퍼티가 없어서 컴파일 에러 발생
  
- [ ] `UIHelpers.showSnackBar` 메서드 시그니처 수정
  - 파일: `lib/core/utils/ui_helpers.dart`
  - 문제: SnackBarType 파라미터 누락
  
- [ ] `AppException` 인스턴스화 문제 해결
  - 파일: `lib/services/audio_service.dart`
  - 해결: 구체적인 Exception 클래스 사용 (StorageException, PermissionException 등)
  
- [ ] `RecordMode` enum 정의 추가
  - 파일: `lib/screens/home_screen_v2.dart`
  - 해결: RecordMode enum 생성 또는 관련 코드 제거

### 2. 런타임 에러 수정
- [ ] 음성 인식 권한 요청 로직 구현
- [ ] 지도 로딩 실패 시 폴백 처리
- [ ] 파일 경로 보안 검증 추가

## 🟡 기능 완성 (우선순위: 중간)

### 3. 음성 기능 개선
- [ ] 음성 인식 정확도 향상
  - 노이즈 캔슬링 옵션 추가
  - 음성 언어 설정 UI 추가
  - 오프라인 음성 인식 지원
  
- [ ] 음성 녹음 관리
  - 녹음 파일 재생 기능
  - 녹음 파일 삭제 기능
  - 녹음 시간 제한 설정

### 4. 지도 기능 개선
- [ ] 지도 성능 최적화
  - 마커 클러스터링 구현 (대량 데이터 처리)
  - 지도 타일 캐싱
  - 오프라인 지도 다운로드
  
- [ ] 지도 기능 확장
  - 경로 추적 기능
  - 히트맵 표시
  - 구역별 통계 표시
  
- [ ] 외부 지도 연동 완성
  - Google Maps 열기 구현
  - 네이버 지도 연동
  - 카카오맵 연동

### 5. UI/UX 개선
- [ ] 다크 모드 지원
- [ ] 반응형 레이아웃 (태블릿 지원)
- [ ] 애니메이션 추가
- [ ] 로딩 상태 표시 개선

## 🟢 추가 기능 (우선순위: 낮음)

### 6. 데이터 관리
- [ ] 데이터 백업/복원
  - 클라우드 백업 (Google Drive)
  - 로컬 백업 파일 생성
  - 자동 백업 스케줄링
  
- [ ] 데이터 동기화
  - 서버 API 연동
  - 실시간 동기화
  - 충돌 해결 로직

### 7. 분석 기능
- [ ] 통계 대시보드
  - 차트 라이브러리 통합
  - 기간별 통계
  - 종별 분포도
  
- [ ] 리포트 생성
  - PDF 리포트 개선
  - Excel 내보내기
  - 사진 포함 리포트

### 8. 사용자 경험
- [ ] 온보딩 화면 추가
- [ ] 도움말 및 튜토리얼
- [ ] 설정 화면 구현
- [ ] 다국어 지원 (영어, 일본어)

## 📝 테스트 계획

### 단위 테스트
- [ ] AudioService 테스트 작성
- [ ] MapWidget 테스트 작성
- [ ] Repository 패턴 테스트
- [ ] Provider 테스트

### 통합 테스트
- [ ] 음성 입력 → 저장 플로우
- [ ] 지도 표시 → 상세 보기 플로우
- [ ] 데이터 내보내기 플로우

### 디바이스 테스트
- [ ] Android 실기기 테스트
- [ ] iOS 실기기 테스트
- [ ] 웹 브라우저 호환성 테스트

## 🐛 알려진 버그

1. **음성 인식이 3초 후 자동 중지되는 문제**
   - 원인: pauseFor 설정
   - 해결: 사용자 설정 가능하도록 변경

2. **지도 마커 클릭 시 상세 정보 미표시**
   - 원인: onRecordTap 콜백 미구현
   - 해결: 바텀시트 구현 완성

3. **큰 이미지 파일 메모리 오버플로우**
   - 원인: 이미지 압축 미적용
   - 해결: 업로드 전 이미지 리사이징

## 🛠️ 개발 환경 설정

### 필요한 도구
- Flutter 3.8.1 이상
- Android Studio / VS Code
- Git

### 패키지 설치
```bash
cd species_gps
flutter pub get
```

### 실행 명령어
```bash
# 웹 실행
flutter run -d chrome

# Android 실행
flutter run -d android

# iOS 실행
flutter run -d ios

# 빌드
flutter build apk --release
flutter build ios --release
flutter build web
```

## 📊 진행 상황 추적

### 완료된 작업 (40%)
- ✅ 음성 녹음 기본 기능
- ✅ 지도 표시 기본 기능
- ✅ Provider 분리
- ✅ Repository 패턴 도입
- ✅ 로깅 시스템 구현

### 진행 중 (30%)
- 🔄 컴파일 에러 수정
- 🔄 UI/UX 개선
- 🔄 테스트 작성

### 예정된 작업 (30%)
- ⏳ 성능 최적화
- ⏳ 추가 기능 개발
- ⏳ 배포 준비

## 📞 연락처 및 참고 자료

### GitHub Repository
- https://github.com/dayoumin/species-GPS

### 참고 문서
- [Flutter 공식 문서](https://docs.flutter.dev/)
- [speech_to_text 패키지](https://pub.dev/packages/speech_to_text)
- [flutter_map 패키지](https://pub.dev/packages/flutter_map)
- [record 패키지](https://pub.dev/packages/record)

### 이슈 트래킹
- GitHub Issues 사용
- 버그 리포트: `bug` 라벨
- 기능 요청: `enhancement` 라벨
- 문서화: `documentation` 라벨

## 💡 추가 아이디어

1. **AI 종 식별 기능**
   - 사진 기반 자동 종 식별
   - TensorFlow Lite 통합

2. **커뮤니티 기능**
   - 사용자 간 데이터 공유
   - 실시간 정보 교환

3. **날씨 정보 통합**
   - 기록 시점 날씨 자동 저장
   - 날씨별 통계 분석

4. **QR 코드 스캔**
   - 빠른 종 정보 입력
   - 바코드 스캐너 통합

---

## ⚠️ 주의사항

1. **개인정보 보호**
   - GPS 좌표 정밀도 조정 옵션
   - 민감 정보 암호화

2. **성능 고려사항**
   - 대량 데이터 처리 시 페이징
   - 이미지 최적화 필수

3. **호환성**
   - Android 최소 API 21
   - iOS 최소 버전 11.0
   - 웹 브라우저 Chrome/Safari 최신 버전

---

*작성일: 2025년 1월 8일*
*작성자: Claude AI Assistant*
*최종 수정: 2025년 1월 8일*