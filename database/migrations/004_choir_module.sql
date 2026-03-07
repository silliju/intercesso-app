-- ============================================================
-- 성가대 모듈 마이그레이션 (004_choir_module.sql)
-- 교회 성가대 관리 시스템
-- ============================================================

-- 1. 교회(성가대) 테이블
CREATE TABLE IF NOT EXISTS public.choirs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,                          -- 성가대 이름
  church_name TEXT NOT NULL,                   -- 교회 이름
  description TEXT,                            -- 소개
  invite_code VARCHAR(10) UNIQUE NOT NULL,     -- 초대 코드 (6자리 대문자+숫자)
  invite_link_active BOOLEAN DEFAULT true,     -- 초대 링크 활성화 여부
  owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  member_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_choirs_owner_id ON public.choirs(owner_id);
CREATE INDEX IF NOT EXISTS idx_choirs_invite_code ON public.choirs(invite_code);

-- 2. 성가대 멤버 테이블
-- 역할: treasurer(총무/전체관리), conductor(지휘자/곡+일정), section_leader(파트장/출석체크), member(단원/조회만)
CREATE TABLE IF NOT EXISTS public.choir_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  choir_id UUID NOT NULL REFERENCES public.choirs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role VARCHAR(20) DEFAULT 'member' NOT NULL CHECK (role IN ('treasurer', 'conductor', 'section_leader', 'member')),
  section VARCHAR(50),                         -- 파트 (soprano, alto, tenor, bass, etc.)
  status VARCHAR(20) DEFAULT 'active' NOT NULL CHECK (status IN ('pending', 'active', 'inactive')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  UNIQUE(choir_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_choir_members_choir_id ON public.choir_members(choir_id);
CREATE INDEX IF NOT EXISTS idx_choir_members_user_id ON public.choir_members(user_id);

-- 3. 성가대 일정 테이블
CREATE TABLE IF NOT EXISTS public.choir_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  choir_id UUID NOT NULL REFERENCES public.choirs(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  schedule_type VARCHAR(30) DEFAULT 'rehearsal' NOT NULL CHECK (schedule_type IN (
    'pre_service_practice',   -- 예배 전 연습
    'service',                -- 예배 찬양
    'post_service_practice',  -- 예배 후 연습
    'weekday_practice',       -- 주중 연습
    'special_event'           -- 특별 행사
  )),
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  location TEXT,
  is_recurring BOOLEAN DEFAULT false,
  recurrence_rule TEXT,                        -- RRULE 형식 (weekly, biweekly 등)
  recurrence_end_date DATE,
  notify_before_minutes INTEGER DEFAULT 60,    -- 알림 시간 (분 전)
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_choir_schedules_choir_id ON public.choir_schedules(choir_id);
CREATE INDEX IF NOT EXISTS idx_choir_schedules_start_time ON public.choir_schedules(start_time);

-- 4. 출석 기록 테이블
CREATE TABLE IF NOT EXISTS public.choir_attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  schedule_id UUID NOT NULL REFERENCES public.choir_schedules(id) ON DELETE CASCADE,
  choir_id UUID NOT NULL REFERENCES public.choirs(id) ON DELETE CASCADE,
  member_id UUID NOT NULL REFERENCES public.choir_members(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'absent' NOT NULL CHECK (status IN ('present', 'absent', 'excused')),
  note TEXT,
  checked_by UUID REFERENCES public.users(id),  -- 출석 체크한 파트장
  checked_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  UNIQUE(schedule_id, member_id)
);
CREATE INDEX IF NOT EXISTS idx_choir_attendance_schedule_id ON public.choir_attendance(schedule_id);
CREATE INDEX IF NOT EXISTS idx_choir_attendance_choir_id ON public.choir_attendance(choir_id);
CREATE INDEX IF NOT EXISTS idx_choir_attendance_user_id ON public.choir_attendance(user_id);

-- 5. 찬양곡 테이블
CREATE TABLE IF NOT EXISTS public.choir_songs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  choir_id UUID NOT NULL REFERENCES public.choirs(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  composer TEXT,
  arranger TEXT,
  parts TEXT[],                                -- ['soprano', 'alto', 'tenor', 'bass']
  youtube_url TEXT,
  genre TEXT,                                  -- 찬송가, CCM, 클래식 등
  difficulty VARCHAR(10) CHECK (difficulty IN ('easy', 'medium', 'hard')),
  notes TEXT,
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_choir_songs_choir_id ON public.choir_songs(choir_id);

-- 6. 일정-찬양곡 연결 테이블 (한 일정에 여러 곡)
CREATE TABLE IF NOT EXISTS public.choir_schedule_songs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  schedule_id UUID NOT NULL REFERENCES public.choir_schedules(id) ON DELETE CASCADE,
  song_id UUID NOT NULL REFERENCES public.choir_songs(id) ON DELETE CASCADE,
  order_index INTEGER DEFAULT 0,
  UNIQUE(schedule_id, song_id)
);
CREATE INDEX IF NOT EXISTS idx_choir_schedule_songs_schedule_id ON public.choir_schedule_songs(schedule_id);

-- 7. 공지사항 테이블
CREATE TABLE IF NOT EXISTS public.choir_notices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  choir_id UUID NOT NULL REFERENCES public.choirs(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES public.users(id),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  target_section TEXT,                         -- NULL이면 전체, 특정 파트면 해당 파트만
  is_pinned BOOLEAN DEFAULT false,
  push_sent BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_choir_notices_choir_id ON public.choir_notices(choir_id);
CREATE INDEX IF NOT EXISTS idx_choir_notices_pinned ON public.choir_notices(is_pinned) WHERE is_pinned = true;

-- 8. members count 자동 업데이트 함수
CREATE OR REPLACE FUNCTION update_choir_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.status = 'active' THEN
    UPDATE public.choirs SET member_count = member_count + 1 WHERE id = NEW.choir_id;
  ELSIF TG_OP = 'DELETE' AND OLD.status = 'active' THEN
    UPDATE public.choirs SET member_count = GREATEST(member_count - 1, 0) WHERE id = OLD.choir_id;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.status != 'active' AND NEW.status = 'active' THEN
      UPDATE public.choirs SET member_count = member_count + 1 WHERE id = NEW.choir_id;
    ELSIF OLD.status = 'active' AND NEW.status != 'active' THEN
      UPDATE public.choirs SET member_count = GREATEST(member_count - 1, 0) WHERE id = NEW.choir_id;
    END IF;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_choir_member_count
AFTER INSERT OR UPDATE OR DELETE ON public.choir_members
FOR EACH ROW EXECUTE FUNCTION update_choir_member_count();

