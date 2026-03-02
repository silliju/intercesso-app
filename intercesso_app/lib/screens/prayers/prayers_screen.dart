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

  // 검색 상태
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<dynamic> _searchResults = [];
  bool _isSearchLoading = false;

  // 현재 선택된 scope (탭에 연동)
  String? get _currentScope => _tabScopes[_tabController.index];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabScopes.length, vsync: this);
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PrayerProvider>();
      provider.setActiveScope(_currentScope);
      _loadPrayers(scope: _currentScope);
    });
  }

  void _onScroll() {
    if (_isSearchMode) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PrayerProvider>().loadPrayers(
            scope: _currentScope,
            category: _selectedCategory,
          );
    }
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    if (q == _searchQuery) return;
    _searchQuery = q;
    if (q.isEmpty) {
      setState(() { _searchResults = []; _isSearchLoading = false; });
      return;
    }
    _debounceSearch(q);
  }

  // 간단한 디바운스 (300ms)
  DateTime? _lastSearchTime;
  void _debounceSearch(String query) {
    _lastSearchTime = DateTime.now();
    final capturedTime = _lastSearchTime;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (capturedTime == _lastSearchTime && mounted) {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted || query.isEmpty) return;
    setState(() => _isSearchLoading = true);
    try {
      final provider = context.read<PrayerProvider>();
      // loadPrayers를 검색용으로 재사용: scope=null(전체)에서 로컬 필터
      await provider.loadPrayers(refresh: true, scope: null);
      // 클라이언트 사이드 필터링 (제목 + 내용 기준)
      final all = provider.prayers;
      final lower = query.toLowerCase();
      setState(() {
        _searchResults = all.where((p) =>
          p.title.toLowerCase().contains(lower) ||
          p.content.toLowerCase().contains(lower)
        ).toList();
        _isSearchLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isSearchLoading = false);
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

  void _enterSearchMode() {
    setState(() {
      _isSearchMode = true;
      _searchQuery = '';
      _searchResults = [];
    });
    _searchController.clear();
  }

  void _exitSearchMode() {
    setState(() {
      _isSearchMode = false;
      _searchQuery = '';
      _searchResults = [];
      _isSearchLoading = false;
    });
    _searchController.clear();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayerProvider = context.watch<PrayerProvider>();

    // 검색 모드
    if (_isSearchMode) {
      return _buildSearchView(prayerProvider);
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('기도 목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: '검색',
            onPressed: _enterSearchMode,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textLight,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          onTap: (index) {
            final scope = _tabScopes[index];
            context.read<PrayerProvider>().setActiveScope(scope);
            _loadPrayers(scope: scope);
          },
          tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
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
            child: _buildPrayerList(prayerProvider),
          ),
        ],
      ),
    );
  }

  // ── 기도 목록 영역 ─────────────────────────────────────────────
  Widget _buildPrayerList(PrayerProvider prayerProvider) {
    if (prayerProvider.isLoading && prayerProvider.prayers.isEmpty) {
      return const LoadingWidget(message: '기도 목록을 불러오는 중...');
    }
    if (prayerProvider.prayers.isEmpty) {
      return EmptyWidget(
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
      );
    }
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () => _loadPrayers(scope: _currentScope),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: prayerProvider.prayers.length + (prayerProvider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= prayerProvider.prayers.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
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
            onTap: () => context.push('/prayer/${prayer.id}'),
          );
        },
      ),
    );
  }

  // ── 검색 뷰 ────────────────────────────────────────────────────
  Widget _buildSearchView(PrayerProvider prayerProvider) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: _exitSearchMode,
        ),
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '기도 제목, 내용으로 검색...',
            hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 15),
            border: InputBorder.none,
            filled: false,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textLight),
                    onPressed: () {
                      _searchController.clear();
                      setState(() { _searchResults = []; _isSearchLoading = false; });
                    },
                  )
                : null,
          ),
          style: const TextStyle(fontSize: 15),
          textInputAction: TextInputAction.search,
        ),
      ),
      body: _buildSearchResults(),
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔍', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('기도 제목이나 내용으로 검색하세요',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    if (_isSearchLoading) {
      return const LoadingWidget(message: '검색 중...');
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😔', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('"$_searchQuery"에 대한 결과가 없어요',
                style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final prayer = _searchResults[index];
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
          onTap: () => context.push('/prayer/${prayer.id}'),
        );
      },
    );
  }

  // ── 카테고리 칩 ────────────────────────────────────────────────
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
