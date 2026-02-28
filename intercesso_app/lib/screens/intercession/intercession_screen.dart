import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../widgets/common_widgets.dart';

class IntercessionScreen extends StatelessWidget {
  const IntercessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('중보기도')),
      body: const Center(
        child: EmptyWidget(
          emoji: '🤝',
          title: '중보기도 요청',
          subtitle: '다른 사람의 기도를 위해\n함께 기도해보세요',
        ),
      ),
    );
  }
}
