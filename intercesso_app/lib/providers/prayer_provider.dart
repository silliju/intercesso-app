import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/prayer_service.dart';

/// 탭별 독립적인 페이지네이션 상태를 관리하는 클래스
class _TabState {
  List<PrayerModel> prayers = [];
  bool isLoading = false;
  bool hasMore = true;
  int currentPage = 1;
  String? error;

  void reset() {
    prayers = [];
    isLoading = false;
    hasMore = true;
    currentPage = 1;
    error = null;
  }
}

class PrayerProvider extends ChangeNotifier {
  final PrayerService _prayerService = PrayerService();

  // ── 탭별 독립 상태 (scope key → _TabState) ──────────────────
  // key: null='public', 'mine', 'friends', 'praying'
  final Map<String?, _TabState> _tabStates = {
    null: _TabState(),
    'mine': _TabState(),
    'friends': _TabState(),
    'praying': _TabState(),
  };

  // ── 홈 전용 최근 기도 목록 (탭과 독립) ─────────────────────
  List<PrayerModel> _homePrayers = [];
  bool _isHomeLoading = false;

  // ── 현재 활성 탭 scope (PrayersScreen에서 관리) ─────────────
  String? _activeScope;

  // ── 공통 에러 ───────────────────────────────────────────────
  String? _error;

  // ── Getters ─────────────────────────────────────────────────
  List<PrayerModel> get prayers => _tabStates[_activeScope]?.prayers ?? [];
  bool get isLoading => _tabStates[_activeScope]?.isLoading ?? false;
  bool get hasMore => _tabStates[_activeScope]?.hasMore ?? true;
  String? get error => _error;

  List<PrayerModel> get homePrayers => _homePrayers;
  /// 홈 피드용: 홈 전용 리스트가 비어 있으면 '전체 공개' 탭 데이터 사용 (기도 목록과 동일 소스)
  List<PrayerModel> get homePrayersForDisplay {
    if (_homePrayers.isNotEmpty) return _homePrayers;
    return _tabStates[null]?.prayers ?? [];
  }
  bool get isHomeLoading => _isHomeLoading;

  // 하위 호환성 유지
  List<PrayerModel> get myPrayers =>
      _tabStates['mine']?.prayers ?? [];
  bool get isMyLoading =>
      _tabStates['mine']?.isLoading ?? false;

  // ─────────────────────────────────────────────────────────────
  // 탭 활성화 (PrayersScreen에서 탭 전환 시 호출)
  // ─────────────────────────────────────────────────────────────
  void setActiveScope(String? scope) {
    // 지원하지 않는 scope는 null(public)로 처리
    final validScope = _tabStates.containsKey(scope) ? scope : null;
    if (_activeScope != validScope) {
      _activeScope = validScope;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 특정 탭의 기도 목록 로드 (탭별 독립 페이지네이션)
  // ─────────────────────────────────────────────────────────────
  Future<void> loadPrayers({
    bool refresh = false,
    String? scope,
    String? category,
    String? status,
  }) async {
    // scope에 해당하는 _TabState 가져오기
    final key = _tabStates.containsKey(scope) ? scope : null;
    final tabState = _tabStates[key]!;

    if (refresh) {
      tabState.reset();
    }

    if (!tabState.hasMore || tabState.isLoading) return;

    tabState.isLoading = true;
    tabState.error = null;
    notifyListeners();

    try {
      final response = await _prayerService.getPrayers(
        page: tabState.currentPage,
        scope: scope,
        category: category,
        status: status,
      );

      final List<dynamic> data = response['data'] ?? [];
      final pagination = response['pagination'];

      final newPrayers = data.map((p) => PrayerModel.fromJson(p)).toList();
      tabState.prayers.addAll(newPrayers);
      tabState.currentPage++;

      if (pagination != null) {
        tabState.hasMore = tabState.currentPage <= (pagination['totalPages'] ?? 1);
      } else {
        tabState.hasMore = newPrayers.length >= 10;
      }
    } catch (e) {
      tabState.error = e.toString();
      _error = e.toString();
    } finally {
      tabState.isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 홈 전용 공개 기도 로드 (최대 5개). 캐시 있으면 즉시 표시 후 백그라운드 갱신.
  // ─────────────────────────────────────────────────────────────
  Future<void> loadHomePrayers() async {
    if (_isHomeLoading) return;
    final hasCache = _homePrayers.isNotEmpty;
    if (!hasCache) {
      _isHomeLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final response = await _prayerService.getPrayers(
        page: 1,
        limit: 5,
        scope: null,
      ).timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw TimeoutException('홈 기도 목록 로드 지연'),
      );
      final List<dynamic> data = response['data'] ?? [];
      _homePrayers = data.map((p) => PrayerModel.fromJson(p)).toList();

      if (_homePrayers.isEmpty) {
        final myResponse = await _prayerService.getPrayers(
          page: 1,
          limit: 5,
          scope: 'mine',
        ).timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw TimeoutException('내 기도 목록 로드 지연'),
        );
        final List<dynamic> myData = myResponse['data'] ?? [];
        _homePrayers = myData.map((p) => PrayerModel.fromJson(p)).toList();
      }
    } catch (e) {
      _error = e.toString();
      if (!hasCache) _homePrayers = [];
    } finally {
      _isHomeLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 하위 호환성: loadMyPrayers (내 기도 탭 직접 로드)
  // ─────────────────────────────────────────────────────────────
  Future<void> loadMyPrayers() async {
    await loadPrayers(refresh: true, scope: 'mine');
  }

  // ─────────────────────────────────────────────────────────────
  // CRUD
  // ─────────────────────────────────────────────────────────────
  Future<PrayerModel?> createPrayer({
    required String title,
    required String content,
    String? category,
    String scope = 'public',
    String? groupId,
    bool isCovenant = false,
    int? covenantDays,
  }) async {
    try {
      final prayer = await _prayerService.createPrayer(
        title: title,
        content: content,
        category: category,
        scope: scope,
        groupId: groupId,
        isCovenant: isCovenant,
        covenantDays: covenantDays,
      );
      // 관련 탭 목록 앞에 삽입 (UI 즉시 반영)
      _tabStates[null]?.prayers.insert(0, prayer); // public
      _tabStates['mine']?.prayers.insert(0, prayer); // mine
      // scope에 맞는 탭도 추가
      if (scope != 'public' && scope != 'mine') {
        _tabStates[scope]?.prayers.insert(0, prayer);
      }
      _homePrayers.insert(0, prayer);
      notifyListeners();
      return prayer;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updatePrayerStatus(String prayerId, String status) async {
    try {
      final updated = await _prayerService.updatePrayer(prayerId, status: status);
      _updateInAllLists(prayerId, updated);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePrayer(String prayerId) async {
    try {
      await _prayerService.deletePrayer(prayerId);
      _removeFromAllLists(prayerId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 헬퍼: 전체 탭 + 홈 목록에서 ID로 업데이트 / 제거
  // ─────────────────────────────────────────────────────────────
  void _updateInAllLists(String prayerId, PrayerModel updated) {
    for (final tabState in _tabStates.values) {
      final idx = tabState.prayers.indexWhere((p) => p.id == prayerId);
      if (idx != -1) tabState.prayers[idx] = updated;
    }
    final homeIdx = _homePrayers.indexWhere((p) => p.id == prayerId);
    if (homeIdx != -1) _homePrayers[homeIdx] = updated;
  }

  void _removeFromAllLists(String prayerId) {
    for (final tabState in _tabStates.values) {
      tabState.prayers.removeWhere((p) => p.id == prayerId);
    }
    _homePrayers.removeWhere((p) => p.id == prayerId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
