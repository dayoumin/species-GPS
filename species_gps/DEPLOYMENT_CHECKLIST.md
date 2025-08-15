# 배포 전 체크리스트

## 🚨 필수 삭제 항목 (더미 데이터 관련)

### 1. **StorageService의 샘플 데이터 함수 제거**
- 파일: `lib/services/storage_service.dart`
- 삭제할 함수:
  - `addSampleData()` - 샘플 데이터 생성 함수 (라인 약 60-200)
  - `hasDummyData()` - 더미 데이터 확인 함수 
  - `deleteDummyData()` - 더미 데이터 삭제 함수

### 2. **HomeScreenV2의 더미 데이터 관련 코드 제거**
- 파일: `lib/screens/home_screen_v2.dart`
- 삭제할 부분:
  - 라인 58-62: 웹 환경에서 샘플 데이터 자동 추가 코드
    ```dart
    // 삭제 필요!
    if (Theme.of(context).platform == TargetPlatform.windows || 
        Theme.of(context).platform == TargetPlatform.linux ||
        Theme.of(context).platform == TargetPlatform.macOS) {
      await StorageService.addSampleData();
    }
    ```
  - 라인 126-168: 더미 데이터 알림 및 삭제 버튼 UI
  - 라인 853-891: `_deleteDummyData()` 함수 전체

### 3. **[DUMMY_DATA] 태그가 포함된 모든 데이터**
- 현재 메모리나 데이터베이스에 저장된 `[DUMMY_DATA]` 태그가 포함된 모든 기록 삭제
- 앱 내에서 "테스트 데이터 삭제" 버튼으로 제거 가능

## ✅ 배포 전 확인 사항

1. **테스트 데이터 제거 확인**
   - [ ] StorageService에서 더미 데이터 관련 함수 삭제
   - [ ] HomeScreenV2에서 더미 데이터 UI 및 로직 삭제
   - [ ] 실제 데이터베이스에 [DUMMY_DATA] 태그 기록 없음 확인

2. **프로덕션 환경 설정**
   - [ ] 디버그 로그 제거
   - [ ] API 키 및 민감 정보 환경 변수로 이동
   - [ ] 릴리즈 빌드 테스트

3. **최종 테스트**
   - [ ] 실제 데이터로 모든 기능 테스트
   - [ ] GPS, 카메라, 마이크 권한 테스트
   - [ ] 데이터 내보내기 기능 확인

## 📝 참고 사항

### 더미 데이터를 사용한 이유
- 개발 및 테스트 중 다양한 시나리오 검증
- UI/UX 개선 작업 시 즉각적인 피드백
- 날짜별 그룹화, 통계 기능 테스트

### 안전한 제거 방법
1. 앱에서 "테스트 데이터 삭제" 버튼 클릭
2. 코드에서 관련 함수 제거
3. 빌드 후 실제 데이터로 테스트

---
*최종 업데이트: 2025.01.15*