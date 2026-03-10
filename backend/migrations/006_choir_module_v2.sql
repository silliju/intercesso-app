-- ═══════════════════════════════════════════════════════════════
-- 006_choir_module_v2.sql - 찬양대 모듈 전체 스키마
-- Supabase Dashboard > SQL Editor에서 실행
-- ═══════════════════════════════════════════════════════════════

-- ── 1. choirs (찬양대) ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.choirs (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name              TEXT NOT NULL,
  description       TEXT,
  image_url         TEXT,
  church_name       TEXT,
  worship_type      TEXT,                    -- '주일1부', '청년예배' 등
  owner_id          UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  invite_code       TEXT UNIQUE,
  invite_link_active BOOLEAN DEFAULT true,
  member_count      INTEGER DEFAULT 1,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_choirs_owner ON public.choirs(owner_id);
CREATE INDEX IF NOT EXISTS idx_choirs_invite_code ON public.choirs(invite_code);

-- ── 2. choir_members (찬양대원) ───────────────────────────────
CREATE TABLE IF NOT EXISTS public.choir_members (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  choir_id    UUID NOT NULL REFERENCES public.choirs(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role        TEXT NOT NULL DEFAULT 'member'
                CHECK (role IN ('conductor','section_leader','treasurer','member')),
  section     TEXT NOT NULL DEFAULT 'all'
                CHECK (section IN ('soprano','alto','tenor','bass','all')),
  status      TEXT NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending','active','inactive')),
  joined_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (choir_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_choir_members_choir ON public.choir_members(choir_id);
CREATE INDEX IF NOT EXISTS idx_choir_members_user  ON public.choir_members(user_id);

-- ── 3. choir_schedules (일정) ─────────────────────────────────
CREATE TABLE IF NOT EXISTS public.choir_schedules (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  choir_id      UUID NOT NULL REFERENCES public.choirs(id) ON DELETE CASCADE,
  title         TEXT NOT NULL,
  schedule_type TEXT NOT NULL DEFAULT 'rehearsal'
                  CHECK (schedule_type IN (
                    'rehearsal','pre_service_practice','service',
                    'post_service_practice','weekday_practice','special_event'
                  )),
  location      TEXT,
  start_time    TIMESTAMPTZ NOT NULL,
  end_time      TIMESTAMPTZ,
  description   TEXT,
  created_by    UUID REFERENCES public.users(id),
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_choir_schedules_choir ON public.choir_schedules(choir_id);
CREATE INDEX IF NOT EXISTS idx_choir_schedules_time  ON public.choir_schedules(start_time);

-- ── 4. choir_songs (찬양곡) ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.choir_songs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  choir_id      UUID NOT NULL REFERENCES public.choirs(id) ON DELETE CASCADE,
  title         TEXT NOT NULL,
  composer      TEXT,
  arranger      TEXT,
  hymn_book_ref TEXT,          -- '찬송가 19장' 등
  youtube_url   TEXT,
  genre         TEXT,          -- '현대 찬양', '찬송가', '클래식' 등
  difficulty    TEXT DEFAULT 'medium'
                  CHECK (difficulty IN ('easy','medium','hard')),
  parts         TEXT[] DEFAULT '{}',  -- ['soprano','alto','tenor','bass']
  notes         TEXT,
  created_by    UUID REFERENCES public.users(id),
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_choir_songs_choir ON public.choir_songs(choir_id);

-- ── 5. choir_schedule_songs (일정-곡 연결) ────────────────────
CREATE TABLE IF NOT EXISTS public.choir_schedule_songs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  schedule_id UUID NOT NULL REFERENCES public.choir_schedules(id) ON DELETE CASCADE,
  song_id     UUID NOT NULL REFERENCES public.choir_songs(id) ON DELETE CASCADE,
  order_num   INTEGER DEFAULT 1,
  UNIQUE (schedule_id, song_id)
);

-- ── 6. choir_attendances (출석) ───────────────────────────────
CREATE TABLE IF NOT EXISTS public.choir_attendances (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  schedule_id UUID NOT NULL REFERENCES public.choir_schedules(id) ON DELETE CASCADE,
  member_id   UUID NOT NULL REFERENCES public.choir_members(id) ON DELETE CASCADE,
  status      TEXT NOT NULL DEFAULT 'present'
                CHECK (status IN ('present','absent','excused')),
  note        TEXT,
  marked_at   TIMESTAMPTZ DEFAULT NOW(),
  marked_by   UUID REFERENCES public.users(id),
  UNIQUE (schedule_id, member_id)
);

CREATE INDEX IF NOT EXISTS idx_choir_attendances_schedule ON public.choir_attendances(schedule_id);
CREATE INDEX IF NOT EXISTS idx_choir_attendances_member   ON public.choir_attendances(member_id);

-- ── 7. choir_notices (공지사항) ───────────────────────────────
CREATE TABLE IF NOT EXISTS public.choir_notices (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  choir_id       UUID NOT NULL REFERENCES public.choirs(id) ON DELETE CASCADE,
  author_id      UUID NOT NULL REFERENCES public.users(id),
  title          TEXT NOT NULL,
  content        TEXT NOT NULL,
  is_pinned      BOOLEAN DEFAULT false,
  target_section TEXT,        -- NULL = 전체, 'soprano' 등
  view_count     INTEGER DEFAULT 0,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_choir_notices_choir ON public.choir_notices(choir_id);

-- ── 8. choir_files (자료실) ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.choir_files (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  choir_id       UUID NOT NULL REFERENCES public.choirs(id) ON DELETE CASCADE,
  title          TEXT NOT NULL,
  description    TEXT,
  file_type      TEXT NOT NULL
                   CHECK (file_type IN ('score','video','audio','document')),
  file_url       TEXT,
  youtube_url    TEXT,
  target_section TEXT,        -- NULL = 전체, 'soprano' 등
  uploaded_by    UUID REFERENCES public.users(id),
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_choir_files_choir ON public.choir_files(choir_id);

-- ── 9. RLS 정책 ───────────────────────────────────────────────
ALTER TABLE public.choirs            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.choir_members     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.choir_schedules   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.choir_songs       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.choir_schedule_songs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.choir_attendances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.choir_notices     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.choir_files       ENABLE ROW LEVEL SECURITY;

-- service_role은 모든 접근 허용 (백엔드 서버에서 사용)
DO $$
DECLARE tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'choirs','choir_members','choir_schedules','choir_songs',
    'choir_schedule_songs','choir_attendances','choir_notices','choir_files'
  ] LOOP
    EXECUTE format(
      'CREATE POLICY IF NOT EXISTS "service_role_all_%1$s" ON public.%1$s
       FOR ALL TO service_role USING (true) WITH CHECK (true);', tbl
    );
  END LOOP;
END $$;

-- ── 10. member_count 관리 함수 ────────────────────────────────
CREATE OR REPLACE FUNCTION public.increment_choir_member_count(p_choir_id UUID)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.choirs
  SET member_count = member_count + 1,
      updated_at = NOW()
  WHERE id = p_choir_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.decrement_choir_member_count(p_choir_id UUID)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.choirs
  SET member_count = GREATEST(member_count - 1, 0),
      updated_at = NOW()
  WHERE id = p_choir_id;
END;
$$;

-- ── 11. updated_at 자동 갱신 트리거 ──────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DO $$
DECLARE tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'choirs','choir_schedules','choir_songs','choir_notices'
  ] LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS set_updated_at_%1$s ON public.%1$s;
       CREATE TRIGGER set_updated_at_%1$s
         BEFORE UPDATE ON public.%1$s
         FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();', tbl
    );
  END LOOP;
END $$;
