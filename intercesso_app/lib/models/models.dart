// lib/models/user_model.dart
class UserModel {
  final String id;
  final String email;
  final String nickname;
  final String? profileImageUrl;
  final String? churchName;
  final String? denomination;
  final String? bio;
  final String createdAt;
  final String? lastLogin;

  UserModel({
    required this.id,
    required this.email,
    required this.nickname,
    this.profileImageUrl,
    this.churchName,
    this.denomination,
    this.bio,
    required this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      nickname: json['nickname'] ?? '',
      profileImageUrl: json['profile_image_url'],
      churchName: json['church_name'],
      denomination: json['denomination'],
      bio: json['bio'],
      createdAt: json['created_at'] ?? '',
      lastLogin: json['last_login'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nickname': nickname,
        'profile_image_url': profileImageUrl,
        'church_name': churchName,
        'denomination': denomination,
        'bio': bio,
        'created_at': createdAt,
        'last_login': lastLogin,
      };
}

// lib/models/prayer_model.dart
class PrayerModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String? category;
  final String scope;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String? answeredAt;
  final String? groupId;
  final bool isCovenant;
  final int? covenantDays;
  final int viewsCount;
  final int prayerCount;
  final UserModel? user;
  final List<CommentModel>? comments;
  final bool isParticipated;
  final int? commentCount;

  PrayerModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.category,
    required this.scope,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.answeredAt,
    this.groupId,
    required this.isCovenant,
    this.covenantDays,
    required this.viewsCount,
    required this.prayerCount,
    this.user,
    this.comments,
    this.isParticipated = false,
    this.commentCount,
  });

  factory PrayerModel.fromJson(Map<String, dynamic> json) {
    return PrayerModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'],
      scope: json['scope'] ?? 'public',
      status: json['status'] ?? 'praying',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      answeredAt: json['answered_at'],
      groupId: json['group_id'],
      isCovenant: json['is_covenant'] ?? false,
      covenantDays: json['covenant_days'],
      viewsCount: json['views_count'] ?? 0,
      prayerCount: json['prayer_count'] ?? 0,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      comments: json['comments'] != null
          ? (json['comments'] as List).map((c) => CommentModel.fromJson(c)).toList()
          : null,
      isParticipated: json['is_participated'] ?? false,
      commentCount: json['comment_count'],
    );
  }

  String get statusEmoji {
    switch (status) {
      case 'answered':
        return '✅';
      case 'grateful':
        return '🙌';
      default:
        return '🙏';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'answered':
        return '응답받음';
      case 'grateful':
        return '감사';
      default:
        return '기도중';
    }
  }

  String get categoryEmoji {
    switch (category) {
      case '건강': return '💊';
      case '가정': return '🏠';
      case '진로': return '🎯';
      case '영적': return '✝️';
      case '사업': return '💼';
      default: return '🙏';
    }
  }

  String get scopeLabel {
    switch (scope) {
      case 'friends':   return '👥 지인 공개';
      case 'community': return '⛪ 공동체';
      case 'private':   return '🔒 비공개';
      default:          return '🌐 전체 공개';
    }
  }

  /// 낙관적 업데이트를 위한 copyWith
  PrayerModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? category,
    String? scope,
    String? status,
    String? createdAt,
    String? updatedAt,
    String? answeredAt,
    String? groupId,
    bool? isCovenant,
    int? covenantDays,
    int? viewsCount,
    int? prayerCount,
    UserModel? user,
    List<CommentModel>? comments,
    bool? isParticipated,
    int? commentCount,
  }) {
    return PrayerModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      scope: scope ?? this.scope,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      answeredAt: answeredAt ?? this.answeredAt,
      groupId: groupId ?? this.groupId,
      isCovenant: isCovenant ?? this.isCovenant,
      covenantDays: covenantDays ?? this.covenantDays,
      viewsCount: viewsCount ?? this.viewsCount,
      prayerCount: prayerCount ?? this.prayerCount,
      user: user ?? this.user,
      comments: comments ?? this.comments,
      isParticipated: isParticipated ?? this.isParticipated,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}

// lib/models/comment_model.dart
class CommentModel {
  final String id;
  final String prayerId;
  final String userId;
  final String content;
  final String createdAt;
  final UserModel? user;

  CommentModel({
    required this.id,
    required this.prayerId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.user,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      prayerId: json['prayer_id'] ?? '',
      userId: json['user_id'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['created_at'] ?? '',
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}

// lib/models/group_model.dart
class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? groupImageUrl;
  final String groupType;
  final String creatorId;
  final String createdAt;
  final String? inviteCode;
  final int memberCount;
  final bool isPublic;
  final UserModel? creator;
  final String? userRole;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.groupImageUrl,
    required this.groupType,
    required this.creatorId,
    required this.createdAt,
    this.inviteCode,
    required this.memberCount,
    required this.isPublic,
    this.creator,
    this.userRole,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      groupImageUrl: json['group_image_url'],
      groupType: json['group_type'] ?? 'gathering',
      creatorId: json['creator_id'] ?? '',
      createdAt: json['created_at'] ?? '',
      inviteCode: json['invite_code'],
      memberCount: json['member_count'] ?? 0,
      isPublic: json['is_public'] ?? true,
      creator: json['creator'] != null ? UserModel.fromJson(json['creator']) : null,
      userRole: json['user_role'],
    );
  }

  String get groupTypeLabel {
    switch (groupType) {
      case 'church':
        return '교회';
      case 'cell':
        return '셀/구역';
      case 'gathering':
        return '소모임';
      case 'family':
        return '가족';
      default:
        return '소모임';
    }
  }

  String get groupTypeEmoji {
    switch (groupType) {
      case 'church':
        return '⛪';
      case 'cell':
        return '🔷';
      case 'gathering':
        return '👥';
      case 'family':
        return '👨‍👩‍👧‍👦';
      default:
        return '👥';
    }
  }
}

// lib/models/notification_model.dart
class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String? relatedId;
  final String title;
  final String? message;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    this.relatedId,
    required this.title,
    this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: json['type'] ?? '',
      relatedId: json['related_id'],
      title: json['title'] ?? '',
      message: json['message'],
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }

  String get typeEmoji {
    switch (type) {
      case 'prayer_participation':
        return '🙏';
      case 'comment':
        return '💬';
      case 'intercession_request':
        return '📨';
      case 'prayer_answered':
        return '✅';
      case 'group_invite':
        return '👥';
      default:
        return '🔔';
    }
  }
}

// lib/models/intercession_model.dart
class IntercessionModel {
  final String id;
  final String prayerId;
  final String requesterId;
  final String recipientId;
  final String status; // 'pending' | 'accepted' | 'rejected'
  final String? message;
  final String createdAt;
  final String? respondedAt;
  final String priority;
  final PrayerModel? prayer;
  final UserModel? requester;

  IntercessionModel({
    required this.id,
    required this.prayerId,
    required this.requesterId,
    required this.recipientId,
    required this.status,
    this.message,
    required this.createdAt,
    this.respondedAt,
    required this.priority,
    this.prayer,
    this.requester,
  });

  factory IntercessionModel.fromJson(Map<String, dynamic> json) {
    return IntercessionModel(
      id: json['id'] ?? '',
      prayerId: json['prayer_id'] ?? '',
      requesterId: json['requester_id'] ?? '',
      recipientId: json['recipient_id'] ?? '',
      status: json['status'] ?? 'pending',
      message: json['message'],
      createdAt: json['created_at'] ?? '',
      respondedAt: json['responded_at'],
      priority: json['priority'] ?? 'normal',
      prayer: json['prayer'] != null ? PrayerModel.fromJson(json['prayer']) : null,
      requester: json['requester'] != null ? UserModel.fromJson(json['requester']) : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'accepted':
        return '수락됨';
      case 'rejected':
        return '거절됨';
      default:
        return '대기중';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'high':
        return '긴급';
      case 'low':
        return '여유';
      default:
        return '보통';
    }
  }
}

// lib/models/statistics_model.dart
class UserStatisticsModel {
  final String id;
  final String userId;
  final int totalPrayers;
  final int answeredPrayers;
  final int gratefulPrayers;
  final int totalParticipations;
  final int totalComments;
  final int streakDays;
  final int? answerRate;

  UserStatisticsModel({
    required this.id,
    required this.userId,
    required this.totalPrayers,
    required this.answeredPrayers,
    required this.gratefulPrayers,
    required this.totalParticipations,
    required this.totalComments,
    required this.streakDays,
    this.answerRate,
  });

  factory UserStatisticsModel.fromJson(Map<String, dynamic> json) {
    return UserStatisticsModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      totalPrayers: json['total_prayers'] ?? 0,
      answeredPrayers: json['answered_prayers'] ?? 0,
      gratefulPrayers: json['grateful_prayers'] ?? 0,
      totalParticipations: json['total_participations'] ?? 0,
      totalComments: json['total_comments'] ?? 0,
      streakDays: json['streak_days'] ?? 0,
      answerRate: json['answer_rate'],
    );
  }
}
