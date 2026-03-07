import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../home/home_screen.dart';
import '../prayers/prayers_screen.dart';
import '../gratitude/gratitude_feed_screen.dart';
import '../groups/groups_screen.dart';
import '../profile/profile_screen.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => MainTabScreenState();
}

// public State 클래스 - HomeScreen에서 탭 전환 접근 가능
class MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    PrayersScreen(),
    GratitudeFeedScreen(),
    GroupsScreen(),
    ProfileScreen(),
  ];

  /// 외부에서 탭을 전환할 때 사용
  void switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE8ECEF), width: 0.8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, '🏠', '홈', AppTheme.primary),
              _buildNavItem(1, '🙏', '기도', AppTheme.primary),
              _buildNavItem(2, '🌸', '감사', const Color(0xFFF59E0B)),
              _buildNavItem(3, '👥', '그룹', AppTheme.primary),
              _buildNavItem(4, '👤', '프로필', AppTheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String emoji, String label, Color activeColor) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: index == 2
                    ? const Color(0xFFFFF8E7)
                    : AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: isSelected ? 24 : 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? activeColor : const Color(0xFFADB5BD),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFAB() {
    // 기도 탭(1)에서만 FAB 표시
    if (_currentIndex != 1) return null;
    return FloatingActionButton(
      backgroundColor: AppTheme.primary,
      elevation: 4,
      onPressed: () => context.push('/prayer/create'),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
    );
  }
}
