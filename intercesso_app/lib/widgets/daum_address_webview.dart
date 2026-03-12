import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _loadFailed = false;
  String? _loadError;

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
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _loadFailed = true;
                _loadError = error.description ?? '페이지를 불러올 수 없습니다.';
              });
            }
          },
          onHttpError: (HttpResponseError error) {
            if (mounted) {
              setState(() {
                _loadFailed = true;
                _loadError = '연결 오류. 서버 주소를 확인해 주세요.';
              });
            }
          },
        ),
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
        child: _loadFailed
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      _loadError ?? '주소 검색 페이지를 불러올 수 없습니다.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '백엔드를 최신 버전으로 배포했는지 확인해 주세요. 또는 아래에서 공공 주소 검색으로 찾은 뒤 직접 입력할 수 있습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse('https://www.juso.go.kr/');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                        if (mounted) Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.open_in_browser, size: 20),
                      label: const Text('브라우저로 주소 검색 후 직접 입력'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('닫기'),
                    ),
                  ],
                ),
              )
            : WebViewWidget(controller: _controller),
      ),
    );
  }
}
