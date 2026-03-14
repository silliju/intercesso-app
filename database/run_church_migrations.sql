-- ============================================================
-- 교회 관련 마이그레이션 통합 스크립트
-- 008_churches + 009_users_choirs_church_id 를 한 번에 적용
-- Supabase Dashboard → SQL Editor 에서 실행하세요.
-- 이미 적용된 경우 일부 문은 무시되거나 스킵됩니다.
-- ============================================================

-- ---------------------------------------------------------------------------
-- 1. churches 테이블 생성 (008)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.churches (
    church_id BIGSERIAL PRIMARY KEY,

    name VARCHAR(100) NOT NULL,
    denomination VARCHAR(100) DEFAULT NULL,
    pastor_name VARCHAR(50) DEFAULT NULL,

    si_do VARCHAR(30) NOT NULL,
    si_gun_gu VARCHAR(50) NOT NULL,
    dong VARCHAR(50) DEFAULT NULL,
    detail_address VARCHAR(200) DEFAULT NULL,
    road_address VARCHAR(255) DEFAULT NULL,
    jibun_address VARCHAR(255) DEFAULT NULL,

    latitude NUMERIC(10,7) DEFAULT NULL,
    longitude NUMERIC(10,7) DEFAULT NULL,

    status VARCHAR(20) DEFAULT 'pending'
        CHECK (status IN ('pending', 'approved', 'rejected', 'deleted')),
    created_by BIGINT DEFAULT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMPTZ DEFAULT NULL
);

-- 인덱스 (이미 있으면 스킵)
CREATE UNIQUE INDEX IF NOT EXISTS idx_churches_unique_name_address
    ON public.churches (
        name,
        si_do,
        si_gun_gu,
        COALESCE(dong, ''),
        COALESCE(detail_address, '')
    );
CREATE INDEX IF NOT EXISTS idx_churches_location ON public.churches (latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_churches_region   ON public.churches (si_do, si_gun_gu, dong);
CREATE INDEX IF NOT EXISTS idx_churches_status   ON public.churches (status);

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_churches_name_trgm ON public.churches USING GIN (name gin_trgm_ops);

COMMENT ON TABLE public.churches IS '사용자가 등록하거나 관리자가 승인하는 교회 정보 테이블';
COMMENT ON COLUMN public.churches.church_id      IS '자동 증가하는 고유 교회 ID (PK)';
COMMENT ON COLUMN public.churches.name            IS '교회 이름 (공식 명칭)';
COMMENT ON COLUMN public.churches.denomination    IS '교단 이름 (자유 입력)';
COMMENT ON COLUMN public.churches.pastor_name     IS '담임목사 성함 (선택)';
COMMENT ON COLUMN public.churches.si_do           IS '시/도';
COMMENT ON COLUMN public.churches.si_gun_gu       IS '시/군/구';
COMMENT ON COLUMN public.churches.dong            IS '동/읍/면/리';
COMMENT ON COLUMN public.churches.detail_address  IS '상세 주소';
COMMENT ON COLUMN public.churches.road_address    IS '전체 도로명 주소';
COMMENT ON COLUMN public.churches.jibun_address   IS '전체 지번 주소';
COMMENT ON COLUMN public.churches.latitude        IS '위도';
COMMENT ON COLUMN public.churches.longitude       IS '경도';
COMMENT ON COLUMN public.churches.status          IS '상태: pending/approved/rejected/deleted';
COMMENT ON COLUMN public.churches.created_by      IS '최초 등록한 사용자 ID';
COMMENT ON COLUMN public.churches.created_at      IS '등록 일시';
COMMENT ON COLUMN public.churches.updated_at      IS '최근 수정 일시';
COMMENT ON COLUMN public.churches.approved_at     IS '관리자 승인 일시';

-- ---------------------------------------------------------------------------
-- 2. users / choirs 에 church_id FK 추가 (009)
-- ---------------------------------------------------------------------------
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS church_id BIGINT REFERENCES public.churches(church_id) ON DELETE SET NULL;
COMMENT ON COLUMN public.users.church_id IS '소속 교회 ID (churches.church_id). 표시용 church_name 은 동기화 가능';
CREATE INDEX IF NOT EXISTS idx_users_church_id ON public.users(church_id);

ALTER TABLE public.choirs
  ADD COLUMN IF NOT EXISTS church_id BIGINT REFERENCES public.churches(church_id) ON DELETE SET NULL;
COMMENT ON COLUMN public.choirs.church_id IS '소속 교회 ID (churches.church_id). 표시용 church_name 은 동기화 가능';
CREATE INDEX IF NOT EXISTS idx_choirs_church_id ON public.choirs(church_id);

-- ============================================================
-- 완료. churches 테이블 + users.church_id, choirs.church_id 적용됨.
-- ============================================================
