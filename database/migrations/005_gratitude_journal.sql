-- ============================================================
-- 감사일기 모듈 (005_gratitude_journal.sql)
-- ============================================================

-- 1. 감사일기 테이블
CREATE TABLE IF NOT EXISTS public.gratitude_journals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  
  -- 감사 3가지
  gratitude_1 TEXT NOT NULL,
  gratitude_2 TEXT,
  gratitude_3 TEXT,
  
  -- 감정 태그
  emotion VARCHAR(20) CHECK (emotion IN ('joy', 'peace', 'moved', 'thankful')),
  
  -- 기도 응답 연결
  linked_prayer_id UUID REFERENCES public.prayers(id) ON DELETE SET NULL,
  
  -- 공개 범위
  scope VARCHAR(20) DEFAULT 'private' NOT NULL 
    CHECK (scope IN ('private', 'group', 'public')),
  
  -- 날짜 (하루 1개 제한용)
  journal_date DATE NOT NULL DEFAULT CURRENT_DATE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  
  -- 하루에 1개만 작성 가능
  UNIQUE(user_id, journal_date)
);

CREATE INDEX IF NOT EXISTS idx_gratitude_user_id 
  ON public.gratitude_journals(user_id);
CREATE INDEX IF NOT EXISTS idx_gratitude_journal_date 
  ON public.gratitude_journals(journal_date DESC);
CREATE INDEX IF NOT EXISTS idx_gratitude_scope 
  ON public.gratitude_journals(scope);

-- 2. 감사일기 반응 테이블
CREATE TABLE IF NOT EXISTS public.gratitude_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journal_id UUID NOT NULL REFERENCES public.gratitude_journals(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  reaction_type VARCHAR(20) NOT NULL 
    CHECK (reaction_type IN ('grace', 'empathy')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  UNIQUE(journal_id, user_id, reaction_type)
);

CREATE INDEX IF NOT EXISTS idx_gratitude_reactions_journal_id 
  ON public.gratitude_reactions(journal_id);

-- 3. 감사일기 댓글 테이블
CREATE TABLE IF NOT EXISTS public.gratitude_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journal_id UUID NOT NULL REFERENCES public.gratitude_journals(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_gratitude_comments_journal_id 
  ON public.gratitude_comments(journal_id);

-- 4. 스트릭 테이블 (연속 작성 기록)
CREATE TABLE IF NOT EXISTS public.gratitude_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_journal_date DATE,
  total_count INTEGER DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_gratitude_streaks_user_id 
  ON public.gratitude_streaks(user_id);

