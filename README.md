# Cync

iOS 앱, NestJS 백엔드, Python AI 서버로 구성된 모노레포입니다.

## 구조

```
Cync/
├── ios/          # iOS 앱 (SwiftUI)
├── backend/      # NestJS API 서버
├── ai/           # Python AI 서버
├── docs/         # API · 아키텍처 문서
├── .gitignore
└── README.md
```

## 빠른 시작

### Backend (NestJS)

```bash
cd backend
npm install
npm run start:dev
```

기본 포트: `3000`

### AI 서버 (Python)

```bash
cd ai
py -m venv .venv
.venv\Scripts\activate   # macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

기본 포트: `8000`

### iOS

1. Xcode에서 `ios/Cync.xcodeproj` 열기
2. 시뮬레이터 또는 실기기에서 Run

## 문서

- [아키텍처](docs/architecture.md)
- [API](docs/API.md)

## 환경 변수

각 패키지의 `.env.example`을 참고해 `.env`를 생성하세요.
