-- 기도 응답 간증 테이블
-- Supabase SQL Editor에서 실행하세요

CREATE TABLE IF NOT EXISTS public.prayer_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

-- 기도 응답 댓글 테이블
CREATE TABLE IF NOT EXISTS public.prayer_answer_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  answer_id UUID NOT NULL REFERENCES public.prayer_answers(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_prayer_answer_comments_answer_id ON public.prayer_answer_comments(answer_id);
CREATE INDEX IF NOT EXISTS idx_prayer_answer_comments_created_at ON public.prayer_answer_comments(created_at);

-- updated_at 자동 업데이트 트리거
CREATE TRIGGER update_prayer_answers_updated_at
  BEFORE UPDATE ON public.prayer_answers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
