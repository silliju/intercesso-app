// ─── 찬양대 모듈 모델 파일 ─────────────────────────────────────
// choir_models.dart

// ─── 찬양대 파트(성부) ─────────────────────────────────────────
enum ChoirSection {
  soprano,
  alto,
  tenor,
  bass,
  all,
}

extension ChoirSectionExt on ChoirSection {
  String get label {
    switch (this) {
      case ChoirSection.soprano: return '소프라노';
      case ChoirSection.alto:    return '알토';
      case ChoirSection.tenor:   return '테너';
      case ChoirSection.bass:    return '베이스';
      case ChoirSection.all:     return '전체';
    }
  }

  String get emoji {
    switch (this) {
      case ChoirSection.soprano: return '🎵';
      case ChoirSection.alto:    return '🎶';
      case ChoirSection.tenor:   return '🎤';
      case ChoirSection.bass:    return '🎸';
      case ChoirSection.all:     return '🎼';
    }
  }

  static ChoirSection fromString(String? s) {
    switch (s) {
      case 'soprano': return ChoirSection.soprano;
      case 'alto':    return ChoirSection.alto;
      case 'tenor':   return ChoirSection.tenor;
      case 'bass':    return ChoirSection.bass;
      default:        return ChoirSection.all;
    }
  }

  String get value {
    switch (this) {
      case ChoirSection.soprano: return 'soprano';
      case ChoirSection.alto:    return 'alto';
      case ChoirSection.tenor:   return 'tenor';
      case ChoirSection.bass:    return 'bass';
      case ChoirSection.all:     return 'all';
    }
  }
}

// ─── 찬양대 역할 ───────────────────────────────────────────────
enum ChoirRole {
  conductor,
  sectionLeader,
  treasurer,
  member,
}

extension ChoirRoleExt on ChoirRole {
  String get label {
    switch (this) {
      case ChoirRole.conductor:     return '지휘자';
      case ChoirRole.sectionLeader: return '파트장';
      case ChoirRole.treasurer:     return '총무';
      case ChoirRole.member:        return '단원';
    }
  }

  String get emoji {
    switch (this) {
      case ChoirRole.conductor:     return '🎼';
      case ChoirRole.sectionLeader: return '⭐';
      case ChoirRole.treasurer:     return '📋';
      case ChoirRole.member:        return '🎵';
    }
  }

  static ChoirRole fromString(String? s) {
    switch (s) {
      case 'conductor':     return ChoirRole.conductor;
      case 'section_leader': return ChoirRole.sectionLeader;
      case 'treasurer':     return ChoirRole.treasurer;
      default:              return ChoirRole.member;
    }
  }

  String get value {
    switch (this) {
      case ChoirRole.conductor:     return 'conductor';
      case ChoirRole.sectionLeader: return 'section_leader';
      case ChoirRole.treasurer:     return 'treasurer';
      case ChoirRole.member:        return 'member';
    }
  }
}

// ─── 일정 타입 ─────────────────────────────────────────────────
enum ScheduleType {
  rehearsal,
  preService,
  service,
  postService,
  weekday,
  special,
}

extension ScheduleTypeExt on ScheduleType {
  String get label {
    switch (this) {
      case ScheduleType.rehearsal:   return '연습';
      case ScheduleType.preService:  return '예배 전 연습';
      case ScheduleType.service:     return '예배';
      case ScheduleType.postService: return '예배 후 연습';
      case ScheduleType.weekday:     return '평일 연습';
      case ScheduleType.special:     return '특별 행사';
    }
  }

  String get emoji {
    switch (this) {
      case ScheduleType.rehearsal:   return '🎵';
      case ScheduleType.preService:  return '⏰';
      case ScheduleType.service:     return '⛪';
      case ScheduleType.postService: return '🎶';
      case ScheduleType.weekday:     return '📅';
      case ScheduleType.special:     return '🌟';
    }
  }

  static ScheduleType fromString(String? s) {
    switch (s) {
      case 'rehearsal':             return ScheduleType.rehearsal;
      case 'pre_service_practice':  return ScheduleType.preService;
      case 'service':               return ScheduleType.service;
      case 'post_service_practice': return ScheduleType.postService;
      case 'weekday_practice':      return ScheduleType.weekday;
      case 'special_event':         return ScheduleType.special;
      default:                      return ScheduleType.rehearsal;
    }
  }

  String get value {
    switch (this) {
      case ScheduleType.rehearsal:   return 'rehearsal';
      case ScheduleType.preService:  return 'pre_service_practice';
      case ScheduleType.service:     return 'service';
      case ScheduleType.postService: return 'post_service_practice';
      case ScheduleType.weekday:     return 'weekday_practice';
      case ScheduleType.special:     return 'special_event';
    }
  }
}

// ─── 출석 상태 ─────────────────────────────────────────────────
enum AttendanceStatus {
  present,
  absent,
  excused,
}

extension AttendanceStatusExt on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present: return '출석';
      case AttendanceStatus.absent:  return '결석';
      case AttendanceStatus.excused: return '공결';
    }
  }

  String get emoji {
    switch (this) {
      case AttendanceStatus.present: return '✅';
      case AttendanceStatus.absent:  return '❌';
      case AttendanceStatus.excused: return '📋';
    }
  }

  static AttendanceStatus fromString(String? s) {
    switch (s) {
      case 'absent':  return AttendanceStatus.absent;
      case 'excused': return AttendanceStatus.excused;
      default:        return AttendanceStatus.present;
    }
  }

  String get value {
    switch (this) {
      case AttendanceStatus.present: return 'present';
      case AttendanceStatus.absent:  return 'absent';
      case AttendanceStatus.excused: return 'excused';
    }
  }
}

// ─── 찬양대 모델 ───────────────────────────────────────────────
class ChoirModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? churchName;
  final String? worshipType;
  final String ownerId;
  final String? inviteCode;
  final bool inviteLinkActive;
  final int memberCount;
  final String createdAt;

  ChoirModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.churchName,
    this.worshipType,
    required this.ownerId,
    this.inviteCode,
    this.inviteLinkActive = true,
    this.memberCount = 0,
    required this.createdAt,
  });

  factory ChoirModel.fromJson(Map<String, dynamic> json) {
    return ChoirModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['image_url'],
      churchName: json['church_name'],
      worshipType: json['worship_type'],
      ownerId: json['owner_id'] ?? '',
      inviteCode: json['invite_code'],
      inviteLinkActive: json['invite_link_active'] ?? true,
      memberCount: json['member_count'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'church_name': churchName,
        'worship_type': worshipType,
        'owner_id': ownerId,
        'invite_code': inviteCode,
        'invite_link_active': inviteLinkActive,
        'member_count': memberCount,
        'created_at': createdAt,
      };

  ChoirModel copyWith({
    String? name,
    String? description,
    String? imageUrl,
    String? churchName,
    String? worshipType,
    bool? inviteLinkActive,
    int? memberCount,
  }) {
    return ChoirModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      churchName: churchName ?? this.churchName,
      worshipType: worshipType ?? this.worshipType,
      ownerId: ownerId,
      inviteCode: inviteCode,
      inviteLinkActive: inviteLinkActive ?? this.inviteLinkActive,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt,
    );
  }
}

// ─── 찬양대 멤버 모델 ──────────────────────────────────────────
class ChoirMemberModel {
  final String id;
  final String choirId;
  final String userId;
  final String name;
  final String? profileImageUrl;
  final ChoirSection section;
  final ChoirRole role;
  final String status; // pending / active / inactive
  final String? joinedAt;
  final String? phone;
  final String? email;

  ChoirMemberModel({
    required this.id,
    required this.choirId,
    required this.userId,
    required this.name,
    this.profileImageUrl,
    required this.section,
    required this.role,
    required this.status,
    this.joinedAt,
    this.phone,
    this.email,
  });

  factory ChoirMemberModel.fromJson(Map<String, dynamic> json) {
    return ChoirMemberModel(
      id: json['id'] ?? '',
      choirId: json['choir_id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? json['user']?['nickname'] ?? '',
      profileImageUrl: json['profile_image_url'] ?? json['user']?['profile_image_url'],
      section: ChoirSectionExt.fromString(json['section']),
      role: ChoirRoleExt.fromString(json['role']),
      status: json['status'] ?? 'active',
      joinedAt: json['joined_at'],
      phone: json['phone'],
      email: json['email'] ?? json['user']?['email'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'choir_id': choirId,
        'user_id': userId,
        'name': name,
        'section': section.value,
        'role': role.value,
        'status': status,
        'joined_at': joinedAt,
        'phone': phone,
        'email': email,
      };

  bool get isAdmin =>
      role == ChoirRole.conductor || role == ChoirRole.sectionLeader;

  bool get isPending => status == 'pending';

  ChoirMemberModel copyWith({
    String? name,
    ChoirSection? section,
    ChoirRole? role,
    String? status,
    String? phone,
  }) {
    return ChoirMemberModel(
      id: id,
      choirId: choirId,
      userId: userId,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl,
      section: section ?? this.section,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt,
      phone: phone ?? this.phone,
      email: email,
    );
  }
}

// ─── 찬양곡 모델 ───────────────────────────────────────────────
class ChoirSongModel {
  final String id;
  final String choirId;
  final String title;
  final String? composer;
  final String? arranger;
  final String? hymnBookRef;
  final String? youtubeUrl;
  final String? genre;
  final String? difficulty;
  final String? notes;
  final List<String> parts;
  final String createdById;
  final String createdAt;

  ChoirSongModel({
    required this.id,
    required this.choirId,
    required this.title,
    this.composer,
    this.arranger,
    this.hymnBookRef,
    this.youtubeUrl,
    this.genre,
    this.difficulty,
    this.notes,
    required this.parts,
    required this.createdById,
    required this.createdAt,
  });

  factory ChoirSongModel.fromJson(Map<String, dynamic> json) {
    return ChoirSongModel(
      id: json['id'] ?? '',
      choirId: json['choir_id'] ?? '',
      title: json['title'] ?? '',
      composer: json['composer'],
      arranger: json['arranger'],
      hymnBookRef: json['hymn_book_ref'],
      youtubeUrl: json['youtube_url'],
      genre: json['genre'],
      difficulty: json['difficulty'],
      notes: json['notes'],
      parts: json['parts'] != null
          ? List<String>.from(json['parts'])
          : [],
      createdById: json['created_by'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'choir_id': choirId,
        'title': title,
        'composer': composer,
        'arranger': arranger,
        'hymn_book_ref': hymnBookRef,
        'youtube_url': youtubeUrl,
        'genre': genre,
        'difficulty': difficulty,
        'notes': notes,
        'parts': parts,
        'created_by': createdById,
        'created_at': createdAt,
      };

  String get difficultyLabel {
    switch (difficulty) {
      case 'easy':   return '쉬움';
      case 'medium': return '보통';
      case 'hard':   return '어려움';
      default:       return '-';
    }
  }

  String get youtubeId {
    if (youtubeUrl == null) return '';
    final uri = Uri.tryParse(youtubeUrl!);
    if (uri == null) return '';
    if (uri.host.contains('youtu.be')) return uri.pathSegments.first;
    return uri.queryParameters['v'] ?? '';
  }
}

// ─── 일정 모델 ─────────────────────────────────────────────────
class ChoirScheduleModel {
  final String id;
  final String choirId;
  final String title;
  final String? description;
  final ScheduleType scheduleType;
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;
  final bool isConfirmed;
  final String? youtubeUrl;
  final List<ChoirSongModel> songs;
  final String createdById;
  final String createdAt;

  ChoirScheduleModel({
    required this.id,
    required this.choirId,
    required this.title,
    this.description,
    required this.scheduleType,
    required this.startTime,
    this.endTime,
    this.location,
    this.isConfirmed = false,
    this.youtubeUrl,
    this.songs = const [],
    required this.createdById,
    required this.createdAt,
  });

  factory ChoirScheduleModel.fromJson(Map<String, dynamic> json) {
    return ChoirScheduleModel(
      id: json['id'] ?? '',
      choirId: json['choir_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      scheduleType: ScheduleTypeExt.fromString(json['schedule_type']),
      startTime: DateTime.tryParse(json['start_time'] ?? '') ?? DateTime.now(),
      endTime: json['end_time'] != null ? DateTime.tryParse(json['end_time']) : null,
      location: json['location'],
      isConfirmed: json['is_confirmed'] ?? false,
      youtubeUrl: json['youtube_url'],
      songs: json['songs'] != null
          ? (json['songs'] as List).map((s) => ChoirSongModel.fromJson(s)).toList()
          : [],
      createdById: json['created_by'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'choir_id': choirId,
        'title': title,
        'description': description,
        'schedule_type': scheduleType.value,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'location': location,
        'is_confirmed': isConfirmed,
        'youtube_url': youtubeUrl,
        'created_by': createdById,
        'created_at': createdAt,
      };

  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return startTime.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        startTime.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  String get formattedDate {
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    return '${startTime.month}월 ${startTime.day}일 (${days[startTime.weekday - 1]})';
  }

  String get formattedTime {
    final h = startTime.hour.toString().padLeft(2, '0');
    final m = startTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─── 출석 모델 ─────────────────────────────────────────────────
class ChoirAttendanceModel {
  final String id;
  final String scheduleId;
  final String choirId;
  final String memberId;
  final String userId;
  final String memberName;
  final ChoirSection section;
  final ChoirRole role;
  final AttendanceStatus status;
  final String? note;
  final String? checkedAt;

  ChoirAttendanceModel({
    required this.id,
    required this.scheduleId,
    required this.choirId,
    required this.memberId,
    required this.userId,
    required this.memberName,
    required this.section,
    required this.role,
    required this.status,
    this.note,
    this.checkedAt,
  });

  factory ChoirAttendanceModel.fromJson(Map<String, dynamic> json) {
    return ChoirAttendanceModel(
      id: json['id'] ?? '',
      scheduleId: json['schedule_id'] ?? '',
      choirId: json['choir_id'] ?? '',
      memberId: json['member_id'] ?? '',
      userId: json['user_id'] ?? '',
      memberName: json['member_name'] ?? json['member']?['name'] ?? '',
      section: ChoirSectionExt.fromString(json['section'] ?? json['member']?['section']),
      role: ChoirRoleExt.fromString(json['role'] ?? json['member']?['role']),
      status: AttendanceStatusExt.fromString(json['status']),
      note: json['note'],
      checkedAt: json['checked_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'schedule_id': scheduleId,
        'choir_id': choirId,
        'member_id': memberId,
        'user_id': userId,
        'status': status.value,
        'note': note,
        'checked_at': checkedAt,
      };

  ChoirAttendanceModel copyWith({AttendanceStatus? status, String? note}) {
    return ChoirAttendanceModel(
      id: id,
      scheduleId: scheduleId,
      choirId: choirId,
      memberId: memberId,
      userId: userId,
      memberName: memberName,
      section: section,
      role: role,
      status: status ?? this.status,
      note: note ?? this.note,
      checkedAt: checkedAt,
    );
  }
}

// ─── 출석 통계 모델 ────────────────────────────────────────────
class AttendanceStats {
  final int totalSchedules;
  final int presentCount;
  final int absentCount;
  final int excusedCount;
  final double attendanceRate;
  final Map<String, double> sectionRates;

  AttendanceStats({
    required this.totalSchedules,
    required this.presentCount,
    required this.absentCount,
    required this.excusedCount,
    required this.attendanceRate,
    required this.sectionRates,
  });

  factory AttendanceStats.empty() => AttendanceStats(
        totalSchedules: 0,
        presentCount: 0,
        absentCount: 0,
        excusedCount: 0,
        attendanceRate: 0,
        sectionRates: {},
      );

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    return AttendanceStats(
      totalSchedules: json['total_schedules'] ?? 0,
      presentCount: json['present_count'] ?? 0,
      absentCount: json['absent_count'] ?? 0,
      excusedCount: json['excused_count'] ?? 0,
      attendanceRate: (json['attendance_rate'] ?? 0.0).toDouble(),
      sectionRates: json['section_rates'] != null
          ? Map<String, double>.from(json['section_rates'])
          : {},
    );
  }
}

// ─── 공지사항 모델 ─────────────────────────────────────────────
class ChoirNoticeModel {
  final String id;
  final String choirId;
  final String authorId;
  final String authorName;
  final String title;
  final String content;
  final String? targetSection;
  final bool isPinned;
  final String createdAt;

  ChoirNoticeModel({
    required this.id,
    required this.choirId,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    this.targetSection,
    this.isPinned = false,
    required this.createdAt,
  });

  factory ChoirNoticeModel.fromJson(Map<String, dynamic> json) {
    return ChoirNoticeModel(
      id: json['id'] ?? '',
      choirId: json['choir_id'] ?? '',
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'] ?? json['author']?['nickname'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      targetSection: json['target_section'],
      isPinned: json['is_pinned'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final created = DateTime.tryParse(createdAt) ?? now;
    final diff = now.difference(created);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${created.month}월 ${created.day}일';
  }
}

// ─── 자료(파일) 모델 ───────────────────────────────────────────
class ChoirFileModel {
  final String id;
  final String choirId;
  final String title;
  final String? description;
  final String? fileUrl;
  final String? youtubeUrl;
  final String fileType; // score / video / document / audio
  final String? targetSection;
  final String uploadedById;
  final String uploaderName;
  final String createdAt;

  ChoirFileModel({
    required this.id,
    required this.choirId,
    required this.title,
    this.description,
    this.fileUrl,
    this.youtubeUrl,
    required this.fileType,
    this.targetSection,
    required this.uploadedById,
    required this.uploaderName,
    required this.createdAt,
  });

  factory ChoirFileModel.fromJson(Map<String, dynamic> json) {
    return ChoirFileModel(
      id: json['id'] ?? '',
      choirId: json['choir_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      fileUrl: json['file_url'],
      youtubeUrl: json['youtube_url'],
      fileType: json['file_type'] ?? 'document',
      targetSection: json['target_section'],
      uploadedById: json['uploaded_by'] ?? '',
      uploaderName: json['uploader_name'] ?? json['uploader']?['nickname'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  String get typeEmoji {
    switch (fileType) {
      case 'score':    return '🎵';
      case 'video':    return '🎬';
      case 'audio':    return '🎧';
      case 'document': return '📄';
      default:         return '📁';
    }
  }

  String get typeLabel {
    switch (fileType) {
      case 'score':    return '악보';
      case 'video':    return '영상';
      case 'audio':    return '음원';
      case 'document': return '문서';
      default:         return '파일';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final created = DateTime.tryParse(createdAt) ?? now;
    final diff = now.difference(created);
    if (diff.inDays < 1) return '오늘';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}주 전';
    return '${created.month}월 ${created.day}일';
  }
}
