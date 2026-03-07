-- FCM 푸시 토큰 컬럼 추가
-- Supabase Dashboard > SQL Editor 에서 실행

-- users 테이블에 fcm_token 컬럼 추가
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- 인덱스 (토큰으로 조회할 경우를 위해)
CREATE INDEX IF NOT EXISTS idx_users_fcm_token ON public.users(fcm_token)
  WHERE fcm_token IS NOT NULL;
