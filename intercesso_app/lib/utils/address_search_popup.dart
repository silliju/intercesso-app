import 'address_search_popup_stub.dart'
    if (dart.library.html) 'address_search_popup_web.dart' as impl;

/// 웹: 팝업으로 주소 검색 후 postMessage로 결과 수신. 비-웹: null 반환(WebView 사용).
Future<Map<String, dynamic>?> openAddressSearchPopup(String url) =>
    impl.openAddressSearchPopup(url);
