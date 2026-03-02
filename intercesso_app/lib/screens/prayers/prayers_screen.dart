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

class _PrayersScreenState extends State<PrayersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategory;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadPrayers();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PrayerProvider>().loadPrayers();
    }
  }

  Future<void> _loadPrayers({String? scope}) async {
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
            final scopes = [null, 'mine', 'friends', 'praying'];
            _loadPrayers(scope: scopes[index]);
          },
          tabs: const [
            Tab(text: '전체 공개'),
            Tab(text: '내 기도'),
            Tab(text: '지인 기도'),
            Tab(text: '기도중'),
          ],
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
                        subtitle: '첫 번째 기도를 작성해보세요',
                        buttonText: '기도 작성하기',
                        onButtonTap: () => context.push('/prayer/create'),
                      )
                    : RefreshIndicator(
                        color: AppTheme.primary,
                        onRefresh: () => _loadPrayers(),
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
          _loadPrayers();
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
