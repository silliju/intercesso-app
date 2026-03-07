import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../home/home_screen.dart';
import '../prayers/prayers_screen.dart';
import '../intercession/intercession_screen.dart';
import '../gratitude/gratitude_feed_screen.dart';
import '../groups/groups_screen.dart';
import '../profile/profile_screen.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => MainTabScreenState();
}

class MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),          // 0 홈
    PrayersScreen(),       // 1 기도
    IntercessionScreen(),  // 2 중보
    GratitudeFeedScreen(), // 3 감사
    GroupsScreen(),        // 4 그룹
    ProfileScreen(),       // 5 프로필
  ];

  void switchToTab(int index) => setState(() => _currentIndex = index);

  static const _tabs = [
    _NavTab('🏠', '홈',    false),
    _NavTab('🙏', '기도',  false),
    _NavTab('🤝', '중보',  false),
    _NavTab('🌸', '감사',  true),   // 감사는 황금색 강조
    _NavTab('👥', '그룹',  false),
    _NavTab('👤', '프로필', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8ECEF), width: 0.8)),
        boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, -3))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final selected = _currentIndex == i;
              final activeColor = tab.isGamsa ? AppTheme.gamsa : AppTheme.primary;
              final activeBg   = tab.isGamsa ? const Color(0xFFFFF8E7) : AppTheme.primaryLight;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
                    decoration: selected
                        ? BoxDecoration(color: activeBg, borderRadius: BorderRadius.circular(12))
                        : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tab.emoji,
                          style: TextStyle(fontSize: selected ? 22 : 20),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                            color: selected ? activeColor : const Color(0xFFADB5BD),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget? _buildFAB() {
    if (_currentIndex == 1) {
      return FloatingActionButton(
        backgroundColor: AppTheme.primary,
        elevation: 4,
        onPressed: () => context.push('/prayer/create'),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      );
    }
    if (_currentIndex == 3) {
      return FloatingActionButton.extended(
        backgroundColor: AppTheme.gamsa,
        elevation: 4,
        onPressed: () => context.push('/gratitude/create'),
        icon: const Text('✨', style: TextStyle(fontSize: 16)),
        label: const Text('감사 쓰기', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      );
    }
    return null;
  }
}

class _NavTab {
  final String emoji;
  final String label;
  final bool isGamsa;
  const _NavTab(this.emoji, this.label, this.isGamsa);
}
