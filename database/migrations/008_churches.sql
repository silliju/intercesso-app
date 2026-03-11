-- ============================================================
-- 교회 테이블 (008_churches.sql)
-- 사용자가 등록하거나 관리자가 승인하는 교회 정보
-- Supabase SQL Editor에서 실행하세요.
-- ============================================================

-- 1. 테이블 생성 (변경 없음)
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

-- 2. 중복 방지: UNIQUE INDEX로 변경 (COALESCE 허용)
CREATE UNIQUE INDEX idx_churches_unique_name_address
    ON public.churches (
        name,
        si_do,
        si_gun_gu,
        COALESCE(dong, ''),
        COALESCE(detail_address, '')
    );

-- 3. 다른 인덱스들
CREATE INDEX idx_churches_location ON public.churches (latitude, longitude);
CREATE INDEX idx_churches_region   ON public.churches (si_do, si_gun_gu, dong);
CREATE INDEX idx_churches_status  ON public.churches (status);

-- 한글 유사 검색용 (pg_trgm 확장 필요 시)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_churches_name_trgm ON public.churches USING GIN (name gin_trgm_ops);

-- 4. 테이블 및 컬럼 설명 (COMMENT)
COMMENT ON TABLE public.churches IS '사용자가 등록하거나 관리자가 승인하는 교회 정보 테이블';

COMMENT ON COLUMN public.churches.church_id      IS '자동 증가하는 고유 교회 ID (PK)';
COMMENT ON COLUMN public.churches.name            IS '교회 이름 (공식 명칭, 예: 사랑의교회, 온누리교회)';
COMMENT ON COLUMN public.churches.denomination    IS '교단 이름 (예: 예장합동, 기독교대한감리회, 무교단, 기타) - 자유 입력';
COMMENT ON COLUMN public.churches.pastor_name     IS '담임목사 성함 (선택 입력, 예: 오정현 목사)';
COMMENT ON COLUMN public.churches.si_do           IS '시/도 (예: 서울특별시, 경기도, 부산광역시)';
COMMENT ON COLUMN public.churches.si_gun_gu       IS '시/군/구 (예: 강남구, 수원시 영통구, 해운대구)';
COMMENT ON COLUMN public.churches.dong            IS '동/읍/면/리 (예: 역삼동, 망우동, 진천읍)';
COMMENT ON COLUMN public.churches.detail_address  IS '상세 주소 (번지수, 건물명 등, 예: 테헤란로 123길 45, 5층)';
COMMENT ON COLUMN public.churches.road_address    IS '전체 도로명 주소 (Geocoding API 결과로 정규화 추천)';
COMMENT ON COLUMN public.churches.jibun_address   IS '전체 지번 주소 (보조용)';
COMMENT ON COLUMN public.churches.latitude        IS '위도 (Geocoding으로 얻은 값, 소수점 7자리 권장)';
COMMENT ON COLUMN public.churches.longitude       IS '경도 (Geocoding으로 얻은 값, 소수점 7자리 권장)';
COMMENT ON COLUMN public.churches.status          IS '상태: pending(대기), approved(승인), rejected(거부), deleted(삭제)';
COMMENT ON COLUMN public.churches.created_by      IS '최초 등록한 사용자 ID (users 테이블 참조)';
COMMENT ON COLUMN public.churches.created_at      IS '등록 일시 (자동 생성)';
COMMENT ON COLUMN public.churches.updated_at      IS '최근 수정 일시 (자동 업데이트)';
COMMENT ON COLUMN public.churches.approved_at     IS '관리자 승인 일시 (승인 완료 시 업데이트)';
