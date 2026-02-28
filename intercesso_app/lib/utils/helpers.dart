import 'package:flutter/material.dart';

class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color backgroundColor = const Color(0xFF323232);
    if (isError) backgroundColor = const Color(0xFFEF4444);
    if (isSuccess) backgroundColor = const Color(0xFF10B981);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void error(BuildContext context, String message) {
    show(context, message, isError: true);
  }

  static void success(BuildContext context, String message) {
    show(context, message, isSuccess: true);
  }
}

class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return '이메일을 입력해주세요';
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value)) return '올바른 이메일 형식이 아닙니다';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return '비밀번호를 입력해주세요';
    if (value.length < 8) return '비밀번호는 8자 이상이어야 합니다';
    return null;
  }

  static String? required(String? value, {String fieldName = '항목'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName을(를) 입력해주세요';
    return null;
  }

  static String? nickname(String? value) {
    if (value == null || value.isEmpty) return '닉네임을 입력해주세요';
    if (value.length < 2) return '닉네임은 2자 이상이어야 합니다';
    if (value.length > 20) return '닉네임은 20자 이하여야 합니다';
    return null;
  }
}
