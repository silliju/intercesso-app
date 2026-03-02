import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/prayer_provider.dart';
import '../../config/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../config/constants.dart';

class PrayersScreen extends StatefulWidget {
  const PrayersScreen({super.key});

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

// 탭 인덱스 → scope 매핑
const _tabScopes = <String?>[null, 'mine', 'friends', 'praying'];
const _tabLabels = ['전체 공개', '내 기도', '지인 기도', '기도중'];

class _PrayersScreenState extends State<PrayersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategory;
  final ScrollController _scrollController = ScrollController();

  // 현재 선택된 scope (탭에 연동)
  String? get _currentScope => _tabScopes[_tabController.index];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabScopes.length, vsync: this);
    _scrollController.addListener(_onScroll);
    // 첫 로드: 전체 공개 (index=0, scope=null)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPrayers(scope: _currentScope);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PrayerProvider>().loadPrayers(
            scope: _currentScope,
            category: _selectedCategory,
          );
    }
  }

  Future<void> _loadPrayers({String? scope}) async {
    if (!mounted) return;
    final provider = context.read<PrayerProvider>();
    await provider.loadPrayers(
      refresh: true,
      scope: scope,
      category: _selectedCategory,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayerProvider = context.watch<PrayerProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('기도 목록'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textLight,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          onTap: (index) {
            // 탭 전환 시 해당 scope로 새로 로드
            _loadPrayers(scope: _tabScopes[index]);
          },
          tabs: _tabLabels
              .map((label) => Tab(text: label))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          // 카테고리 필터
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildCategoryChip(null, '전체'),
                  ...AppConstants.prayerCategories
                      .map((cat) => _buildCategoryChip(cat, cat)),
                ],
              ),
            ),
          ),
          // 기도 목록
          Expanded(
            child: prayerProvider.isLoading && prayerProvider.prayers.isEmpty
                ? const LoadingWidget(message: '기도 목록을 불러오는 중...')
                : prayerProvider.prayers.isEmpty
                    ? EmptyWidget(
                        emoji: '🙏',
                        title: '기도가 없어요',
                        subtitle: _currentScope == 'mine'
                            ? '첫 번째 기도를 작성해보세요'
                            : _currentScope == 'praying'
                                ? '함께 기도하는 내역이 없어요'
                                : _currentScope == 'friends'
                                    ? '지인이 작성한 기도가 없어요'
                                    : '첫 번째 기도를 작성해보세요',
                        buttonText: _currentScope == 'mine' || _currentScope == null
                            ? '기도 작성하기'
                            : null,
                        onButtonTap: _currentScope == 'mine' || _currentScope == null
                            ? () => context.push('/prayer/create')
                            : null,
                      )
                    : RefreshIndicator(
                        color: AppTheme.primary,
                        onRefresh: () => _loadPrayers(scope: _currentScope),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: prayerProvider.prayers.length +
                              (prayerProvider.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= prayerProvider.prayers.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primary,
                                  ),
                                ),
                              );
                            }
                            final prayer = prayerProvider.prayers[index];
                            return PrayerCard(
                              title: prayer.title,
                              content: prayer.content,
                              userNickname: prayer.user?.nickname,
                              userImage: prayer.user?.profileImageUrl,
                              status: prayer.status,
                              category: prayer.category,
                              scope: prayer.scope,
                              prayerCount: prayer.prayerCount,
                              commentCount: prayer.commentCount,
                              createdAt: prayer.createdAt,
                              isParticipated: prayer.isParticipated,
                              onTap: () =>
                                  context.push('/prayer/${prayer.id}'),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? value, String label) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedCategory = value);
          _loadPrayers(scope: _currentScope);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : AppTheme.surface,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
