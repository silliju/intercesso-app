-- ============================================================
-- 찬양대 모듈 v2 마이그레이션 (006_choir_module_v2.sql)
-- 기존 004_choir_module.sql 에서 누락된 테이블/컬럼 추가
-- 작성일: 2026-03-10
-- ============================================================

-- ============================================================
-- 1. choirs 테이블 컬럼 추가 (기존 테이블 확장)
-- ============================================================
ALTER TABLE public.choirs
  ADD COLUMN IF NOT EXISTS image_url TEXT,                          -- 찬양대 대표 이미지
  ADD COLUMN IF NOT EXISTS worship_types TEXT[] DEFAULT '{}',       -- 활동 예배 유형 ['주일예배','헌신예배','부흥회']
  ADD COLUMN IF NOT EXISTS practice_schedule TEXT,                  -- 정기 연습 일정 (예: 매주 목요일 오후 7시)
  ADD COLUMN IF NOT EXISTS practice_location TEXT,                  -- 연습 장소
  ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT true,          -- 교회 검색 노출 여부
  ADD COLUMN IF NOT EXISTS allow_join_request BOOLEAN DEFAULT true, -- 초대 없이 가입 신청 허용
  ADD COLUMN IF NOT EXISTS require_approval BOOLEAN DEFAULT true,   -- 관리자 승인 필요 여부
  ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active'      -- 찬양대 상태
    CHECK (status IN ('active', 'inactive', 'disbanded'));

-- ============================================================
-- 2. choir_members 테이블 컬럼 추가
-- ============================================================
ALTER TABLE public.choir_members
  ADD COLUMN IF NOT EXISTS position VARCHAR(30),                    -- 직책 (대장,총무,서기,회계,악보장,파트장,지휘자,반주자)
  ADD COLUMN IF NOT EXISTS phone TEXT,                              -- 연락처
  ADD COLUMN IF NOT EXISTS note TEXT,                               -- 관리자 메모
  ADD COLUMN IF NOT EXISTS receive_notification BOOLEAN DEFAULT true, -- 공지 수신 여부
  ADD COLUMN IF NOT EXISTS invite_id UUID,                          -- 가입에 사용한 초대 ID
  ADD COLUMN IF NOT EXISTS join_method VARCHAR(20) DEFAULT 'invite' -- 가입 경로
    CHECK (join_method IN ('invite_link', 'invite_code', 'search', 'admin_add'));

-- role 컬럼 CHECK 제약 업데이트 (직책 추가)
ALTER TABLE public.choir_members
  DROP CONSTRAINT IF EXISTS choir_members_role_check;
ALTER TABLE public.choir_members
  ADD CONSTRAINT choir_members_role_check
  CHECK (role IN ('owner', 'admin', 'section_leader', 'member'));

-- ============================================================
-- 3. choir_schedules 테이블 컬럼 추가
-- ============================================================
ALTER TABLE public.choir_schedules
  ADD COLUMN IF NOT EXISTS worship_type VARCHAR(30),                -- 예배 종류 (주일예배, 헌신예배 등)
  ADD COLUMN IF NOT EXISTS conductor_id UUID REFERENCES public.users(id), -- 지휘자
  ADD COLUMN IF NOT EXISTS accompanist_id UUID REFERENCES public.users(id), -- 반주자
  ADD COLUMN IF NOT EXISTS practice_notice TEXT,                    -- 연습 공지 내용
  ADD COLUMN IF NOT EXISTS is_confirmed BOOLEAN DEFAULT false,      -- 일정 확정 여부
  ADD COLUMN IF NOT EXISTS confirmed_at TIMESTAMP WITH TIME ZONE,   -- 확정 시각
  ADD COLUMN IF NOT EXISTS push_sent BOOLEAN DEFAULT false;         -- 푸시 발송 여부

-- schedule_type CHECK 업데이트
ALTER TABLE public.choir_schedules
  DROP CONSTRAINT IF EXISTS choir_schedules_schedule_type_check;
ALTER TABLE public.choir_schedules
  ADD CONSTRAINT choir_schedules_schedule_type_check
  CHECK (schedule_type IN (
    'sunday_service',       -- 주일예배
    'dedication_service',   -- 헌신예배
    'revival',              -- 부흥회
    'special_service',      -- 특별예배
    'wednesday_service',    -- 수요예배
    'dawn_service',         -- 새벽예배
    'weekday_practice',     -- 주중 연습
    'special_event'         -- 특별 행사
  ));

-- ============================================================
-- 4. choir_songs 테이블 컬럼 추가
-- ============================================================
ALTER TABLE public.choir_songs
  ADD COLUMN IF NOT EXISTS hymn_book TEXT,                          -- 찬양집명 (찬양집 Vol.3 등)
  ADD COLUMN IF NOT EXISTS hymn_number TEXT,                        -- 찬양집 번호
  ADD COLUMN IF NOT EXISTS youtube_part_urls JSONB DEFAULT '{}',    -- 파트별 유튜브 {"soprano":"url","alto":"url"}
  ADD COLUMN IF NOT EXISTS score_urls JSONB DEFAULT '{}',           -- 악보 파일 URL {"full":"url","soprano":"url"}
  ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';                -- 태그

-- ============================================================
-- 5. choir_invites 테이블 (초대 링크/코드 관리)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.choir_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  choir_id UUID NOT NULL REFERENCES public.choirs(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES public.users(id),
  invite_code VARCHAR(10) UNIQUE NOT NULL,                          -- 초대 코드 (6자리)
  invite_link TEXT UNIQUE,                                          -- 초대 링크 전체 URL
  target_section VARCHAR(50),                                       -- 특정 파트 초대 (NULL=전체)
  max_uses INTEGER DEFAULT NULL,                                    -- 최대 사용 횟수 (NULL=무제한)
  used_count INTEGER DEFAULT 0,                                     -- 사용된 횟수
  expires_at TIMESTAMP WITH TIME ZONE,                             -- 만료 시각 (NULL=무제한)
  is_active BOOLEAN DEFAULT true,                                   -- 활성화 여부
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_choir_invites_choir_id ON public.choir_invites(choir_id);
CREATE INDEX IF NOT EXISTS idx_choir_invites_code ON public.choir_invites(invite_code);

-- ============================================================
-- 6. choir_join_requests 테이블 (가입 신청 관리)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.choir_join_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  choir_id UUID NOT NULL REFERENCES public.choirs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  invite_id UUID REFERENCES public.choir_invites(id),
  requested_section VARCHAR(50),                                    -- 신청한 파트
  join_method VARCHAR(20) DEFAULT 'invite_code'
    CHECK (join_method IN ('invite_link', 'invite_code', 'search')),
  status VARCHAR(20) DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by UUID REFERENCES public.users(id),                    -- 승인/거절한 관리자
  reviewed_at TIMESTAMP WITH TIME ZONE,
  reject_reason TEXT,                                               -- 거절 사유
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  UNIQUE(choir_id, user_id)                                         -- 중복 신청 방지
);
CREATE INDEX IF NOT EXISTS idx_choir_join_requests_choir_id ON public.choir_join_requests(choir_id);
CREATE INDEX IF NOT EXISTS idx_choir_join_requests_user_id ON public.choir_join_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_choir_join_requests_status ON public.choir_join_requests(status);

-- ============================================================
-- 7. choir_materials 테이블 (자료실 - 악보/영상/파일)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.choir_materials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  choir_id UUID NOT NULL REFERENCES public.choirs(id) ON DELETE CASCADE,
  schedule_id UUID REFERENCES public.choir_schedules(id) ON DELETE SET NULL, -- 연결된 일정
  song_id UUID REFERENCES public.choir_songs(id) ON DELETE SET NULL,         -- 연결된 찬양곡
  uploaded_by UUID NOT NULL REFERENCES public.users(id),
  title TEXT NOT NULL,                                              -- 자료명
  description TEXT,                                                 -- 설명
  material_type VARCHAR(20) NOT NULL
    CHECK (material_type IN ('score', 'video_link', 'audio', 'document', 'image', 'other')),
  file_url TEXT,                                                    -- 파일 URL (Supabase Storage)
  youtube_url TEXT,                                                 -- 유튜브 링크
  external_url TEXT,                                                -- 외부 링크
  file_size_bytes BIGINT,                                          -- 파일 크기
  file_type VARCHAR(20),                                           -- 파일 확장자 (pdf, jpg, mp3 등)
  target_section VARCHAR(50),                                       -- 대상 파트 (NULL=전체)
  download_count INTEGER DEFAULT 0,                                 -- 다운로드 횟수
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_choir_materials_choir_id ON public.choir_materials(choir_id);
CREATE INDEX IF NOT EXISTS idx_choir_materials_schedule_id ON public.choir_materials(schedule_id);
CREATE INDEX IF NOT EXISTS idx_choir_materials_type ON public.choir_materials(material_type);

-- ============================================================
-- 8. choir_attendance 테이블 컬럼 추가
-- ============================================================
ALTER TABLE public.choir_attendance
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- ============================================================
-- 9. choir_parts 테이블 (파트 구성 관리)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.choir_parts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  choir_id UUID NOT NULL REFERENCES public.choirs(id) ON DELETE CASCADE,
  part_name VARCHAR(50) NOT NULL,                                   -- 파트명 (소프라노, 알토, 테너, 베이스 등)
  part_key VARCHAR(30) NOT NULL,                                    -- 시스템 키 (soprano, alto, tenor, bass)
  color_hex VARCHAR(7) DEFAULT '#2f6fed',                          -- 파트 색상
  target_count INTEGER DEFAULT 0,                                   -- 목표 인원
  display_order INTEGER DEFAULT 0,                                  -- 표시 순서
  is_active BOOLEAN DEFAULT true,
  UNIQUE(choir_id, part_key)
);
CREATE INDEX IF NOT EXISTS idx_choir_parts_choir_id ON public.choir_parts(choir_id);

-- ============================================================
-- 10. updated_at 자동 업데이트 트리거 추가
-- ============================================================

-- choirs
CREATE OR REPLACE TRIGGER trigger_choirs_updated_at
  BEFORE UPDATE ON public.choirs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- choir_schedules
CREATE OR REPLACE TRIGGER trigger_choir_schedules_updated_at
  BEFORE UPDATE ON public.choir_schedules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- choir_songs
CREATE OR REPLACE TRIGGER trigger_choir_songs_updated_at
  BEFORE UPDATE ON public.choir_songs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- choir_notices
CREATE OR REPLACE TRIGGER trigger_choir_notices_updated_at
  BEFORE UPDATE ON public.choir_notices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- choir_materials
CREATE OR REPLACE TRIGGER trigger_choir_materials_updated_at
  BEFORE UPDATE ON public.choir_materials
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 11. RLS (Row Level Security) 정책
-- ============================================================

-- choirs 테이블 RLS
ALTER TABLE public.choirs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "choirs_select_public" ON public.choirs
  FOR SELECT USING (is_public = true OR owner_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choirs.id AND user_id = auth.uid() AND status = 'active'));

CREATE POLICY "choirs_insert_auth" ON public.choirs
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "choirs_update_owner" ON public.choirs
  FOR UPDATE USING (owner_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choirs.id AND user_id = auth.uid() AND role IN ('owner','admin') AND status = 'active'));

CREATE POLICY "choirs_delete_owner" ON public.choirs
  FOR DELETE USING (owner_id = auth.uid());

-- choir_members 테이블 RLS
ALTER TABLE public.choir_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "choir_members_select" ON public.choir_members
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.choir_members cm WHERE cm.choir_id = choir_members.choir_id AND cm.user_id = auth.uid() AND cm.status = 'active')
  );

CREATE POLICY "choir_members_insert_admin" ON public.choir_members
  FOR INSERT WITH CHECK (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.choir_members cm WHERE cm.choir_id = choir_members.choir_id AND cm.user_id = auth.uid() AND cm.role IN ('owner','admin') AND cm.status = 'active')
  );

CREATE POLICY "choir_members_update_admin" ON public.choir_members
  FOR UPDATE USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.choir_members cm WHERE cm.choir_id = choir_members.choir_id AND cm.user_id = auth.uid() AND cm.role IN ('owner','admin') AND cm.status = 'active')
  );

CREATE POLICY "choir_members_delete_admin" ON public.choir_members
  FOR DELETE USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.choir_members cm WHERE cm.choir_id = choir_members.choir_id AND cm.user_id = auth.uid() AND cm.role IN ('owner','admin') AND cm.status = 'active')
  );

-- choir_schedules 테이블 RLS
ALTER TABLE public.choir_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "choir_schedules_select_member" ON public.choir_schedules
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_schedules.choir_id AND user_id = auth.uid() AND status = 'active')
  );

CREATE POLICY "choir_schedules_insert_admin" ON public.choir_schedules
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_schedules.choir_id AND user_id = auth.uid() AND role IN ('owner','admin','section_leader') AND status = 'active')
  );

CREATE POLICY "choir_schedules_update_admin" ON public.choir_schedules
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_schedules.choir_id AND user_id = auth.uid() AND role IN ('owner','admin','section_leader') AND status = 'active')
  );

CREATE POLICY "choir_schedules_delete_admin" ON public.choir_schedules
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_schedules.choir_id AND user_id = auth.uid() AND role IN ('owner','admin') AND status = 'active')
  );

-- choir_attendance 테이블 RLS
ALTER TABLE public.choir_attendance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "choir_attendance_select_member" ON public.choir_attendance
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_attendance.choir_id AND user_id = auth.uid() AND role IN ('owner','admin','section_leader') AND status = 'active')
  );

CREATE POLICY "choir_attendance_insert_admin" ON public.choir_attendance
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_attendance.choir_id AND user_id = auth.uid() AND role IN ('owner','admin','section_leader') AND status = 'active')
  );

CREATE POLICY "choir_attendance_update_admin" ON public.choir_attendance
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_attendance.choir_id AND user_id = auth.uid() AND role IN ('owner','admin','section_leader') AND status = 'active')
  );

-- choir_songs 테이블 RLS
ALTER TABLE public.choir_songs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "choir_songs_select_member" ON public.choir_songs
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_songs.choir_id AND user_id = auth.uid() AND status = 'active')
  );

CREATE POLICY "choir_songs_insert_admin" ON public.choir_songs
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_songs.choir_id AND user_id = auth.uid() AND role IN ('owner','admin','section_leader') AND status = 'active')
  );

CREATE POLICY "choir_songs_update_admin" ON public.choir_songs
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_songs.choir_id AND user_id = auth.uid() AND role IN ('owner','admin','section_leader') AND status = 'active')
  );

-- choir_invites 테이블 RLS
ALTER TABLE public.choir_invites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "choir_invites_select_admin" ON public.choir_invites
  FOR SELECT USING (
    created_by = auth.uid() OR
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_invites.choir_id AND user_id = auth.uid() AND role IN ('owner','admin') AND status = 'active')
  );

CREATE POLICY "choir_invites_insert_admin" ON public.choir_invites
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_invites.choir_id AND user_id = auth.uid() AND role IN ('owner','admin') AND status = 'active')
  );

CREATE POLICY "choir_invites_update_admin" ON public.choir_invites
  FOR UPDATE USING (
    created_by = auth.uid() OR
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_invites.choir_id AND user_id = auth.uid() AND role IN ('owner','admin') AND status = 'active')
  );

-- choir_join_requests 테이블 RLS
ALTER TABLE public.choir_join_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "choir_join_requests_select" ON public.choir_join_requests
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_join_requests.choir_id AND user_id = auth.uid() AND role IN ('owner','admin') AND status = 'active')
  );

CREATE POLICY "choir_join_requests_insert_auth" ON public.choir_join_requests
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "choir_join_requests_update_admin" ON public.choir_join_requests
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_join_requests.choir_id AND user_id = auth.uid() AND role IN ('owner','admin') AND status = 'active')
  );

-- choir_materials 테이블 RLS
ALTER TABLE public.choir_materials ENABLE ROW LEVEL SECURITY;

CREATE POLICY "choir_materials_select_member" ON public.choir_materials
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_materials.choir_id AND user_id = auth.uid() AND status = 'active')
  );

CREATE POLICY "choir_materials_insert_admin" ON public.choir_materials
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_materials.choir_id AND user_id = auth.uid() AND role IN ('owner','admin','section_leader') AND status = 'active')
  );

CREATE POLICY "choir_materials_update_admin" ON public.choir_materials
  FOR UPDATE USING (
    uploaded_by = auth.uid() OR
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_materials.choir_id AND user_id = auth.uid() AND role IN ('owner','admin') AND status = 'active')
  );

CREATE POLICY "choir_materials_delete_admin" ON public.choir_materials
  FOR DELETE USING (
    uploaded_by = auth.uid() OR
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_materials.choir_id AND user_id = auth.uid() AND role IN ('owner','admin') AND status = 'active')
  );

-- choir_notices 테이블 RLS
ALTER TABLE public.choir_notices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "choir_notices_select_member" ON public.choir_notices
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_notices.choir_id AND user_id = auth.uid() AND status = 'active')
  );

CREATE POLICY "choir_notices_insert_admin" ON public.choir_notices
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_notices.choir_id AND user_id = auth.uid() AND role IN ('owner','admin') AND status = 'active')
  );

CREATE POLICY "choir_notices_update_admin" ON public.choir_notices
  FOR UPDATE USING (
    author_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_notices.choir_id AND user_id = auth.uid() AND role IN ('owner','admin') AND status = 'active')
  );

-- choir_parts 테이블 RLS
ALTER TABLE public.choir_parts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "choir_parts_select_member" ON public.choir_parts
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_parts.choir_id AND user_id = auth.uid() AND status = 'active')
  );

CREATE POLICY "choir_parts_manage_admin" ON public.choir_parts
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.choir_members WHERE choir_id = choir_parts.choir_id AND user_id = auth.uid() AND role IN ('owner','admin') AND status = 'active')
  );

-- ============================================================
-- 12. 유용한 뷰(View) 생성
-- ============================================================

-- 찬양대 멤버 상세 뷰
CREATE OR REPLACE VIEW public.v_choir_members AS
SELECT
  cm.id,
  cm.choir_id,
  cm.user_id,
  cm.role,
  cm.position,
  cm.section,
  cm.status,
  cm.phone,
  cm.note,
  cm.receive_notification,
  cm.join_method,
  cm.joined_at,
  u.nickname,
  u.email,
  u.profile_image_url,
  c.name AS choir_name
FROM public.choir_members cm
JOIN public.users u ON u.id = cm.user_id
JOIN public.choirs c ON c.id = cm.choir_id;

-- 출석 통계 뷰 (멤버별)
CREATE OR REPLACE VIEW public.v_choir_attendance_stats AS
SELECT
  ca.choir_id,
  ca.member_id,
  ca.user_id,
  COUNT(*) FILTER (WHERE ca.status = 'present') AS present_count,
  COUNT(*) FILTER (WHERE ca.status = 'absent')  AS absent_count,
  COUNT(*) FILTER (WHERE ca.status = 'excused') AS excused_count,
  COUNT(*) AS total_count,
  ROUND(
    COUNT(*) FILTER (WHERE ca.status = 'present')::NUMERIC / NULLIF(COUNT(*), 0) * 100, 1
  ) AS attendance_rate
FROM public.choir_attendance ca
GROUP BY ca.choir_id, ca.member_id, ca.user_id;

-- 다가오는 일정 뷰
CREATE OR REPLACE VIEW public.v_upcoming_schedules AS
SELECT
  cs.*,
  c.name AS choir_name,
  c.church_name,
  COUNT(css.song_id) AS song_count
FROM public.choir_schedules cs
JOIN public.choirs c ON c.id = cs.choir_id
LEFT JOIN public.choir_schedule_songs css ON css.schedule_id = cs.id
WHERE cs.start_time >= NOW()
GROUP BY cs.id, c.name, c.church_name
ORDER BY cs.start_time ASC;
