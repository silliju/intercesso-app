# 주소 API (다음/카카오 주소 검색) 현황 및 해결 방향

## 현재 구조

- **백엔드**: `GET /address-search-page` 에서 다음(카카오) 주소 검색용 HTML 제공.
  - 스크립트: `https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js` (공식 권장 URL)
  - 사용자가 주소 선택 시 `window.Address.postMessage(JSON)` 호출 → Flutter WebView의 JavaScriptChannel 로 전달
  - 웹 팝업일 때는 `window.opener.postMessage` 로 전달
- **Flutter**
  - **웹**: 팝업으로 주소 검색 페이지 열고 `postMessage` 로 결과 수신 → 정상 동작
  - **APK**: `DaumAddressWebView`(WebView)로 같은 URL 로드, 채널 이름 `'Address'` 로 결과 수신

## APK에서 안 될 수 있는 원인 (해결 가능)

| 원인 | 설명 | 대응 |
|------|------|------|
| **1. 채널 타이밍** | WebView에서 `window.Address` 가 주입되기 전에 주소 선택 콜백이 실행되면 전달 실패 | 백엔드 HTML에 **재시도 로직** 추가함(선택 시 100ms 간격으로 최대 15회까지 `window.Address.postMessage` 호출). |
| **2. 페이지 로드 실패** | APK에서 `/address-search-page` URL 로드 시 SSL·네트워크·CSP 등으로 실패 | WebView 에러 화면에서 “연결 오류” 등 메시지 확인. 백엔드 URL이 HTTPS 인지, Railway 배포가 살아 있는지 확인. |
| **3. CSP / 스크립트 차단** | Android WebView가 일부 스크립트/도메인을 막는 경우 | 백엔드 CSP는 `t1.daumcdn.net`, `postcode.map.kakao.com` 등 허용돼 있음. 필요 시 CSP 완화 검토. |
| **4. 다음 API 정책 변경** | 도메인 제한·앱 키 필요 등 | [다음 우편번호 가이드](https://postcode.map.daum.net/guide) 확인. 현재는 무료 오픈 API 사용. |

## 적용한 수정 (이번 변경)

- **백엔드 `handleAddressSearchPage`**
  - 주소 선택 시 `window.Address` 가 아직 없을 수 있어, **최대 15회까지 100ms 간격 재시도**로 `window.Address.postMessage(payload)` 호출.
  - APK WebView에서 채널 주입이 조금 늦어져도 결과가 Flutter 쪽으로 전달될 가능성이 높아짐.

## 우리가 해결 못하는 게 아닌지

- **구조상 해결 가능한 이슈**입니다.  
  - 웹은 이미 동작하므로, **APK만의 차이**는 WebView 환경(채널 타이밍, 로드 실패, CSP 등)으로 좁혀짐.
- **확인 순서 제안**
  1. APK에서 “주소 찾기” 탭 후 WebView가 뜨는지, 다음 주소 검색 UI가 보이는지 확인.
  2. 주소를 선택했을 때  
     - 교회 등록 화면으로 돌아가면서 주소가 채워지면 → 정상(이번 재시도 로직이 효과 있는 경우).  
     - 아무 반응 없으면 → WebView 쪽에서 `window.Address` 미노출 또는 로드/스크립트 오류 가능.
  3. WebView에서 “연결 오류” 등 에러 메시지가 보이면, 백엔드 URL(HTTPS) 및 네트워크 설정 확인.

## 추가로 할 수 있는 것

- **Flutter WebView**
  - `webview_flutter` 의 `JavascriptChannel` 이름이 `'Address'` 인지 다시 확인.
  - 필요 시 주소 선택 결과를 **URL fragment** 나 **직접 로드하는 별도 HTML** 로 넘기는 방식으로 우회 가능(구조 변경 필요).
- **대안**
  - “브라우저로 주소 검색 후 직접 입력”처럼, 공공 주소 검색(juso.go.kr 등)으로 찾고 앱에 직접 입력하는 플로우는 이미 안내돼 있음.

정리하면, **주소 API는 현재 구조 안에서 해결 가능한 문제**이고, 이번에 채널 타이밍 재시도를 넣었으니 APK에서 한 번 더 테스트해 보시면 됩니다.
