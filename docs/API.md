# API

Base URL (local): `http://localhost:3000`

공통 응답 형식:

```json
{
  "success": true,
  "data": {},
  "message": "optional"
}
```

에러:

```json
{
  "success": false,
  "statusCode": 400,
  "message": "error description"
}
```

---

## Health

### `GET /health`

서버 상태 확인.

**Response**

```json
{
  "success": true,
  "data": {
    "status": "ok",
    "service": "cync-backend"
  }
}
```

---

## AI Proxy

### `POST /api/v1/ai/predict`

텍스트(또는 입력)를 AI 서버로 전달해 추론 결과를 반환합니다.

**Request**

```json
{
  "text": "hello"
}
```

**Response**

```json
{
  "success": true,
  "data": {
    "label": "example",
    "score": 0.92
  }
}
```

---

## Internal AI Server

Base URL (local): `http://localhost:8000`  
(Backend 전용. iOS에서 직접 호출하지 않음)

### `GET /health`

```json
{
  "status": "ok",
  "service": "cync-ai"
}
```

### `POST /predict`

**Request**

```json
{
  "text": "hello"
}
```

**Response**

```json
{
  "label": "example",
  "score": 0.92
}
```
