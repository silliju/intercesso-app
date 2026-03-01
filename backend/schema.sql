-- ============================================================
-- INTERCESSO 데이터베이스 스키마
-- Supabase (PostgreSQL) 실행 스크립트
-- ============================================================

-- 확장 기능 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. USERS 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    nickname VARCHAR(50) NOT NULL,
    profile_image_url TEXT,
    church_name VARCHAR(100),
    denomination VARCHAR(50),
    bio TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    last_login TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_nickname ON public.users(nickname);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON public.users(created_at);

-- ============================================================
-- 2. GROUPS 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS public.groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    group_image_url TEXT,
    group_type VARCHAR(50) NOT NULL CHECK (group_type IN ('church', 'cell', 'gathering', 'family')),
    creator_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    invite_code VARCHAR(20) UNIQUE,
    member_count INTEGER DEFAULT 1 NOT NULL,
    is_public BOOLEAN DEFAULT true NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_groups_creator_id ON public.groups(creator_id);
CREATE INDEX IF NOT EXISTS idx_groups_invite_code ON public.groups(invite_code);

-- ============================================================
-- 3. PRAYERS 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS public.prayers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    category VARCHAR(50) DEFAULT '기타' CHECK (category IN ('건강', '가정', '진로', '영적', '사업', '기타')),
    scope VARCHAR(20) DEFAULT 'public' NOT NULL CHECK (scope IN ('public', 'friends', 'community', 'private')),
    status VARCHAR(20) DEFAULT 'praying' NOT NULL CHECK (status IN ('praying', 'answered', 'grateful')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    answered_at TIMESTAMP WITH TIME ZONE,
    group_id UUID REFERENCES public.groups(id) ON DELETE SET NULL,
    is_covenant BOOLEAN DEFAULT false NOT NULL,
    covenant_days INTEGER,
    covenant_start_date DATE,
    views_count INTEGER DEFAULT 0 NOT NULL,
    prayer_count INTEGER DEFAULT 0 NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_prayers_user_id ON public.prayers(user_id);
CREATE INDEX IF NOT EXISTS idx_prayers_group_id ON public.prayers(group_id);
CREATE INDEX IF NOT EXISTS idx_prayers_scope ON public.prayers(scope);
CREATE INDEX IF NOT EXISTS idx_prayers_status ON public.prayers(status);
CREATE INDEX IF NOT EXISTS idx_prayers_category ON public.prayers(category);
CREATE INDEX IF NOT EXISTS idx_prayers_created_at ON public.prayers(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_prayers_is_covenant ON public.prayers(is_covenant);

-- ============================================================
-- 4. PRAYER_PARTICIPATIONS 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS public.prayer_participations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prayer_id UUID NOT NULL REFERENCES public.prayers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    participated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(prayer_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_prayer_participations_prayer_id ON public.prayer_participations(prayer_id);
CREATE INDEX IF NOT EXISTS idx_prayer_participations_user_id ON public.prayer_participations(user_id);

-- ============================================================
-- 5. COMMENTS 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS public.comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prayer_id UUID NOT NULL REFERENCES public.prayers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_comments_prayer_id ON public.comments(prayer_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON public.comments(user_id);

-- ============================================================
-- 6. INTERCESSION_REQUESTS 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS public.intercession_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prayer_id UUID NOT NULL REFERENCES public.prayers(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'accepted', 'rejected')),
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    responded_at TIMESTAMP WITH TIME ZONE,
    priority VARCHAR(20) DEFAULT 'normal' NOT NULL CHECK (priority IN ('high', 'normal', 'low'))
);

CREATE INDEX IF NOT EXISTS idx_intercession_requests_recipient_id ON public.intercession_requests(recipient_id);
CREATE INDEX IF NOT EXISTS idx_intercession_requests_requester_id ON public.intercession_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_intercession_requests_status ON public.intercession_requests(status);

-- ============================================================
-- 7. GROUP_MEMBERS 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS public.group_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member' NOT NULL CHECK (role IN ('admin', 'member')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(group_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON public.group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON public.group_members(user_id);

-- ============================================================
-- 8. CONNECTIONS 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS public.connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    connection_type VARCHAR(20) DEFAULT 'friend' NOT NULL CHECK (connection_type IN ('friend', 'following')),
    connected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(user_id, friend_id)
);

CREATE INDEX IF NOT EXISTS idx_connections_user_id ON public.connections(user_id);
CREATE INDEX IF NOT EXISTS idx_connections_friend_id ON public.connections(friend_id);

-- ============================================================
-- 9. NOTIFICATIONS 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('intercession_request', 'prayer_participation', 'comment', 'prayer_answered', 'group_invite')),
    related_id UUID,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    is_read BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- ============================================================
-- 10. NOTIFICATION_PREFERENCES 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    all_notifications_enabled BOOLEAN DEFAULT true NOT NULL,
    intercession_request BOOLEAN DEFAULT true NOT NULL,
    prayer_participation BOOLEAN DEFAULT true NOT NULL,
    comment_notification BOOLEAN DEFAULT true NOT NULL,
    prayer_answered BOOLEAN DEFAULT true NOT NULL,
    group_notification BOOLEAN DEFAULT false NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- ============================================================
-- 11. COVENANT_CHECKINS 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS public.covenant_checkins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prayer_id UUID NOT NULL REFERENCES public.prayers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    day INTEGER NOT NULL,
    checked_in_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(prayer_id, user_id, day)
);

CREATE INDEX IF NOT EXISTS idx_covenant_checkins_prayer_id ON public.covenant_checkins(prayer_id);
CREATE INDEX IF NOT EXISTS idx_covenant_checkins_user_id ON public.covenant_checkins(user_id);

-- ============================================================
-- 12. BLOCKED_USERS 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS public.blocked_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    blocked_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    reason TEXT,
    blocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(user_id, blocked_user_id)
);

CREATE INDEX IF NOT EXISTS idx_blocked_users_user_id ON public.blocked_users(user_id);

-- ============================================================
-- 13. REPORTS 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN ('prayer', 'comment', 'user')),
    related_id UUID NOT NULL,
    reason TEXT NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'reviewed', 'resolved')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    reviewed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON public.reports(created_at DESC);

-- ============================================================
-- 14. USER_STATISTICS 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_statistics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    total_prayers INTEGER DEFAULT 0 NOT NULL,
    answered_prayers INTEGER DEFAULT 0 NOT NULL,
    grateful_prayers INTEGER DEFAULT 0 NOT NULL,
    total_participations INTEGER DEFAULT 0 NOT NULL,
    total_comments INTEGER DEFAULT 0 NOT NULL,
    streak_days INTEGER DEFAULT 0 NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- ============================================================
-- 15. PRAYER_ANSWERS 테이블 (기도 응답 간증)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.prayer_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prayer_id UUID NOT NULL REFERENCES public.prayers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    content TEXT,
    scope VARCHAR(20) DEFAULT 'public' NOT NULL CHECK (scope IN ('public', 'group', 'private')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(prayer_id)
);

CREATE INDEX IF NOT EXISTS idx_prayer_answers_prayer_id ON public.prayer_answers(prayer_id);
CREATE INDEX IF NOT EXISTS idx_prayer_answers_user_id ON public.prayer_answers(user_id);
CREATE INDEX IF NOT EXISTS idx_prayer_answers_scope ON public.prayer_answers(scope);
CREATE INDEX IF NOT EXISTS idx_prayer_answers_created_at ON public.prayer_answers(created_at DESC);

-- ============================================================
-- 16. PRAYER_ANSWER_COMMENTS 테이블 (기도 응답 댓글)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.prayer_answer_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    answer_id UUID NOT NULL REFERENCES public.prayer_answers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_prayer_answer_comments_answer_id ON public.prayer_answer_comments(answer_id);
CREATE INDEX IF NOT EXISTS idx_prayer_answer_comments_user_id ON public.prayer_answer_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_prayer_answer_comments_created_at ON public.prayer_answer_comments(created_at);

-- ============================================================
-- RLS (Row Level Security) 정책
-- ============================================================

-- users 테이블 RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users_public_read" ON public.users FOR SELECT USING (true);
CREATE POLICY "users_own_update" ON public.users FOR UPDATE USING (auth.uid() = id);

-- prayers 테이블 RLS
ALTER TABLE public.prayers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "prayers_public_read" ON public.prayers FOR SELECT USING (
    scope = 'public' OR user_id = auth.uid()
);
CREATE POLICY "prayers_own_insert" ON public.prayers FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "prayers_own_update" ON public.prayers FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "prayers_own_delete" ON public.prayers FOR DELETE USING (user_id = auth.uid());

-- notifications 테이블 RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notifications_own" ON public.notifications FOR ALL USING (user_id = auth.uid());

-- notification_preferences 테이블 RLS
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notification_preferences_own" ON public.notification_preferences FOR ALL USING (user_id = auth.uid());

-- user_statistics 테이블 RLS
ALTER TABLE public.user_statistics ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_statistics_public_read" ON public.user_statistics FOR SELECT USING (true);
CREATE POLICY "user_statistics_own_update" ON public.user_statistics FOR UPDATE USING (user_id = auth.uid());

-- ============================================================
-- 트리거: updated_at 자동 업데이트
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER update_prayers_updated_at
    BEFORE UPDATE ON public.prayers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER update_groups_updated_at
    BEFORE UPDATE ON public.groups
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER update_comments_updated_at
    BEFORE UPDATE ON public.comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
