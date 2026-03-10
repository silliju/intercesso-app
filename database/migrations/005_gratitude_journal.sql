-- ============================================================
-- 감사일기 모듈 마이그레이션 (005_gratitude_journal.sql)
-- 역할: 감사일기 작성, 반응, 댓글, 스트릭(연속작성) 기능 테이블 생성
-- ============================================================

-- 1. 감사일기 테이블
-- 역할: 사용자가 매일 작성하는 감사일기 저장. 하루에 1개만 작성 가능합니다.
CREATE TABLE IF NOT EXISTS public.gratitude_journals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),         -- 감사일기 고유 식별자
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                                                         -- 작성자 사용자 ID (외래키)

  -- 감사 3가지 항목
  gratitude_1 TEXT NOT NULL,                             -- 첫 번째 감사 내용 (필수)
  gratitude_2 TEXT,                                      -- 두 번째 감사 내용 (선택)
  gratitude_3 TEXT,                                      -- 세 번째 감사 내용 (선택)

  -- 감정 태그 (오늘의 기분)
  emotion VARCHAR(20) CHECK (emotion IN ('joy', 'peace', 'moved', 'thankful')),
                                                         -- 감정 태그 (joy=기쁨, peace=평안, moved=감동, thankful=감사)

  -- 기도 응답 연결 (응답받은 기도와 감사일기 연결)
  linked_prayer_id UUID REFERENCES public.prayers(id) ON DELETE SET NULL,
                                                         -- 연결된 기도제목 ID (선택, 응답 기도 연결 시 사용)

  -- 공개 범위
  scope VARCHAR(20) DEFAULT 'private' NOT NULL
    CHECK (scope IN ('private', 'group', 'public')),
                                                         -- 공개 범위 (private=비공개, group=그룹공개, public=전체공개)

  -- 날짜 (하루 1개 제한용)
  journal_date DATE NOT NULL DEFAULT CURRENT_DATE,       -- 작성 날짜 (YYYY-MM-DD, 하루 1개 제한 기준)

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,  -- 일기 작성 일시
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,  -- 일기 수정 일시

  -- 하루에 1개만 작성 가능 (user + 날짜 조합 유일)
  UNIQUE(user_id, journal_date)
);

CREATE INDEX IF NOT EXISTS idx_gratitude_user_id
  ON public.gratitude_journals(user_id);
CREATE INDEX IF NOT EXISTS idx_gratitude_journal_date
  ON public.gratitude_journals(journal_date DESC);
CREATE INDEX IF NOT EXISTS idx_gratitude_scope
  ON public.gratitude_journals(scope);

-- 2. 감사일기 반응 테이블
-- 역할: 감사일기에 대한 이모지 반응 저장. 각 사용자는 반응 유형당 1번만 반응 가능합니다.
CREATE TABLE IF NOT EXISTS public.gratitude_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),         -- 반응 고유 식별자
  journal_id UUID NOT NULL REFERENCES public.gratitude_journals(id) ON DELETE CASCADE,
                                                         -- 반응 대상 감사일기 ID (외래키)
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                                                         -- 반응한 사용자 ID (외래키)
  reaction_type VARCHAR(20) NOT NULL
    CHECK (reaction_type IN ('grace', 'empathy')),
                                                         -- 반응 유형 (grace=은혜받음, empathy=공감)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,  -- 반응 일시
  UNIQUE(journal_id, user_id, reaction_type)             -- 동일 일기·동일 사용자·동일 반응 중복 불가
);

CREATE INDEX IF NOT EXISTS idx_gratitude_reactions_journal_id
  ON public.gratitude_reactions(journal_id);

-- 3. 감사일기 댓글 테이블
-- 역할: 감사일기에 달린 댓글 저장. 그룹 피드에서 서로 격려·공감 메시지를 나눕니다.
CREATE TABLE IF NOT EXISTS public.gratitude_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),         -- 댓글 고유 식별자
  journal_id UUID NOT NULL REFERENCES public.gratitude_journals(id) ON DELETE CASCADE,
                                                         -- 댓글 대상 감사일기 ID (외래키)
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                                                         -- 댓글 작성자 사용자 ID (외래키)
  content TEXT NOT NULL,                                 -- 댓글 내용
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL   -- 댓글 작성 일시
);

CREATE INDEX IF NOT EXISTS idx_gratitude_comments_journal_id
  ON public.gratitude_comments(journal_id);

-- 4. 스트릭 테이블 (연속 작성 기록)
-- 역할: 사용자별 감사일기 연속 작성 현황 저장. 홈화면 스트릭 배지 표시에 사용됩니다.
CREATE TABLE IF NOT EXISTS public.gratitude_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),         -- 스트릭 레코드 고유 식별자
  user_id UUID UNIQUE NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
                                                         -- 사용자 ID (1인 1레코드, 외래키)
  current_streak INTEGER DEFAULT 0,                      -- 현재 연속 작성 일수
  longest_streak INTEGER DEFAULT 0,                      -- 최장 연속 작성 일수 (역대 최고)
  last_journal_date DATE,                                -- 마지막으로 감사일기를 작성한 날짜
  total_count INTEGER DEFAULT 0,                         -- 총 작성 횟수 (누적)
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL   -- 스트릭 마지막 갱신 일시
);

CREATE INDEX IF NOT EXISTS idx_gratitude_streaks_user_id
  ON public.gratitude_streaks(user_id);
