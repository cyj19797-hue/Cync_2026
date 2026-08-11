# iOS (Cync)

SwiftUI 기반 iOS 클라이언트입니다. Backend(`:3000`)만 호출합니다.

## Open

macOS에서:

```bash
open ios/Cync.xcodeproj
```

Xcode에서 Signing Team을 설정한 뒤 Run 하세요.

## Notes

- 시뮬레이터: `http://localhost:3000`
- 실기기: `APIClient.swift`의 baseURL을 Mac LAN IP로 변경
- ATS: 로컬 네트워크 HTTP는 프로젝트에서 허용됨
