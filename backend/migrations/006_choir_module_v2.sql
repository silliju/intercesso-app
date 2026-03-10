-- ═══════════════════════════════════════════════════════════════
-- 006_choir_module_v2.sql
-- 찬양대 모듈 전체 스키마 (테이블 8개 + 함수 + 트리거)
-- 실행 위치: Supabase Dashboard > SQL Editor
-- 실행 순서: 위에서 아래로 순서대로 실행
-- ═══════════════════════════════════════════════════════════════


-- ────────────────────────────────────────────────────────────────
-- 1. choirs : 찬양대 기본 정보
--    한 교회에 여러 찬양대를 만들 수 있음 (주일 1부, 청년부 등)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.choirs (
  id                 UUID        PRIMARY KEY DEFAULT gen_random_uuid(), -- 찬양대 고유 ID
  name               TEXT        NOT NULL,                              -- 찬양대 이름 (예: 주일 찬양대)
  description        TEXT,                                             -- 찬양대 소개 (선택)
  image_url          TEXT,                                             -- 찬양대 대표 이미지 URL (선택)
  church_name        TEXT,                                             -- 소속 교회 이름 (선택)
  worship_type       TEXT,                                             -- 예배 유형 (예: 주일1부, 청년예배, 수요예배)
  owner_id           UUID        NOT NULL                              -- 찬양대 소유자(생성자) user ID
                       REFERENCES public.users(id) ON DELETE CASCADE,
  invite_code        TEXT        UNIQUE,                               -- 초대 코드 (8자리 대문자+숫자, 예: AB12CD34)
  invite_link_active BOOLEAN     DEFAULT true,                         -- 초대 링크 활성화 여부 (false=초대 비활성)
  member_count       INTEGER     DEFAULT 1,                            -- 현재 활성 단원 수 (캐시 값)
  created_at         TIMESTAMPTZ DEFAULT NOW(),                        -- 찬양대 생성일시
  updated_at         TIMESTAMPTZ DEFAULT NOW()                         -- 마지막 수정일시
);

-- 인덱스: 소유자별 조회, 초대코드로 조회
CREATE INDEX IF NOT EXISTS idx_choirs_owner       ON public.choirs(owner_id);
CREATE INDEX IF NOT EXISTS idx_choirs_invite_code ON public.choirs(invite_code);


-- ────────────────────────────────────────────────────────────────
-- 2. choir_members : 찬양대원 (찬양대 ↔ 사용자 다대다 연결)
--    role: 지휘자 / 파트장 / 총무 / 단원
--    section: 소프라노 / 알토 / 테너 / 베이스 / 전체
--    status: pending(가입신청) / active(승인됨) / inactive(비활성)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.choir_members (
  id        UUID        PRIMARY KEY DEFAULT gen_random_uuid(), -- 멤버십 고유 ID
  choir_id  UUID        NOT NULL                              -- 소속 찬양대 ID
              REFERENCES public.choirs(id) ON DELETE CASCADE,
  user_id   UUID        NOT NULL                              -- 단원 user ID
              REFERENCES public.users(id) ON DELETE CASCADE,
  role      TEXT        NOT NULL DEFAULT 'member'             -- 역할: conductor(지휘자) / section_leader(파트장) / treasurer(총무) / member(단원)
              CHECK (role IN ('conductor','section_leader','treasurer','member')),
  section   TEXT        NOT NULL DEFAULT 'all'                -- 성부: soprano(소프라노) / alto(알토) / tenor(테너) / bass(베이스) / all(전체)
              CHECK (section IN ('soprano','alto','tenor','bass','all')),
  status    TEXT        NOT NULL DEFAULT 'pending'            -- 상태: pending(승인대기) / active(활성) / inactive(비활성)
              CHECK (status IN ('pending','active','inactive')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),                        -- 가입(신청)일시
  UNIQUE (choir_id, user_id)                                  -- 한 찬양대에 같은 사용자 중복 가입 방지
);

-- 인덱스: 찬양대별 멤버 조회, 사용자별 소속 찬양대 조회
CREATE INDEX IF NOT EXISTS idx_choir_members_choir ON public.choir_members(choir_id);
CREATE INDEX IF NOT EXISTS idx_choir_members_user  ON public.choir_members(user_id);


-- ────────────────────────────────────────────────────────────────
-- 3. choir_schedules : 찬양대 일정
--    연습, 예배, 특별행사 등의 일정을 관리
--    schedule_type 값:
--      rehearsal             = 일반 연습
--      pre_service_practice  = 예배 전 연습
--      service               = 예배
--      post_service_practice = 예배 후 연습
--      weekday_practice      = 평일 연습
--      special_event         = 특별 행사
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.choir_schedules (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(), -- 일정 고유 ID
  choir_id      UUID        NOT NULL                              -- 소속 찬양대 ID
                  REFERENCES public.choirs(id) ON DELETE CASCADE,
  title         TEXT        NOT NULL,                             -- 일정 제목 (예: 주일예배 연습)
  schedule_type TEXT        NOT NULL DEFAULT 'rehearsal'          -- 일정 유형 (위 설명 참조)
                  CHECK (schedule_type IN (
                    'rehearsal',
                    'pre_service_practice',
                    'service',
                    'post_service_practice',
                    'weekday_practice',
                    'special_event'
                  )),
  location      TEXT,                                             -- 장소 (예: 찬양실, 본당, 선택)
  start_time    TIMESTAMPTZ NOT NULL,                             -- 시작 일시
  end_time      TIMESTAMPTZ,                                      -- 종료 일시 (선택)
  description   TEXT,                                             -- 일정 상세 설명 (선택)
  created_by    UUID        REFERENCES public.users(id),          -- 일정 생성자 user ID
  created_at    TIMESTAMPTZ DEFAULT NOW(),                        -- 생성일시
  updated_at    TIMESTAMPTZ DEFAULT NOW()                         -- 마지막 수정일시
);

-- 인덱스: 찬양대별 일정 조회, 날짜순 정렬
CREATE INDEX IF NOT EXISTS idx_choir_schedules_choir ON public.choir_schedules(choir_id);
CREATE INDEX IF NOT EXISTS idx_choir_schedules_time  ON public.choir_schedules(start_time);


-- ────────────────────────────────────────────────────────────────
-- 4. choir_songs : 찬양곡 목록
--    찬양대에서 사용하는 곡 목록 관리
--    difficulty: easy(쉬움) / medium(보통) / hard(어려움)
--    parts: 해당 곡에 필요한 성부 배열 (예: ['soprano','alto','tenor','bass'])
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.choir_songs (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(), -- 곡 고유 ID
  choir_id      UUID        NOT NULL                              -- 소속 찬양대 ID
                  REFERENCES public.choirs(id) ON DELETE CASCADE,
  title         TEXT        NOT NULL,                             -- 곡 제목 (예: 주님의 은혜)
  composer      TEXT,                                             -- 작곡가 (선택)
  arranger      TEXT,                                             -- 편곡자 (선택)
  hymn_book_ref TEXT,                                             -- 찬송가 번호 (예: 찬송가 19장, 선택)
  youtube_url   TEXT,                                             -- YouTube 링크 (연습용 영상, 선택)
  genre         TEXT,                                             -- 장르 (예: 현대 찬양, 찬송가, 클래식, 복음성가)
  difficulty    TEXT        DEFAULT 'medium'                      -- 난이도: easy(쉬움) / medium(보통) / hard(어려움)
                  CHECK (difficulty IN ('easy','medium','hard')),
  parts         TEXT[]      DEFAULT '{}',                         -- 필요 성부 배열 (예: '{soprano,alto,tenor,bass}')
  notes         TEXT,                                             -- 메모 / 연습 포인트 (선택)
  created_by    UUID        REFERENCES public.users(id),          -- 곡 등록자 user ID
  created_at    TIMESTAMPTZ DEFAULT NOW(),                        -- 등록일시
  updated_at    TIMESTAMPTZ DEFAULT NOW()                         -- 마지막 수정일시
);

-- 인덱스: 찬양대별 곡 조회
CREATE INDEX IF NOT EXISTS idx_choir_songs_choir ON public.choir_songs(choir_id);


-- ────────────────────────────────────────────────────────────────
-- 5. choir_schedule_songs : 일정 ↔ 찬양곡 연결 (다대다)
--    특정 일정(연습/예배)에 어떤 곡을 부를지 연결
--    order_num: 같은 일정 안에서 곡 순서 (1번부터 시작)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.choir_schedule_songs (
  id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(), -- 연결 고유 ID
  schedule_id UUID    NOT NULL                              -- 일정 ID
                REFERENCES public.choir_schedules(id) ON DELETE CASCADE,
  song_id     UUID    NOT NULL                              -- 곡 ID
                REFERENCES public.choir_songs(id) ON DELETE CASCADE,
  order_num   INTEGER DEFAULT 1,                            -- 해당 일정 내 곡 순서 (1 = 첫 번째 곡)
  UNIQUE (schedule_id, song_id)                             -- 같은 일정에 같은 곡 중복 등록 방지
);


-- ────────────────────────────────────────────────────────────────
-- 6. choir_attendances : 출석 기록
--    일정별 단원 출석 체크 결과 저장
--    status: present(출석) / absent(결석) / excused(공결)
--    note: 결석/공결 사유 메모
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.choir_attendances (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(), -- 출석 기록 고유 ID
  schedule_id UUID        NOT NULL                              -- 대상 일정 ID
                REFERENCES public.choir_schedules(id) ON DELETE CASCADE,
  member_id   UUID        NOT NULL                              -- 대상 단원 (choir_members.id)
                REFERENCES public.choir_members(id) ON DELETE CASCADE,
  status      TEXT        NOT NULL DEFAULT 'present'            -- 출석 상태: present(출석) / absent(결석) / excused(공결)
                CHECK (status IN ('present','absent','excused')),
  note        TEXT,                                             -- 결석/공결 사유 메모 (선택)
  marked_at   TIMESTAMPTZ DEFAULT NOW(),                        -- 출석 체크 일시
  marked_by   UUID        REFERENCES public.users(id),          -- 출석 체크한 관리자 user ID
  UNIQUE (schedule_id, member_id)                               -- 같은 일정에 같은 단원 중복 기록 방지
);

-- 인덱스: 일정별 출석 조회, 단원별 출석 이력 조회
CREATE INDEX IF NOT EXISTS idx_choir_attendances_schedule ON public.choir_attendances(schedule_id);
CREATE INDEX IF NOT EXISTS idx_choir_attendances_member   ON public.choir_attendances(member_id);


-- ────────────────────────────────────────────────────────────────
-- 7. choir_notices : 찬양대 공지사항
--    지휘자/관리자가 단원들에게 공지 게시
--    is_pinned: true이면 항상 상단 고정
--    target_section: NULL이면 전체 공지, 값이 있으면 해당 성부만
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.choir_notices (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(), -- 공지사항 고유 ID
  choir_id       UUID        NOT NULL                              -- 소속 찬양대 ID
                   REFERENCES public.choirs(id) ON DELETE CASCADE,
  author_id      UUID        NOT NULL                              -- 작성자 user ID
                   REFERENCES public.users(id),
  title          TEXT        NOT NULL,                             -- 공지 제목
  content        TEXT        NOT NULL,                             -- 공지 본문 내용
  is_pinned      BOOLEAN     DEFAULT false,                        -- 상단 고정 여부 (true = 항상 맨 위)
  target_section TEXT,                                             -- 대상 성부 (NULL=전체, soprano/alto/tenor/bass)
  view_count     INTEGER     DEFAULT 0,                            -- 조회수
  created_at     TIMESTAMPTZ DEFAULT NOW(),                        -- 작성일시
  updated_at     TIMESTAMPTZ DEFAULT NOW()                         -- 마지막 수정일시
);

-- 인덱스: 찬양대별 공지 조회
CREATE INDEX IF NOT EXISTS idx_choir_notices_choir ON public.choir_notices(choir_id);


-- ────────────────────────────────────────────────────────────────
-- 8. choir_files : 찬양대 자료실
--    악보, 연습 영상, 음원, 문서 등 파일/링크 관리
--    file_type: score(악보) / video(영상) / audio(음원) / document(문서)
--    file_url 또는 youtube_url 중 하나는 반드시 있어야 함
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.choir_files (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(), -- 파일 고유 ID
  choir_id       UUID        NOT NULL                              -- 소속 찬양대 ID
                   REFERENCES public.choirs(id) ON DELETE CASCADE,
  title          TEXT        NOT NULL,                             -- 파일 제목 (예: 주님의 은혜 - 소프라노 악보)
  description    TEXT,                                             -- 파일 설명 (선택)
  file_type      TEXT        NOT NULL                              -- 파일 유형: score(악보) / video(영상) / audio(음원) / document(문서)
                   CHECK (file_type IN ('score','video','audio','document')),
  file_url       TEXT,                                             -- 파일 다운로드 URL (악보, 음원, 문서 등)
  youtube_url    TEXT,                                             -- YouTube 링크 (영상 자료)
  target_section TEXT,                                             -- 대상 성부 (NULL=전체, soprano/alto/tenor/bass)
  uploaded_by    UUID        REFERENCES public.users(id),          -- 업로드한 단원 user ID
  created_at     TIMESTAMPTZ DEFAULT NOW()                         -- 업로드 일시
);

-- 인덱스: 찬양대별 파일 조회
CREATE INDEX IF NOT EXISTS idx_choir_files_choir ON public.choir_files(choir_id);


-- ────────────────────────────────────────────────────────────────
-- 9. RLS (Row Level Security) 정책
--    백엔드 서버는 service_role 키로 접근 → 모든 행 읽기/쓰기 허용
--    일반 사용자(anon/authenticated)는 직접 접근 불가 → 반드시 백엔드 API 통해서만 접근
-- ────────────────────────────────────────────────────────────────
ALTER TABLE public.choirs               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.choir_members        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.choir_schedules      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.choir_songs          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.choir_schedule_songs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.choir_attendances    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.choir_notices        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.choir_files          ENABLE ROW LEVEL SECURITY;

-- service_role(백엔드 서버)에게 모든 테이블 전체 접근 허용
-- (기존 정책 있으면 먼저 삭제 후 재생성 → 멱등성 보장)
DO $$
DECLARE tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'choirs',
    'choir_members',
    'choir_schedules',
    'choir_songs',
    'choir_schedule_songs',
    'choir_attendances',
    'choir_notices',
    'choir_files'
  ] LOOP
    -- 기존 동일 이름 정책 삭제 (없으면 무시)
    EXECUTE format(
      'DROP POLICY IF EXISTS "service_role_all_%1$s" ON public.%1$s;',
      tbl
    );
    -- 재생성
    EXECUTE format(
      'CREATE POLICY "service_role_all_%1$s"
         ON public.%1$s
         FOR ALL
         TO service_role
         USING (true)
         WITH CHECK (true);',
      tbl
    );
  END LOOP;
END $$;


-- ────────────────────────────────────────────────────────────────
-- 10. 찬양대 단원 수 관리 함수
--     단원 승인 시 +1, 단원 제거 시 -1 (최솟값 0 보장)
-- ────────────────────────────────────────────────────────────────

-- 단원 수 1 증가 (단원 승인 시 호출)
CREATE OR REPLACE FUNCTION public.increment_choir_member_count(p_choir_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.choirs
  SET member_count = member_count + 1,
      updated_at   = NOW()
  WHERE id = p_choir_id;
END;
$$;

-- 단원 수 1 감소 (단원 제거 시 호출, 0 미만으로 내려가지 않음)
CREATE OR REPLACE FUNCTION public.decrement_choir_member_count(p_choir_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.choirs
  SET member_count = GREATEST(member_count - 1, 0),
      updated_at   = NOW()
  WHERE id = p_choir_id;
END;
$$;


-- ────────────────────────────────────────────────────────────────
-- 11. updated_at 자동 갱신 트리거
--     INSERT/UPDATE 시 updated_at 컬럼을 현재 시각으로 자동 갱신
--     대상 테이블: choirs, choir_schedules, choir_songs, choir_notices
-- ────────────────────────────────────────────────────────────────

-- 트리거 실행 함수 (공통)
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- 각 테이블에 트리거 적용
DO $$
DECLARE tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'choirs',
    'choir_schedules',
    'choir_songs',
    'choir_notices'
  ] LOOP
    -- 기존 트리거 삭제 후 재생성 (멱등성 보장)
    EXECUTE format(
      'DROP TRIGGER IF EXISTS trg_set_updated_at_%1$s ON public.%1$s;
       CREATE TRIGGER trg_set_updated_at_%1$s
         BEFORE UPDATE ON public.%1$s
         FOR EACH ROW
         EXECUTE FUNCTION public.set_updated_at();',
      tbl
    );
  END LOOP;
END $$;
