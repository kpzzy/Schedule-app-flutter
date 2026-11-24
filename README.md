# 하루 계획

Android·iOS용 Flutter 개인 스케줄 앱의 초기 프로젝트입니다. 한국어 UI로 일간·주간·월간 계획을 보고, 같은 일정 데이터를 편집하도록 구성했습니다.

**현재 상태: 소스와 플랫폼 프로젝트, 테스트 코드를 준비한 단계입니다. 서버에는 Flutter·Dart·JDK·Android SDK가 없어 `flutter analyze`, `flutter test`, Android·iOS 빌드 및 기기 실행은 아직 수행하지 않았습니다.**

## 기본 구현 범위

- 일간: 시간대별 목록, 현재 시각 표시, 빈 시간대에서 일정 추가
- 주간: 월요일 시작, 날짜별 목록과 시간 점유 막대
- 월간: 날짜별 제목 요약, 날짜를 누르면 일간 화면으로 이동
- 보기 전환 시 선택 날짜 유지, 이전·다음 기간 이동, 오늘로 돌아오기
- 일정 생성·수정·삭제, 완료·완료 취소, 편집 화면에서 날짜 변경
- 제목·메모·카테고리, 분 단위 시작·종료 입력, 자정을 넘는 일정
- 시간 미정 할 일, 여러 날짜에 걸친 종일 일정
- 겹치는 시간 안내와 겹침을 허용하는 저장
- 기기 내 JSON 자동 저장, 읽기·쓰기 실패 처리

처음 실행하면 빈 목록으로 시작합니다. 실제 일정이나 예시 데이터를 앱에 넣지 않았습니다. 반복 일정, 알림, 드래그 이동, 계정·동기화·백업 기능은 후속 범위입니다. 현재 시간표는 시간별 목록과 진행 중 표시를 사용하며, 일정 길이에 비례한 드래그 블록 UI는 구현하지 않았습니다.

## 개발 환경

기준 버전은 **Flutter 3.38.5 / Dart 3.10.4**입니다. 최신 버전이라는 의미가 아니라, 공식 태그의 템플릿과 의존성 기준을 고정한 것입니다. `.fvmrc`에도 같은 버전을 기록했습니다. FVM 사용은 선택 사항이며, 사용할 경우 아래 `flutter` 명령을 `fvm flutter`로 실행합니다.

| 구분 | 프로젝트 설정 / 로컬 준비 사항 |
| --- | --- |
| Android | Android 7.0(API 24) 이상, compile/target SDK 36 |
| Android 빌드 | JDK 17, Android SDK Platform 36, Build Tools 35.0.0, SDK 명령줄 도구 |
| Android 플러그인 | AGP 8.11.1, Gradle 8.14, Kotlin 2.2.20 |
| iOS | iOS 13.0 이상, macOS·Xcode·CocoaPods 필요 |
| 앱 식별자 | Android `com.example.schedule_app`, iOS `com.example.scheduleApp` — 개발용 자리표시자 |

네이티브 설정은 [Flutter 3.38.5 공식 템플릿](https://github.com/flutter/flutter/tree/3.38.5/packages/flutter_tools/templates/app)에 기반합니다. Android 버전 조합은 [공식 AGP 8.11 호환성 표](https://developer.android.com/build/releases/agp-8-11-0-release-notes)를 참고했습니다. 이 설정의 실제 플랫폼 빌드는 아직 검증하지 않았습니다.

## 처음 실행하기

1. [Flutter SDK 아카이브](https://docs.flutter.dev/install/archive)에서 기준 SDK를 준비하고 `flutter/bin`을 로컬 PATH에 등록합니다. Android Studio만 설치해서는 Dart 앱을 빌드할 수 없습니다.
2. 저장소의 **프로젝트 루트 폴더**를 Android Studio에서 엽니다. Flutter·Dart 플러그인을 설치하고 SDK 위치를 지정합니다.
3. 프로젝트 루트에서 아래 명령을 실행합니다.

```sh
flutter --version
flutter doctor -v
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter devices
flutter run
```

`pubspec.lock`은 Flutter 3.38.5 저장소의 잠금 파일에서 필요한 의존성만 추출하고 pub.dev 메타데이터와 해시를 대조해 준비했습니다. **이 서버에서 SDK의 의존성 해결 명령을 실행한 결과는 아닙니다.** 로컬에서 `flutter pub get`으로 확인하고, 잠금 파일이 달라지면 SDK 버전과 변경 내용을 검토한 뒤 함께 버전 관리합니다.

SDK 경로는 `android/local.properties`, iOS의 생성된 xcconfig 등에 로컬 도구가 기록합니다. 이 파일들은 Git에서 제외됩니다. 새 프로젝트를 다시 생성하는 `flutter create .`는 필요하지 않습니다.

### Android

Android Studio의 SDK Manager에서 API 36, 빌드 도구, SDK 명령줄 도구를 준비하고 JDK 17을 사용합니다. Flutter가 요구하는 NDK는 `flutter.ndkVersion`을 따릅니다. 필요한 SDK 패키지 다운로드와 라이선스 동의가 최초 빌드에 필요할 수 있습니다.

```sh
flutter doctor --android-licenses
flutter build apk --debug
flutter run
```

에뮬레이터를 시작하거나 USB 디버깅을 켠 기기를 연결한 뒤 실행합니다. 에뮬레이터와 Android Studio는 서버에서 APK만 빌드할 때의 필수 조건은 아닙니다.

Gradle wrapper 실행 파일·JAR는 공식 Flutter 템플릿의 제외 규칙을 따릅니다. 최초 `flutter build apk --debug` 또는 `flutter run`에서 Flutter가 생성하므로, `android/` 폴더만 별도로 열기 전에 Flutter 명령으로 한 번 초기화합니다. Gradle 배포 버전 설정은 저장소에 포함되어 있습니다.

현재 release 설정도 공식 템플릿처럼 개발용 debug 서명을 사용합니다. 스토어 배포 전에는 앱 식별자와 별도의 배포 서명을 설정해야 합니다. 키스토어·암호는 저장소에 넣지 않습니다.

### iOS — macOS에서 수행

[Flutter 공식 iOS 준비 안내](https://docs.flutter.dev/platform-integration/ios/setup)에 따라 Xcode, 명령줄 도구, 시뮬레이터 런타임, CocoaPods를 준비합니다. 이 프로젝트는 CocoaPods 방식으로 플러그인을 연결합니다.

```sh
flutter pub get
cd ios
pod install
cd ..
flutter build ios --simulator
open ios/Runner.xcworkspace
```

시뮬레이터를 시작한 뒤 프로젝트 루트에서 `flutter run`을 실행할 수도 있습니다. 실제 기기 실행은 Xcode의 Runner → Signing & Capabilities에서 자신의 Team과 Bundle Identifier를 설정합니다. 개인 서명 정보는 소스에 고정하지 않습니다. Ubuntu에서는 iOS 빌드·시뮬레이터 실행을 할 수 없습니다.

## 코드 구조

```text
lib/
  main.dart                                # 플랫폼 저장 경로 주입
  app/                                     # 앱 수명주기, 테마, 한국어 문자열
  core/calendar_date.dart                  # 시간대와 독립적인 날짜 계산
  features/schedule/
    domain/                                # 일정 모델, 입력 검증, 시간표 분류
    data/json_schedule_repository.dart     # 버전이 있는 로컬 JSON 저장
    presentation/                          # 상태, 화면, 편집, 표시 위젯
android/                                   # Kotlin/Gradle 프로젝트
ios/                                       # Swift/Xcode/CocoaPods 프로젝트
test/                                      # 날짜·모델·저장소·상태·위젯 테스트
```

상태는 Flutter의 `ChangeNotifier`로 관리합니다. 화면은 하나의 `ScheduleController`와 `ScheduleRepository`를 공유합니다. `path_provider` 2.1.5는 [Android·iOS의 앱 저장 경로를 제공하는 공식 패키지](https://pub.dev/packages/path_provider/versions/2.1.5)로 선택했습니다. 별도 상태 관리·데이터베이스·ID 패키지는 추가하지 않았습니다. 잠금 파일에 있는 Linux·Windows용 전이 의존성은 패키지 구조상 포함되며, 앱의 웹·데스크톱 프로젝트를 추가한 것은 아닙니다.

앱 문구는 `lib/app/app_strings.dart`에서 관리하고, Flutter 기본 날짜·시간 선택기는 `flutter_localizations`를 사용합니다. 월간 달력은 큰 글자에서도 날짜와 조작 영역을 유지하도록 가로로 스크롤할 수 있습니다.

## 데이터와 저장 규칙

- UUID v4 형식의 ID를 만들고, 수정·완료·날짜 이동에서도 동일한 ID를 유지합니다.
- 시간 지정 일정은 기기 현지 날짜·시각으로 입력받아 UTC로 저장하고, 표시·날짜 조회 시 현지 시간으로 변환합니다. 기기 시간대가 바뀌면 같은 순간의 표시 시각도 바뀝니다.
- 종일 일정은 날짜 문자열과 종료 제외 날짜로, 시간 미정 할 일은 날짜 문자열 하나로 저장합니다. 자정 시각으로 치환하지 않습니다. 편집 화면의 종일 종료 날짜는 **포함**하는 날짜입니다.
- 범위 비교는 `[시작, 종료)`입니다. 자정에 끝나는 일정은 다음 날에 나타나지 않으며, 맞닿은 두 일정은 겹치지 않습니다.
- 달력 이동은 날짜 계산으로 수행합니다. 현지 시각에서 존재하지 않는 서머타임 입력은 거부합니다. 중복되는 현지 시각의 두 발생을 사용자가 따로 선택하는 기능은 없으며 Dart의 기기 시간대 해석을 따릅니다.
- `getApplicationSupportDirectory()` 아래 `schedules.json`에 `schemaVersion: 1`로 저장합니다. 임시 파일을 flush한 다음 같은 디렉터리에서 rename하여 기존 파일을 교체합니다. 화면에는 저장 성공 뒤 새 상태를 반영합니다.
- 손상되거나 지원하지 않는 저장 형식은 자동 초기화하지 않습니다. 불러오기 실패를 표시하고 편집을 막아 원본을 보존합니다. 다음 스키마 변경 시 명시적인 마이그레이션을 추가해야 합니다.
- 현재 저장은 단일 앱 프로세스의 소규모 개인 일정에 맞춘 전체 파일 저장입니다. 별도 암호화·복원 기능은 없으며 앱 삭제 시 데이터가 사라질 수 있습니다. 운영체제 자체 백업은 기기 설정의 영향을 받습니다.

## 검증 상태와 다음 확인

서버에서 실시한 점검:

- Dart 소스의 문법 파싱과 포맷 적용: 임시 `dart_style` WASM 포트 사용. SDK의 `dart format`·타입 분석을 대체하지 않습니다.
- Android XML, iOS plist·스토리보드·워크스페이스 XML, JSON·YAML 구조 검사
- 공식 템플릿 치환, 로컬 import와 리소스 참조, 의존성 잠금 정보 점검
- Android·iOS PNG 23개의 공식 원본 일치 여부, PNG 체크섬, iOS 앱 아이콘 크기 검사
- Git 공백 오류와 민감정보 패턴 검사

SDK 부재로 실행하지 못한 항목:

- `flutter pub get`, `dart format`의 SDK 기준 확인, `flutter analyze`
- `flutter test`에 포함된 날짜 경계·저장 후 재조회·실패 복구·화면 조작 테스트
- Android·iOS 빌드, 저장 플러그인과 기기 UI 동작 검증

로컬에서는 위의 공통 명령을 실행하고 다음 흐름을 확인합니다.

1. 일정 추가 → 일간·주간·월간에서 동일 내용 확인 → 수정·완료·삭제
2. 앱 종료·재실행 후 일정 복원
3. 23:47~다음 날 01:13, 정확히 자정에 끝나는 일정, 월말의 여러 날 종일 일정
4. 작은 기기, 큰 글자, 키보드가 표시된 편집 화면, 가로 화면
5. Android와 iOS에서 각각 날짜·시간 선택기와 저장 실패 안내

Linux·macOS에서는 다른 시간대에서도 공통 날짜 테스트를 실행할 수 있습니다.

```sh
TZ=America/New_York flutter test test/calendar_date_test.dart test/schedule_item_test.dart
```

## 저장소 관리

`pubspec.lock`과 앱 소스·플랫폼 설정·테스트는 버전 관리 대상입니다. 빌드 결과, SDK 캐시, 개인 SDK 경로, 인증·서명 파일은 제외합니다. `credential.txt`와 서버 전용 인증 보조 스크립트는 앱 실행에 필요하지 않으며 다른 개발 환경으로 복사할 필요가 없습니다.

플랫폼 템플릿과 Android 기본 아이콘의 Flutter 라이선스는 [licenses/flutter_template_LICENSE](licenses/flutter_template_LICENSE)에 보관했습니다. iOS 기본 이미지는 Flutter 3.38.5가 사용하는 `flutter_template_images` 5.0.0의 실제 이미지 파일로 구성했으며, 해당 라이선스는 [licenses/flutter_template_images_LICENSE](licenses/flutter_template_images_LICENSE)에 포함했습니다. 프로젝트 작업 규칙은 [AGENTS.md](AGENTS.md)를 따릅니다.
