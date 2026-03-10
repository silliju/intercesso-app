-- ═══════════════════════════════════════════════════════════════
-- 007_choir_comments.sql
-- 찬양대 모듈 테이블·컬럼 한글 주석 추가
-- 실행 위치: Supabase Dashboard > SQL Editor
-- 006_choir_module_v2.sql 실행 후에 실행하세요
-- ═══════════════════════════════════════════════════════════════


-- ────────────────────────────────────────────────────────────────
-- 1. choirs (찬양대 기본 정보)
-- ────────────────────────────────────────────────────────────────
COMMENT ON TABLE  public.choirs                    IS '찬양대 기본 정보 (한 교회에 여러 찬양대 가능)';
COMMENT ON COLUMN public.choirs.id                 IS '찬양대 고유 ID (UUID)';
COMMENT ON COLUMN public.choirs.name               IS '찬양대 이름 (예: 주일 찬양대, 청년 찬양대)';
COMMENT ON COLUMN public.choirs.description        IS '찬양대 소개글 (선택)';
COMMENT ON COLUMN public.choirs.image_url          IS '찬양대 대표 이미지 URL (선택)';
COMMENT ON COLUMN public.choirs.church_name        IS '소속 교회 이름 (선택)';
COMMENT ON COLUMN public.choirs.worship_type       IS '담당 예배 유형 (예: 주일1부, 청년예배, 수요예배)';
COMMENT ON COLUMN public.choirs.owner_id           IS '찬양대 소유자(생성자) user ID → users.id 참조';
COMMENT ON COLUMN public.choirs.invite_code        IS '초대 코드 8자리 대문자+숫자 (예: AB12CD34), UNIQUE';
COMMENT ON COLUMN public.choirs.invite_link_active IS '초대 링크 활성화 여부 (false = 초대 비활성화)';
COMMENT ON COLUMN public.choirs.member_count       IS '현재 활성 단원 수 캐시 값 (increment/decrement 함수로 관리)';
COMMENT ON COLUMN public.choirs.created_at         IS '찬양대 생성 일시';
COMMENT ON COLUMN public.choirs.updated_at         IS '마지막 수정 일시 (트리거 자동 갱신)';


-- ────────────────────────────────────────────────────────────────
-- 2. choir_members (찬양대원)
-- ────────────────────────────────────────────────────────────────
COMMENT ON TABLE  public.choir_members             IS '찬양대원 정보 (찬양대 ↔ 사용자 다대다 연결)';
COMMENT ON COLUMN public.choir_members.id          IS '멤버십 고유 ID (UUID)';
COMMENT ON COLUMN public.choir_members.choir_id    IS '소속 찬양대 ID → choirs.id 참조';
COMMENT ON COLUMN public.choir_members.user_id     IS '단원 사용자 ID → users.id 참조';
COMMENT ON COLUMN public.choir_members.role        IS '역할: conductor(지휘자) / section_leader(파트장) / treasurer(총무) / member(단원)';
COMMENT ON COLUMN public.choir_members.section     IS '성부: soprano(소프라노) / alto(알토) / tenor(테너) / bass(베이스) / all(전체)';
COMMENT ON COLUMN public.choir_members.status      IS '가입 상태: pending(승인대기) / active(활성) / inactive(비활성)';
COMMENT ON COLUMN public.choir_members.joined_at   IS '가입(신청) 일시';


-- ────────────────────────────────────────────────────────────────
-- 3. choir_schedules (찬양대 일정)
-- ────────────────────────────────────────────────────────────────
COMMENT ON TABLE  public.choir_schedules                IS '찬양대 일정 (연습, 예배, 특별행사 등)';
COMMENT ON COLUMN public.choir_schedules.id             IS '일정 고유 ID (UUID)';
COMMENT ON COLUMN public.choir_schedules.choir_id       IS '소속 찬양대 ID → choirs.id 참조';
COMMENT ON COLUMN public.choir_schedules.title          IS '일정 제목 (예: 주일예배 연습, 수요 파트 연습)';
COMMENT ON COLUMN public.choir_schedules.schedule_type  IS '일정 유형: rehearsal(연습) / pre_service_practice(예배전연습) / service(예배) / post_service_practice(예배후연습) / weekday_practice(평일연습) / special_event(특별행사)';
COMMENT ON COLUMN public.choir_schedules.location       IS '장소 (예: 찬양실, 본당, 선택)';
COMMENT ON COLUMN public.choir_schedules.start_time     IS '일정 시작 일시 (TIMESTAMPTZ)';
COMMENT ON COLUMN public.choir_schedules.end_time       IS '일정 종료 일시 (선택)';
COMMENT ON COLUMN public.choir_schedules.description    IS '일정 상세 설명 / 준비사항 메모 (선택)';
COMMENT ON COLUMN public.choir_schedules.created_by     IS '일정 생성자 user ID → users.id 참조';
COMMENT ON COLUMN public.choir_schedules.created_at     IS '일정 생성 일시';
COMMENT ON COLUMN public.choir_schedules.updated_at     IS '마지막 수정 일시 (트리거 자동 갱신)';


-- ────────────────────────────────────────────────────────────────
-- 4. choir_songs (찬양곡 목록)
-- ────────────────────────────────────────────────────────────────
COMMENT ON TABLE  public.choir_songs                IS '찬양대에서 사용하는 찬양곡 목록';
COMMENT ON COLUMN public.choir_songs.id             IS '곡 고유 ID (UUID)';
COMMENT ON COLUMN public.choir_songs.choir_id       IS '소속 찬양대 ID → choirs.id 참조';
COMMENT ON COLUMN public.choir_songs.title          IS '곡 제목 (예: 주님의 은혜, 할렐루야)';
COMMENT ON COLUMN public.choir_songs.composer       IS '작곡가 이름 (선택)';
COMMENT ON COLUMN public.choir_songs.arranger       IS '편곡자 이름 (선택)';
COMMENT ON COLUMN public.choir_songs.hymn_book_ref  IS '찬송가 참조 번호 (예: 찬송가 19장, 선택)';
COMMENT ON COLUMN public.choir_songs.youtube_url    IS 'YouTube 연습 영상 링크 (선택)';
COMMENT ON COLUMN public.choir_songs.genre          IS '장르 (예: 현대 찬양, 찬송가, 클래식, 복음성가)';
COMMENT ON COLUMN public.choir_songs.difficulty     IS '난이도: easy(쉬움) / medium(보통) / hard(어려움)';
COMMENT ON COLUMN public.choir_songs.parts          IS '필요 성부 배열 (예: {soprano,alto,tenor,bass})';
COMMENT ON COLUMN public.choir_songs.notes          IS '연습 포인트 / 메모 (선택)';
COMMENT ON COLUMN public.choir_songs.created_by     IS '곡 등록자 user ID → users.id 참조';
COMMENT ON COLUMN public.choir_songs.created_at     IS '곡 등록 일시';
COMMENT ON COLUMN public.choir_songs.updated_at     IS '마지막 수정 일시 (트리거 자동 갱신)';


-- ────────────────────────────────────────────────────────────────
-- 5. choir_schedule_songs (일정 ↔ 찬양곡 연결)
-- ────────────────────────────────────────────────────────────────
COMMENT ON TABLE  public.choir_schedule_songs             IS '일정과 찬양곡 다대다 연결 (어떤 일정에 어떤 곡을 부를지)';
COMMENT ON COLUMN public.choir_schedule_songs.id          IS '연결 고유 ID (UUID)';
COMMENT ON COLUMN public.choir_schedule_songs.schedule_id IS '대상 일정 ID → choir_schedules.id 참조';
COMMENT ON COLUMN public.choir_schedule_songs.song_id     IS '대상 곡 ID → choir_songs.id 참조';
COMMENT ON COLUMN public.choir_schedule_songs.order_num   IS '해당 일정 내 곡 순서 (1번부터 시작, 1 = 첫 번째 곡)';


-- ────────────────────────────────────────────────────────────────
-- 6. choir_attendances (출석 기록)
-- ────────────────────────────────────────────────────────────────
COMMENT ON TABLE  public.choir_attendances             IS '찬양대 일정별 단원 출석 기록';
COMMENT ON COLUMN public.choir_attendances.id          IS '출석 기록 고유 ID (UUID)';
COMMENT ON COLUMN public.choir_attendances.schedule_id IS '대상 일정 ID → choir_schedules.id 참조';
COMMENT ON COLUMN public.choir_attendances.member_id   IS '대상 단원 ID → choir_members.id 참조';
COMMENT ON COLUMN public.choir_attendances.status      IS '출석 상태: present(출석) / absent(결석) / excused(공결)';
COMMENT ON COLUMN public.choir_attendances.note        IS '결석·공결 사유 메모 (선택)';
COMMENT ON COLUMN public.choir_attendances.marked_at   IS '출석 체크 일시';
COMMENT ON COLUMN public.choir_attendances.marked_by   IS '출석 체크한 관리자 user ID → users.id 참조';


-- ────────────────────────────────────────────────────────────────
-- 7. choir_notices (공지사항)
-- ────────────────────────────────────────────────────────────────
COMMENT ON TABLE  public.choir_notices                IS '찬양대 공지사항 (지휘자/관리자 → 단원 공지)';
COMMENT ON COLUMN public.choir_notices.id             IS '공지사항 고유 ID (UUID)';
COMMENT ON COLUMN public.choir_notices.choir_id       IS '소속 찬양대 ID → choirs.id 참조';
COMMENT ON COLUMN public.choir_notices.author_id      IS '공지 작성자 user ID → users.id 참조';
COMMENT ON COLUMN public.choir_notices.title          IS '공지 제목';
COMMENT ON COLUMN public.choir_notices.content        IS '공지 본문 내용';
COMMENT ON COLUMN public.choir_notices.is_pinned      IS '상단 고정 여부 (true = 항상 맨 위 표시)';
COMMENT ON COLUMN public.choir_notices.target_section IS '대상 성부 (NULL=전체, soprano/alto/tenor/bass)';
COMMENT ON COLUMN public.choir_notices.view_count     IS '공지 조회수';
COMMENT ON COLUMN public.choir_notices.created_at     IS '공지 작성 일시';
COMMENT ON COLUMN public.choir_notices.updated_at     IS '마지막 수정 일시 (트리거 자동 갱신)';


-- ────────────────────────────────────────────────────────────────
-- 8. choir_files (자료실)
-- ────────────────────────────────────────────────────────────────
COMMENT ON TABLE  public.choir_files                  IS '찬양대 자료실 (악보, 연습 영상, 음원, 문서 등)';
COMMENT ON COLUMN public.choir_files.id               IS '파일 고유 ID (UUID)';
COMMENT ON COLUMN public.choir_files.choir_id         IS '소속 찬양대 ID → choirs.id 참조';
COMMENT ON COLUMN public.choir_files.title            IS '파일 제목 (예: 주님의 은혜 - 소프라노 악보)';
COMMENT ON COLUMN public.choir_files.description      IS '파일 설명 (선택)';
COMMENT ON COLUMN public.choir_files.file_type        IS '파일 유형: score(악보) / video(영상) / audio(음원) / document(문서)';
COMMENT ON COLUMN public.choir_files.file_url         IS '파일 다운로드 URL (악보, 음원, 문서 등, 선택)';
COMMENT ON COLUMN public.choir_files.youtube_url      IS 'YouTube 링크 (영상 자료, 선택) — file_url 또는 youtube_url 중 하나 필수';
COMMENT ON COLUMN public.choir_files.target_section   IS '대상 성부 (NULL=전체, soprano/alto/tenor/bass)';
COMMENT ON COLUMN public.choir_files.uploaded_by      IS '업로드한 단원 user ID → users.id 참조';
COMMENT ON COLUMN public.choir_files.created_at       IS '파일 업로드 일시';
