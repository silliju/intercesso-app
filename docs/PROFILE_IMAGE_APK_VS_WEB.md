# 웹에서는 프로필 사진 되는데 APK에서는 안 될 때

## 가능한 원인

### 1. **업로드가 APK에서만 실패하는 경우**
- **증상**: 웹에선 프로필 수정 후 사진이 보이는데, APK에선 저장해도 사진이 안 바뀜.
- **원인 후보**  
  - **요청 크기**: APK에서 찍은/고른 사진이 웹보다 커서 base64 body가 크고, 타임아웃·413 발생.  
  - **타임아웃**: 모바일 네트워크가 느릴 때 15초 안에 응답이 안 오면 실패.
- **확인 방법**  
  - 프로필 수정 후 **다시 로그인하거나** `GET /users/me` 로 `profile_image_url` 이 들어오는지 확인.  
  - 백엔드 로그에서 `PUT /users/me` 200 여부, 413/5xx 여부 확인.
- **조치**  
  - `edit_profile_screen` 에서 `imageQuality`, `maxWidth`, `maxHeight` 로 더 줄여서 업로드 (이미 70, 512, 512 적용됨).  
  - APK 전용으로 `ApiService.put` 타임아웃만 늘려보기.

### 2. **이미지 URL은 저장되는데 APK에서만 안 보이는 경우**
- **증상**: 웹에선 프로필/기도 피드에서 사진이 보이는데, APK에선 같은 URL인데도 안 보임.
- **원인 후보**  
  - **Android 9+ Cleartext 차단**: 이미지 URL이 **HTTP** 이면 기본 정책으로 차단됨. (Supabase Storage 는 보통 **HTTPS** 라서 해당 없을 수 있음.)  
  - **네트워크/SSL**: APK만 다른 네트워크(회사 Wi‑Fi, VPN)를 쓰거나, SSL 검증 이슈.  
  - **CachedNetworkImage / HTTP 클라이언트**: 특정 URL/리다이렉트에서만 실패하는 경우.
- **확인 방법**  
  - DB/API에서 저장된 `profile_image_url` 값을 복사해 **APK 기기에서 브라우저나 WebView** 로 직접 열어보기.  
  - 주소가 `https://` 로 시작하는지 확인.
- **조치**  
  - `android/app/src/main/res/xml/network_security_config.xml` 추가하고, `AndroidManifest` 에 `android:networkSecurityConfig="@xml/network_security_config"` 적용해 두었음.  
  - URL이 **반드시 HTTPS** 인지 확인 (Supabase public URL 은 보통 HTTPS).

### 3. **웹/APK 환경 차이**
- **웹**: 브라우저가 쿠키·캐시·CORS 등으로 이미지 요청 처리. 같은 도메인이면 더 관대할 수 있음.  
- **APK**: Flutter 앱의 HTTP 클라이언트가 요청. User-Agent·리다이렉트 처리 등이 달라서 특정 CDN/Storage 에서만 실패할 수 있음.

## 체크리스트
- [ ] 저장 후 `GET /users/me` 에 `profile_image_url` 이 채워져 있는가? (APK에서도)  
- [ ] 그 URL 이 `https://` 인가?  
- [ ] 그 URL 을 APK 기기 브라우저에서 열면 이미지가 보이는가?  
- [ ] 백엔드 `PUT /users/me` 가 200 이고, Supabase Storage `avatars` 버킷에 파일이 올라가 있는가?

위를 확인하면 “웹은 되는데 APK만 안 된다”가 **업로드 실패**인지 **표시(로드) 실패**인지 구분할 수 있습니다.
