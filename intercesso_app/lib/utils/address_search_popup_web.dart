import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// 웹 전용: 주소 검색 페이지를 팝업으로 열고, 선택 시 postMessage로 받아서 반환.
Future<Map<String, dynamic>?> openAddressSearchPopup(String url) async {
  final uri = Uri.parse(url);
  final expectedOrigin = '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
  bool isAllowedOrigin(String? o) =>
      o != null && (o == expectedOrigin || o.startsWith('${uri.scheme}://${uri.host}'));

  final completer = Completer<Map<String, dynamic>?>();
  StreamSubscription<html.MessageEvent>? sub;
  Timer? closeCheck;
  Timer? closeDelay;

  void finish(Map<String, dynamic>? value) {
    if (!completer.isCompleted) {
      sub?.cancel();
      closeCheck?.cancel();
      closeDelay?.cancel();
      completer.complete(value);
    }
  }

  sub = html.window.onMessage.listen((html.MessageEvent event) {
    if (!isAllowedOrigin(event.origin)) return;
    try {
      final data = event.data;
      if (data is! String) return;
      final map = jsonDecode(data) as Map<String, dynamic>;
      if (map.containsKey('sido') || map.containsKey('roadAddress')) {
        finish(map);
      }
    } catch (e) {
      debugPrint('주소 팝업 postMessage 파싱 실패: $e');
    }
  });

  final window = html.window.open(
    url,
    'addressSearch',
    'width=500,height=600,scrollbars=yes,resizable=yes',
  );

  // 팝업이 닫혀도 postMessage가 도착할 때까지 잠시 대기 후에만 null 완료 (경쟁 조건 방지)
  closeCheck = Timer.periodic(const Duration(milliseconds: 300), (_) {
    if (window.closed == true) {
      closeCheck?.cancel();
      closeDelay = Timer(const Duration(milliseconds: 600), () => finish(null));
    }
  });

  return completer.future;
}
