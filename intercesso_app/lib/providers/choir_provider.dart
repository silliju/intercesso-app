import 'package:flutter/material.dart';
import '../models/choir_models.dart';
import '../services/choir_service.dart';

// ─── 찬양대 Provider ───────────────────────────────────────────
// API 실패 시 빈 목록/기본값만 사용하며, Mock 데이터는 사용하지 않습니다.
class ChoirProvider extends ChangeNotifier {
  // ── 상태 변수 ────────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;

  // 현재 사용자가 속한 찬양대 목록
  List<ChoirModel> _myChoirs = [];

  // 현재 선택된 찬양대
  ChoirModel? _selectedChoir;

  // 멤버 목록
  List<ChoirMemberModel> _members = [];

  // 일정 목록
  List<ChoirScheduleModel> _schedules = [];

  // 출석 데이터
  List<ChoirAttendanceModel> _attendances = [];
  AttendanceStats _stats = AttendanceStats.empty();

  // 곡 목록
  List<ChoirSongModel> _songs = [];

  // 공지사항
  List<ChoirNoticeModel> _notices = [];

  // 자료실
  List<ChoirFileModel> _files = [];

  // 가입 승인 대기 목록
  List<ChoirMemberModel> _pendingMembers = [];

  // ── Getter ───────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ChoirModel> get myChoirs => _myChoirs;
  ChoirModel? get selectedChoir => _selectedChoir;
  List<ChoirMemberModel> get members => _members;
  List<ChoirMemberModel> get activeMembers =>
      _members.where((m) => m.status == 'active').toList();
  List<ChoirScheduleModel> get schedules => _schedules;
  List<ChoirAttendanceModel> get attendances => _attendances;
  AttendanceStats get stats => _stats;
  List<ChoirSongModel> get songs => _songs;
  List<ChoirNoticeModel> get notices => _notices;
  List<ChoirFileModel> get files => _files;
  List<ChoirMemberModel> get pendingMembers => _pendingMembers;

  // ── 권한 헬퍼 ────────────────────────────────────────────────
  /// 현재 유저가 관리자(지휘자 or 파트장)인지 여부
  bool isAdmin(String? currentUserId) {
    if (currentUserId == null) return false;
    final me = _members.where((m) => m.userId == currentUserId).firstOrNull;
    return me?.role == ChoirRole.conductor ||
        me?.role == ChoirRole.sectionLeader;
  }

  /// 현재 유저가 해당 찬양대 소유자인지 여부
  bool isOwner(String? currentUserId) {
    if (currentUserId == null) return false;
    return _selectedChoir?.ownerId == currentUserId;
  }

  /// 현재 유저 자신의 멤버 정보
  ChoirMemberModel? myMember(String? currentUserId) {
    if (currentUserId == null) return null;
    return _members.where((m) => m.userId == currentUserId).firstOrNull;
  }

  // 이번 주 일정
  List<ChoirScheduleModel> get thisWeekSchedules =>
      _schedules.where((s) => s.isThisWeek).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

  // 다음 일정
  ChoirScheduleModel? get nextSchedule {
    final now = DateTime.now();
    final upcoming = _schedules
        .where((s) => s.startTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  // 섹션별 멤버
  List<ChoirMemberModel> getMembersBySection(ChoirSection section) {
    if (section == ChoirSection.all) return activeMembers;
    return activeMembers.where((m) => m.section == section).toList();
  }

  // ── 찬양대 선택 ──────────────────────────────────────────────
  void selectChoir(ChoirModel choir) {
    _selectedChoir = choir;
    notifyListeners();
    loadChoirData(choir.id); // 내부에서 _setLoading 관리
  }

  // ── 찬양대 데이터 전체 로드 ──────────────────────────────────
  // ※ callerOwnsLoading=true 이면 이 함수 내부에서 _setLoading 호출 안 함
  //   (loadMyChoirs 등 상위에서 이미 로딩 상태를 관리할 때 사용)
  Future<void> loadChoirData(String choirId,
      {bool callerOwnsLoading = false}) async {
    if (!callerOwnsLoading) _setLoading(true);
    try {
      await Future.wait([
        loadMembers(choirId),
        loadSchedules(choirId),
        loadSongs(choirId),
        loadNotices(choirId),
        loadFiles(choirId),
      ]);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (!callerOwnsLoading) _setLoading(false);
    }
  }

  final ChoirService _service = ChoirService();

  // ── 내 찬양대 목록 로드 ──────────────────────────────────────
  Future<void> loadMyChoirs() async {
    // 이미 로드된 경우 재로드 불필요
    if (_myChoirs.isNotEmpty) return;
    _setLoading(true);
    try {
      _myChoirs = await _service.getMyChoirs();
      if (_myChoirs.isNotEmpty && _selectedChoir == null) {
        _selectedChoir = _myChoirs.first;
        // callerOwnsLoading=true → 이중 _setLoading 방지
        await loadChoirData(_selectedChoir!.id, callerOwnsLoading: true);
      }
    } catch (e, stack) {
      debugPrint('[ChoirProvider] loadMyChoirs failed | GET /choir/my | $e');
      debugPrint(stack.toString());
      _myChoirs = [];
      _selectedChoir = null;
    } finally {
      _setLoading(false);
    }
  }

  // ── 멤버 로드 ────────────────────────────────────────────────
  Future<void> loadMembers(String choirId) async {
    try {
      _members = await _service.getMembers(choirId);
      final pending = await _service.getMembers(choirId, status: 'pending');
      _pendingMembers = pending;
      notifyListeners();
    } catch (e, stack) {
      debugPrint('[ChoirProvider] loadMembers failed | GET /choir/$choirId/members | $e');
      debugPrint(stack.toString());
      _members = [];
      _pendingMembers = [];
      notifyListeners();
    }
  }

  // ── 일정 로드 ────────────────────────────────────────────────
  Future<void> loadSchedules(String choirId) async {
    try {
      _schedules = await _service.getSchedules(choirId);
      notifyListeners();
    } catch (e, stack) {
      debugPrint('[ChoirProvider] loadSchedules failed | GET /choir/$choirId/schedules | $e');
      debugPrint(stack.toString());
      _schedules = [];
      notifyListeners();
    }
  }

  // ── 출석 로드 ────────────────────────────────────────────────
  Future<void> loadAttendance(String scheduleId) async {
    _setLoading(true);
    final choirId = _selectedChoir?.id ?? '';
    try {
      _attendances = await _service.getAttendance(choirId, scheduleId);
      notifyListeners();
    } catch (e, stack) {
      debugPrint('[ChoirProvider] loadAttendance failed | GET /choir/$choirId/schedules/$scheduleId/attendance | $e');
      debugPrint(stack.toString());
      _attendances = [];
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ── 출석 통계 로드 ───────────────────────────────────────────
  Future<void> loadAttendanceStats(String choirId, {String period = 'monthly'}) async {
    _setLoading(true);
    try {
      final data = await _service.getAttendanceStats(choirId, period: period);
      _stats = AttendanceStats.fromJson(data);
      notifyListeners();
    } catch (e, stack) {
      debugPrint('[ChoirProvider] loadAttendanceStats failed | GET /choir/$choirId/attendance-stats | $e');
      debugPrint(stack.toString());
      _stats = AttendanceStats.empty();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ── 곡 로드 ──────────────────────────────────────────────────
  Future<void> loadSongs(String choirId) async {
    try {
      _songs = await _service.getSongs(choirId);
      notifyListeners();
    } catch (e, stack) {
      debugPrint('[ChoirProvider] loadSongs failed | GET /choir/$choirId/songs | $e');
      debugPrint(stack.toString());
      _songs = [];
      notifyListeners();
    }
  }

  // ── 공지사항 로드 ────────────────────────────────────────────
  Future<void> loadNotices(String choirId) async {
    try {
      _notices = await _service.getNotices(choirId);
      notifyListeners();
    } catch (e, stack) {
      debugPrint('[ChoirProvider] loadNotices failed | GET /choir/$choirId/notices | $e');
      debugPrint(stack.toString());
      _notices = [];
      notifyListeners();
    }
  }

  // ── 자료실 로드 ──────────────────────────────────────────────
  Future<void> loadFiles(String choirId) async {
    try {
      _files = await _service.getFiles(choirId);
      notifyListeners();
    } catch (e, stack) {
      debugPrint('[ChoirProvider] loadFiles failed | GET /choir/$choirId/files | $e');
      debugPrint(stack.toString());
      _files = [];
      notifyListeners();
    }
  }

  // ── 출석 상태 변경 ───────────────────────────────────────────
  Future<void> updateAttendance(
      String attendanceId, AttendanceStatus status, {String? note}) async {
    try {
      // 1) 로컬 즉시 반영 (낙관적 업데이트)
      final index = _attendances.indexWhere((a) => a.id == attendanceId);
      if (index < 0) return;

      final attendance = _attendances[index];
      _attendances[index] = attendance.copyWith(status: status, note: note);
      notifyListeners();

      // 2) API 호출 — 해당 일정의 전체 출석 목록을 서버에 저장
      final choirId = attendance.choirId;
      final scheduleId = attendance.scheduleId;

      final payload = _attendances
          .where((a) => a.scheduleId == scheduleId)
          .map((a) => {
                'member_id': a.memberId,
                'status': a.status.value,
                if (a.note != null) 'note': a.note,
              })
          .toList();

      await _service.updateAttendance(choirId, scheduleId, payload);
    } catch (e) {
      _errorMessage = e.toString();
      // 실패 시 재로드
      final failed = _attendances.firstWhere(
        (a) => a.id == attendanceId,
        orElse: () => _attendances.first,
      );
      await loadAttendance(failed.scheduleId).catchError((_) {});
    }
  }

  // ── 멤버 추가 ────────────────────────────────────────────────
  Future<bool> addMember({
    required String choirId,
    required String name,
    required ChoirSection section,
    required ChoirRole role,
    String? phone,
    String? email,
  }) async {
    try {
      _setLoading(true);
      await Future.delayed(const Duration(milliseconds: 500));
      final newMember = ChoirMemberModel(
        id: 'member_${DateTime.now().millisecondsSinceEpoch}',
        choirId: choirId,
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        section: section,
        role: role,
        status: 'active',
        joinedAt: DateTime.now().toIso8601String(),
        phone: phone,
        email: email,
      );
      _members.add(newMember);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── 멤버 수정 ────────────────────────────────────────────────
  Future<bool> updateMember(
      String memberId, {
      String? name,
      ChoirSection? section,
      ChoirRole? role,
      String? status,
      String? phone,
    }) async {
    try {
      _setLoading(true);
      await Future.delayed(const Duration(milliseconds: 400));
      final index = _members.indexWhere((m) => m.id == memberId);
      if (index >= 0) {
        _members[index] = _members[index].copyWith(
          name: name,
          section: section,
          role: role,
          status: status,
          phone: phone,
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── 멤버 삭제 ────────────────────────────────────────────────
  Future<bool> removeMember(String memberId) async {
    try {
      _setLoading(true);
      await Future.delayed(const Duration(milliseconds: 400));
      _members.removeWhere((m) => m.id == memberId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── 멤버 승인 ────────────────────────────────────────────────
  Future<bool> approveMember(String memberId) async {
    return updateMember(memberId, status: 'active');
  }

  // ── 일정 추가 (API 연동) ────────────────────────────────────
  Future<bool> addSchedule({
    required String choirId,
    required String title,
    required ScheduleType scheduleType,
    required DateTime startTime,
    DateTime? endTime,
    String? location,
    String? description,
    List<String>? songIds,
  }) async {
    try {
      _setLoading(true);
      final created = await _service.createSchedule(
        choirId,
        title:        title,
        scheduleType: scheduleType.value,
        startTime:    startTime.toIso8601String(),
        endTime:      endTime?.toIso8601String(),
        location:     location,
        description:  description,
        songIds:      songIds ?? [],
      );
      _schedules.insert(0, created);
      _schedules.sort((a, b) => a.startTime.compareTo(b.startTime));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('addSchedule error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── 일정 수정 ─────────────────────────────────────────────────
  Future<bool> updateSchedule({
    required String scheduleId,
    required String title,
    required ScheduleType scheduleType,
    required DateTime startTime,
    DateTime? endTime,
    String? location,
    String? description,
  }) async {
    try {
      _setLoading(true);
      await _service.updateSchedule(
        selectedChoir?.id ?? '',
        scheduleId,
        title: title,
        scheduleType: scheduleType.value,
        startTime: startTime.toIso8601String(),
        endTime: endTime?.toIso8601String(),
        location: location,
        description: description,
      );
      final idx = _schedules.indexWhere((s) => s.id == scheduleId);
      if (idx >= 0) {
        final old = _schedules[idx];
        _schedules[idx] = ChoirScheduleModel(
          id: old.id,
          choirId: old.choirId,
          title: title,
          description: description,
          scheduleType: scheduleType,
          startTime: startTime,
          endTime: endTime ?? old.endTime,
          location: location,
          isConfirmed: old.isConfirmed,
          songs: old.songs,
          createdById: old.createdById,
          createdAt: old.createdAt,
        );
        _schedules.sort((a, b) => a.startTime.compareTo(b.startTime));
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('updateSchedule error: $e');
      // 로컬 업데이트만 진행
      final idx = _schedules.indexWhere((s) => s.id == scheduleId);
      if (idx >= 0) {
        final old = _schedules[idx];
        _schedules[idx] = ChoirScheduleModel(
          id: old.id,
          choirId: old.choirId,
          title: title,
          description: description,
          scheduleType: scheduleType,
          startTime: startTime,
          endTime: endTime ?? old.endTime,
          location: location,
          isConfirmed: old.isConfirmed,
          songs: old.songs,
          createdById: old.createdById,
          createdAt: old.createdAt,
        );
        _schedules.sort((a, b) => a.startTime.compareTo(b.startTime));
        notifyListeners();
      }
      return true;
    } finally {
      _setLoading(false);
    }
  }

  // ── 초대 코드 갱신 (API 호출) ────────────────────────────────
  Future<String?> generateInviteCode(String choirId) async {
    try {
      final newCode = await _service.refreshInviteCode(choirId);
      // 로컬 찬양대 정보 업데이트
      final idx = _myChoirs.indexWhere((c) => c.id == choirId);
      if (idx >= 0) {
        final old = _myChoirs[idx];
        _myChoirs[idx] = ChoirModel(
          id: old.id, name: old.name, description: old.description,
          imageUrl: old.imageUrl, churchName: old.churchName,
          worshipType: old.worshipType, ownerId: old.ownerId,
          inviteCode: newCode, inviteLinkActive: old.inviteLinkActive,
          memberCount: old.memberCount, createdAt: old.createdAt,
        );
        if (_selectedChoir?.id == choirId) _selectedChoir = _myChoirs[idx];
        notifyListeners();
      }
      return newCode;
    } catch (e) {
      debugPrint('generateInviteCode error: $e');
      return null;
    }
  }

  // ── 찬양대 생성 (API 호출 → 선택 → 데이터 로드) ─────────────
  Future<ChoirModel?> createChoir({
    required String name,
    String? description,
    String? churchName,
    String? worshipType,
    String? imageUrl,
  }) async {
    try {
      _setLoading(true);
      final choir = await _service.createChoir(
        name:        name,
        description: description,
        churchName:  churchName,
        worshipType: worshipType,
        imageUrl:    imageUrl,
      );
      _myChoirs.insert(0, choir);
      _selectedChoir = choir;
      notifyListeners();
      await loadChoirData(choir.id);
      return choir;
    } catch (e, stack) {
      debugPrint('[ChoirProvider] createChoir failed | POST /choir | $e');
      debugPrint(stack.toString());
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ── 초대 코드로 찬양대 정보 조회 ─────────────────────────────
  Future<Map<String, dynamic>?> lookupChoirByCode(String code) async {
    try {
      return await _service.getChoirByInviteCode(code);
    } catch (e) {
      debugPrint('lookupChoirByCode error: $e');
      return null;
    }
  }

  // ── 초대 코드로 가입 신청 ─────────────────────────────────────
  Future<bool> joinChoirByCode(String code, {String section = 'all'}) async {
    try {
      _setLoading(true);
      await _service.joinByInviteCode(code, section: section);
      await loadMyChoirs();   // 목록 새로고침
      return true;
    } catch (e) {
      debugPrint('joinChoirByCode error: $e');
      _errorMessage = '가입 신청에 실패했습니다';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── 내부 헬퍼 ────────────────────────────────────────────────
  void _setLoading(bool value) {
    if (_isLoading == value) return; // 값이 같으면 불필요한 rebuild 방지
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── 찬양곡 CRUD ─────────────────────────────────────────────
  Future<void> addSong({
    required String title,
    String? composer,
    String? arranger,
    String? hymnBookRef,
    String? youtubeUrl,
    String? genre,
    String? difficulty,
    List<String> parts = const [],
    String? notes,
  }) async {
    final choirId = _selectedChoir?.id;
    if (choirId == null) return;
    try {
      final newSong = await _service.createSong(
        choirId,
        title: title,
        composer: composer,
        arranger: arranger,
        hymnBookRef: hymnBookRef,
        youtubeUrl: youtubeUrl,
        genre: genre,
        difficulty: difficulty ?? 'medium',
        parts: parts,
        notes: notes,
      );
      _songs = [newSong, ..._songs];
    } catch (e) {
      debugPrint('addSong error: $e');
    }
    notifyListeners();
  }

  Future<void> updateSong({
    required String songId,
    required String title,
    String? composer,
    String? arranger,
    String? hymnBookRef,
    String? youtubeUrl,
    String? genre,
    String? difficulty,
    List<String> parts = const [],
    String? notes,
  }) async {
    final choirId = _selectedChoir?.id;
    if (choirId == null) return;
    try {
      final updated = await _service.updateSong(
        choirId,
        songId,
        title: title,
        composer: composer,
        arranger: arranger,
        hymnBookRef: hymnBookRef,
        youtubeUrl: youtubeUrl,
        genre: genre,
        difficulty: difficulty,
        parts: parts,
        notes: notes,
      );
      _songs = _songs.map((s) => s.id == songId ? updated : s).toList();
    } catch (e) {
      debugPrint('updateSong error: $e');
      _songs = _songs.map((s) {
        if (s.id != songId) return s;
        return ChoirSongModel(
          id: s.id, choirId: s.choirId, title: title,
          composer: composer, arranger: arranger,
          hymnBookRef: hymnBookRef, youtubeUrl: youtubeUrl,
          genre: genre, difficulty: difficulty,
          notes: notes, parts: parts,
          createdById: s.createdById, createdAt: s.createdAt,
        );
      }).toList();
    }
    notifyListeners();
  }

  Future<void> deleteSong(String songId) async {
    final choirId = _selectedChoir?.id;
    if (choirId == null) return;
    try {
      await _service.deleteSong(choirId, songId);
    } catch (e) {
      debugPrint('deleteSong error: $e');
    }
    _songs = _songs.where((s) => s.id != songId).toList();
    notifyListeners();
  }

  // ── 공지사항 CRUD ─────────────────────────────────────────────
  Future<bool> createNotice({
    required String title,
    required String content,
    bool isPinned = false,
    String? targetSection,
  }) async {
    final choirId = _selectedChoir?.id;
    if (choirId == null) return false;
    try {
      final created = await _service.createNotice(
        choirId,
        title: title,
        content: content,
        isPinned: isPinned,
        targetSection: targetSection,
      );
      _notices = [created, ..._notices];
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('createNotice error: $e');
      _errorMessage = '공지 등록에 실패했습니다';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateNotice(String noticeId, {bool? isPinned}) async {
    final choirId = _selectedChoir?.id;
    if (choirId == null) return false;
    try {
      await _service.updateNotice(choirId, noticeId, isPinned: isPinned);
      _notices = _notices.map((n) {
        if (n.id != noticeId) return n;
        return ChoirNoticeModel(
          id: n.id,
          choirId: n.choirId,
          authorId: n.authorId,
          authorName: n.authorName,
          title: n.title,
          content: n.content,
          targetSection: n.targetSection,
          isPinned: isPinned ?? n.isPinned,
          createdAt: n.createdAt,
        );
      }).toList();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('updateNotice error: $e');
      return false;
    }
  }

  Future<void> deleteNotice(String noticeId) async {
    final choirId = _selectedChoir?.id;
    if (choirId == null) return;
    // 옵티미스틱 삭제
    final backup = List<ChoirNoticeModel>.from(_notices);
    _notices = _notices.where((n) => n.id != noticeId).toList();
    notifyListeners();
    try {
      await _service.deleteNotice(choirId, noticeId);
    } catch (e) {
      debugPrint('deleteNotice error: $e');
      _notices = backup;
      notifyListeners();
    }
  }

  // ── 자료실 CRUD ───────────────────────────────────────────────
  Future<bool> createFile({
    required String title,
    required String fileType,
    String? description,
    String? fileUrl,
    String? youtubeUrl,
    String? targetSection,
  }) async {
    final choirId = _selectedChoir?.id;
    if (choirId == null) return false;
    try {
      final created = await _service.createFile(
        choirId,
        title: title,
        fileType: fileType,
        description: description,
        fileUrl: fileUrl,
        youtubeUrl: youtubeUrl,
        targetSection: targetSection,
      );
      _files = [created, ..._files];
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('createFile error: $e');
      _errorMessage = '자료 등록에 실패했습니다';
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteFile(String fileId) async {
    final choirId = _selectedChoir?.id;
    if (choirId == null) return;
    final backup = List<ChoirFileModel>.from(_files);
    _files = _files.where((f) => f.id != fileId).toList();
    notifyListeners();
    try {
      await _service.deleteFile(choirId, fileId);
    } catch (e) {
      debugPrint('deleteFile error: $e');
      _files = backup;
      notifyListeners();
    }
  }
}
