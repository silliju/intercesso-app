-- ============================================================
-- users / choirs 에 church_id FK 추가 (009)
-- 회원가입·찬양대에서 교회 검색/선택 시 churches.church_id 로 연결
-- Supabase SQL Editor에서 008_churches.sql 적용 후 실행하세요.
-- ============================================================

-- 1. users 테이블에 church_id 추가
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS church_id BIGINT REFERENCES public.churches(church_id) ON DELETE SET NULL;

COMMENT ON COLUMN public.users.church_id IS '소속 교회 ID (churches.church_id). 표시용 church_name 은 동기화 가능';

CREATE INDEX IF NOT EXISTS idx_users_church_id ON public.users(church_id);

-- 2. choirs 테이블에 church_id 추가
ALTER TABLE public.choirs
  ADD COLUMN IF NOT EXISTS church_id BIGINT REFERENCES public.churches(church_id) ON DELETE SET NULL;

COMMENT ON COLUMN public.choirs.church_id IS '소속 교회 ID (churches.church_id). 표시용 church_name 은 동기화 가능';

CREATE INDEX IF NOT EXISTS idx_choirs_church_id ON public.choirs(church_id);
