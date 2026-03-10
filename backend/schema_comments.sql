-- ============================================================
-- INTERCESSO 데이터베이스 Description (COMMENT ON 구문)
-- Supabase (PostgreSQL) SQL Editor 에서 실행하세요.
-- ============================================================


-- ============================================================
-- 1. USERS 테이블
-- ============================================================
COMMENT ON TABLE public.users IS
  '앱 사용자 계정 정보 저장. 인증·프로필·교회 정보 등을 관리합니다.';

COMMENT ON COLUMN public.users.id IS
  '사용자 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.users.email IS
  '이메일 주소. 로그인 ID로 사용되며 중복 불가(UNIQUE).';
COMMENT ON COLUMN public.users.nickname IS
  '화면에 표시되는 닉네임';
COMMENT ON COLUMN public.users.profile_image_url IS
  '프로필 사진 URL (S3 또는 Supabase Storage 경로)';
COMMENT ON COLUMN public.users.church_name IS
  '소속 교회명 (선택 입력)';
COMMENT ON COLUMN public.users.denomination IS
  '교단명. 예: 장로교, 감리교, 침례교 (선택 입력)';
COMMENT ON COLUMN public.users.bio IS
  '자기소개 문구 (선택 입력)';
COMMENT ON COLUMN public.users.created_at IS
  '계정 최초 생성 일시 (UTC)';
COMMENT ON COLUMN public.users.updated_at IS
  '프로필 마지막 수정 일시 (트리거로 자동 갱신)';
COMMENT ON COLUMN public.users.last_login IS
  '마지막 로그인 일시 (로그인 시 백엔드에서 갱신)';


-- ============================================================
-- 2. GROUPS 테이블
-- ============================================================
COMMENT ON TABLE public.groups IS
  '기도 그룹 정보 저장. 교회·셀·소모임·가족 등 커뮤니티 단위를 관리합니다.';

COMMENT ON COLUMN public.groups.id IS
  '그룹 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.groups.name IS
  '그룹 이름';
COMMENT ON COLUMN public.groups.description IS
  '그룹 소개 설명 (선택 입력)';
COMMENT ON COLUMN public.groups.group_image_url IS
  '그룹 대표 이미지 URL (선택 입력)';
COMMENT ON COLUMN public.groups.group_type IS
  '그룹 유형. church=교회 / cell=셀·구역 / gathering=소모임 / family=가족';
COMMENT ON COLUMN public.groups.creator_id IS
  '그룹 개설자 사용자 ID (외래키 → users.id). 탈퇴 시 그룹도 함께 삭제.';
COMMENT ON COLUMN public.groups.created_at IS
  '그룹 생성 일시 (UTC)';
COMMENT ON COLUMN public.groups.updated_at IS
  '그룹 정보 마지막 수정 일시 (트리거로 자동 갱신)';
COMMENT ON COLUMN public.groups.invite_code IS
  '멤버 초대 시 사용하는 6~20자 코드 (UNIQUE). NULL이면 초대 비활성화.';
COMMENT ON COLUMN public.groups.member_count IS
  '현재 그룹 멤버 수 (group_members INSERT/DELETE 시 백엔드에서 갱신)';
COMMENT ON COLUMN public.groups.is_public IS
  '그룹 공개 여부. true=검색 노출 / false=초대 코드로만 참가 가능';


-- ============================================================
-- 3. PRAYERS 테이블
-- ============================================================
COMMENT ON TABLE public.prayers IS
  '기도제목 저장. 공개 범위·카테고리·언약기도 여부 등 기도의 핵심 정보를 관리합니다.';

COMMENT ON COLUMN public.prayers.id IS
  '기도제목 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.prayers.user_id IS
  '기도 작성자 사용자 ID (외래키 → users.id). 탈퇴 시 기도도 함께 삭제.';
COMMENT ON COLUMN public.prayers.title IS
  '기도제목 제목 (최대 255자)';
COMMENT ON COLUMN public.prayers.content IS
  '기도제목 본문 내용';
COMMENT ON COLUMN public.prayers.category IS
  '기도 카테고리. 건강 / 가정 / 진로 / 영적 / 사업 / 기타 (기본값: 기타)';
COMMENT ON COLUMN public.prayers.scope IS
  '공개 범위. public=전체공개 / friends=지인공개 / community=공동체 / private=비공개 (기본값: public)';
COMMENT ON COLUMN public.prayers.status IS
  '기도 상태. praying=기도중 / answered=응답받음 / grateful=감사 (기본값: praying)';
COMMENT ON COLUMN public.prayers.created_at IS
  '기도제목 작성 일시 (UTC)';
COMMENT ON COLUMN public.prayers.updated_at IS
  '기도제목 마지막 수정 일시 (트리거로 자동 갱신)';
COMMENT ON COLUMN public.prayers.answered_at IS
  '기도 응답받은 일시. status가 answered로 변경될 때 백엔드에서 기록.';
COMMENT ON COLUMN public.prayers.group_id IS
  '연결된 그룹 ID (외래키 → groups.id). 그룹 기도일 때만 값이 있으며, 그룹 삭제 시 NULL로 변경.';
COMMENT ON COLUMN public.prayers.is_covenant IS
  '언약기도 여부. true=언약기도 / false=일반기도 (기본값: false)';
COMMENT ON COLUMN public.prayers.covenant_days IS
  '언약기도 목표 일수. 7 / 21 / 40 / 50 / 100 중 선택 (일반기도일 때는 NULL)';
COMMENT ON COLUMN public.prayers.covenant_start_date IS
  '언약기도 시작 날짜 (DATE). 일반기도일 때는 NULL.';
COMMENT ON COLUMN public.prayers.views_count IS
  '기도제목 조회 수 (상세 화면 진입 시 +1)';
COMMENT ON COLUMN public.prayers.prayer_count IS
  '"함께 기도하기" 버튼을 누른 인원 수 (prayer_participations 기준으로 갱신)';


-- ============================================================
-- 4. PRAYER_PARTICIPATIONS 테이블
-- ============================================================
COMMENT ON TABLE public.prayer_participations IS
  '"함께 기도하기" 참여 기록. 누가 어떤 기도에 참여했는지 저장합니다.';

COMMENT ON COLUMN public.prayer_participations.id IS
  '참여 기록 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.prayer_participations.prayer_id IS
  '참여 대상 기도제목 ID (외래키 → prayers.id). 기도 삭제 시 참여 기록도 삭제.';
COMMENT ON COLUMN public.prayer_participations.user_id IS
  '함께 기도한 사용자 ID (외래키 → users.id). 탈퇴 시 참여 기록도 삭제.';
COMMENT ON COLUMN public.prayer_participations.participated_at IS
  '"함께 기도하기" 버튼을 누른 일시 (UTC)';


-- ============================================================
-- 5. COMMENTS 테이블
-- ============================================================
COMMENT ON TABLE public.comments IS
  '기도제목에 달린 댓글 저장. 응원·위로 메시지 등 커뮤니티 소통 내용을 관리합니다.';

COMMENT ON COLUMN public.comments.id IS
  '댓글 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.comments.prayer_id IS
  '댓글이 달린 기도제목 ID (외래키 → prayers.id). 기도 삭제 시 댓글도 함께 삭제.';
COMMENT ON COLUMN public.comments.user_id IS
  '댓글 작성자 사용자 ID (외래키 → users.id). 탈퇴 시 댓글도 함께 삭제.';
COMMENT ON COLUMN public.comments.content IS
  '댓글 내용 (빈 문자열 불가)';
COMMENT ON COLUMN public.comments.created_at IS
  '댓글 작성 일시 (UTC)';
COMMENT ON COLUMN public.comments.updated_at IS
  '댓글 마지막 수정 일시 (트리거로 자동 갱신)';


-- ============================================================
-- 6. INTERCESSION_REQUESTS 테이블
-- ============================================================
COMMENT ON TABLE public.intercession_requests IS
  '중보기도 요청 저장. 특정 사용자에게 중보기도를 요청하고 수락/거절 상태를 관리합니다.';

COMMENT ON COLUMN public.intercession_requests.id IS
  '중보기도 요청 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.intercession_requests.prayer_id IS
  '중보기도 대상 기도제목 ID (외래키 → prayers.id). 기도 삭제 시 요청도 함께 삭제.';
COMMENT ON COLUMN public.intercession_requests.requester_id IS
  '중보기도를 요청한 사용자 ID (외래키 → users.id)';
COMMENT ON COLUMN public.intercession_requests.recipient_id IS
  '중보기도를 받을 사용자 ID (외래키 → users.id)';
COMMENT ON COLUMN public.intercession_requests.status IS
  '요청 처리 상태. pending=수락 대기중 / accepted=수락 / rejected=거절 (기본값: pending)';
COMMENT ON COLUMN public.intercession_requests.message IS
  '요청 시 함께 보내는 메시지 (선택 입력)';
COMMENT ON COLUMN public.intercession_requests.created_at IS
  '중보기도 요청 생성 일시 (UTC)';
COMMENT ON COLUMN public.intercession_requests.responded_at IS
  '수락 또는 거절 응답 일시. 대기 중일 때는 NULL.';
COMMENT ON COLUMN public.intercession_requests.priority IS
  '요청 긴급도. high=긴급 / normal=보통 / low=낮음 (기본값: normal)';


-- ============================================================
-- 7. GROUP_MEMBERS 테이블
-- ============================================================
COMMENT ON TABLE public.group_members IS
  '그룹 멤버십 관리. 어떤 사용자가 어떤 그룹에 소속되고 어떤 역할을 맡는지 저장합니다.';

COMMENT ON COLUMN public.group_members.id IS
  '그룹 멤버십 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.group_members.group_id IS
  '소속 그룹 ID (외래키 → groups.id). 그룹 삭제 시 멤버십도 함께 삭제.';
COMMENT ON COLUMN public.group_members.user_id IS
  '멤버 사용자 ID (외래키 → users.id). 탈퇴 시 멤버십도 함께 삭제.';
COMMENT ON COLUMN public.group_members.role IS
  '그룹 내 역할. admin=관리자(그룹 설정·멤버 관리 가능) / member=일반 멤버 (기본값: member)';
COMMENT ON COLUMN public.group_members.joined_at IS
  '그룹 가입 일시 (UTC)';


-- ============================================================
-- 8. CONNECTIONS 테이블
-- ============================================================
COMMENT ON TABLE public.connections IS
  '사용자 간 친구/팔로우 관계 저장. friends 범위 기도 공유 여부 결정에 사용됩니다.';

COMMENT ON COLUMN public.connections.id IS
  '연결 관계 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.connections.user_id IS
  '연결을 시작한(팔로우한) 사용자 ID (외래키 → users.id)';
COMMENT ON COLUMN public.connections.friend_id IS
  '연결 대상(팔로우 대상) 사용자 ID (외래키 → users.id)';
COMMENT ON COLUMN public.connections.connection_type IS
  '연결 유형. friend=상호 친구 / following=단방향 팔로잉 (기본값: friend)';
COMMENT ON COLUMN public.connections.connected_at IS
  '연결(친구 추가 또는 팔로우) 일시 (UTC)';


-- ============================================================
-- 9. NOTIFICATIONS 테이블
-- ============================================================
COMMENT ON TABLE public.notifications IS
  '앱 내 알림 메시지 저장. 중보기도 요청·기도 참여·댓글·응답·그룹 초대 등 알림 내용을 관리합니다.';

COMMENT ON COLUMN public.notifications.id IS
  '알림 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.notifications.user_id IS
  '알림 수신자 사용자 ID (외래키 → users.id). 탈퇴 시 알림도 함께 삭제.';
COMMENT ON COLUMN public.notifications.type IS
  '알림 유형. intercession_request=중보요청 / prayer_participation=기도참여 / comment=댓글 / prayer_answered=기도응답 / group_invite=그룹초대';
COMMENT ON COLUMN public.notifications.related_id IS
  '알림과 연관된 대상 ID. type에 따라 기도ID·댓글ID·그룹ID 등이 들어옴.';
COMMENT ON COLUMN public.notifications.title IS
  '알림 제목 (푸시 알림 제목으로도 사용)';
COMMENT ON COLUMN public.notifications.message IS
  '알림 상세 메시지 본문 (선택 입력)';
COMMENT ON COLUMN public.notifications.is_read IS
  '읽음 여부. true=읽음 / false=미읽음 (기본값: false). 알림 탭 진입 시 일괄 true로 변경.';
COMMENT ON COLUMN public.notifications.created_at IS
  '알림 생성 일시 (UTC)';


-- ============================================================
-- 10. NOTIFICATION_PREFERENCES 테이블
-- ============================================================
COMMENT ON TABLE public.notification_preferences IS
  '사용자별 알림 수신 설정 저장. 알림 유형별로 개별 ON/OFF 가 가능합니다. 사용자 1인당 1레코드.';

COMMENT ON COLUMN public.notification_preferences.id IS
  '알림 설정 레코드 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.notification_preferences.user_id IS
  '설정 대상 사용자 ID (외래키 → users.id, UNIQUE). 탈퇴 시 설정도 함께 삭제.';
COMMENT ON COLUMN public.notification_preferences.all_notifications_enabled IS
  '전체 알림 마스터 스위치. false이면 개별 설정과 무관하게 모든 알림 비활성화.';
COMMENT ON COLUMN public.notification_preferences.intercession_request IS
  '중보기도 요청 알림 수신 여부 (기본값: true)';
COMMENT ON COLUMN public.notification_preferences.prayer_participation IS
  '"함께 기도하기" 참여 알림 수신 여부 (기본값: true)';
COMMENT ON COLUMN public.notification_preferences.comment_notification IS
  '내 기도에 달린 댓글 알림 수신 여부 (기본값: true)';
COMMENT ON COLUMN public.notification_preferences.prayer_answered IS
  '기도 응답 알림 수신 여부 (기본값: true)';
COMMENT ON COLUMN public.notification_preferences.group_notification IS
  '그룹 관련 알림 수신 여부 (기본값: false)';
COMMENT ON COLUMN public.notification_preferences.updated_at IS
  '알림 설정 마지막 수정 일시 (UTC)';


-- ============================================================
-- 11. COVENANT_CHECKINS 테이블
-- ============================================================
COMMENT ON TABLE public.covenant_checkins IS
  '언약기도 일별 체크인 기록. 몇 일째 언약을 지키고 있는지 추적합니다.';

COMMENT ON COLUMN public.covenant_checkins.id IS
  '체크인 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.covenant_checkins.prayer_id IS
  '언약기도 대상 기도제목 ID (외래키 → prayers.id). 기도 삭제 시 체크인도 함께 삭제.';
COMMENT ON COLUMN public.covenant_checkins.user_id IS
  '체크인한 사용자 ID (외래키 → users.id). 탈퇴 시 체크인도 함께 삭제.';
COMMENT ON COLUMN public.covenant_checkins.day IS
  '체크인 일차 (1일차, 2일차 …). 언약기도 시작 날짜 기준으로 계산.';
COMMENT ON COLUMN public.covenant_checkins.checked_in_at IS
  '체크인 일시 (UTC)';


-- ============================================================
-- 12. BLOCKED_USERS 테이블
-- ============================================================
COMMENT ON TABLE public.blocked_users IS
  '사용자 차단 목록. 차단된 사용자의 기도·댓글이 피드에 노출되지 않도록 합니다.';

COMMENT ON COLUMN public.blocked_users.id IS
  '차단 기록 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.blocked_users.user_id IS
  '차단을 실행한 사용자 ID (외래키 → users.id)';
COMMENT ON COLUMN public.blocked_users.blocked_user_id IS
  '차단 대상 사용자 ID (외래키 → users.id). 탈퇴 시 차단 기록도 함께 삭제.';
COMMENT ON COLUMN public.blocked_users.reason IS
  '차단 사유 (선택 입력)';
COMMENT ON COLUMN public.blocked_users.blocked_at IS
  '차단 실행 일시 (UTC)';


-- ============================================================
-- 13. REPORTS 테이블
-- ============================================================
COMMENT ON TABLE public.reports IS
  '신고 접수 기록. 부적절한 기도·댓글·사용자에 대한 신고를 저장하고 관리자 검토 상태를 관리합니다.';

COMMENT ON COLUMN public.reports.id IS
  '신고 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.reports.reporter_id IS
  '신고자 사용자 ID (외래키 → users.id). 탈퇴 시 NULL로 변경 (신고 기록은 유지).';
COMMENT ON COLUMN public.reports.report_type IS
  '신고 대상 유형. prayer=기도제목 / comment=댓글 / user=사용자';
COMMENT ON COLUMN public.reports.related_id IS
  '신고 대상의 실제 ID. report_type에 따라 기도ID·댓글ID·사용자ID가 들어옴.';
COMMENT ON COLUMN public.reports.reason IS
  '신고 사유 (필수 입력). 예: 욕설·혐오·스팸 등';
COMMENT ON COLUMN public.reports.description IS
  '신고 상세 설명 (선택 입력)';
COMMENT ON COLUMN public.reports.status IS
  '신고 처리 상태. pending=접수 대기중 / reviewed=관리자 검토중 / resolved=처리 완료 (기본값: pending)';
COMMENT ON COLUMN public.reports.created_at IS
  '신고 접수 일시 (UTC)';
COMMENT ON COLUMN public.reports.reviewed_at IS
  '관리자 검토 완료 일시. 처리 전에는 NULL.';


-- ============================================================
-- 14. USER_STATISTICS 테이블
-- ============================================================
COMMENT ON TABLE public.user_statistics IS
  '사용자별 기도 통계 집계 캐시. 대시보드에서 빠르게 통계를 표시하기 위해 별도 관리합니다. 사용자 1인당 1레코드.';

COMMENT ON COLUMN public.user_statistics.id IS
  '통계 레코드 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.user_statistics.user_id IS
  '통계 대상 사용자 ID (외래키 → users.id, UNIQUE). 탈퇴 시 통계도 함께 삭제.';
COMMENT ON COLUMN public.user_statistics.total_prayers IS
  '작성한 총 기도제목 수 (기도 생성 시 +1, 삭제 시 -1)';
COMMENT ON COLUMN public.user_statistics.answered_prayers IS
  '응답받은 기도 수 (prayers.status가 answered로 변경될 때 +1)';
COMMENT ON COLUMN public.user_statistics.grateful_prayers IS
  '감사 상태로 전환된 기도 수 (prayers.status가 grateful로 변경될 때 +1)';
COMMENT ON COLUMN public.user_statistics.total_participations IS
  '타인 기도에 "함께 기도하기"로 참여한 누적 횟수';
COMMENT ON COLUMN public.user_statistics.total_comments IS
  '작성한 총 댓글 수 (기도 댓글 + 간증 댓글 포함)';
COMMENT ON COLUMN public.user_statistics.streak_days IS
  '현재 연속 기도 일수 (스트릭). gratitude_streaks.current_streak 값과 동기화.';
COMMENT ON COLUMN public.user_statistics.updated_at IS
  '통계 마지막 갱신 일시 (각 이벤트 발생 시 백엔드에서 갱신)';


-- ============================================================
-- 15. PRAYER_ANSWERS 테이블
-- ============================================================
COMMENT ON TABLE public.prayer_answers IS
  '기도 응답 간증문 저장. 기도가 응답받았을 때 작성자가 간증을 남기는 테이블. 기도 1개당 간증 1개 제한(prayer_id UNIQUE). 등록 시 prayers.status가 answered로 자동 변경됩니다.';

COMMENT ON COLUMN public.prayer_answers.id IS
  '기도 응답 간증 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.prayer_answers.prayer_id IS
  '응답받은 기도제목 ID (외래키 → prayers.id, UNIQUE). 기도 1개당 간증 1개만 허용. 기도 삭제 시 간증도 함께 삭제.';
COMMENT ON COLUMN public.prayer_answers.user_id IS
  '간증 작성자 사용자 ID (외래키 → users.id). 백엔드에서 prayer.user_id == userId 일 때만 등록 허용(본인 기도만 간증 가능).';
COMMENT ON COLUMN public.prayer_answers.content IS
  '간증 내용 (선택). NULL 허용 → 내용 없이 응답 상태만 기록할 때 사용.';
COMMENT ON COLUMN public.prayer_answers.scope IS
  '공개 범위. public=전체 공개(응답 피드 노출, 기본값) / group=그룹 공개 / private=나만 볼 수 있음(댓글 달기 불가)';
COMMENT ON COLUMN public.prayer_answers.created_at IS
  '간증 최초 작성 일시 (UTC)';
COMMENT ON COLUMN public.prayer_answers.updated_at IS
  '간증 마지막 수정 일시 (트리거로 자동 갱신)';


-- ============================================================
-- 16. PRAYER_ANSWER_COMMENTS 테이블
-- ============================================================
COMMENT ON TABLE public.prayer_answer_comments IS
  '기도 응답 간증에 달리는 축하·감동 댓글 저장. 비공개(scope=private) 간증에는 댓글을 달 수 없으며 백엔드에서 403을 반환합니다.';

COMMENT ON COLUMN public.prayer_answer_comments.id IS
  '댓글 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.prayer_answer_comments.answer_id IS
  '댓글이 달린 기도 응답 간증 ID (외래키 → prayer_answers.id). 간증 삭제 시 댓글도 함께 삭제.';
COMMENT ON COLUMN public.prayer_answer_comments.user_id IS
  '댓글 작성자 사용자 ID (외래키 → users.id). 탈퇴 시 댓글도 함께 삭제.';
COMMENT ON COLUMN public.prayer_answer_comments.content IS
  '댓글 내용 (빈 문자열 불가, 백엔드에서 trim 후 저장). 예: "할렐루야! 기도 응답 감사해요 🙏"';
COMMENT ON COLUMN public.prayer_answer_comments.created_at IS
  '댓글 작성 일시 (UTC). 수정 기능 없음 → updated_at 없음.';


-- ============================================================
-- 17. GRATITUDE_JOURNALS 테이블
-- ============================================================
COMMENT ON TABLE public.gratitude_journals IS
  '감사일기 본문 저장. 사용자가 매일 최대 3가지 감사 항목을 기록하는 핵심 테이블. 하루 1개 제한(user_id + journal_date UNIQUE). 같은 날 재등록 시 upsert(덮어쓰기)로 처리됩니다.';

COMMENT ON COLUMN public.gratitude_journals.id IS
  '감사일기 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.gratitude_journals.user_id IS
  '작성자 사용자 ID (외래키 → users.id). 탈퇴 시 일기도 함께 삭제.';
COMMENT ON COLUMN public.gratitude_journals.journal_date IS
  '일기 날짜 (DATE, YYYY-MM-DD). user_id와 함께 UNIQUE 제약 → 하루 1개 제한. 과거 날짜 소급 입력은 허용.';
COMMENT ON COLUMN public.gratitude_journals.gratitude_1 IS
  '첫 번째 감사 항목 (필수 입력). 예: "오늘 맛있는 밥을 먹었다"';
COMMENT ON COLUMN public.gratitude_journals.gratitude_2 IS
  '두 번째 감사 항목 (선택, NULL 허용)';
COMMENT ON COLUMN public.gratitude_journals.gratitude_3 IS
  '세 번째 감사 항목 (선택, NULL 허용)';
COMMENT ON COLUMN public.gratitude_journals.emotion IS
  '오늘의 감정 태그 (선택). joy=기쁨 / peace=평안 / moved=감동 / thankful=감사 / NULL=미선택';
COMMENT ON COLUMN public.gratitude_journals.linked_prayer_id IS
  '이 일기와 연결된 기도제목 ID (외래키 → prayers.id, 선택). 기도 삭제 시 NULL로 자동 변경(ON DELETE SET NULL).';
COMMENT ON COLUMN public.gratitude_journals.scope IS
  '공개 범위. private=나만 볼 수 있음(기본값, 피드 미노출) / group=내가 속한 그룹 멤버에게 노출 / public=전체 공개(팔로우·전체 탭 피드에도 노출)';
COMMENT ON COLUMN public.gratitude_journals.created_at IS
  '레코드 최초 생성 일시 (UTC)';
COMMENT ON COLUMN public.gratitude_journals.updated_at IS
  '마지막 수정 일시 (트리거로 자동 갱신)';


-- ============================================================
-- 18. GRATITUDE_REACTIONS 테이블
-- ============================================================
COMMENT ON TABLE public.gratitude_reactions IS
  '감사일기에 대한 반응(은혜/공감) 저장. 한 사용자가 한 일기에 같은 반응을 중복으로 남길 수 없으며, 재클릭 시 반응이 취소(toggle)됩니다.';

COMMENT ON COLUMN public.gratitude_reactions.id IS
  '반응 레코드 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.gratitude_reactions.journal_id IS
  '반응 대상 감사일기 ID (외래키 → gratitude_journals.id). 일기 삭제 시 반응도 함께 삭제.';
COMMENT ON COLUMN public.gratitude_reactions.user_id IS
  '반응한 사용자 ID (외래키 → users.id). 탈퇴 시 반응도 함께 삭제.';
COMMENT ON COLUMN public.gratitude_reactions.reaction_type IS
  '반응 종류. grace=은혜(✨) / empathy=공감(🤝)';
COMMENT ON COLUMN public.gratitude_reactions.created_at IS
  '반응 생성 일시 (UTC)';


-- ============================================================
-- 19. GRATITUDE_COMMENTS 테이블
-- ============================================================
COMMENT ON TABLE public.gratitude_comments IS
  '감사일기에 달리는 응원·공감 댓글 저장. 기도제목의 comments 테이블과 별개로 감사일기 전용으로 관리됩니다.';

COMMENT ON COLUMN public.gratitude_comments.id IS
  '댓글 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.gratitude_comments.journal_id IS
  '댓글이 달린 감사일기 ID (외래키 → gratitude_journals.id). 일기 삭제 시 댓글도 함께 삭제.';
COMMENT ON COLUMN public.gratitude_comments.user_id IS
  '댓글 작성자 사용자 ID (외래키 → users.id). 탈퇴 시 댓글도 함께 삭제.';
COMMENT ON COLUMN public.gratitude_comments.content IS
  '댓글 내용 (빈 문자열 불가, 백엔드에서 trim 후 저장)';
COMMENT ON COLUMN public.gratitude_comments.created_at IS
  '댓글 작성 일시 (UTC)';
COMMENT ON COLUMN public.gratitude_comments.updated_at IS
  '댓글 마지막 수정 일시 (트리거로 자동 갱신)';


-- ============================================================
-- 20. GRATITUDE_STREAKS 테이블
-- ============================================================
COMMENT ON TABLE public.gratitude_streaks IS
  '감사일기 연속 작성 스트릭 저장. 일기 작성 시마다 updateStreak()가 자동 갱신. 당일 재수정(upsert)은 카운트에 포함되지 않으며, 하루라도 빠지면 current_streak이 1로 초기화됩니다. 사용자 1인당 1레코드.';

COMMENT ON COLUMN public.gratitude_streaks.id IS
  '스트릭 레코드 고유 식별자 (UUID, 자동 생성)';
COMMENT ON COLUMN public.gratitude_streaks.user_id IS
  '사용자 ID (외래키 → users.id, UNIQUE). 1인 1레코드. 탈퇴 시 스트릭 기록도 함께 삭제.';
COMMENT ON COLUMN public.gratitude_streaks.current_streak IS
  '현재 연속 작성 일수. 예: 오늘까지 7일 연속 작성 중 → 7. 하루라도 빠지면 1로 초기화.';
COMMENT ON COLUMN public.gratitude_streaks.longest_streak IS
  '역대 최장 연속 작성 일수. current_streak 갱신 시 함께 비교·업데이트.';
COMMENT ON COLUMN public.gratitude_streaks.last_journal_date IS
  '가장 마지막으로 감사일기를 작성한 날짜(DATE). 연속 여부 판단 기준: 오늘 날짜 - last_journal_date = 1이면 연속.';
COMMENT ON COLUMN public.gratitude_streaks.total_count IS
  '누적 감사일기 작성 횟수 (당일 재수정은 카운트 제외)';
COMMENT ON COLUMN public.gratitude_streaks.updated_at IS
  '스트릭 마지막 갱신 일시 (UTC)';
