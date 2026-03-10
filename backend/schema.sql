-- ============================================================
-- INTERCESSO 데이터베이스 스키마
-- Supabase (PostgreSQL) 실행 스크립트
-- ============================================================

-- 확장 기능 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. USERS 테이블
-- 역할: 앱 사용자 계정 정보 저장. 인증, 프로필, 교회 정보 등을 관리합니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),  -- 사용자 고유 식별자 (UUID)
    email VARCHAR(255) UNIQUE NOT NULL,              -- 이메일 주소 (로그인 ID, 유일값)
    nickname VARCHAR(50) NOT NULL,                   -- 닉네임 (화면 표시명)
    profile_image_url TEXT,                          -- 프로필 이미지 URL
    church_name VARCHAR(100),                        -- 소속 교회명
    denomination VARCHAR(50),                        -- 교단명 (예: 장로교, 감리교)
    bio TEXT,                                        -- 자기소개 문구
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,  -- 계정 생성 일시
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,  -- 마지막 수정 일시
    last_login TIMESTAMP WITH TIME ZONE              -- 마지막 로그인 일시
);

CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_nickname ON public.users(nickname);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON public.users(created_at);

-- ============================================================
-- 2. GROUPS 테이블
-- 역할: 기도 그룹 정보 저장. 교회·셀·소모임·가족 등 커뮤니티 단위를 관리합니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),  -- 그룹 고유 식별자
    name VARCHAR(100) NOT NULL,                      -- 그룹 이름
    description TEXT,                                -- 그룹 설명
    group_image_url TEXT,                            -- 그룹 대표 이미지 URL
    group_type VARCHAR(50) NOT NULL CHECK (group_type IN ('church', 'cell', 'gathering', 'family')),
                                                     -- 그룹 유형 (church=교회, cell=셀/구역, gathering=소모임, family=가족)
    creator_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                                                     -- 그룹 개설자 사용자 ID (외래키)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,  -- 그룹 생성 일시
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,  -- 마지막 수정 일시
    invite_code VARCHAR(20) UNIQUE,                  -- 초대 코드 (멤버 초대 시 사용)
    member_count INTEGER DEFAULT 1 NOT NULL,         -- 현재 멤버 수
    is_public BOOLEAN DEFAULT true NOT NULL          -- 공개 여부 (true=공개, false=비공개)
);

CREATE INDEX IF NOT EXISTS idx_groups_creator_id ON public.groups(creator_id);
CREATE INDEX IF NOT EXISTS idx_groups_invite_code ON public.groups(invite_code);

-- ============================================================
-- 3. PRAYERS 테이블
-- 역할: 기도제목 저장. 공개 범위·카테고리·언약기도 여부 등 기도의 핵심 정보를 관리합니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.prayers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),  -- 기도제목 고유 식별자
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                                                     -- 기도 작성자 사용자 ID (외래키)
    title VARCHAR(255) NOT NULL,                     -- 기도제목 제목
    content TEXT NOT NULL,                           -- 기도제목 본문 내용
    category VARCHAR(50) DEFAULT '기타' CHECK (category IN ('건강', '가정', '진로', '영적', '사업', '기타')),
                                                     -- 기도 카테고리 (건강/가정/진로/영적/사업/기타)
    scope VARCHAR(20) DEFAULT 'public' NOT NULL CHECK (scope IN ('public', 'friends', 'community', 'private')),
                                                     -- 공개 범위 (public=전체공개, friends=지인공개, community=공동체, private=비공개)
    status VARCHAR(20) DEFAULT 'praying' NOT NULL CHECK (status IN ('praying', 'answered', 'grateful')),
                                                     -- 기도 상태 (praying=기도중, answered=응답받음, grateful=감사)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,  -- 기도제목 작성 일시
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,  -- 마지막 수정 일시
    answered_at TIMESTAMP WITH TIME ZONE,            -- 응답받은 일시 (응답 시 기록)
    group_id UUID REFERENCES public.groups(id) ON DELETE SET NULL,
                                                     -- 연결된 그룹 ID (그룹 기도일 때, 외래키)
    is_covenant BOOLEAN DEFAULT false NOT NULL,      -- 언약기도 여부 (true=언약기도)
    covenant_days INTEGER,                           -- 언약기도 목표 일수 (7/21/40/50/100일)
    covenant_start_date DATE,                        -- 언약기도 시작 날짜
    views_count INTEGER DEFAULT 0 NOT NULL,          -- 조회 수
    prayer_count INTEGER DEFAULT 0 NOT NULL          -- 함께 기도한 인원 수
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
-- 역할: "함께 기도하기" 참여 기록. 누가 어떤 기도에 참여했는지를 저장합니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.prayer_participations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),  -- 참여 기록 고유 식별자
    prayer_id UUID NOT NULL REFERENCES public.prayers(id) ON DELETE CASCADE,
                                                     -- 참여 대상 기도제목 ID (외래키)
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                                                     -- 참여한 사용자 ID (외래키)
    participated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
                                                     -- 기도 참여 일시
    UNIQUE(prayer_id, user_id)                       -- 동일 기도에 중복 참여 불가
);

CREATE INDEX IF NOT EXISTS idx_prayer_participations_prayer_id ON public.prayer_participations(prayer_id);
CREATE INDEX IF NOT EXISTS idx_prayer_participations_user_id ON public.prayer_participations(user_id);

-- ============================================================
-- 5. COMMENTS 테이블
-- 역할: 기도제목에 달린 댓글 저장. 응원·위로 메시지 등 커뮤니티 소통 내용을 관리합니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),  -- 댓글 고유 식별자
    prayer_id UUID NOT NULL REFERENCES public.prayers(id) ON DELETE CASCADE,
                                                     -- 댓글이 달린 기도제목 ID (외래키)
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                                                     -- 댓글 작성자 사용자 ID (외래키)
    content TEXT NOT NULL,                           -- 댓글 내용
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,  -- 댓글 작성 일시
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL   -- 댓글 수정 일시
);

CREATE INDEX IF NOT EXISTS idx_comments_prayer_id ON public.comments(prayer_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON public.comments(user_id);

-- ============================================================
-- 6. INTERCESSION_REQUESTS 테이블
-- 역할: 중보기도 요청 저장. 특정 사용자에게 중보기도를 요청하고 수락/거절 상태를 관리합니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.intercession_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),  -- 중보기도 요청 고유 식별자
    prayer_id UUID NOT NULL REFERENCES public.prayers(id) ON DELETE CASCADE,
                                                     -- 중보기도 대상 기도제목 ID (외래키)
    requester_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                                                     -- 중보기도 요청자 사용자 ID (외래키)
    recipient_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                                                     -- 중보기도 수신자 사용자 ID (외래키)
    status VARCHAR(20) DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'accepted', 'rejected')),
                                                     -- 요청 상태 (pending=대기중, accepted=수락, rejected=거절)
    message TEXT,                                    -- 요청 메시지 (선택 입력)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,  -- 요청 생성 일시
    responded_at TIMESTAMP WITH TIME ZONE,           -- 수락/거절 응답 일시
    priority VARCHAR(20) DEFAULT 'normal' NOT NULL CHECK (priority IN ('high', 'normal', 'low'))
                                                     -- 긴급도 (high=긴급, normal=보통, low=낮음)
);

CREATE INDEX IF NOT EXISTS idx_intercession_requests_recipient_id ON public.intercession_requests(recipient_id);
CREATE INDEX IF NOT EXISTS idx_intercession_requests_requester_id ON public.intercession_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_intercession_requests_status ON public.intercession_requests(status);

-- ============================================================
-- 7. GROUP_MEMBERS 테이블
-- 역할: 그룹 멤버십 관리. 어떤 사용자가 어떤 그룹에 소속되고 어떤 역할을 맡는지 저장합니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.group_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),  -- 그룹 멤버십 고유 식별자
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
                                                     -- 소속 그룹 ID (외래키)
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                                                     -- 멤버 사용자 ID (외래키)
    role VARCHAR(20) DEFAULT 'member' NOT NULL CHECK (role IN ('admin', 'member')),
                                                     -- 그룹 내 역할 (admin=관리자, member=일반멤버)
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
                                                     -- 그룹 가입 일시
    UNIQUE(group_id, user_id)                        -- 같은 그룹에 중복 가입 불가
);

CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON public.group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON public.group_members(user_id);

-- ============================================================
-- 8. CONNECTIONS 테이블
-- 역할: 사용자 간 친구/팔로우 관계 저장. 지인 기도 공유 범위 결정에 사용됩니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),  -- 연결 관계 고유 식별자
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                                                     -- 연결을 시작한 사용자 ID (외래키)
    friend_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                                                     -- 연결 대상 사용자 ID (외래키)
    connection_type VARCHAR(20) DEFAULT 'friend' NOT NULL CHECK (connection_type IN ('friend', 'following')),
                                                     -- 연결 유형 (friend=친구, following=팔로잉)
    connected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
                                                     -- 연결(친구추가) 일시
    UNIQUE(user_id, friend_id)                       -- 동일 관계 중복 불가
);

CREATE INDEX IF NOT EXISTS idx_connections_user_id ON public.connections(user_id);
CREATE INDEX IF NOT EXISTS idx_connections_friend_id ON public.connections(friend_id);

-- ============================================================
-- 9. NOTIFICATIONS 테이블
-- 역할: 앱 알림 메시지 저장. 중보기도 요청·참여·댓글·응답·그룹 초대 등 알림 내용을 관리합니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),  -- 알림 고유 식별자
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                                                     -- 알림 수신자 사용자 ID (외래키)
    type VARCHAR(50) NOT NULL CHECK (type IN ('intercession_request', 'prayer_participation', 'comment', 'prayer_answered', 'group_invite')),
                                                     -- 알림 유형 (중보요청/기도참여/댓글/응답/그룹초대)
    related_id UUID,                                 -- 알림 연관 대상 ID (기도/댓글/그룹 등)
    title VARCHAR(255) NOT NULL,                     -- 알림 제목
    message TEXT,                                    -- 알림 상세 메시지
    is_read BOOLEAN DEFAULT false NOT NULL,          -- 읽음 여부 (true=읽음, false=미읽음)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL   -- 알림 생성 일시
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- ============================================================
-- 10. NOTIFICATION_PREFERENCES 테이블
-- 역할: 사용자별 알림 설정 저장. 각 알림 유형을 개별적으로 ON/OFF 할 수 있습니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),  -- 알림 설정 고유 식별자
    user_id UUID UNIQUE NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                                                     -- 설정 대상 사용자 ID (1인 1설정, 외래키)
    all_notifications_enabled BOOLEAN DEFAULT true NOT NULL,
                                                     -- 전체 알림 활성화 여부
    intercession_request BOOLEAN DEFAULT true NOT NULL,
                                                     -- 중보기도 요청 알림 수신 여부
    prayer_participation BOOLEAN DEFAULT true NOT NULL,
                                                     -- 기도 참여 알림 수신 여부
    comment_notification BOOLEAN DEFAULT true NOT NULL,
                                                     -- 댓글 알림 수신 여부
    prayer_answered BOOLEAN DEFAULT true NOT NULL,   -- 기도 응답 알림 수신 여부
    group_notification BOOLEAN DEFAULT false NOT NULL,
                                                     -- 그룹 알림 수신 여부 (기본 OFF)
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL   -- 설정 마지막 수정 일시
);

-- ============================================================
-- 11. COVENANT_CHECKINS 테이블
-- 역할: 언약기도 일별 체크인 기록. 며칠째 언약을 지키고 있는지 추적합니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.covenant_checkins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),  -- 체크인 고유 식별자
    prayer_id UUID NOT NULL REFERENCES public.prayers(id) ON DELETE CASCADE,
                                                     -- 언약기도 대상 기도제목 ID (외래키)
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                                                     -- 체크인한 사용자 ID (외래키)
    day INTEGER NOT NULL,                            -- 체크인 일차 (1일차, 2일차 ...)
    checked_in_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
                                                     -- 체크인 일시
    UNIQUE(prayer_id, user_id, day)                  -- 같은 기도·같은 사용자·같은 일차 중복 불가
);

CREATE INDEX IF NOT EXISTS idx_covenant_checkins_prayer_id ON public.covenant_checkins(prayer_id);
CREATE INDEX IF NOT EXISTS idx_covenant_checkins_user_id ON public.covenant_checkins(user_id);

-- ============================================================
-- 12. BLOCKED_USERS 테이블
-- 역할: 사용자 차단 목록. 차단된 사용자의 기도·댓글이 노출되지 않도록 합니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.blocked_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),  -- 차단 기록 고유 식별자
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                                                     -- 차단을 실행한 사용자 ID (외래키)
    blocked_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                                                     -- 차단 대상 사용자 ID (외래키)
    reason TEXT,                                     -- 차단 사유 (선택 입력)
    blocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
                                                     -- 차단 실행 일시
    UNIQUE(user_id, blocked_user_id)                 -- 동일 사용자 중복 차단 불가
);

CREATE INDEX IF NOT EXISTS idx_blocked_users_user_id ON public.blocked_users(user_id);

-- ============================================================
-- 13. REPORTS 테이블
-- 역할: 신고 접수 기록. 부적절한 기도·댓글·사용자에 대한 신고를 저장하고 검토 상태를 관리합니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),  -- 신고 고유 식별자
    reporter_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
                                                     -- 신고자 사용자 ID (탈퇴 시 NULL, 외래키)
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN ('prayer', 'comment', 'user')),
                                                     -- 신고 대상 유형 (prayer=기도, comment=댓글, user=사용자)
    related_id UUID NOT NULL,                        -- 신고 대상의 실제 ID (기도/댓글/사용자 ID)
    reason TEXT NOT NULL,                            -- 신고 사유 (필수)
    description TEXT,                                -- 신고 상세 설명 (선택)
    status VARCHAR(20) DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'reviewed', 'resolved')),
                                                     -- 신고 처리 상태 (pending=접수대기, reviewed=검토중, resolved=처리완료)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,  -- 신고 접수 일시
    reviewed_at TIMESTAMP WITH TIME ZONE             -- 신고 검토 완료 일시
);

CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON public.reports(created_at DESC);

-- ============================================================
-- 14. USER_STATISTICS 테이블
-- 역할: 사용자별 기도 통계 집계. 대시보드에서 빠르게 통계를 표시하기 위한 캐시 테이블입니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_statistics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),  -- 통계 레코드 고유 식별자
    user_id UUID UNIQUE NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                                                     -- 통계 대상 사용자 ID (1인 1레코드, 외래키)
    total_prayers INTEGER DEFAULT 0 NOT NULL,        -- 작성한 총 기도제목 수
    answered_prayers INTEGER DEFAULT 0 NOT NULL,     -- 응답받은 기도 수
    grateful_prayers INTEGER DEFAULT 0 NOT NULL,     -- 감사 상태로 전환된 기도 수
    total_participations INTEGER DEFAULT 0 NOT NULL, -- 타인 기도에 참여한 총 횟수
    total_comments INTEGER DEFAULT 0 NOT NULL,       -- 작성한 총 댓글 수
    streak_days INTEGER DEFAULT 0 NOT NULL,          -- 연속 기도 일수 (스트릭)
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL   -- 통계 마지막 갱신 일시
);

-- ============================================================
-- 15. PRAYER_ANSWERS 테이블
-- 역할: 기도 응답 간증문 저장.
--       기도가 응답받았을 때 작성자가 간증을 남기는 테이블.
--       기도 1개당 간증 1개 제한 (prayer_id UNIQUE).
--       등록 시 해당 prayers.status 가 'answered' 로 자동 변경됩니다.
--       공개 범위(scope)에 따라 다른 사용자에게 노출됩니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.prayer_answers (
    id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- 기도 응답 간증 고유 식별자

    prayer_id  UUID        UNIQUE NOT NULL REFERENCES public.prayers(id) ON DELETE CASCADE,
    -- 응답받은 기도제목 ID (외래키 → prayers.id).
    -- UNIQUE 제약으로 기도 1개당 간증 1개만 허용.
    -- 기도 삭제 시 간증도 함께 삭제.

    user_id    UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    -- 간증 작성자 사용자 ID (외래키 → users.id).
    -- 백엔드에서 prayer.user_id == userId 일 때만 등록 허용 (본인 기도만 간증 가능).

    content    TEXT,
    -- 간증 내용 (선택). NULL 허용 → 내용 없이 응답 상태만 기록할 때 사용.

    scope      VARCHAR(20) NOT NULL DEFAULT 'public'
               CHECK (scope IN ('public', 'group', 'private')),
    -- 공개 범위.
    --   'public'  : 전체 공개 (응답 피드에 노출, 기본값)
    --   'group'   : 그룹 공개
    --   'private' : 나만 볼 수 있음 (댓글 달기 불가)

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- 간증 최초 작성 일시

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    -- 간증 마지막 수정 일시 (트리거로 자동 갱신)
);

CREATE INDEX IF NOT EXISTS idx_prayer_answers_prayer_id ON public.prayer_answers(prayer_id);
-- prayer_id 기준 단일 조회 최적화

CREATE INDEX IF NOT EXISTS idx_prayer_answers_user_id ON public.prayer_answers(user_id);
-- 사용자별 작성 간증 목록 조회 최적화

CREATE INDEX IF NOT EXISTS idx_prayer_answers_scope ON public.prayer_answers(scope);
-- 공개 범위 필터링 최적화

CREATE INDEX IF NOT EXISTS idx_prayer_answers_created_at ON public.prayer_answers(created_at DESC);
-- 최신순 피드 정렬 최적화

-- ============================================================
-- 16. PRAYER_ANSWER_COMMENTS 테이블
-- 역할: 기도 응답 간증에 달리는 축하·감동 댓글 저장.
--       비공개(scope='private') 간증에는 댓글을 달 수 없으며,
--       백엔드에서 scope 확인 후 403 을 반환합니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.prayer_answer_comments (
    id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- 댓글 고유 식별자

    answer_id  UUID        NOT NULL REFERENCES public.prayer_answers(id) ON DELETE CASCADE,
    -- 댓글이 달린 기도 응답 간증 ID (외래키 → prayer_answers.id).
    -- 간증 삭제 시 댓글도 함께 삭제.

    user_id    UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    -- 댓글 작성자 사용자 ID (외래키 → users.id).
    -- 탈퇴 시 댓글도 함께 삭제.

    content    TEXT        NOT NULL,
    -- 댓글 내용 (빈 문자열 불가, 백엔드에서 trim 후 저장).
    -- 예: "할렐루야! 기도 응답 감사해요 🙏"

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    -- 댓글 작성 일시 (수정 기능 없음 → updated_at 없음)
);

CREATE INDEX IF NOT EXISTS idx_prayer_answer_comments_answer_id ON public.prayer_answer_comments(answer_id);
-- 간증별 댓글 목록 조회 최적화

CREATE INDEX IF NOT EXISTS idx_prayer_answer_comments_user_id ON public.prayer_answer_comments(user_id);
-- 사용자별 작성 댓글 조회 최적화

CREATE INDEX IF NOT EXISTS idx_prayer_answer_comments_created_at ON public.prayer_answer_comments(created_at ASC);
-- 오래된 순(등록순) 정렬 최적화

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

-- ============================================================
-- ※ 아래 6개 테이블은 감사일기 기능 및 기도 응답 간증 기능에 필요한
--   추가 테이블입니다. schema.sql 초기 버전에 누락되었으므로
--   Supabase SQL Editor 에서 이 블록을 별도로 실행해주세요.
-- ============================================================


-- ============================================================
-- 17. GRATITUDE_JOURNALS 테이블
-- 역할: 감사일기 본문 저장.
--       사용자가 매일 최대 3가지 감사 항목을 기록하는 핵심 테이블.
--       하루 1개 제한(user_id + journal_date UNIQUE)이며,
--       같은 날 재등록 시 upsert(덮어쓰기)로 처리됩니다.
--       공개 범위(scope)에 따라 그룹/팔로우/전체 피드에 노출됩니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.gratitude_journals (
    id               UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- 감사일기 고유 식별자 (UUID, 자동 생성)

    user_id          UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    -- 작성자 사용자 ID (외래키 → users.id, 탈퇴 시 일기도 함께 삭제)

    journal_date     DATE        NOT NULL,
    -- 일기 날짜 (YYYY-MM-DD). 미래 날짜 입력 불가, 과거 날짜 소급 입력 허용.
    -- user_id 와 함께 UNIQUE 제약 → 하루 1개 제한

    gratitude_1      TEXT        NOT NULL,
    -- 첫 번째 감사 항목 (필수 입력). 예: "오늘 맛있는 밥을 먹었다"

    gratitude_2      TEXT,
    -- 두 번째 감사 항목 (선택). NULL 허용.

    gratitude_3      TEXT,
    -- 세 번째 감사 항목 (선택). NULL 허용.

    emotion          VARCHAR(20),
    -- 오늘의 감정 태그. 'joy'(기쁨) | 'peace'(평안) | 'moved'(감동) | 'thankful'(감사) | NULL

    linked_prayer_id UUID        REFERENCES public.prayers(id) ON DELETE SET NULL,
    -- 연결된 기도제목 ID (선택). 이 일기와 관련된 기도를 연결할 때 사용.
    -- 기도가 삭제되면 NULL 로 자동 변경 (ON DELETE SET NULL)

    scope            VARCHAR(20) NOT NULL DEFAULT 'private'
                     CHECK (scope IN ('private', 'group', 'public')),
    -- 공개 범위.
    --   'private' : 나만 볼 수 있음 (기본값, 피드 미노출)
    --   'group'   : 내가 속한 그룹 멤버에게 노출
    --   'public'  : 전체 공개 (팔로우·전체 탭 피드에도 노출)

    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- 레코드 최초 생성 일시 (UTC)

    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- 마지막 수정 일시 (updated_at 트리거로 자동 갱신)

    UNIQUE (user_id, journal_date)
    -- 동일 사용자가 같은 날 중복 작성 불가 (upsert 충돌 키)
);

CREATE INDEX IF NOT EXISTS idx_gratitude_journals_user_id
    ON public.gratitude_journals(user_id);
-- user_id 기준 내 일기 목록 조회 최적화

CREATE INDEX IF NOT EXISTS idx_gratitude_journals_journal_date
    ON public.gratitude_journals(journal_date DESC);
-- 날짜 기준 정렬·캘린더 조회 최적화

CREATE INDEX IF NOT EXISTS idx_gratitude_journals_scope
    ON public.gratitude_journals(scope);
-- 공개 범위 필터링 최적화 (피드 조회 시 scope != 'private' 조건)

CREATE INDEX IF NOT EXISTS idx_gratitude_journals_created_at
    ON public.gratitude_journals(created_at DESC);
-- 피드 최신순 정렬 최적화


-- ============================================================
-- 18. GRATITUDE_REACTIONS 테이블
-- 역할: 감사일기에 대한 반응(은혜 / 공감) 저장.
--       한 사용자가 한 일기에 같은 반응 타입을 중복으로 남길 수 없으며,
--       재클릭 시 반응이 취소(toggle)됩니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.gratitude_reactions (
    id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- 반응 레코드 고유 식별자

    journal_id    UUID        NOT NULL REFERENCES public.gratitude_journals(id) ON DELETE CASCADE,
    -- 반응 대상 감사일기 ID (외래키 → gratitude_journals.id, 일기 삭제 시 반응도 함께 삭제)

    user_id       UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    -- 반응한 사용자 ID (외래키 → users.id, 탈퇴 시 반응도 함께 삭제)

    reaction_type VARCHAR(20) NOT NULL CHECK (reaction_type IN ('grace', 'empathy')),
    -- 반응 종류.
    --   'grace'   : 은혜 반응 (✨ 은혜)
    --   'empathy' : 공감 반응 (🤝 공감)

    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- 반응 생성 일시

    UNIQUE (journal_id, user_id, reaction_type)
    -- 같은 사용자가 같은 일기에 같은 반응 중복 불가 (toggle 충돌 키)
);

CREATE INDEX IF NOT EXISTS idx_gratitude_reactions_journal_id
    ON public.gratitude_reactions(journal_id);
-- 일기별 반응 수 집계 최적화

CREATE INDEX IF NOT EXISTS idx_gratitude_reactions_user_id
    ON public.gratitude_reactions(user_id);
-- 사용자가 반응한 일기 목록 조회 최적화


-- ============================================================
-- 19. GRATITUDE_COMMENTS 테이블
-- 역할: 감사일기에 달리는 응원·공감 댓글 저장.
--       기도제목의 comments 테이블과 별개로 감사일기 전용으로 관리됩니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.gratitude_comments (
    id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- 댓글 고유 식별자

    journal_id UUID        NOT NULL REFERENCES public.gratitude_journals(id) ON DELETE CASCADE,
    -- 댓글이 달린 감사일기 ID (외래키 → gratitude_journals.id, 일기 삭제 시 댓글도 삭제)

    user_id    UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    -- 댓글 작성자 사용자 ID (외래키 → users.id, 탈퇴 시 댓글도 삭제)

    content    TEXT        NOT NULL,
    -- 댓글 내용 (빈 문자열 불가, 백엔드에서 trim 후 저장)

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- 댓글 작성 일시

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    -- 댓글 수정 일시 (수정 기능 구현 시 트리거로 자동 갱신)
);

CREATE INDEX IF NOT EXISTS idx_gratitude_comments_journal_id
    ON public.gratitude_comments(journal_id);
-- 일기별 댓글 목록 조회 최적화

CREATE INDEX IF NOT EXISTS idx_gratitude_comments_user_id
    ON public.gratitude_comments(user_id);
-- 사용자별 작성 댓글 조회 최적화

CREATE INDEX IF NOT EXISTS idx_gratitude_comments_created_at
    ON public.gratitude_comments(created_at ASC);
-- 댓글 오래된 순(등록순) 정렬 최적화


-- ============================================================
-- 20. GRATITUDE_STREAKS 테이블
-- 역할: 감사일기 연속 작성 기록(스트릭) 저장.
--       일기를 작성할 때마다 updateStreak() 함수가 자동으로 갱신합니다.
--       당일 재수정(upsert)은 카운트를 올리지 않으며,
--       전날 대비 하루라도 빠지면 current_streak 이 1로 초기화됩니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.gratitude_streaks (
    id                UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- 스트릭 레코드 고유 식별자

    user_id           UUID        UNIQUE NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    -- 사용자 ID (외래키 → users.id). 1인 1레코드 (UNIQUE).
    -- 탈퇴 시 스트릭 기록도 함께 삭제.

    current_streak    INTEGER     NOT NULL DEFAULT 0,
    -- 현재 연속 작성 일수.
    -- 예: 오늘까지 7일 연속 작성 중 → 7
    -- 하루라도 빠지면 0 → 1 로 초기화.

    longest_streak    INTEGER     NOT NULL DEFAULT 0,
    -- 역대 최장 연속 작성 일수.
    -- current_streak 가 갱신될 때 함께 비교·업데이트.

    last_journal_date DATE,
    -- 가장 마지막으로 감사일기를 작성한 날짜 (YYYY-MM-DD).
    -- 연속 여부 판단 기준: 오늘 날짜 - last_journal_date = 1 이면 연속.

    total_count       INTEGER     NOT NULL DEFAULT 0,
    -- 누적 감사일기 작성 횟수 (당일 재수정은 카운트 제외).

    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
    -- 스트릭 마지막 갱신 일시
);

CREATE INDEX IF NOT EXISTS idx_gratitude_streaks_user_id
    ON public.gratitude_streaks(user_id);
-- user_id 기준 단일 조회 최적화 (이미 UNIQUE 이지만 명시적으로 추가)


-- ============================================================
-- ※ 21번 PRAYER_ANSWERS 와 22번 PRAYER_ANSWER_COMMENTS 는
--   schema.sql 15·16번에 이미 정의되어 있습니다.
--   아래는 필드 Description 이 보강된 최신 버전입니다.
--   Supabase 에 테이블이 없을 경우에만 실행하세요.
-- 21. PRAYER_ANSWERS 테이블
-- 역할: 기도 응답 간증문 저장.
--       기도가 응답받았을 때 작성자가 간증을 남기는 테이블.
--       기도 1개당 간증 1개 제한 (prayer_id UNIQUE).
--       등록 시 해당 prayers.status 가 'answered' 로 자동 변경됩니다.
--       공개 범위(scope)에 따라 다른 사용자에게 노출됩니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.prayer_answers (
    id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- 기도 응답 간증 고유 식별자

    prayer_id  UUID        UNIQUE NOT NULL REFERENCES public.prayers(id) ON DELETE CASCADE,
    -- 응답받은 기도제목 ID (외래키 → prayers.id).
    -- UNIQUE 제약으로 기도 1개당 간증 1개만 허용.
    -- 기도 삭제 시 간증도 함께 삭제.

    user_id    UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    -- 간증 작성자 사용자 ID (외래키 → users.id).
    -- 백엔드에서 prayer.user_id == userId 일 때만 등록 허용 (본인 기도만 간증 가능).

    content    TEXT,
    -- 간증 내용 (선택). NULL 허용 → 내용 없이 응답 상태만 기록할 때 사용.

    scope      VARCHAR(20) NOT NULL DEFAULT 'public'
               CHECK (scope IN ('public', 'group', 'private')),
    -- 공개 범위.
    --   'public'  : 전체 공개 (응답 피드에 노출, 기본값)
    --   'group'   : 그룹 공개
    --   'private' : 나만 볼 수 있음 (댓글 달기 불가)

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- 간증 최초 작성 일시

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    -- 간증 마지막 수정 일시 (트리거로 자동 갱신)
);

CREATE INDEX IF NOT EXISTS idx_prayer_answers_prayer_id
    ON public.prayer_answers(prayer_id);
-- prayer_id 기준 단일 조회 최적화 (이미 UNIQUE 이지만 명시적으로 추가)

CREATE INDEX IF NOT EXISTS idx_prayer_answers_user_id
    ON public.prayer_answers(user_id);
-- 사용자별 작성 간증 목록 조회 최적화

CREATE INDEX IF NOT EXISTS idx_prayer_answers_scope
    ON public.prayer_answers(scope);
-- 공개 범위 필터링 최적화 (피드 조회 시 scope = 'public' 조건)

CREATE INDEX IF NOT EXISTS idx_prayer_answers_created_at
    ON public.prayer_answers(created_at DESC);
-- 최신순 피드 정렬 최적화


-- ============================================================
-- 22. PRAYER_ANSWER_COMMENTS 테이블
-- 역할: 기도 응답 간증에 달리는 축하·감동 댓글 저장.
--       비공개(scope='private') 간증에는 댓글을 달 수 없으며,
--       백엔드에서 scope 확인 후 403 을 반환합니다.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.prayer_answer_comments (
    id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- 댓글 고유 식별자

    answer_id  UUID        NOT NULL REFERENCES public.prayer_answers(id) ON DELETE CASCADE,
    -- 댓글이 달린 기도 응답 간증 ID (외래키 → prayer_answers.id).
    -- 간증 삭제 시 댓글도 함께 삭제.

    user_id    UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    -- 댓글 작성자 사용자 ID (외래키 → users.id).
    -- 탈퇴 시 댓글도 함께 삭제.

    content    TEXT        NOT NULL,
    -- 댓글 내용 (빈 문자열 불가, 백엔드에서 trim 후 저장).
    -- 예: "할렐루야! 기도 응답 감사해요 🙏"

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    -- 댓글 작성 일시 (수정 기능 없음 → updated_at 없음)
);

CREATE INDEX IF NOT EXISTS idx_prayer_answer_comments_answer_id
    ON public.prayer_answer_comments(answer_id);
-- 간증별 댓글 목록 조회 최적화

CREATE INDEX IF NOT EXISTS idx_prayer_answer_comments_user_id
    ON public.prayer_answer_comments(user_id);
-- 사용자별 작성 댓글 조회 최적화

CREATE INDEX IF NOT EXISTS idx_prayer_answer_comments_created_at
    ON public.prayer_answer_comments(created_at ASC);
-- 오래된 순(등록순) 정렬 최적화


-- ============================================================
-- updated_at 자동 갱신 트리거 (신규 테이블)
-- ============================================================
CREATE OR REPLACE TRIGGER update_gratitude_journals_updated_at
    BEFORE UPDATE ON public.gratitude_journals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER update_gratitude_comments_updated_at
    BEFORE UPDATE ON public.gratitude_comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER update_gratitude_streaks_updated_at
    BEFORE UPDATE ON public.gratitude_streaks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER update_prayer_answers_updated_at
    BEFORE UPDATE ON public.prayer_answers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
