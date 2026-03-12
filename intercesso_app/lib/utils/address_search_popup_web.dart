import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

/// 웹 전용: 주소 검색 페이지를 팝업으로 열고, 선택 시 postMessage로 받아서 반환.
Future<Map<String, dynamic>?> openAddressSearchPopup(String url) async {
  final uri = Uri.parse(url);
  final origin = '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';

  final completer = Completer<Map<String, dynamic>?>();
  StreamSubscription<html.MessageEvent>? sub;
  Timer? closeCheck;

  void finish(Map<String, dynamic>? value) {
    if (!completer.isCompleted) {
      sub?.cancel();
      closeCheck?.cancel();
      completer.complete(value);
    }
  }

  sub = html.window.onMessage.listen((html.MessageEvent event) {
    if (event.origin != origin) return;
    try {
      final data = event.data;
      if (data is! String) return;
      final map = jsonDecode(data) as Map<String, dynamic>;
      if (map.containsKey('sido') || map.containsKey('roadAddress')) {
        finish(map);
      }
    } catch (_) {}
  });

  final window = html.window.open(
    url,
    'addressSearch',
    'width=500,height=600,scrollbars=yes,resizable=yes',
  );

  closeCheck = Timer.periodic(const Duration(milliseconds: 300), (_) {
    if (window.closed == true) {
      finish(null);
    }
  });

  return completer.future;
}
