import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 다음(카카오) 주소 검색 WebView. 백엔드 /address-search-page 에서 제공하는 HTML 로드.
/// 주소 선택 시 [sido, sigungu, bname, roadAddress, jibunAddress, buildingName, zonecode] 반환.
class DaumAddressWebView extends StatefulWidget {
  final String url;

  const DaumAddressWebView({super.key, required this.url});

  @override
  State<DaumAddressWebView> createState() => _DaumAddressWebViewState();
}

class _DaumAddressWebViewState extends State<DaumAddressWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'Address',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final map = jsonDecode(message.message) as Map<String, dynamic>;
            if (mounted) Navigator.of(context).pop(map);
          } catch (_) {
            if (mounted) Navigator.of(context).pop(<String, String>{});
          }
        },
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주소 검색'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
