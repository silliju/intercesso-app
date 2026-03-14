-- ============================================================
-- 오늘의 말씀 테이블 (010_daily_verse.sql)
-- 날짜(YYYY-MM-DD) 기반 성경 말씀
-- 기준 윤년(2000년) 366일 저장 후, 조회 시 오늘 MM-DD로 매핑
-- Supabase SQL Editor에서 실행하세요.
-- ============================================================

DROP TABLE IF EXISTS public.daily_verse CASCADE;

CREATE TABLE public.daily_verse (
    verse_date DATE NOT NULL PRIMARY KEY,
    text TEXT NOT NULL,
    reference VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE public.daily_verse IS '오늘의 말씀 (기준 윤년 2000년 날짜, 조회 시 MM-DD 매핑)';
COMMENT ON COLUMN public.daily_verse.verse_date IS '기준 날짜 (YYYY-MM-DD)';
COMMENT ON COLUMN public.daily_verse.text IS '말씀 본문';
COMMENT ON COLUMN public.daily_verse.reference IS '성경 출처 (예: 시편 23:1)';

-- RLS (선택 사항: 공개 읽기만 허용)
ALTER TABLE public.daily_verse ENABLE ROW LEVEL SECURITY;

CREATE POLICY "daily_verse_select_policy"
    ON public.daily_verse FOR SELECT
    USING (true);
