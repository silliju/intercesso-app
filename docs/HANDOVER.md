# Intercesso — Cursor AI 인수인계 문서

> **작성일**: 2026-03-13  
> **최신 커밋**: `29cc34d` (intercesso-app) / `main` (intercesso-backend)  
> **Flutter analyze**: error 0 / warning 0  
> **백엔드**: Railway 24/7 운영 중 ✅

---

## 1. 프로젝트 한 줄 요약

기독교 공동체용 **중보기도 + 찬양대 관리** Flutter 앱.  
슬로건: "함께 기도하는 공동체"

---

## 2. 저장소 구조

```
GitHub: silliju (계정)
├── silliju/intercesso-app      ← Flutter 앱 (이 저장소)
└── silliju/intercesso-backend  ← Node.js 백엔드
```

**클론 방법:**
```bash
# 앱
git clone https://github.com/silliju/intercesso-app.git
cd intercesso-app && flutter pub get

# 백엔드
git clone https://github.com/silliju/intercesso-backend.git
cd intercesso-backend && npm install
```

---

## 3. 기술 스택

### Flutter 앱
| 항목 | 내용 |
|------|------|
| Flutter | 3.27.4 stable |
| Dart SDK | >=3.3.0 |
| 상태관리 | Provider 6.x (ChangeNotifier) |
| 라우팅 | go_router 13.x |
| HTTP | ApiService (http 패키지 래퍼) + Dio 5.x |
| 로컬저장소 | shared_preferences + flutter_secure_storage |
| 소셜로그인 | google_sign_in |
| 차트 | fl_chart |
| 알림 | firebase_messaging + flutter_local_notifications |
| URL | url_launcher, share_plus |

### 백엔드 (Node.js)
| 항목 | 내용 |
|------|------|
| Runtime | Node.js 20.x |
| Framework | Express 4.18 + TypeScript 5.3 |
| 인증 | JWT (jsonwebtoken) + bcryptjs |
| DB | @supabase/supabase-js 2.39 |
| 소셜인증 | google-auth-library |
| 보안 | helmet, cors, morgan |
| 배포 | Railway (dist/ 폴더 포함 커밋 방식) |

### 인프라
| 항목 | 내용 |
|------|------|
| DB | Supabase PostgreSQL (ypqbkqflikdjickyywvc) |
| 백엔드 호스팅 | Railway (자동 재배포) |
| 앱 배포 | Google Play Store (준비 중) |

---

## 4. 아키텍처

```
Flutter App
  └─ screens/ (UI)
  └─ providers/ (상태: ChangeNotifier)
  └─ services/ (API 호출)
  └─ api/api_client.dart (ApiService 래퍼)
         │
         │ HTTPS REST API
         ▼
Railway Backend (Express + TypeScript)
  └─ routes/ → controllers/ → supabaseAdmin
         │
         │ Supabase JS SDK (service_role key)
         ▼
Supabase PostgreSQL
```

**인증 흐름:**
```
1. POST /api/auth/login → { token, user }
2. token → shared_preferences 저장
3. 모든 요청: Authorization: Bearer {token}
4. 만료 시 → POST /api/auth/refresh
```

---

## 5. 환경변수

### 백엔드 `.env` (Railway Variables에도 동일 설정)
```env
# PORT 는 Railway가 자동 주입 → 절대 수동 설정 금지!
NODE_ENV=production

SUPABASE_URL=https://ypqbkqflikdjickyywvc.supabase.co
SUPABASE_ANON_KEY=<Supabase 대시보드에서 확인>
SUPABASE_SERVICE_ROLE_KEY=<Supabase 대시보드에서 확인>

JWT_SECRET=intercesso_jwt_secret_2026_secure_key
JWT_EXPIRES_IN=7d

GOOGLE_CLIENT_ID=777786565733-uklsbfk4i1mt4f7sa4daud7ih47t729b.apps.googleusercontent.com
KAKAO_REST_API_KEY=3853e9c9f28e388a2f4dc4cffed572b4
```

### Flutter 앱 (`lib/config/constants.dart`)
```dart
// APK 빌드 시 --dart-define으로 오버라이드 가능
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://intercesso-backend-production-5f72.up.railway.app/api',
);
```
> ⚠️ 현재 `defaultValue`가 샌드박스 URL로 세팅되어 있을 수 있음.  
> **로컬 개발 전 반드시 Railway URL로 변경할 것.**
```dart
defaultValue: 'https://intercesso-backend-production-5f72.up.railway.app/api',
```

---

## 6. 프로젝트 파일 구조

### Flutter 앱 (`intercesso-app/lib/`)
```
lib/
├── main.dart                    ← Provider 등록, GoRouter 초기화, FCM 설정
├── config/
│   ├── constants.dart           ← API URL, 색상, 카테고리 상수 전부
│   └── theme.dart               ← 구버전 테마 (AppTheme.lightTheme)
├── theme/app_theme.dart         ← 최신 테마 정의
├── models/
│   ├── models.dart              ← UserModel, PrayerModel, GroupModel,
│   │                               GratitudeModel, IntercessionModel 등
│   └── choir_models.dart        ← ChoirModel, ChoirMemberModel,
│                                   ChoirScheduleModel, ChoirSongModel 등
├── providers/                   ← ChangeNotifier 상태관리
│   ├── auth_provider.dart       ← 로그인 상태, 토큰, 자동로그인
│   ├── prayer_provider.dart     ← 기도 목록, 필터, 검색
│   ├── group_provider.dart      ← 그룹 목록, 선택 그룹
│   ├── notification_provider.dart ← 읽지 않은 알림 수
│   ├── gratitude_provider.dart  ← 감사일기 피드/달력 상태
│   └── choir_provider.dart      ← 찬양대 전체 상태 (API + Mock 폴백)
├── services/                    ← API 호출 레이어
│   ├── api_service.dart         ← 기본 HTTP 클라이언트 (GET/POST/PUT/DELETE)
│   ├── auth_service.dart
│   ├── prayer_service.dart
│   ├── group_service.dart
│   ├── intercession_service.dart
│   ├── user_service.dart
│   ├── notification_service.dart
│   ├── statistics_service.dart
│   ├── prayer_answer_service.dart
│   ├── social_auth_service.dart
│   ├── gratitude_service.dart
│   ├── fcm_service.dart         ← FCM 초기화만 (실제 발송 미구현)
│   └── choir_service.dart
├── api/api_client.dart          ← ApiService의 얇은 래퍼 (하위 호환)
├── routes/app_router.dart       ← GoRouter 라우팅 테이블 + 인증 리다이렉트
├── screens/
│   ├── splash_screen.dart
│   ├── onboarding/
│   ├── auth/                    ← login, signup, find_account
│   ├── main/main_tab_screen.dart ← 하단 탭 (홈/기도/그룹/프로필)
│   ├── home/                    ← 홈 피드, 오늘의 말씀
│   ├── prayers/                 ← 내 기도 목록
│   ├── prayer/                  ← 기도 CRUD 상세화면
│   ├── groups/ + group/         ← 그룹 목록 + 상세
│   ├── intercession/            ← 중보기도 요청/받기
│   ├── notifications/
│   ├── profile/                 ← 프로필 + 수정
│   ├── dashboard/               ← 통계 차트
│   ├── gratitude/               ← 감사일기 (피드/캘린더/작성/상세)
│   └── choir/                   ← 찬양대 모듈 (10개 화면)
├── widgets/
│   ├── common_widgets.dart
│   └── prayer_answer_section.dart
└── utils/
    ├── date_utils.dart
    ├── helpers.dart
    └── url_utils.dart
```

### 백엔드 (`intercesso-backend/src/`)
```
src/
├── index.ts                     ← 서버 진입점, 미들웨어, 라우터 등록
├── config/supabase.ts           ← supabase (anon) + supabaseAdmin (service_role)
├── controllers/                 ← 비즈니스 로직
│   ├── auth.controller.ts
│   ├── social_auth.controller.ts
│   ├── prayer.controller.ts
│   ├── prayer_answer.controller.ts
│   ├── group.controller.ts
│   ├── intercession.controller.ts
│   ├── user.controller.ts
│   ├── notification.controller.ts
│   ├── statistics.controller.ts
│   ├── gratitude.controller.ts
│   └── choir.controller.ts
├── routes/                      ← Express 라우터
│   └── *.routes.ts
├── middleware/auth.ts            ← authenticate / optionalAuth
├── types/index.ts               ← TypeScript 타입 전체
└── utils/
    ├── response.ts              ← sendSuccess / sendError / sendPaginated
    └── fcm.ts                   ← FCM 유틸 (미완성)
```

---

## 7. 라우트 전체 목록

```dart
// ── 인증 ─────────────────────────────────
/splash           → SplashScreen
/onboarding       → OnboardingScreen
/login            → LoginScreen
/signup           → SignupScreen
/find-account     → FindAccountScreen

// ── 메인 탭 ──────────────────────────────
/home             → MainTabScreen
  탭0: HomeScreen      (공개 기도 피드)
  탭1: PrayersScreen   (내 기도 목록)
  탭2: GroupsScreen    (그룹 목록)
  탭3: ProfileScreen

// ── 기도 ─────────────────────────────────
// ⚠️ 정적 라우트는 반드시 동적 라우트보다 먼저!
/prayer/create    → CreatePrayerScreen
/prayer/:id/edit  → PrayerEditScreen
/prayer/:id       → PrayerDetailScreen

// ── 그룹 ─────────────────────────────────
/group/create     → CreateGroupScreen
/group/:id        → GroupDetailScreen

// ── 기타 ─────────────────────────────────
/profile/edit     → EditProfileScreen
/notifications    → NotificationsScreen
/dashboard        → DashboardScreen (fl_chart 통계)

// ── 감사일기 ──────────────────────────────
/gratitude           → GratitudeFeedScreen
/gratitude/calendar  → GratitudeCalendarScreen
/gratitude/create    → CreateGratitudeScreen

// ── 찬양대 모듈 ───────────────────────────
/choir              → ChoirHomeScreen
/choir/create       → ChoirCreateScreen
/choir/join         → ChoirJoinScreen
/choir/schedules    → ChoirSchedulesScreen
/choir/schedule/:id → ChoirScheduleDetailScreen
/choir/members      → ChoirMembersScreen
/choir/attendance/:scheduleId → ChoirAttendanceScreen
/choir/stats        → ChoirAttendanceStatsScreen
/choir/library      → ChoirLibraryScreen
/choir/management   → ChoirManagementScreen
/choir/songs        → ChoirSongScreen
/choir/notices      → ChoirNoticeScreen
```

---

## 8. API 엔드포인트 요약

**Base URL**: `https://intercesso-backend-production-5f72.up.railway.app`

| 접두사 | 설명 |
|--------|------|
| `/api/auth` | 회원가입, 로그인, 소셜로그인, 토큰갱신 |
| `/api/prayers` | 기도 CRUD + 참여 + 댓글 + 작정기도 + 응답/간증 |
| `/api/gratitude` | 감사일기 CRUD + 피드 + 댓글 + 리액션 + 스트릭 |
| `/api/choir` | 찬양대 CRUD + 일정 + 출석 + 찬양곡 + 공지 + 자료실 |
| `/api/groups` | 그룹 CRUD + 초대코드 + 멤버 |
| `/api/intercessions` | 중보기도 요청/수락/거절 |
| `/api/users` | 프로필 조회/수정/삭제 |
| `/api/statistics` | 통계 대시보드 |
| `/api/notifications` | 알림 목록 + 읽음 처리 |
| `/health` | 헬스체크 `{"status":"ok"}` |
| `/terms`, `/privacy` | HTML 페이지 |

---

## 9. DB 스키마 요약

### 기존 테이블
| 테이블 | 설명 |
|--------|------|
| `users` | 이메일/닉네임/소셜/프로필/교회 |
| `prayers` | 기도제목 (scope, status, category, covenant) |
| `prayer_participants` | 함께기도 참여 |
| `prayer_comments` | 기도 댓글 |
| `covenant_checkins` | 작정기도 체크인 |
| `prayer_answers` | 기도 응답/간증 (prayer와 1:1) |
| `prayer_answer_comments` | 응답 댓글 |
| `groups` | 그룹 (church/cell/gathering/family) |
| `group_members` | 그룹 멤버 (admin/member) |
| `intercession_requests` | 중보기도 요청 (public/group/personal) |
| `notifications` | 알림 |
| `user_statistics` | 기도 통계 캐시 |
| `gratitude_journals` | 감사일기 (감사1/2/3, scope) |
| `gratitude_reactions` | 감사 리액션 |
| `gratitude_comments` | 감사 댓글 |

### 찬양대 테이블 (migration 006)
> ⚠️ **Supabase SQL Editor에서 `migrations/006_choir_module_v2.sql` 실행 필요!**

| 테이블 | 설명 |
|--------|------|
| `choirs` | 찬양대 기본정보 + 초대코드 |
| `choir_members` | 단원 (role: conductor/section_leader/treasurer/member) |
| `choir_schedules` | 일정 (rehearsal/service/special_event 등) |
| `choir_songs` | 찬양곡 목록 |
| `choir_schedule_songs` | 일정↔곡 다대다 |
| `choir_attendances` | 출석 (present/absent/excused) |
| `choir_notices` | 공지사항 (핀 고정 가능) |
| `choir_files` | 자료실 (score/video/audio/document) |

---

## 10. 완료된 작업

### 기도/그룹/중보기도 모듈
- [x] 이메일 회원가입/로그인
- [x] 구글 OAuth + 카카오 로그인
- [x] 기도제목 CRUD + 공개범위 + 카테고리
- [x] 작정기도 (7/21/40/50/100일 체크인)
- [x] 기도 응답/간증 CRUD + 댓글
- [x] 함께기도 참여/취소
- [x] 그룹 CRUD + 초대코드 + 멤버 관리
- [x] 중보기도 요청 → 수락/거절
- [x] 통계 대시보드 (fl_chart)
- [x] 알림 목록
- [x] 프로필 수정 + 계정 완전 삭제

### 감사일기 모듈
- [x] 매일 3가지 감사 작성
- [x] 피드 (그룹/전체)
- [x] 달력 뷰 + 스트릭
- [x] 댓글 실제 API 연동 (`gratitude_comments` 파싱)
- [x] 리액션 토글

### 찬양대 모듈
- [x] 찬양대 생성/가입/초대코드 API 연동
- [x] 찬양대 홈 (퀵메뉴, 이번 주 일정, 설정 버튼 → `/choir/management`)
- [x] 일정 CRUD + 수정(기존 데이터 채움) + 공유(클립보드)
- [x] 출석 체크 (전체출석 FAB, 성부 필터, 진행률 바)
- [x] 출석 통계 (월별/주별)
- [x] 찬양곡 관리 CRUD
- [x] 공지사항 CRUD (핀 고정)
- [x] 자료실 (파일/YouTube 링크 등록 API 연동)
- [x] 멤버 관리 (역할/성부 변경, 강퇴, 가입 승인)
- [x] 권한 시스템 (isAdmin/isOwner → FAB·편집·삭제 UI 분기)

### 코드 품질
- [x] Flutter analyze: error 0, warning 0
- [x] 미사용 변수/import 전부 제거
- [x] APK Release 빌드 성공 (29.5MB)

---

## 11. 다음 할 작업 (우선순위 순)

### 🔴 즉시 처리 필요

#### 1. Supabase 찬양대 마이그레이션 실행
```
Supabase Dashboard → SQL Editor
→ intercesso-backend/migrations/006_choir_module_v2.sql 전체 복붙 실행
```
이 작업 없이는 찬양대 기능이 실제 DB에서 동작하지 않음.

#### 2. `constants.dart` API URL 수정
현재 샌드박스 URL이 남아있을 수 있음:
```dart
// lib/config/constants.dart 에서 아래로 변경
defaultValue: 'https://intercesso-backend-production-5f72.up.railway.app/api',
```

#### 3. 출석체크 FAB → 'Page Not Found' 오류 수정
- `choir_schedule_screen.dart`의 ChoirScheduleDetailScreen
- `_buildActionButtons` 내 출석 체크 버튼 onPressed 확인
- 올바른 라우트: `context.push('/choir/attendance/${schedule.id}')`

### 🟡 중간 우선순위

#### 4. 찬양대 출석 화면 UX 개선
- 홈에서 이번 주 일정 클릭 시: 읽기전용(출석 현황만 표시)
- 관리자만 출석 수정 가능하도록 권한 분기
  ```dart
  // choir_attendance_screen.dart
  if (!isAdmin) → 저장 버튼 숨김, 체크 비활성화
  ```

#### 5. 감사일기 디자인 리디자인
- 현재: 흰색 배경 기본 스타일
- 목표: 찬양대 테마처럼 보라/퍼플 그라데이션
  ```dart
  const gratitudeColor = Color(0xFF885CF6);
  const gratitudeLightColor = Color(0xFFEDE9FE);
  ```

#### 6. FCM 푸시 알림 실제 구현
- Firebase 설정 완료 (`google-services.json` 포함)
- `lib/services/fcm_service.dart` → FCM 초기화만, 발송 미구현
- 백엔드 `src/utils/fcm.ts` 작성 필요
- 이벤트: 중보기도 요청 수신, 댓글, 기도 참여

### 🟢 낮은 우선순위

#### 7. Release APK 서명
```bash
keytool -genkey -v -keystore intercesso.jks \
  -alias intercesso -keyalg RSA -keysize 2048 -validity 10000
flutter build apk --release
```

#### 8. Google Play Store 출시 준비
- Feature Graphic (1024×500) 제작
- 스크린샷 최소 2장
- 앱 설명 한국어 작성

#### 9. 프로필 이미지 업로드
- 현재: URL만 저장
- Supabase Storage 또는 외부 CDN 활용

---

## 12. 코딩 컨벤션

### Flutter
```dart
// 1. Provider 접근
Consumer2<ChoirProvider, AuthProvider>(
  builder: (ctx, choir, auth, _) { ... }
)

// 2. 라우팅 — go_router만 사용 (Navigator.push 금지)
context.push('/choir/schedule/$id');
context.pop();

// 3. 찬양대 권한 체크 패턴
final isAdmin = choir.isAdmin(auth.user?.id) || choir.isOwner(auth.user?.id);

// 4. 에러 처리 패턴
try {
  await service.doSomething();
} catch (e) {
  if (mounted) setState(() => _error = e.toString());
}

// 5. API 호출 패턴 (서비스 레이어)
final result = await _apiService.get('/endpoint');
return SomeModel.fromJson(result['data']);
```

### 백엔드 TypeScript
```typescript
// 1. 표준 응답
sendSuccess(res, data, '성공');
sendError(res, '실패 메시지', 400);
sendPaginated(res, items, { page, limit, total });

// 2. Supabase 쿼리
const { data, error } = await supabaseAdmin
  .from('table')
  .select('*')
  .eq('user_id', req.user!.userId);
if (error) return sendError(res, '조회 실패', 500);

// 3. 라우트 등록
router.get('/path', authenticate, handlerFn);
router.get('/public', optionalAuth, handlerFn);
```

### 디자인 색상 시스템
```dart
// 앱 공통
primary:    Color(0xFF00AAFF)  // 파란색
secondary:  Color(0xFF00C9A7)  // 청록색
success:    Color(0xFF10B981)  // 초록
warning:    Color(0xFFF59E0B)  // 노랑
error:      Color(0xFFEF4444)  // 빨강

// 찬양대 모듈
purple:      Color(0xFF7C3AED)  // 보라 (메인)
purpleLight: Color(0xFFEDE9FE)  // 연보라 (배경)

// 출석 상태
present: Color(0xFF10B981)  // 초록
absent:  Color(0xFFEF4444)  // 빨강
excused: Color(0xFFF59E0B)  // 노랑
```

---

## 13. 주요 주의사항

### ⚠️ 백엔드 배포 (Railway)
```
❌ Railway Variables에 PORT 수동 설정 → 절대 금지
✅ Railway가 PORT를 자동 주입함
   코드: const PORT = process.env.PORT || 3000;

❌ src/ 수정 후 바로 push
✅ npm run build → dist/ 커밋 → push (dist/ 포함 필수!)

도메인 오류 시:
  Railway → Settings → Networking → 도메인 삭제 후 재생성
```

### ⚠️ Flutter go_router
```dart
// ❌ 충돌 발생 (/prayer/create가 /:id 로 매칭됨)
GoRoute(path: '/prayer/:id', ...),
GoRoute(path: '/prayer/create', ...),

// ✅ 정적 라우트를 항상 동적 라우트 앞에 등록
GoRoute(path: '/prayer/create', ...),
GoRoute(path: '/prayer/:id', ...),
```

### ⚠️ Supabase 보안
```
supabaseAdmin (service_role key) → 백엔드에서만 사용
Flutter 앱에 절대 노출 금지!
```

### ⚠️ 찬양대 Provider Mock 폴백
```dart
// choir_provider.dart: API 실패 시 Mock 데이터로 폴백됨
// 개발 편의를 위해 추가된 기능
// 실 서비스 전 제거 권장 (_mockChoirs(), _mockMembers() 등)
```

---

## 14. 중요 URL 모음

```
백엔드 URL:       https://intercesso-backend-production-5f72.up.railway.app
헬스체크:         .../health
이용약관:         .../terms
개인정보처리방침:  .../privacy

GitHub (앱):      https://github.com/silliju/intercesso-app
GitHub (백엔드):  https://github.com/silliju/intercesso-backend

Supabase:         https://app.supabase.com (프로젝트: ypqbkqflikdjickyywvc)
Railway:          https://railway.app (silliju 계정)
Firebase:         https://console.firebase.google.com (프로젝트: intercesso-7924d)
Google Play:      https://play.google.com/console
```

---

*최종 업데이트: 2026-03-13 | Flutter 3.27.4 | Node.js 20.x | APK Release v1*
