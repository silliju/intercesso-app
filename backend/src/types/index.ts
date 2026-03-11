// 공통 응답 타입
export interface ApiResponse<T = any> {
  success: boolean;
  statusCode: number;
  message: string;
  data?: T;
  error?: {
    code: string;
    details?: string;
  };
}

export interface PaginatedResponse<T = any> {
  success: boolean;
  statusCode: number;
  message: string;
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

// 사용자 타입
export interface User {
  id: string;
  email: string;
  nickname: string;
  profile_image_url?: string;
  church_id?: number;
  church_name?: string;
  denomination?: string;
  bio?: string;
  created_at: string;
  updated_at: string;
  last_login?: string;
}

// 기도 타입
export type PrayerScope = 'public' | 'friends' | 'community' | 'private';
export type PrayerStatus = 'praying' | 'answered' | 'grateful';
export type PrayerCategory = '건강' | '가정' | '진로' | '영적' | '사업' | '기타';

export interface Prayer {
  id: string;
  user_id: string;
  title: string;
  content: string;
  category?: PrayerCategory;
  scope: PrayerScope;
  status: PrayerStatus;
  created_at: string;
  updated_at: string;
  answered_at?: string;
  group_id?: string;
  is_covenant: boolean;
  covenant_days?: number;
  covenant_start_date?: string;
  views_count: number;
  prayer_count: number;
  // 조인 데이터
  user?: User;
  comment_count?: number;
  is_participated?: boolean;
}

// 댓글 타입
export interface Comment {
  id: string;
  prayer_id: string;
  user_id: string;
  content: string;
  created_at: string;
  updated_at: string;
  user?: User;
}

// 그룹 타입
export type GroupType = 'church' | 'cell' | 'gathering' | 'family';

export interface Group {
  id: string;
  name: string;
  description?: string;
  group_image_url?: string;
  group_type: GroupType;
  creator_id: string;
  created_at: string;
  updated_at: string;
  invite_code?: string;
  member_count: number;
  is_public: boolean;
  creator?: User;
  user_role?: string;
}

// 중보기도 요청 타입
export type IntercessionStatus = 'pending' | 'accepted' | 'rejected';
export type IntercessionPriority = 'high' | 'normal' | 'low';

export interface IntercessionRequest {
  id: string;
  prayer_id: string;
  requester_id: string;
  recipient_id: string;
  status: IntercessionStatus;
  message?: string;
  created_at: string;
  responded_at?: string;
  priority: IntercessionPriority;
  prayer?: Prayer;
  requester?: User;
}

// 알림 타입
export type NotificationType =
  | 'intercession_request'
  | 'prayer_participation'
  | 'comment'
  | 'prayer_answered'
  | 'group_invite';

export interface Notification {
  id: string;
  user_id: string;
  type: NotificationType;
  related_id?: string;
  title: string;
  message?: string;
  is_read: boolean;
  created_at: string;
}

// 알림 설정 타입
export interface NotificationPreferences {
  id: string;
  user_id: string;
  all_notifications_enabled: boolean;
  intercession_request: boolean;
  prayer_participation: boolean;
  comment_notification: boolean;
  prayer_answered: boolean;
  group_notification: boolean;
  updated_at: string;
}

// 사용자 통계 타입
export interface UserStatistics {
  id: string;
  user_id: string;
  total_prayers: number;
  answered_prayers: number;
  grateful_prayers: number;
  total_participations: number;
  total_comments: number;
  streak_days: number;
  updated_at: string;
}

// JWT 페이로드
export interface JwtPayload {
  userId: string;
  email: string;
  iat?: number;
  exp?: number;
}

// 요청 바디 타입
export interface SignUpBody {
  email: string;
  password: string;
  nickname: string;
  church_id?: number;
  church_name?: string;
  denomination?: string;
  bio?: string;
}

export interface LoginBody {
  email: string;
  password: string;
}

export interface CreatePrayerBody {
  title: string;
  content: string;
  category?: PrayerCategory;
  scope?: PrayerScope;
  group_id?: string;
  is_covenant?: boolean;
  covenant_days?: number;
  covenant_start_date?: string;
}

export interface UpdatePrayerBody {
  title?: string;
  content?: string;
  category?: PrayerCategory;
  scope?: PrayerScope;
  status?: PrayerStatus;
}

export interface CreateGroupBody {
  name: string;
  description?: string;
  group_type: GroupType;
  is_public?: boolean;
}
