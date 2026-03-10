import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ═══════════════════════════════════════════════════════════════
// URL 열기 유틸
// ═══════════════════════════════════════════════════════════════

/// URL을 외부 브라우저/앱으로 엽니다.
/// 실패 시 SnackBar로 안내합니다.
Future<void> openUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    _showError(context, '잘못된 URL입니다');
    return;
  }
  try {
    final canOpen = await canLaunchUrl(uri);
    if (canOpen) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) _showError(context, '링크를 열 수 없습니다');
    }
  } catch (e) {
    if (context.mounted) _showError(context, '링크 열기 실패: $e');
  }
}

/// YouTube URL을 엽니다 (앱 우선 → 브라우저 폴백).
Future<void> openYoutube(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    _showError(context, '잘못된 YouTube URL입니다');
    return;
  }
  try {
    // YouTube 앱 우선 시도
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalNonBrowserApplication,
    );
    if (!launched) {
      // 앱 없으면 브라우저로
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (_) {
    // 앱 실패 시 브라우저로 재시도
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) _showError(context, 'YouTube를 열 수 없습니다');
    }
  }
}

void _showError(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
