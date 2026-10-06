# 🔒 FocusLock

AI 기반 스마트폰 잠금 화면 관리 앱 - 집중력 향상을 위한 스마트 잠금 솔루션

## 📋 프로젝트 개요

- **목적**: 감정/상황에 맞는 AI 기반 커스텀 잠금 화면 제공
- **핵심 기능**:
  - 🤖 AI 기반 잠금 화면 커스터마이징 (ChatGPT/Gemini)
  - ⏱️ 3-5분 강제 잠금 기능 (집중 모드)
  - 🔐 바이오 코딩 (AI 생성 코드로 보호)
  - 📊 사용 통계 및 AI 조언

## 🛠️ 기술 스택

### 프론트엔드 (앱)
- **프레임워크**: Flutter
- **플랫폼**: iOS / Android
- **언어**: Dart

### 백엔드 (서버)
- **런타임**: Node.js
- **프레임워크**: Express.js
- **데이터베이스**: Firebase
- **언어**: JavaScript/TypeScript

### AI/외부 API
- **AI 모델**: ChatGPT / Gemini
- **인증**: Firebase Auth

## 📁 프로젝트 구조

```
FocusLock/
├── mobile/                 # Flutter 앱 (iOS/Android)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── screens/
│   │   ├── services/
│   │   └── widgets/
│   ├── pubspec.yaml
│   └── README.md
│
├── backend/                # Node.js 백엔드
│   ├── src/
│   │   ├── index.js
│   │   ├── routes/
│   │   ├── controllers/
│   │   ├── services/
│   │   ├── middleware/
│   │   └── config/
│   ├── package.json
│   ├── .env.example
│   └── README.md
│
├── docs/                   # 문서
│   ├── API_SPECIFICATION.md
│   ├── ARCHITECTURE.md
│   └── REQUIREMENTS.md
│
└── README.md (이 파일)
```

## 🚀 빠른 시작

### 백엔드 실행
```bash
cd backend
npm install
npm run dev
```

### 앱 실행
```bash
cd mobile
flutter pub get
flutter run
```

## 📌 개발 로드맵

### Phase 1 (MVP)
- [ ] Firebase 프로젝트 설정
- [ ] 기본 인증 (회원가입/로그인)
- [ ] 메인 화면 UI
- [ ] AI API 통합

### Phase 2
- [ ] 3-5분 강제 잠금 기능
- [ ] 바이오 코딩 구현
- [ ] 통계 대시보드

### Phase 3
- [ ] 고급 AI 조언
- [ ] 알림/리마인더
- [ ] 다국어 지원

## 👥 팀 정보

- **프로젝트 매니저**: 이정민
- **버전**: V3.0

## 📄 라이선스

MIT License

---

**상태**: 🚧 진행 중

마지막 업데이트: 2026-10-06
