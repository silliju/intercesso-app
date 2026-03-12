# Mac 개발 환경 설정 가이드 (Intercesso)

맥에서 Flutter(iOS + Android + Web) 개발 환경을 만드는 순서입니다.

---

## 1. 필수 설치

### 1) Xcode (iOS 빌드용)

- **App Store**에서 **Xcode** 검색 후 설치 (용량 큼, 시간 소요).
- 설치 후 한 번 실행해서 **라이선스 동의** 및 **추가 컴포넌트** 설치 완료.
- 터미널에서 명령어 사용을 위해:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### 2) Xcode Command Line Tools (Xcode 없이 최소만 쓰는 경우)

- Xcode 전체가 부담되면 먼저 Command Line Tools만 설치해도 됩니다.

```bash
xcode-select --install
```

- iOS 시뮬레이터/실기기 빌드는 나중에 **Xcode 앱 전체 설치**가 필요합니다.

### 3) Homebrew (선택, 권장)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

- 설치 후 터미널에 나오는 안내대로 `PATH` 설정 (`echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile` 등).

### 4) Flutter SDK

**방법 A – 공식 사이트**

1. https://docs.flutter.dev/get-started/install/macos 에서 안내대로 진행.
2. 또는 직접 다운로드: https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_*.zip (Apple Silicon) 또는 `flutter_macos_*_x64_*.zip` (Intel).
3. 압축 해제 후 원하는 폴더로 이동 (예: `~/development/flutter`).
4. PATH 추가 (`.zshrc` 또는 `.zprofile`):

```bash
export PATH="$PATH:$HOME/development/flutter/bin"
```

**방법 B – Homebrew**

```bash
brew install --cask flutter
```

- 설치 후:

```bash
flutter doctor
```

- 여기서 나오는 안내대로 Android 라이선스, Xcode 설정 등 추가 작업하면 됩니다.

### 5) CocoaPods (iOS 의존성)

```bash
sudo gem install cocoapods
```

- 또는 Homebrew:

```bash
brew install cocoapods
```

- 프로젝트에서 iOS 빌드 시 `pod install`이 자동으로 실행됩니다.

---

## 2. 프로젝트에서 할 일

### 저장소 클론 후

```bash
cd /원하는경로/intercesso-app/intercesso_app
flutter pub get
```

### iOS 빌드/실행

- **시뮬레이터** (Xcode 설치 후):

```bash
open ios/Runner.xcworkspace
```

- Xcode에서 상단에서 시뮬레이터 선택 후 Run (▶) 하거나,

```bash
flutter run
```

- 연결된 **실기기**가 있으면 기기 선택해서 실행 가능.

- **Release IPA** (TestFlight/배포용):

```bash
flutter build ipa
```

- 생성된 IPA는 `build/ios/ipa/` 근처에서 확인. Xcode Organizer나 Transporter로 업로드.

### Android (맥에서도 가능)

- Android Studio 설치 후 SDK 경로 맞추고:

```bash
flutter doctor
```

- 에러 없으면:

```bash
flutter build apk
```

### API 주소 지정해서 빌드 (실서버 연동)

```bash
flutter build apk --dart-define=API_BASE_URL=https://intercesso-backend-production-5f72.up.railway.app/api
flutter build ipa --dart-define=API_BASE_URL=https://intercesso-backend-production-5f72.up.railway.app/api
```

---

## 3. 한 번에 확인

```bash
cd intercesso_app
flutter doctor -v
```

- ✅가 많을수록 준비된 상태. ⚠️/❌는 해당 항목 설치·설정 후 다시 실행.

---

## 4. 정리

| 항목 | 용도 |
|------|------|
| **Xcode** | iOS 앱 빌드, 시뮬레이터, 서명/배포 |
| **Flutter SDK** | 앱 빌드·실행 (iOS/Android/Web) |
| **CocoaPods** | iOS 네이티브 의존성 (webview 등) |
| **Apple 개발자 계정** | 실기기 배포·TestFlight (유료) |

맥만 있으면 위 순서대로 진행하면 iOS 포함 개발 환경을 만들 수 있습니다.  
Windows에서는 iOS 빌드가 불가능하므로, iOS 빌드·설치는 반드시 맥에서 진행해야 합니다.
