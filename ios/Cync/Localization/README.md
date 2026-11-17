# Localization — 영어 화면은 어떻게 만들었나

Cync는 **String Catalog(`Localizable.xcstrings`) 하나**로 한국어/영어 화면을 같이 관리합니다.
화면별로 영어 버전을 따로 만든 게 아니라, 같은 화면이 고른 언어에 맞는 문자열을 꺼내 쓰는 구조예요.

## 1. 문자열 카탈로그 — `Localizable.xcstrings`

- 기준 언어(source)는 `ko`, 번역 언어는 `en`.
- 키 299개 중 292개가 `ko`/`en` 둘 다 번역됨(`state: translated`). 나머지 7개는 `"Hello, World!"` 같은 안 쓰는 자동 추출 키.
- 키는 `화면.의미` 형식으로 직접 작성(`extractionState: manual`)
  - 예: `settings.language`, `locker.applyNumbered`, `comment.postFailed`
  - 접두어별: locker 51 · notif 34 · calendar 26 · comment 26 · community 19 · settings 16 · login 15 · common 14 …
- 변수: `%@`(문자열), `%lld`(숫자) 사용
  - `locker.applyNumbered` → ko `%@번 사물함 신청하기` / en `Apply for Locker No. %@`
  - 어순이 달라도 키 하나로 처리됨
- 영어 복수형은 `plural` variation으로 처리
  - `community.commentCount` → en `1 comment` / `3 comments`, ko는 `댓글 %lld개` 하나

Xcode가 키마다 Swift 심볼을 만들어 줘서 코드에서는 `settings.language` → `.settingsLanguage`처럼 씁니다(오타 나면 컴파일 에러).

## 2. 코드에서 쓰는 법

| 상황 | 쓰는 법 |
|---|---|
| 화면에 보이는 텍스트 | `Text(.settingsLanguage)` |
| 코드에서 만드는 문자열 (에러 메시지, placeholder, 접근성 텍스트 등) | `String(appLocalized: .profileEditNetworkError)` |
| 날짜·숫자 포맷 | `Locale.current` 대신 `AppLanguage.currentLocale` |
| 언어 이름 ("한국어", "English") | `Text(verbatim:)` — 일부러 번역 안 함 (잘못 바꿔도 돌아갈 수 있게) |

⚠️ `String(localized:)`는 쓰지 말고 항상 `String(appLocalized:)`를 쓰세요. 안 그러면 앱 안에서 바꾼 언어가 반영되지 않습니다.

## 3. 앱 안에서 언어 바꾸기 (설정 > 언어 설정)

선택지: **시스템 설정값 / 한국어 / English** (`Models/AppLanguage.swift`)

1. `SettingsView` → `LanguagePickerDialog`에서 선택
2. `LanguageSettings.shared.select(_:)`가 선택값을 `UserDefaults`(`appLanguage`)와 `AppleLanguages`에 저장
3. `CyncApp.swift`의 `RootView`가 `.environment(\.locale, languageSettings.locale)`를 주입 → 모든 `Text(.key)`가 **재시작 없이 바로** 바뀜
4. `RootTabView`는 언어가 바뀌면 `.id`로 탭 화면을 다시 만들어서, 미리 계산해 둔 텍스트도 새로 그려짐

참고:
- `Bundle.main`을 바꿔치기하는 흔한 방법은 String Catalog에서 동작하지 않아서(실기기 확인) 위처럼 locale 주입 방식을 사용함
- 키보드·공유 시트 같은 시스템 UI는 앱을 다시 켜야 바뀜(`AppleLanguages` 덕분에 재실행 후 맞춰짐)

## 4. 새 문구 추가할 때

1. `Localizable.xcstrings`에서 키 추가 (`화면.의미` 형식)
2. `ko`, `en` 값 둘 다 입력 (숫자 들어가면 en에 plural 고려)
3. 코드에서 `Text(.새키)` 또는 `String(appLocalized: .새키)`로 사용
4. 시뮬레이터에서 설정 > 언어 설정 > English로 바꿔 확인
