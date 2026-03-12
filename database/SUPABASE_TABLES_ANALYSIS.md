# Intercesso 앱 – Supabase 테이블 분석

> 이 문서는 **프로젝트 내 스키마/마이그레이션/백엔드 코드**를 기준으로 정리한 것입니다.  
> Supabase 대시보드에 실제로 어떤 테이블이 있는지는 **Supabase Dashboard → Table Editor**에서 확인해야 합니다.

---

## 1. 핵심 스키마 출처

| 출처 | 설명 |
|------|------|
| `backend/schema.sql` | 사용자, 기도, 그룹, 알림, 기도 응답, 감사일기 등 기본 테이블 |
| `database/migrations/002_prayer_answers.sql` | 기도 응답·간증 댓글 (또는 schema.sql 15·16번과 중복 정의) |
| `database/migrations/003_fcm_token.sql` | `users.fcm_token` 컬럼 추가 |
| `database/migrations/004_choir_module.sql` | 찬양대 기본 테이블 (choirs, choir_members, choir_schedules 등) |
| `database/migrations/005_gratitude_journal.sql` | 감사일기 전용 테이블 (또는 schema.sql 17~20번과 중복) |
| `database/migrations/006_choir_module_v2.sql` | 찬양대 확장 컬럼·테이블 (choir_invites, choir_join_requests, choir_materials 등) |

---

## 2. 전체 테이블 목록 (알파벳 순)

### 2.1 인증·사용자

| 테이블 | 설명 | 주요 컬럼 |
|--------|------|-----------|
| **users** | 앱 사용자 (계정·프로필) | id, email, nickname, profile_image_url, church_name, denomination, bio, created_at, updated_at, last_login, password_hash(자체인증), fcm_token(003) |

---

### 2.2 기도

| 테이블 | 설명 | 주요 컬럼 |
|--------|------|-----------|
| **prayers** | 기도제목 | id, user_id, title, content, category, scope, status, group_id, is_covenant, covenant_days, prayer_count, views_count, created_at, updated_at, answered_at |
| **prayer_participations** | 함께 기도하기 참여 | id, prayer_id, user_id, participated_at |
| **comments** | 기도제목 댓글 | id, prayer_id, user_id, content, created_at, updated_at |
| **covenant_checkins** | 언약기도 일별 체크인 | id, prayer_id, user_id, day, checked_in_at |
| **prayer_answers** | 기도 응답 간증 (1기도 1간증) | id, prayer_id, user_id, content, scope, created_at, updated_at |
| **prayer_answer_comments** | 간증 댓글 | id, answer_id, user_id, content, created_at |

※ 백엔드 `user.controller`에서는 `prayer_checkins`를 참조합니다. 스키마에는 **covenant_checkins**만 정의되어 있으므로, 실제 DB 테이블명이 다르면 마이그레이션/코드 정리가 필요할 수 있습니다.

---

### 2.3 그룹·연결

| 테이블 | 설명 | 주요 컬럼 |
|--------|------|-----------|
| **groups** | 기도 그룹 (교회/셀/소모임/가족) | id, name, description, group_image_url, group_type, creator_id, invite_code, member_count, is_public, created_at, updated_at |
| **group_members** | 그룹 멤버십 | id, group_id, user_id, role(admin/member), joined_at |
| **connections** | 사용자 간 친구/팔로우 | id, user_id, friend_id, connection_type, connected_at |

※ 감사일기 피드에서 백엔드가 `user_connections`를 참조합니다. 스키마에는 **connections**만 있으므로, 뷰/별칭이 있거나 코드와 테이블명 불일치일 수 있습니다.

---

### 2.4 중보·알림

| 테이블 | 설명 | 주요 컬럼 |
|--------|------|-----------|
| **intercession_requests** | 중보기도 요청 | id, prayer_id, requester_id, recipient_id, status, message, target_type, group_id(선택), created_at, responded_at, priority |
| **notifications** | 알림 | id, user_id, type, related_id, title, message, is_read, created_at |
| **notification_preferences** | 알림 설정 (1인 1행) | id, user_id, all_notifications_enabled, intercession_request, prayer_participation, comment_notification, prayer_answered, group_notification, updated_at |

---

### 2.5 감사일기

| 테이블 | 설명 | 주요 컬럼 |
|--------|------|-----------|
| **gratitude_journals** | 감사일기 (하루 1개) | id, user_id, journal_date, gratitude_1, gratitude_2, gratitude_3, emotion, linked_prayer_id, scope, created_at, updated_at |
| **gratitude_reactions** | 감사일기 반응 (은혜/공감) | id, journal_id, user_id, reaction_type, created_at |
| **gratitude_comments** | 감사일기 댓글 | id, journal_id, user_id, content, created_at, updated_at |
| **gratitude_streaks** | 연속 작성 스트릭 (1인 1행) | id, user_id, current_streak, longest_streak, last_journal_date, total_count, updated_at |

---

### 2.6 찬양대 (choir)

| 테이블 | 설명 | 주요 컬럼 |
|--------|------|-----------|
| **choirs** | 찬양대 기본 정보 | id, name, church_name, description, invite_code, invite_link_active, owner_id, member_count, image_url, worship_type(s), practice_schedule, practice_location, is_public, status, created_at, updated_at (004+006) |
| **choir_members** | 찬양대원 | id, choir_id, user_id, role, section, status, joined_at, position, phone, note, receive_notification, join_method (004+006) |
| **choir_schedules** | 찬양대 일정 | id, choir_id, title, description, schedule_type, start_time, end_time, location, is_confirmed, created_by, created_at, updated_at, worship_type, conductor_id, accompanist_id 등 (004+006) |
| **choir_attendance** | 일정별 출석 (004) | id, schedule_id, choir_id, member_id, user_id, status(present/absent/excused), note, checked_by, checked_at, created_at, updated_at(006) |
| **choir_songs** | 찬양곡 목록 | id, choir_id, title, composer, arranger, parts, youtube_url, genre, difficulty, notes, created_by, created_at, updated_at, hymn_book_ref 등 (004+006) |
| **choir_schedule_songs** | 일정–곡 연결 | id, schedule_id, song_id, order_index |
| **choir_notices** | 찬양대 공지 | id, choir_id, author_id, title, content, target_section, is_pinned, created_at, updated_at |
| **choir_invites** (006) | 초대 링크/코드 | id, choir_id, created_by, invite_code, invite_link, target_section, max_uses, used_count, expires_at, is_active, created_at |
| **choir_join_requests** (006) | 가입 신청 | id, choir_id, user_id, invite_id, requested_section, join_method, status, reviewed_by, reviewed_at, reject_reason, created_at |
| **choir_materials** (006) | 자료실 (악보/영상/파일) | id, choir_id, schedule_id, song_id, uploaded_by, title, description, material_type, file_url, youtube_url, target_section, created_at, updated_at |
| **choir_parts** (006) | 파트 구성 | id, choir_id, part_name, part_key, color_hex, target_count, display_order, is_active |

※ 백엔드 `choir.controller`는 출석 테이블을 **choir_attendances**(복수형)로, 자료실을 **choir_files**로 참조합니다.  
  마이그레이션에는 **choir_attendance**(단수), **choir_materials**만 정의되어 있으므로, 실제 DB/뷰 이름이 다르면 라우트 404나 쿼리 오류 원인이 될 수 있습니다.

---

### 2.7 기타 (보안·통계)

| 테이블 | 설명 | 주요 컬럼 |
|--------|------|-----------|
| **blocked_users** | 차단 목록 | id, user_id, blocked_user_id, reason, blocked_at |
| **reports** | 신고 | id, reporter_id, report_type, related_id, reason, description, status, created_at, reviewed_at |
| **user_statistics** | 사용자 통계 캐시 (1인 1행) | id, user_id, total_prayers, answered_prayers, grateful_prayers, total_participations, total_comments, streak_days, updated_at |

---

## 3. 테이블 수 요약

| 구분 | 테이블 수 |
|------|-----------|
| schema.sql + 마이그레이션 기준 | 약 **28개** (뷰 제외) |
| 백엔드에서 참조하는 이름 기준 | 위와 대부분 일치, 일부 이름 불일치 가능 (choir_attendances vs choir_attendance, choir_files vs choir_materials, user_connections vs connections, prayer_checkins vs covenant_checkins) |

---

## 4. 실제 DB와 비교하는 방법

1. **Supabase Dashboard** → **Table Editor**: 위 테이블이 모두 존재하는지 확인.
2. **SQL Editor**에서 예시:
   ```sql
   SELECT table_name
   FROM information_schema.tables
   WHERE table_schema = 'public'
     AND table_type = 'BASE TABLE'
   ORDER BY table_name;
   ```
   실행 후, 위 목록과 비교해 누락/추가된 테이블을 확인하면 됩니다.

---

## 5. 참고 파일 경로

- `backend/schema.sql` – 기본 스키마
- `backend/src/controllers/*.ts` – 테이블 참조 (`.from('테이블명')`)
- `database/migrations/*.sql` – 증분 마이그레이션

이 문서는 위 파일들을 기준으로 생성되었습니다.
