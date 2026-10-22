# FocusLock 작업 인수인계

## 2026-10-23 Codex 하네스 실습

- 이번 사용자 지시: Oh My Agent 제외, 기존 Android 작업 보존, 기존 앱 코드 수정은 먼저 보고 후 승인, 커밋·푸시 금지.
- `harness/verify.ps1`, `harness/README.md`, `harness/BASELINE.md`, `harness/.gitignore` 추가. 루트 AGENTS.md에 검증 절차 연결.
- 스크립트가 프로젝트 위치를 기준으로 SDK/캐시를 찾고 테스트·분석·웹/APK 빌드·Android JVM 검사 명령, 로그, 종료 코드를 제공한다. Codex 세션이 로그 분석 및 승인된 수정/재테스트를 담당하며 자동 소스 수정은 하지 않는다.
- 실제 기존 일정 경계 테스트 1개 통과. 하네스 전체 Flutter 테스트 6개 통과. 전체 Dart 분석은 기존 info 51건(오류·경고 없음)으로 종료 1. 기존 코드 수정이 필요하여 수정하지 않았다.
- 웹 빌드 성공. Android JVM 검사 명령 BUILD SUCCESSFUL이나 testDebugUnitTest는 UP-TO-DATE로 기존 결과 재사용. APK 모드는 이번 실습에서 미실행. 실기기 잠금·전화·알림 차단 미검증.
- 프로필 파일 접근 제한으로 일부 검사는 필수 승인 후 동일 명령 재실행. 현재 Android SDK와 Android Studio JDK 존재를 확인했으므로 과거 SDK 부재 기록과 구분할 것.
- 기존 앱 소스·Android 작업은 변경하지 않았고 설치·커밋·푸시하지 않았다. 상세 명령과 로그 위치는 harness/BASELINE.md 참고.

마지막 정리: 2026-10-23

## 작업 위치와 진행 방식

- 작업 폴더: `C:\Users\i\Desktop\FocusLock`
- GitHub: https://github.com/lbb209800-crypto/FocusLock
- 이 프로젝트의 기존 코드를 계속 수정한다. 새 저장소를 만들지 않는다.
- 사용자는 기능 추가·수정 요청 시 구현, 검증, 커밋, GitHub main 푸시까지 진행하도록 승인했다.
- 사용자 지시 범위의 통상적이고 되돌릴 수 있는 작업은 재확인하지 않는다. 필수 시스템 승인과 되돌리기 어려운 조치는 별도다.
- 모든 프로젝트 산출물은 이 작업 폴더 안에 저장한다.
- 로컬 브랜치는 master, 원격 대상은 main이므로 `git push origin HEAD:main`을 사용했다.

## 제품 목적

사용자가 정한 시간에 휴대폰 사용을 끊어, 예정한 일을 시작하게 만드는 앱.
공부 전용이 아니다. 업무, 운동, 청소, 외출 준비 등 사용자가 정한 모든 일정을 지원한다.
알림만 보내거나 잠금 화면 배경을 꾸미는 앱이 아니다.
AI/바이오코딩은 개발 방식이며, AI 이미지 생성이나 유료 AI API는 핵심 요구사항이 아니다.

예시: 오후 8시 / 회사에서 받은 작업 시작 / 10분 잠금.
그 시각에 다른 앱을 사용하고 있어도 잠금이 시작되고,
잠금 화면에 `오후 8시 일정`, `회사에서 받은 작업 시작`, 남은 시간이 표시된다.
사용자가 폰을 계속 보는 대신 그 일을 시작하도록 유도한다.

## 합의한 요구사항

1. 일정 제목·실행 날짜/시각 등록. 잠금 시간은 10분 고정(2026-10-23 변경).
2. 정해진 시각에 자동 잠금. 다른 앱 터치와 앱 이동을 최대한 차단.
3. 잠금 중 카카오톡·인스타그램 등 일반 알림의 소리/진동/표시를 제한하고 싶어 한다.
4. 급한 일반 전화는 수신·통화 가능해야 한다. 통화 후 남은 잠금 유지가 목표다.
5. 종료 시 잠금과 앱이 적용한 알림 제한 해제. 사용자의 기존 설정을 존중해야 한다.
6. 일정은 로컬 저장. 복잡한 외부 서버나 실시간 DB는 제외.
7. 한국어/영어 선택과 언어 설정 유지.
8. 실제 배포 화면에는 개발용 테스트·미리보기 버튼을 제외한다.
9. 매일 지정 시각에 `오늘 꼭 해야 할 일이 있나요?` 같은 일정 등록 리마인더.
   알림을 누르면 일정 등록 화면으로 이동. 시간 설정, 켜기/끄기 제공.
   오늘 일정이 이미 등록돼 있으면 생략하는 방향에 합의했다.
   아침에 앱을 강제로 자동 실행하는 아이디어는 취소됐다.

원본 PDF는 Downloads에 있으며, 개인정보가 있으므로 GitHub에 복사하지 않았다:
`C:\Users\i\Downloads\요구사항 명세서 V2_FocusLock (바이오코딩 기반 스마트폰 강제 잠금 앱) (2).pdf`
원본은 3~5분 잠금이었으나 이후 5분/10분으로 변경했다.
원본에는 AI 협업 개발·디버깅 기록도 포함되어 있다.

## 구현 상태

최신 기능 커밋: `4df9cbb` (GitHub main에 푸시 완료).
그 이전 `8533ae4`는 한국어/영어 및 Flutter 미리보기 설정.

- Flutter 기본 진입점은 로그인 없는 일정 앱.
- 일정 등록·삭제·로컬 저장, 날짜/시각, 10분 고정 잠금 구현.
- 과거 시각 및 잠금 시간이 겹치는 일정 등록 방지.
- 웹에서는 탭 내부 잠금 화면/일정 제목/카운트다운/자동 해제 구현.
- 원래 종료 시각 기준이므로 재실행해도 잠금 시간이 처음부터 다시 시작하지 않는다.
- 한국어/영어 선택 및 저장 구현.
- 개발용 `15초 뒤 일정 시작`은 10분 잠금을 예약한다.
- 별도 `잠금 화면만 15초 미리보기`는 짧은 UI 확인용이다.
- 자동 테스트 4개 통과: 시간 경계, 저장/삭제, 등록·미리보기·언어,
  재실행 후 자동 잠금/종료.
- Android 프로젝트와 네이티브 알람/오버레이 서비스 코드 작성.
- 현재 PC에서 Android Studio/SDK를 발견하여 Kotlin/APK 빌드 검증을 진행. 실제 휴대폰 동작은 여전히 미검증.
- 전화 예외, 앱 전용 방해금지 규칙, 접근성을 통한 앱 이동 제한 코드 추가(아래 2026-10-23 후속 기록 참고).
- 매일 일정 등록 리마인더도 요구사항만 합의했으며 아직 미구현.
- 일회성 일정만 구현. 매일 반복 일정은 아직 없음.

기존 Firebase 인증·AI 배경 생성 코드는 legacy로 남아 있으나 현재 화면 흐름에 연결되지 않는다.
현재 일정 앱은 Firebase, Node 백엔드, AI API 없이 동작한다.

## 주요 파일

- `mobile/lib/main.dart`, `preview.dart`: `focus_app.dart`로 연결
- `mobile/lib/focus_app.dart`: 앱 테마와 시작 화면
- `mobile/lib/schedule.dart`: 일정 모델/저장, Android MethodChannel
- `mobile/lib/schedule_screen.dart`: 일정 UI 및 웹 잠금
- `mobile/lib/language.dart`: 번역/언어 설정
- `mobile/android/app/src/main/kotlin/com/focuslock/focuslock/`:
  `MainActivity.kt`, `ScheduleEngine.kt`, `LockService.kt`
- `mobile/test/widget_test.dart`: 자동 테스트
- `docs/SCHEDULE_LOCK.md`: 실행법과 제약, Android 검증 체크 항목

## 실행과 환경

공식 Flutter SDK는 `.tools/flutter`, Pub 캐시는 `.tools/pub-cache`에 있다.
`.tools`와 `backend/node_modules`는 Git에서 제외한다.
PowerShell, mobile 폴더에서:

```powershell
$env:PUB_CACHE = 'C:\Users\i\Desktop\FocusLock\.tools\pub-cache'
..\.tools\flutter\bin\flutter.bat run -d chrome --web-hostname 127.0.0.1 --web-port 8084
```

최근 미리보기 주소: http://127.0.0.1:8084
실행 프로세스는 다음 세션에 유지된다고 가정하지 말고 확인 후 필요하면 재실행한다.
테스트: 같은 환경에서 `flutter.bat test`.
Node 24/npm 11은 설치되어 있으나 현재 일정 앱에 백엔드는 필요 없다.
명령 실행 도구의 일반 환경 초기화 오류 때문에 이전 작업은 시스템 승인을 받은 실행으로 진행했다.

## 중요한 한계와 다음 작업

일반 오버레이는 시스템 키가드나 완전한 기기 봉쇄가 아니다.
홈/최근 앱/알림창/강제 종료/권한 철회 등 모든 우회를 막는다고 설명하면 안 된다.
전화 상태에 따른 오버레이 숨김 코드를 추가했으나 전화 화면을 안전하게 허용한다고 실기기 검증한 적이 없다.
실제 휴대폰 잠금 완료 또는 전화 예외 완료로 보고하지 말 것.

사용자는 다른 잠금 앱이 일반 설치만으로 잘 차단되는 경험이 있다고 했다.
해당 앱 이름과 테스트 휴대폰 기종/OS 버전은 아직 받지 못했다.
정확한 구현 방식과 제한을 실기기로 확인하는 것이 다음 핵심 단계다.

조사한 공식 문서:
- https://developer.android.com/develop/background-work/services/alarms
- https://developer.android.com/reference/android/app/NotificationManager.Policy
- https://developer.android.com/about/versions/15/behavior-changes-15
- https://developer.android.com/work/dpc/dedicated-devices/lock-task-mode

Android 방해금지/자동 규칙은 알림 제한과 전화 예외의 후보이다.
Android 15+는 앱의 전역 방해금지 변경 대신 앱 소유 규칙으로 동작하는 변경이 있다.
기기 관리 키오스크 모드는 강한 차단 후보지만 일반 권한 팝업만으로 얻는 권한은 아니다.
이들은 조사 결과이며 구현·실기기 검증 완료를 뜻하지 않는다.

## 다음 대화 시작 문장

`C:\Users\i\Desktop\FocusLock의 HANDOFF.md를 읽고 이전 작업을 이어서 진행해줘.`

## 2026-10-23 변경

- 사용자 요청으로 새 일정의 잠금 시간을 10분으로 고정하고 5분 선택 UI를 제거. Android 신규 등록도 10분만 허용.
- 기존 저장 일정의 종료 시각은 유지하며, 15초 화면 미리보기는 그대로 유지.
- Flutter 자동 테스트 4개 통과(10분 등록, 5분 선택 제거, 10분 종료 경계 포함). 변경 Dart 파일 분석에서 오류·경고 없이 기존 중괄호 스타일 안내만 확인. Android 빌드·실기기 잠금은 여전히 미검증.

## 2026-10-23 후속: 요구사항 1~4 구현

- 사용자 요청: 예약 자동 잠금, 앱 이동 제한, 전화 수신 예외, 일반 알림 차단까지 코드 구현.
- 10분 예약 알람/오버레이에 접근성 기반 일반 앱 전환 시 FocusLock 복귀를 연결. 화면 내용·입력 내용은 읽지 않으며 권한 안내 후 사용자가 직접 활성화.
- 전화는 Telecom의 전체 통화 상태와 전화 상태 방송으로 감지. 수신/통화 중 오버레이와 앱 복귀를 중단하고 종료 후 원래 종료 시각까지 재개. 전화 걸기 버튼 제공. 전화·긴급전화·시스템 설정·키가드는 예외.
- Android 10+ 앱 소유 AutomaticZenRule로 일반 알림 제한, 모든 전화 허용을 요청. 기존 전역 방해금지 설정을 덮어쓰지 않으며 시스템/우회 알림과 더 엄격한 사용자 규칙은 OS 정책에 따름.
- 종료·서비스 정리·일정 취소·재부팅·앱 재시작 시 앱 규칙 해제/복구 처리. 프로세스 종료에 대비한 별도 종료 알람 추가. 강제 종료는 알람까지 취소하므로 앱 재실행 또는 사용자 규칙 해제가 필요할 수 있음.
- 예약 전 표시·알람·알림·통화 상태·방해금지·접근성 권한 확인. Android 8/9 설치는 가능하지만 이 통합 예약 기능은 Android 10 이상 필요.
- Flutter 테스트 6개, Android JVM 단위 테스트 3개 통과. Debug APK 빌드 성공. Android Lint 오류 0개(스타일·deprecated 관련 경고는 남음).
- 전체 하네스 verify는 테스트 통과/분석 실패(exit 1): 이번 수정 파일 밖의 기존 legacy 화면에 info 41개가 남음. 분석 규칙 완화나 검사 삭제는 하지 않음. 변경한 일정/권한 Dart 파일의 분석 결과는 깨끗함.
- 검증 로그: `harness/runs/20261023-032133-904-verify-25032/`. Android 보고서: `mobile/build/app/reports/lint-results-debug.html`, `mobile/build/app/test-results/testDebugUnitTest/`.
- Android Lint에서 로컬 properties의 Windows 드라이브 콜론 이스케이프를 요구하여 미추적 환경 파일 `mobile/android/local.properties`만 정리. Kotlin 빌드 캐시 `.kotlin/`을 Git 제외.
- 실제 휴대폰 잠금·수신/발신/듀얼 SIM·알림 소리/진동/표시·기존 방해금지 복구는 미검증. `docs/SCHEDULE_LOCK.md`에 실기기 확인 목록 기록.
- 사용자 폴더 `oh-my-agent-main/`은 이 기능과 무관한 미추적 파일이므로 수정/커밋하지 않음.
