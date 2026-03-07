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

  final List<Widget> _screens = [
    const HomeScreen(),
    const PrayersScreen(),
    const GratitudeFeedScreen(),  // 🌸 감사 탭
    const GroupsScreen(),
    const ProfileScreen(),
  ];

  /// 외부에서 탭을 전환할 때 사용 (예: 홈화면 '전체보기' 버튼)
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 1),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppTheme.surface,
          selectedItemColor: _selectedColor(_currentIndex),
          unselectedItemColor: AppTheme.textLight,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '홈',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: '기도',
            ),
            // 🌸 감사일기 탭 (황금색 강조)
            BottomNavigationBarItem(
              icon: const Text('🌸', style: TextStyle(fontSize: 22)),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🌸', style: TextStyle(fontSize: 22)),
              ),
              label: '감사',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: '그룹',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '마이',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              backgroundColor: AppTheme.primary,
              onPressed: () => context.push('/prayer/create'),
              child: const Icon(Icons.edit_outlined, color: Colors.white),
            )
          : null,
    );
  }

  Color _selectedColor(int index) {
    if (index == 2) return const Color(0xFFF59E0B); // 감사 탭 = 황금색
    return AppTheme.primary;
  }
}
