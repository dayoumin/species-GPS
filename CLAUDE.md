# Species GPS 프로젝트 가이드

## 프로젝트 개요
해양 수산생명자원 확보 현장에서 실시간으로 어획 정보를 기록하는 Flutter 앱

## 최근 작업 내역 (2025.01.12)

### 완료된 기능
1. **음성 메모 기록 기능 추가**
   - 녹음/재생 인터페이스 구현
   - 기록별 음성 파일 저장

2. **어종 동향 분석 화면**
   - 시계열 차트 구현 (fl_chart)
   - 최대 3종 비교 기능
   - 기간별 필터링

3. **XLSX 내보내기 기능**
   - Excel 파일 직접 생성
   - 스타일링 및 자동 열 너비 조정

4. **UI/UX 개선**
   - 날짜 범위 필터 추가 (목록 탭)
   - 어종 키워드 검색 구현 (통계 탭)
   - 엔터키 검색 지원
   - 안전 삭제 확인 (어종명 입력 필요)

### 프로젝트 구조
```
species_gps/
├── lib/
│   ├── screens/
│   │   ├── records_list_screen_v2.dart  # 기록 조회 (목록/통계)
│   │   ├── species_trend_screen.dart    # 어종 동향 분석
│   │   └── add_record_screen_v3.dart    # 기록 추가
│   ├── services/
│   │   ├── export_service.dart          # CSV/PDF/XLSX 내보내기
│   │   └── audio_service.dart           # 음성 녹음/재생
│   └── providers/
│       └── app_state_provider.dart      # 전역 상태 관리
```

## 향후 개발 계획
- [ ] **데이터 서버 동기화** - 클라우드 서버에 데이터 업로드 및 취합
- [ ] **다중 사용자 협업** - 팀 단위 데이터 공유
- [ ] **오프라인/온라인 동기화** - 네트워크 연결 시 자동 동기화
- [ ] **백업 및 복원** - 클라우드 백업 기능

## 개발 환경
- Flutter 3.32.6
- Dart 3.8.1
- 지원 플랫폼: Android, Web

## 테스트 명령어
```bash
# 웹에서 테스트
flutter run -d chrome --web-port=8080

# 빌드
flutter build web
flutter build apk
```

## 주의사항
1. GPS 권한 필수 (Android)
2. 카메라/마이크 권한 필요
3. 웹 환경에서는 샘플 데이터 자동 추가

## Git 작업 흐름
```bash
git add .
git commit -m "feat: 음성 기록, 어종 동향 분석, UI 개선"
git push origin main
```