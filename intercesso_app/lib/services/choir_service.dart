import '../models/choir_models.dart';
import 'api_service.dart';

// ═══════════════════════════════════════════════════════════════
// 찬양대 API 서비스
// ═══════════════════════════════════════════════════════════════
class ChoirService {
  final ApiService _api = ApiService();

  // ── 찬양대 CRUD ─────────────────────────────────────────────

  Future<List<ChoirModel>> getMyChoirs() async {
    final res = await _api.get('/choir/my');
    final list = res['data'] as List? ?? [];
    return list.map((j) => ChoirModel.fromJson(j)).toList();
  }

  Future<ChoirModel> getChoirById(String choirId) async {
    final res = await _api.get('/choir/$choirId');
    return ChoirModel.fromJson(res['data']);
  }

  Future<ChoirModel> createChoir({
    required String name,
    String? description,
    String? churchName,
    String? worshipType,
    String? imageUrl,
  }) async {
    final res = await _api.post('/choir', body: {
      'name': name,
      if (description != null) 'description': description,
      if (churchName != null) 'church_name': churchName,
      if (worshipType != null) 'worship_type': worshipType,
      if (imageUrl != null) 'image_url': imageUrl,
    });
    return ChoirModel.fromJson(res['data']);
  }

  Future<ChoirModel> updateChoir(
    String choirId, {
    String? name,
    String? description,
    String? churchName,
    String? worshipType,
    String? imageUrl,
  }) async {
    final res = await _api.put('/choir/$choirId', body: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (churchName != null) 'church_name': churchName,
      if (worshipType != null) 'worship_type': worshipType,
      if (imageUrl != null) 'image_url': imageUrl,
    });
    return ChoirModel.fromJson(res['data']);
  }

  Future<void> deleteChoir(String choirId) async {
    await _api.delete('/choir/$choirId');
  }

  // ── 초대 코드 ──────────────────────────────────────────────

  Future<Map<String, dynamic>> getInviteCode(String choirId) async {
    final res = await _api.get('/choir/$choirId/invite');
    return res['data'] as Map<String, dynamic>;
  }

  Future<String> refreshInviteCode(String choirId) async {
    final res = await _api.post('/choir/$choirId/invite/refresh', body: {});
    return res['data']['invite_code'] as String;
  }

  Future<Map<String, dynamic>> getChoirByInviteCode(String code) async {
    final res = await _api.get('/choir/join-by-code',
        queryParams: {'code': code});
    return res['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinByInviteCode(
      String code, {String section = 'all'}) async {
    final res = await _api.post('/choir/join-by-code', body: {
      'code': code,
      'section': section,
    });
    return res['data'] as Map<String, dynamic>;
  }

  // ── 멤버 관리 ──────────────────────────────────────────────

  Future<List<ChoirMemberModel>> getMembers(String choirId,
      {String status = 'active'}) async {
    final res = await _api.get('/choir/$choirId/members',
        queryParams: {'status': status});
    final list = res['data'] as List? ?? [];
    return list.map((j) => ChoirMemberModel.fromJson(j)).toList();
  }

  Future<void> updateMember(
    String choirId,
    String memberId, {
    String? role,
    String? section,
  }) async {
    await _api.put('/choir/$choirId/members/$memberId', body: {
      if (role != null) 'role': role,
      if (section != null) 'section': section,
    });
  }

  Future<void> removeMember(String choirId, String memberId) async {
    await _api.delete('/choir/$choirId/members/$memberId');
  }

  Future<void> approveMember(String choirId, String memberId) async {
    await _api.post('/choir/$choirId/members/$memberId/approve', body: {});
  }

  // ── 일정 CRUD ─────────────────────────────────────────────

  Future<List<ChoirScheduleModel>> getSchedules(
    String choirId, {
    String? from,
    String? to,
    String? type,
  }) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    if (type != null) params['type'] = type;

    final res = await _api.get('/choir/$choirId/schedules',
        queryParams: params.isNotEmpty ? params : null);
    final list = res['data'] as List? ?? [];
    return list.map((j) => ChoirScheduleModel.fromJson(j)).toList();
  }

  Future<ChoirScheduleModel> createSchedule(
    String choirId, {
    required String title,
    required String scheduleType,
    required String startTime,
    String? endTime,
    String? location,
    String? description,
    List<String> songIds = const [],
  }) async {
    final res = await _api.post('/choir/$choirId/schedules', body: {
      'title': title,
      'schedule_type': scheduleType,
      'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (location != null) 'location': location,
      if (description != null) 'description': description,
      if (songIds.isNotEmpty) 'song_ids': songIds,
    });
    return ChoirScheduleModel.fromJson(res['data']);
  }

  Future<ChoirScheduleModel> getScheduleById(
      String choirId, String scheduleId) async {
    final res =
        await _api.get('/choir/$choirId/schedules/$scheduleId');
    return ChoirScheduleModel.fromJson(res['data']);
  }

  Future<ChoirScheduleModel> updateSchedule(
    String choirId,
    String scheduleId, {
    String? title,
    String? scheduleType,
    String? startTime,
    String? endTime,
    String? location,
    String? description,
  }) async {
    final res = await _api.put(
        '/choir/$choirId/schedules/$scheduleId',
        body: {
          if (title != null) 'title': title,
          if (scheduleType != null) 'schedule_type': scheduleType,
          if (startTime != null) 'start_time': startTime,
          if (endTime != null) 'end_time': endTime,
          if (location != null) 'location': location,
          if (description != null) 'description': description,
        });
    return ChoirScheduleModel.fromJson(res['data']);
  }

  Future<void> deleteSchedule(String choirId, String scheduleId) async {
    await _api.delete('/choir/$choirId/schedules/$scheduleId');
  }

  // ── 출석 관리 ─────────────────────────────────────────────

  Future<List<ChoirAttendanceModel>> getAttendance(
      String choirId, String scheduleId) async {
    final res = await _api
        .get('/choir/$choirId/schedules/$scheduleId/attendance');
    final list = res['data'] as List? ?? [];
    return list.map((j) => ChoirAttendanceModel.fromJson(j)).toList();
  }

  Future<void> updateAttendance(
    String choirId,
    String scheduleId,
    List<Map<String, dynamic>> attendances,
  ) async {
    await _api.put(
      '/choir/$choirId/schedules/$scheduleId/attendance',
      body: {'attendances': attendances},
    );
  }

  Future<Map<String, dynamic>> getAttendanceStats(
    String choirId, {
    String period = 'monthly',
    int? year,
    int? month,
  }) async {
    final params = <String, String>{'period': period};
    if (year != null) params['year'] = '$year';
    if (month != null) params['month'] = '$month';

    final res = await _api.get('/choir/$choirId/attendance-stats',
        queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  // ── 찬양곡 CRUD ───────────────────────────────────────────

  Future<List<ChoirSongModel>> getSongs(
    String choirId, {
    String? genre,
    String? difficulty,
    String? search,
  }) async {
    final params = <String, String>{};
    if (genre != null) params['genre'] = genre;
    if (difficulty != null) params['difficulty'] = difficulty;
    if (search != null) params['search'] = search;

    final res = await _api.get('/choir/$choirId/songs',
        queryParams: params.isNotEmpty ? params : null);
    final list = res['data'] as List? ?? [];
    return list.map((j) => ChoirSongModel.fromJson(j)).toList();
  }

  Future<ChoirSongModel> createSong(
    String choirId, {
    required String title,
    String? composer,
    String? arranger,
    String? hymnBookRef,
    String? youtubeUrl,
    String? genre,
    String difficulty = 'medium',
    List<String> parts = const [],
    String? notes,
  }) async {
    final res = await _api.post('/choir/$choirId/songs', body: {
      'title': title,
      if (composer != null) 'composer': composer,
      if (arranger != null) 'arranger': arranger,
      if (hymnBookRef != null) 'hymn_book_ref': hymnBookRef,
      if (youtubeUrl != null) 'youtube_url': youtubeUrl,
      if (genre != null) 'genre': genre,
      'difficulty': difficulty,
      'parts': parts,
      if (notes != null) 'notes': notes,
    });
    return ChoirSongModel.fromJson(res['data']);
  }

  Future<ChoirSongModel> updateSong(
    String choirId,
    String songId, {
    String? title,
    String? composer,
    String? arranger,
    String? hymnBookRef,
    String? youtubeUrl,
    String? genre,
    String? difficulty,
    List<String>? parts,
    String? notes,
  }) async {
    final res = await _api.put('/choir/$choirId/songs/$songId', body: {
      if (title != null) 'title': title,
      if (composer != null) 'composer': composer,
      if (arranger != null) 'arranger': arranger,
      if (hymnBookRef != null) 'hymn_book_ref': hymnBookRef,
      if (youtubeUrl != null) 'youtube_url': youtubeUrl,
      if (genre != null) 'genre': genre,
      if (difficulty != null) 'difficulty': difficulty,
      if (parts != null) 'parts': parts,
      if (notes != null) 'notes': notes,
    });
    return ChoirSongModel.fromJson(res['data']);
  }

  Future<void> deleteSong(String choirId, String songId) async {
    await _api.delete('/choir/$choirId/songs/$songId');
  }

  // ── 공지사항 CRUD ─────────────────────────────────────────

  Future<List<ChoirNoticeModel>> getNotices(String choirId) async {
    final res = await _api.get('/choir/$choirId/notices');
    final list = res['data'] as List? ?? [];
    return list.map((j) => ChoirNoticeModel.fromJson(j)).toList();
  }

  Future<ChoirNoticeModel> createNotice(
    String choirId, {
    required String title,
    required String content,
    bool isPinned = false,
    String? targetSection,
  }) async {
    final res = await _api.post('/choir/$choirId/notices', body: {
      'title': title,
      'content': content,
      'is_pinned': isPinned,
      if (targetSection != null) 'target_section': targetSection,
    });
    return ChoirNoticeModel.fromJson(res['data']);
  }

  Future<void> updateNotice(
    String choirId,
    String noticeId, {
    String? title,
    String? content,
    bool? isPinned,
    String? targetSection,
  }) async {
    await _api.put('/choir/$choirId/notices/$noticeId', body: {
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (isPinned != null) 'is_pinned': isPinned,
      if (targetSection != null) 'target_section': targetSection,
    });
  }

  Future<void> deleteNotice(String choirId, String noticeId) async {
    await _api.delete('/choir/$choirId/notices/$noticeId');
  }

  // ── 자료실 CRUD ───────────────────────────────────────────

  Future<List<ChoirFileModel>> getFiles(String choirId,
      {String? fileType}) async {
    final res = await _api.get('/choir/$choirId/files',
        queryParams: fileType != null ? {'file_type': fileType} : null);
    final list = res['data'] as List? ?? [];
    return list.map((j) => ChoirFileModel.fromJson(j)).toList();
  }

  Future<ChoirFileModel> createFile(
    String choirId, {
    required String title,
    required String fileType,
    String? description,
    String? fileUrl,
    String? youtubeUrl,
    String? targetSection,
  }) async {
    final res = await _api.post('/choir/$choirId/files', body: {
      'title': title,
      'file_type': fileType,
      if (description != null) 'description': description,
      if (fileUrl != null) 'file_url': fileUrl,
      if (youtubeUrl != null) 'youtube_url': youtubeUrl,
      if (targetSection != null) 'target_section': targetSection,
    });
    return ChoirFileModel.fromJson(res['data']);
  }

  Future<void> deleteFile(String choirId, String fileId) async {
    await _api.delete('/choir/$choirId/files/$fileId');
  }
}
