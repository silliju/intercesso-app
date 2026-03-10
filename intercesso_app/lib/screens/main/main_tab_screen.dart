import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/gratitude_provider.dart';
import '../../screens/gratitude/create_gratitude_screen.dart';
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
    _NavTab('🏠', '홈',    _TabType.home),
    _NavTab('🙏', '기도',  _TabType.prayer),
    _NavTab('🤝', '중보',  _TabType.intercession),
    _NavTab('🌷', '감사',  _TabType.gamsa),
    _NavTab('👥', '그룹',  _TabType.group),
    _NavTab('👤', '프로필', _TabType.profile),
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
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final selected = _currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: _buildNavItem(tab, selected),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavTab tab, bool selected) {
    final Color activeColor = _getActiveColor(tab.type);
    final Color activeBg = _getActiveBg(tab.type);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: selected
          ? BoxDecoration(
              color: activeBg,
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(fontSize: selected ? 22 : 20),
            child: Text(tab.emoji),
          ),
          const SizedBox(height: 2),
          Text(
            tab.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? activeColor : AppTheme.textLight,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActiveColor(_TabType type) {
    switch (type) {
      case _TabType.gamsa:
        return AppTheme.gamsa;
      case _TabType.intercession:
        return AppTheme.secondary;
      default:
        return AppTheme.primary;
    }
  }

  Color _getActiveBg(_TabType type) {
    switch (type) {
      case _TabType.gamsa:
        return AppTheme.gamsaLight;
      case _TabType.intercession:
        return const Color(0xFFE6FBF7);
      default:
        return AppTheme.primaryLight;
    }
  }

  Widget? _buildFAB() {
    // 기도 탭 FAB
    if (_currentIndex == 1) {
      return FloatingActionButton(
        backgroundColor: AppTheme.primary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onPressed: () => context.push('/prayer/create'),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      );
    }
    // 감사 탭 FAB
    if (_currentIndex == 3) {
      return Consumer<GratitudeProvider>(
        builder: (_, provider, __) {
          final hasTodayJournal = provider.hasTodayJournal;
          return FloatingActionButton.extended(
            backgroundColor: AppTheme.gamsa,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CreateGratitudeScreen(existing: provider.todayJournal),
                ),
              );
              if (result == true && mounted) {
                provider.loadFeed('group', refresh: true);
              }
            },
            icon: Text(
              hasTodayJournal ? '✏️' : '✨',
              style: const TextStyle(fontSize: 16),
            ),
            label: Text(
              hasTodayJournal ? '오늘 일기 수정' : '감사 쓰기',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          );
        },
      );
    }
    return null;
  }
}

enum _TabType { home, prayer, intercession, gamsa, group, profile }

class _NavTab {
  final String emoji;
  final String label;
  final _TabType type;
  const _NavTab(this.emoji, this.label, this.type);
}
