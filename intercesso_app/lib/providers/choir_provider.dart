import 'package:flutter/material.dart';
import '../models/choir_models.dart';
import '../services/choir_service.dart';

// ─── 찬양대 Provider ───────────────────────────────────────────
// 현재는 Mock 데이터로 동작하며, API 연동 시 실제 서비스 호출로 교체합니다.
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
    } catch (e) {
      // API 실패 시 mock 데이터로 즉시 반환 (추가 딜레이 없음)
      debugPrint('loadMyChoirs API error: $e');
      _myChoirs = _mockChoirs();
      if (_myChoirs.isNotEmpty && _selectedChoir == null) {
        _selectedChoir = _myChoirs.first;
        // mock 데이터도 동일하게 병렬 로드
        await loadChoirData(_selectedChoir!.id, callerOwnsLoading: true);
      }
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
    } catch (e) {
      debugPrint('loadMembers error: $e');
      _members = _mockMembers(choirId);
      _pendingMembers = _members.where((m) => m.isPending).toList();
      notifyListeners();
    }
  }

  // ── 일정 로드 ────────────────────────────────────────────────
  Future<void> loadSchedules(String choirId) async {
    try {
      _schedules = await _service.getSchedules(choirId);
      notifyListeners();
    } catch (e) {
      debugPrint('loadSchedules error: $e');
      _schedules = _mockSchedules(choirId);
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
    } catch (e) {
      debugPrint('loadAttendance error: $e');
      _attendances = _mockAttendances(scheduleId);
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
    } catch (e) {
      debugPrint('loadAttendanceStats error: $e');
      _stats = _mockStats();
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
    } catch (e) {
      debugPrint('loadSongs error: $e');
      _songs = _mockSongs(choirId);
      notifyListeners();
    }
  }

  // ── 공지사항 로드 ────────────────────────────────────────────
  Future<void> loadNotices(String choirId) async {
    try {
      _notices = await _service.getNotices(choirId);
      notifyListeners();
    } catch (e) {
      debugPrint('loadNotices error: $e');
      _notices = _mockNotices(choirId);
      notifyListeners();
    }
  }

  // ── 자료실 로드 ──────────────────────────────────────────────
  Future<void> loadFiles(String choirId) async {
    try {
      _files = await _service.getFiles(choirId);
      notifyListeners();
    } catch (e) {
      debugPrint('loadFiles error: $e');
      _files = _mockFiles(choirId);
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
      // API 실패 시 로컬 mock으로 폴백
      final fallback = ChoirScheduleModel(
        id: 'schedule_${DateTime.now().millisecondsSinceEpoch}',
        choirId: choirId,
        title: title,
        description: description,
        scheduleType: scheduleType,
        startTime: startTime,
        endTime: endTime,
        location: location,
        isConfirmed: false,
        createdById: 'current_user',
        createdAt: DateTime.now().toIso8601String(),
      );
      _schedules.insert(0, fallback);
      notifyListeners();
      return false;
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
    } catch (e) {
      debugPrint('createChoir error: $e');
      _errorMessage = '찬양대 생성에 실패했습니다';
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

  // ── Mock 데이터 ──────────────────────────────────────────────
  List<ChoirModel> _mockChoirs() => [
        ChoirModel(
          id: 'choir_1',
          name: '주일예배 찬양대',
          description: '매주 주일 예배 찬양을 섬기는 찬양대입니다',
          churchName: '사랑교회',
          worshipType: '주일예배',
          ownerId: 'user_1',
          inviteCode: 'PRAISE01',
          inviteLinkActive: true,
          memberCount: 24,
          createdAt: '2024-01-01',
        ),
        ChoirModel(
          id: 'choir_2',
          name: '수요 찬양대',
          description: '수요예배를 섬기는 찬양대입니다',
          churchName: '사랑교회',
          worshipType: '수요예배',
          ownerId: 'user_1',
          inviteCode: 'MIDWEEK1',
          inviteLinkActive: true,
          memberCount: 16,
          createdAt: '2024-02-01',
        ),
      ];

  List<ChoirMemberModel> _mockMembers(String choirId) => [
        ChoirMemberModel(id: 'm1', choirId: choirId, userId: 'u1', name: '김지휘', section: ChoirSection.all, role: ChoirRole.conductor, status: 'active', joinedAt: '2024-01-01', phone: '010-1234-5678'),
        ChoirMemberModel(id: 'm2', choirId: choirId, userId: 'u2', name: '이소영', section: ChoirSection.soprano, role: ChoirRole.sectionLeader, status: 'active', joinedAt: '2024-01-05', phone: '010-2345-6789'),
        ChoirMemberModel(id: 'm3', choirId: choirId, userId: 'u3', name: '박민지', section: ChoirSection.soprano, role: ChoirRole.member, status: 'active', joinedAt: '2024-01-10'),
        ChoirMemberModel(id: 'm4', choirId: choirId, userId: 'u4', name: '최수진', section: ChoirSection.soprano, role: ChoirRole.member, status: 'active', joinedAt: '2024-01-15'),
        ChoirMemberModel(id: 'm5', choirId: choirId, userId: 'u5', name: '정알토', section: ChoirSection.alto, role: ChoirRole.sectionLeader, status: 'active', joinedAt: '2024-01-05'),
        ChoirMemberModel(id: 'm6', choirId: choirId, userId: 'u6', name: '강현주', section: ChoirSection.alto, role: ChoirRole.member, status: 'active', joinedAt: '2024-01-20'),
        ChoirMemberModel(id: 'm7', choirId: choirId, userId: 'u7', name: '한테너', section: ChoirSection.tenor, role: ChoirRole.sectionLeader, status: 'active', joinedAt: '2024-01-05'),
        ChoirMemberModel(id: 'm8', choirId: choirId, userId: 'u8', name: '임성민', section: ChoirSection.tenor, role: ChoirRole.member, status: 'active', joinedAt: '2024-02-01'),
        ChoirMemberModel(id: 'm9', choirId: choirId, userId: 'u9', name: '조베이스', section: ChoirSection.bass, role: ChoirRole.sectionLeader, status: 'active', joinedAt: '2024-01-05'),
        ChoirMemberModel(id: 'm10', choirId: choirId, userId: 'u10', name: '윤대한', section: ChoirSection.bass, role: ChoirRole.member, status: 'active', joinedAt: '2024-02-15'),
        ChoirMemberModel(id: 'm11', choirId: choirId, userId: 'u11', name: '신청자1', section: ChoirSection.soprano, role: ChoirRole.member, status: 'pending', joinedAt: null),
      ];

  List<ChoirScheduleModel> _mockSchedules(String choirId) {
    final now = DateTime.now();
    return [
      ChoirScheduleModel(
        id: 's1', choirId: choirId, title: '주일예배 찬양',
        description: '3월 주일예배 찬양 - 주님의 은혜',
        scheduleType: ScheduleType.service,
        startTime: now.add(const Duration(days: 3)),
        endTime: now.add(const Duration(days: 3, hours: 2)),
        location: '본당', isConfirmed: true,
        songs: [], createdById: 'u1', createdAt: now.subtract(const Duration(days: 7)).toIso8601String(),
      ),
      ChoirScheduleModel(
        id: 's2', choirId: choirId, title: '토요 연습',
        description: '주일 예배 전 마지막 연습',
        scheduleType: ScheduleType.rehearsal,
        startTime: now.add(const Duration(days: 1)),
        endTime: now.add(const Duration(days: 1, hours: 2)),
        location: '찬양실', isConfirmed: true,
        songs: [], createdById: 'u1', createdAt: now.subtract(const Duration(days: 5)).toIso8601String(),
      ),
      ChoirScheduleModel(
        id: 's3', choirId: choirId, title: '다음 주일예배',
        description: '3월 17일 주일예배',
        scheduleType: ScheduleType.service,
        startTime: now.add(const Duration(days: 10)),
        endTime: now.add(const Duration(days: 10, hours: 2)),
        location: '본당', isConfirmed: false,
        songs: [], createdById: 'u1', createdAt: now.subtract(const Duration(days: 2)).toIso8601String(),
      ),
      ChoirScheduleModel(
        id: 's4', choirId: choirId, title: '평일 파트 연습',
        description: '소프라노/알토 파트 연습',
        scheduleType: ScheduleType.weekday,
        startTime: now.add(const Duration(days: 5)),
        endTime: now.add(const Duration(days: 5, hours: 1, minutes: 30)),
        location: '찬양실', isConfirmed: true,
        songs: [], createdById: 'u2', createdAt: now.subtract(const Duration(days: 3)).toIso8601String(),
      ),
    ];
  }

  List<ChoirAttendanceModel> _mockAttendances(String scheduleId) => [
        ChoirAttendanceModel(id: 'a1', scheduleId: scheduleId, choirId: 'choir_1', memberId: 'm1', userId: 'u1', memberName: '김지휘', section: ChoirSection.all, role: ChoirRole.conductor, status: AttendanceStatus.present),
        ChoirAttendanceModel(id: 'a2', scheduleId: scheduleId, choirId: 'choir_1', memberId: 'm2', userId: 'u2', memberName: '이소영', section: ChoirSection.soprano, role: ChoirRole.sectionLeader, status: AttendanceStatus.present),
        ChoirAttendanceModel(id: 'a3', scheduleId: scheduleId, choirId: 'choir_1', memberId: 'm3', userId: 'u3', memberName: '박민지', section: ChoirSection.soprano, role: ChoirRole.member, status: AttendanceStatus.absent),
        ChoirAttendanceModel(id: 'a4', scheduleId: scheduleId, choirId: 'choir_1', memberId: 'm4', userId: 'u4', memberName: '최수진', section: ChoirSection.soprano, role: ChoirRole.member, status: AttendanceStatus.excused, note: '결혼식 참석'),
        ChoirAttendanceModel(id: 'a5', scheduleId: scheduleId, choirId: 'choir_1', memberId: 'm5', userId: 'u5', memberName: '정알토', section: ChoirSection.alto, role: ChoirRole.sectionLeader, status: AttendanceStatus.present),
        ChoirAttendanceModel(id: 'a6', scheduleId: scheduleId, choirId: 'choir_1', memberId: 'm6', userId: 'u6', memberName: '강현주', section: ChoirSection.alto, role: ChoirRole.member, status: AttendanceStatus.present),
        ChoirAttendanceModel(id: 'a7', scheduleId: scheduleId, choirId: 'choir_1', memberId: 'm7', userId: 'u7', memberName: '한테너', section: ChoirSection.tenor, role: ChoirRole.sectionLeader, status: AttendanceStatus.present),
        ChoirAttendanceModel(id: 'a8', scheduleId: scheduleId, choirId: 'choir_1', memberId: 'm8', userId: 'u8', memberName: '임성민', section: ChoirSection.tenor, role: ChoirRole.member, status: AttendanceStatus.absent),
        ChoirAttendanceModel(id: 'a9', scheduleId: scheduleId, choirId: 'choir_1', memberId: 'm9', userId: 'u9', memberName: '조베이스', section: ChoirSection.bass, role: ChoirRole.sectionLeader, status: AttendanceStatus.present),
        ChoirAttendanceModel(id: 'a10', scheduleId: scheduleId, choirId: 'choir_1', memberId: 'm10', userId: 'u10', memberName: '윤대한', section: ChoirSection.bass, role: ChoirRole.member, status: AttendanceStatus.present),
      ];

  AttendanceStats _mockStats() => AttendanceStats(
        totalSchedules: 8,
        presentCount: 6,
        absentCount: 1,
        excusedCount: 1,
        attendanceRate: 87.5,
        sectionRates: {
          'soprano': 90.0,
          'alto': 95.0,
          'tenor': 80.0,
          'bass': 85.0,
        },
      );

  List<ChoirSongModel> _mockSongs(String choirId) => [
        ChoirSongModel(id: 'song1', choirId: choirId, title: '주님의 은혜', composer: '김성경', youtubeUrl: 'https://youtu.be/example1', genre: '현대 찬양', difficulty: 'medium', parts: ['soprano', 'alto', 'tenor', 'bass'], createdById: 'u1', createdAt: '2024-01-15'),
        ChoirSongModel(id: 'song2', choirId: choirId, title: '주를 찬양', composer: '이찬양', hymnBookRef: '찬송가 19장', youtubeUrl: 'https://youtu.be/example2', genre: '찬송가', difficulty: 'easy', parts: ['soprano', 'alto', 'tenor', 'bass'], createdById: 'u1', createdAt: '2024-01-20'),
        ChoirSongModel(id: 'song3', choirId: choirId, title: '할렐루야', composer: '헨델', arranger: '박편곡', genre: '클래식', difficulty: 'hard', parts: ['soprano', 'alto', 'tenor', 'bass'], createdById: 'u1', createdAt: '2024-02-01'),
        ChoirSongModel(id: 'song4', choirId: choirId, title: '은혜로다', composer: '정은혜', youtubeUrl: 'https://youtu.be/example4', genre: '현대 찬양', difficulty: 'easy', parts: ['soprano', 'alto'], createdById: 'u2', createdAt: '2024-02-10'),
      ];

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
      // API 실패 시 로컬에서 mock 추가
      final mockSong = ChoirSongModel(
        id: 'song_${DateTime.now().millisecondsSinceEpoch}',
        choirId: choirId,
        title: title,
        composer: composer,
        arranger: arranger,
        hymnBookRef: hymnBookRef,
        youtubeUrl: youtubeUrl,
        genre: genre,
        difficulty: difficulty,
        notes: notes,
        parts: parts,
        createdById: 'currentUser',
        createdAt: DateTime.now().toIso8601String(),
      );
      _songs = [mockSong, ..._songs];
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

  List<ChoirNoticeModel> _mockNotices(String choirId) => [
        ChoirNoticeModel(id: 'n1', choirId: choirId, authorId: 'u1', authorName: '김지휘', title: '이번 주 연습 공지', content: '토요일 오후 7시 찬양실에서 연습합니다. 악보 꼭 준비해 오세요!', isPinned: true, createdAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String()),
        ChoirNoticeModel(id: 'n2', choirId: choirId, authorId: 'u1', authorName: '김지휘', title: '주일예배 찬양곡 안내', content: '3월 10일 주일예배 찬양곡: 주님의 은혜, 주를 찬양', isPinned: false, createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String()),
        ChoirNoticeModel(id: 'n3', choirId: choirId, authorId: 'u2', authorName: '이소영', title: '소프라노 파트 추가 연습', content: '목요일 저녁 파트 연습 있습니다. 소프라노만 참석', targetSection: 'soprano', isPinned: false, createdAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String()),
      ];

  List<ChoirFileModel> _mockFiles(String choirId) => [
        ChoirFileModel(id: 'f1', choirId: choirId, title: '주님의 은혜 - 악보', fileType: 'score', fileUrl: 'https://example.com/score1.pdf', uploadedById: 'u1', uploaderName: '김지휘', createdAt: DateTime.now().subtract(const Duration(days: 3)).toIso8601String()),
        ChoirFileModel(id: 'f2', choirId: choirId, title: '주를 찬양 - 연습 영상', fileType: 'video', youtubeUrl: 'https://youtu.be/practice1', uploadedById: 'u1', uploaderName: '김지휘', createdAt: DateTime.now().subtract(const Duration(days: 5)).toIso8601String()),
        ChoirFileModel(id: 'f3', choirId: choirId, title: '할렐루야 - 악보', description: '소프라노 파트', fileType: 'score', fileUrl: 'https://example.com/score3.pdf', targetSection: 'soprano', uploadedById: 'u2', uploaderName: '이소영', createdAt: DateTime.now().subtract(const Duration(days: 7)).toIso8601String()),
        ChoirFileModel(id: 'f4', choirId: choirId, title: '3월 찬양 일정', fileType: 'document', fileUrl: 'https://example.com/schedule.pdf', uploadedById: 'u1', uploaderName: '김지휘', createdAt: DateTime.now().subtract(const Duration(days: 10)).toIso8601String()),
      ];
}
