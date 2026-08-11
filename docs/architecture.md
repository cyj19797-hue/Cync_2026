# Architecture

## Overview

Cync는 세 개의 독립 서비스로 구성됩니다.

| Layer | Tech | Role |
|-------|------|------|
| Client | iOS (SwiftUI) | 사용자 UI, API 호출 |
| Backend | NestJS | 인증, 비즈니스 로직, AI 프록시 |
| AI | Python (FastAPI) | 추론 / 모델 서빙 |

```
┌─────────────┐      HTTPS       ┌──────────────┐      HTTP       ┌─────────────┐
│  iOS App    │ ───────────────► │  NestJS API  │ ──────────────► │  AI Server  │
│  (SwiftUI)  │ ◄─────────────── │  :3000       │ ◄────────────── │  :8000      │
└─────────────┘                  └──────────────┘                 └─────────────┘
```

## Responsibilities

### iOS (`ios/`)
- 화면·상태 관리
- Backend REST API 호출
- AI 서버에 직접 연결하지 않음 (Backend를 통해서만)

### Backend (`backend/`)
- REST API 제공
- 요청 검증, 인증/인가
- AI 서버로의 프록시 및 결과 가공

### AI (`ai/`)
- 모델 로드 및 추론
- `/predict` 등 내부 API 제공
- Backend 전용 호출을 가정 (외부 직접 노출 최소화)

## Data flow (예시)

1. iOS가 Backend `POST /api/v1/...` 호출
2. Backend가 필요 시 AI `POST /predict` 호출
3. AI가 추론 결과 반환
4. Backend가 응답을 정규화해 iOS에 반환

## 배포 메모

- Backend와 AI는 별도 프로세스로 실행
- 로컬 개발 시 Backend `AI_BASE_URL=http://localhost:8000`
- 프로덕션에서는 내부 네트워크/서비스 메시로 AI를 격리하는 것을 권장
