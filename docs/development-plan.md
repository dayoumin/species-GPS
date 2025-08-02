# 수산생명자원 기록 앱 개발 계획서

## 1. 프로젝트 개요

### 목표
Flutter + Firebase를 활용한 수산생명자원 확보 기록 앱 개발

### 핵심 가치
- 실시간 GPS 좌표와 함께 어획 정보 자동 기록
- 오프라인 환경에서도 완전한 기능 지원
- 간편한 사진/음성 입력으로 현장 작업 효율성 극대화

## 2. MVP 기능 정의 (1차 목표 - 4주)

### 필수 기능
1. **GPS 위치 자동 기록**
   - 현재 위치 좌표 획득
   - 위치 정확도 표시

2. **사진 촬영 및 저장**
   - 카메라 촬영
   - 사진에 GPS 메타데이터 포함
   - 로컬 저장

3. **기본 정보 입력**
   - 어종명 (텍스트)
   - 개체수 (숫자)
   - 간단한 메모

4. **로컬 데이터 저장**
   - SQLite 데이터베이스
   - 오프라인 완전 지원

5. **기록 조회**
   - 날짜별 목록
   - 상세 정보 보기

### 2차 기능 (추후 확장)
- 음성 녹음
- Firebase 클라우드 동기화
- 데이터 내보내기 (CSV)
- 사용자 인증

## 3. 기술 스택

### 프론트엔드
```yaml
dependencies:
  flutter: sdk
  
  # 핵심 기능
  geolocator: ^10.1.0
  camera: ^0.10.5
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  
  # UI/UX
  provider: ^6.1.1
  intl: ^0.18.1
  
  # 권한
  permission_handler: ^11.0.1
```

### 백엔드 (2차)
```yaml
  # Firebase
  firebase_core: ^2.24.2
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.6.0
```

## 4. 데이터 모델

```dart
class FishingRecord {
  int? id;
  String species;        // 어종명
  int count;            // 개체수
  double latitude;      // 위도
  double longitude;     // 경도
  double? accuracy;     // GPS 정확도
  String? photoPath;    // 로컬 사진 경로
  String? notes;        // 메모
  DateTime timestamp;   // 기록 시간
}
```

## 5. 개발 일정 (MVP - 4주)

### Week 1: 기반 구축
- [ ] Flutter 프로젝트 생성
- [ ] 기본 화면 구조 (3개 화면)
- [ ] 권한 관리 시스템
- [ ] GPS 서비스 구현

### Week 2: 핵심 기능
- [ ] 카메라 서비스 구현
- [ ] SQLite 데이터베이스 설정
- [ ] 기록 추가 화면 완성

### Week 3: 데이터 관리
- [ ] 기록 조회 화면
- [ ] 데이터 CRUD 완성
- [ ] 에러 처리

### Week 4: 마무리
- [ ] UI/UX 개선
- [ ] 테스트 및 버그 수정
- [ ] APK 빌드

## 6. 화면 설계

### 6.1 홈 화면
- 현재 GPS 상태 표시
- 빠른 기록 버튼 (크게)
- 최근 기록 요약

### 6.2 기록 추가 화면
- 카메라 뷰 (전체 화면)
- 하단에 입력 필드
  - 어종명
  - 개체수
  - 메모 (선택)
- GPS 좌표 자동 표시

### 6.3 기록 목록 화면
- 날짜별 그룹핑
- 썸네일 이미지
- 어종명, 개체수, 위치 표시

## 7. 주요 기술 구현 포인트

### GPS 서비스
```dart
class LocationService {
  Future<Position?> getCurrentPosition();
  Future<bool> checkPermission();
  Stream<Position> getPositionStream();
}
```

### 카메라 서비스
```dart
class CameraService {
  Future<XFile?> takePicture();
  Future<String> saveImageWithGPS(XFile image, Position position);
}
```

### 로컬 데이터베이스
```dart
class DatabaseService {
  Future<int> insertRecord(FishingRecord record);
  Future<List<FishingRecord>> getRecords();
  Future<void> deleteRecord(int id);
}
```

## 8. 위험 요소 및 대응

### 기술적 위험
1. **GPS 정확도**: 실내/해상에서 테스트 필요
2. **카메라 권한**: 권한 거부 시 대응 UI
3. **저장 공간**: 사진 압축 알고리즘 적용

### 사용성 위험
1. **조작성**: 큰 버튼, 단순한 UI
2. **배터리**: GPS 업데이트 주기 최적화

## 9. 테스트 계획

### 기능 테스트
- [ ] GPS 좌표 정확도
- [ ] 카메라 촬영 및 저장
- [ ] 데이터 저장/조회
- [ ] 오프라인 모드

### 현장 테스트
- [ ] 실제 환경에서 사용성
- [ ] 다양한 조명 조건
- [ ] 장갑 착용 시 조작

## 10. 성공 지표

- 기록 생성 시간: 30초 이내
- GPS 정확도: 10m 이내
- 앱 크래시율: 1% 미만
- 오프라인 기능: 100% 동작