import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/prayer_service.dart';

class PrayerProvider extends ChangeNotifier {
  final PrayerService _prayerService = PrayerService();

  List<PrayerModel> _prayers = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  String? _scopeFilter;
  String? _categoryFilter;
  String? _statusFilter;

  List<PrayerModel> get prayers => _prayers;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> loadPrayers({
    bool refresh = false,
    String? scope,
    String? category,
    String? status,
  }) async {
    if (refresh) {
      _prayers = [];
      _currentPage = 1;
      _hasMore = true;
      _scopeFilter = scope;
      _categoryFilter = category;
      _statusFilter = status;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _prayerService.getPrayers(
        page: _currentPage,
        scope: _scopeFilter,
        category: _categoryFilter,
        status: _statusFilter,
      );

      final List<dynamic> data = response['data'] ?? [];
      final pagination = response['pagination'];

      final newPrayers = data.map((p) => PrayerModel.fromJson(p)).toList();
      _prayers.addAll(newPrayers);
      _currentPage++;

      if (pagination != null) {
        _hasMore = _currentPage <= (pagination['totalPages'] ?? 1);
      } else {
        _hasMore = newPrayers.isNotEmpty;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
      _prayers.insert(0, prayer);
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
      final idx = _prayers.indexWhere((p) => p.id == prayerId);
      if (idx != -1) {
        _prayers[idx] = updated;
        notifyListeners();
      }
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
      _prayers.removeWhere((p) => p.id == prayerId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
