import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/gratitude_service.dart';

class GratitudeProvider extends ChangeNotifier {
  final GratitudeService _service = GratitudeService();

  // ── 오늘 일기 ──────────────────────────────────────────────
  GratitudeModel? _todayJournal;
  bool _isTodayLoading = false;

  GratitudeModel? get todayJournal => _todayJournal;
  bool get isTodayLoading => _isTodayLoading;
  bool get hasTodayJournal => _todayJournal != null;

  // ── 피드 (탭별) ────────────────────────────────────────────
  final Map<String, List<GratitudeModel>> _feedData = {
    'group': [],
    'following': [],
    'public': [],
  };
  final Map<String, bool> _feedLoading = {
    'group': false,
    'following': false,
    'public': false,
  };
  final Map<String, bool> _feedHasMore = {
    'group': true,
    'following': true,
    'public': true,
  };
  final Map<String, int> _feedPage = {
    'group': 1,
    'following': 1,
    'public': 1,
  };

  List<GratitudeModel> getFeedByTab(String tab) => _feedData[tab] ?? [];
  bool isFeedLoading(String tab) => _feedLoading[tab] ?? false;
  bool hasFeedMore(String tab) => _feedHasMore[tab] ?? true;

  // ── 내 일기 목록 ───────────────────────────────────────────
  List<GratitudeModel> _myJournals = [];
  bool _isMyJournalsLoading = false;
  bool _myJournalsHasMore = true;
  int _myJournalsPage = 1;

  List<GratitudeModel> get myJournals => _myJournals;
  bool get isMyJournalsLoading => _isMyJournalsLoading;
  bool get myJournalsHasMore => _myJournalsHasMore;

  // ── 스트릭 ─────────────────────────────────────────────────
  GratitudeStreakModel _streak = GratitudeStreakModel(
    currentStreak: 0,
    longestStreak: 0,
    totalCount: 0,
  );
  GratitudeStreakModel get streak => _streak;

  // ── 캘린더 ─────────────────────────────────────────────────
  Map<String, dynamic> _calendarData = {};
  bool _isCalendarLoading = false;
  Map<String, dynamic> get calendarData => _calendarData;
  bool get isCalendarLoading => _isCalendarLoading;

  // ── 에러 ───────────────────────────────────────────────────
  String? _error;
  String? get error => _error;

  // ════════════════════════════════════════════════════════════
  // 오늘 일기
  // ════════════════════════════════════════════════════════════

  Future<void> loadTodayJournal() async {
    _isTodayLoading = true;
    notifyListeners();
    try {
      _todayJournal = await _service.getTodayJournal();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isTodayLoading = false;
      notifyListeners();
    }
  }

  Future<GratitudeModel?> saveJournal({
    required String gratitude1,
    String? gratitude2,
    String? gratitude3,
    String? emotion,
    String? linkedPrayerId,
    String scope = 'private',
  }) async {
    try {
      final journal = await _service.saveJournal(
        gratitude1: gratitude1,
        gratitude2: gratitude2,
        gratitude3: gratitude3,
        emotion: emotion,
        linkedPrayerId: linkedPrayerId,
        scope: scope,
      );
      _todayJournal = journal;
      // 스트릭 갱신
      await loadStreak();
      // 내 목록 첫 페이지 갱신
      _myJournals = [];
      _myJournalsPage = 1;
      _myJournalsHasMore = true;
      await loadMyJournals();
      notifyListeners();
      return journal;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteJournal(String journalId) async {
    try {
      await _service.deleteJournal(journalId);
      if (_todayJournal?.id == journalId) _todayJournal = null;
      _myJournals.removeWhere((j) => j.id == journalId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // 피드
  // ════════════════════════════════════════════════════════════

  Future<void> loadFeed(String tab, {bool refresh = false}) async {
    if (_feedLoading[tab] == true) return;
    if (refresh) {
      _feedData[tab] = [];
      _feedPage[tab] = 1;
      _feedHasMore[tab] = true;
    }
    if (_feedHasMore[tab] == false && !refresh) return;

    final hasCache = (_feedData[tab] ?? []).isNotEmpty;
    if (!hasCache) {
      _feedLoading[tab] = true;
      notifyListeners();
    }

    try {
      final response = await _service.getFeed(
        tab: tab,
        page: _feedPage[tab]!,
      );
      final List<dynamic> items = response['data'] ?? [];
      final newJournals = items.map((j) => GratitudeModel.fromJson(j)).toList();

      _feedData[tab] = [...(_feedData[tab] ?? []), ...newJournals];
      _feedPage[tab] = (_feedPage[tab] ?? 1) + 1;

      final pagination = response['pagination'];
      final total = pagination?['total'] ?? 0;
      _feedHasMore[tab] = (_feedData[tab]?.length ?? 0) < (total as int);
    } catch (e) {
      _error = e.toString();
    } finally {
      _feedLoading[tab] = false;
      notifyListeners();
    }
  }

  // ════════════════════════════════════════════════════════════
  // 내 일기 목록
  // ════════════════════════════════════════════════════════════

  Future<void> loadMyJournals({bool refresh = false}) async {
    if (_isMyJournalsLoading) return;
    if (refresh) {
      _myJournals = [];
      _myJournalsPage = 1;
      _myJournalsHasMore = true;
    }
    if (!_myJournalsHasMore && !refresh) return;

    _isMyJournalsLoading = true;
    notifyListeners();

    try {
      final response = await _service.getMyJournals(page: _myJournalsPage);
      final List<dynamic> items = response['data'] ?? [];
      final newJournals = items.map((j) => GratitudeModel.fromJson(j)).toList();

      _myJournals = [..._myJournals, ...newJournals];
      _myJournalsPage++;

      final pagination = response['pagination'];
      final total = pagination?['total'] ?? 0;
      _myJournalsHasMore = _myJournals.length < (total as int);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isMyJournalsLoading = false;
      notifyListeners();
    }
  }

  // ════════════════════════════════════════════════════════════
  // 반응
  // ════════════════════════════════════════════════════════════

  Future<void> toggleReaction(String journalId, String reactionType, String tab) async {
    try {
      final response = await _service.toggleReaction(journalId, reactionType);
      final toggled = response['data']?['toggled'] ?? false;

      // 피드 내 해당 아이템 찾아서 낙관적 업데이트
      for (final feedTab in _feedData.keys) {
        final list = _feedData[feedTab];
        if (list == null) continue;
        final idx = list.indexWhere((j) => j.id == journalId);
        if (idx < 0) continue;

        final journal = list[idx];
        final newMyReactions = List<String>.from(journal.myReactions);
        final newCounts = Map<String, int>.from(journal.reactionCounts);

        if (toggled) {
          newMyReactions.add(reactionType);
          newCounts[reactionType] = (newCounts[reactionType] ?? 0) + 1;
        } else {
          newMyReactions.remove(reactionType);
          newCounts[reactionType] = ((newCounts[reactionType] ?? 1) - 1).clamp(0, 9999);
        }

        list[idx] = GratitudeModel.fromJson({
          'id': journal.id,
          'user_id': journal.userId,
          'gratitude_1': journal.gratitude1,
          'gratitude_2': journal.gratitude2,
          'gratitude_3': journal.gratitude3,
          'emotion': journal.emotion,
          'linked_prayer_id': journal.linkedPrayerId,
          'scope': journal.scope,
          'journal_date': journal.journalDate,
          'created_at': journal.createdAt,
          'updated_at': journal.updatedAt,
          'user': journal.user?.toJson(),
          'reaction_counts': newCounts,
          'comment_count': journal.commentCount,
          'my_reactions': newMyReactions,
        });
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ════════════════════════════════════════════════════════════
  // 스트릭 & 캘린더
  // ════════════════════════════════════════════════════════════

  Future<void> loadStreak() async {
    try {
      _streak = await _service.getStreak();
      notifyListeners();
    } catch (_) {
      // 실패 시 기본값 유지. 로그 생략
    }
  }

  Future<void> loadCalendar({int? year, int? month}) async {
    _isCalendarLoading = true;
    notifyListeners();
    try {
      _calendarData = await _service.getCalendar(year: year, month: month);
    } catch (e) {
      debugPrint('GratitudeProvider loadCalendar 실패: $e');
    }
    _isCalendarLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
  }
}
