# 수산생명자원 GPS 기록 앱

<img src="https://img.shields.io/badge/Flutter-3.32.6-blue" alt="Flutter Version">
<img src="https://img.shields.io/badge/Dart-3.8.1-blue" alt="Dart Version">
<img src="https://img.shields.io/badge/Platform-Android-green" alt="Platform">

## 📱 프로젝트 소개

해양 수산생명자원 확보 현장에서 실시간으로 어획 정보를 기록하는 모바일 앱입니다.

### 주요 기능
- 🗺️ **GPS 위치 자동 기록** - 어획 위치를 정확하게 기록
- 📸 **사진 촬영 및 저장** - 자동 이미지 압축으로 저장 공간 절약
- 📝 **간편한 데이터 입력** - 어종명, 개체수, 메모 입력
- 💾 **오프라인 완벽 지원** - 인터넷 없이도 모든 기능 사용 가능
- 📊 **데이터 내보내기** - CSV/PDF 형식으로 내보내기 및 카톡 공유
- 📈 **통계 및 필터링** - 날짜별, 어종별 필터링 및 통계 확인

## 🚀 시작하기

### 사전 요구사항
- Flutter SDK 3.32.6 이상
- Android Studio 또는 VS Code
- Android 기기 또는 에뮬레이터

### 설치 방법

1. 저장소 클론
```bash
git clone https://github.com/dayoumin/species-GPS.git
cd species-GPS/species_gps
```

2. 의존성 설치
```bash
flutter pub get
```

3. 앱 실행
```bash
flutter run
```

## 📁 프로젝트 구조

```
species_gps/
├── lib/
│   ├── core/           # 핵심 유틸리티
│   │   ├── errors/     # 에러 처리
│   │   ├── theme/      # 디자인 시스템
│   │   └── utils/      # 헬퍼 함수
│   ├── models/         # 데이터 모델
│   ├── providers/      # 상태 관리 (Provider)
│   ├── screens/        # 화면 UI
│   ├── services/       # 비즈니스 로직
│   └── widgets/        # 재사용 위젯
└── android/            # Android 설정
```

## 🛠️ 기술 스택

- **Frontend**: Flutter 3.x
- **State Management**: Provider
- **Local Database**: SQLite
- **주요 패키지**:
  - `geolocator`: GPS 위치 추적
  - `camera`: 카메라 제어
  - `sqflite`: 로컬 데이터베이스
  - `flutter_image_compress`: 이미지 압축
  - `pdf` & `csv`: 데이터 내보내기
  - `share_plus`: 파일 공유

## 📸 스크린샷

[추후 추가 예정]

## 🔒 보안 및 프라이버시

- GPS 정보는 파일명에 노출되지 않고 별도 메타데이터로 안전하게 저장
- EXIF 데이터 자동 제거로 개인정보 보호
- 모든 데이터는 기기 내부에만 저장 (클라우드 동기화 없음)

## 📋 주요 기능 상세

### 1. GPS 위치 기록
- 실시간 위치 추적
- 정확도 표시
- 위치 서비스 상태 모니터링

### 2. 사진 관리
- 즉시 촬영 모드
- 자동 이미지 압축 (2MB 이상 시)
- 썸네일 자동 생성

### 3. 데이터 관리
- 날짜별 그룹화
- 어종별 필터링
- 통계 대시보드

### 4. 내보내기 기능
- CSV: Excel에서 바로 열기 가능
- PDF: 보고서 형식으로 생성
- 카카오톡, 이메일 등으로 즉시 공유

## 🤝 기여하기

이슈나 개선사항이 있다면 자유롭게 Issue를 등록하거나 PR을 보내주세요.

## 📝 라이선스

이 프로젝트는 MIT 라이선스 하에 있습니다.

## 👨‍💻 개발자

- GitHub: [@dayoumin](https://github.com/dayoumin)

---

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>