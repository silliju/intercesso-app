# 📖 Intercesso 프로젝트 완전 문서

> **작성일**: 2026년 3월  
> **현재 버전**: APK v19  
> **백엔드**: Railway 배포 완료 (24/7 운영 중)  
> **상태**: ✅ 운영 중

---

## 📋 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [기술 스택](#2-기술-스택)
3. [시스템 아키텍처](#3-시스템-아키텍처)
4. [백엔드 파일 구조 및 역할](#4-백엔드-파일-구조-및-역할)
5. [Flutter 앱 파일 구조 및 역할](#5-flutter-앱-파일-구조-및-역할)
6. [웹앱 파일 구조 및 역할](#6-웹앱-파일-구조-및-역할)
7. [데이터베이스 구조](#7-데이터베이스-구조)
8. [API 엔드포인트 목록](#8-api-엔드포인트-목록)
9. [데이터 타입 정의](#9-데이터-타입-정의)
10. [환경변수 및 설정](#10-환경변수-및-설정)
11. [배포 현황](#11-배포-현황)
12. [로컬 개발 환경 복원 방법](#12-로컬-개발-환경-복원-방법)
13. [주요 주의사항 및 트러블슈팅](#13-주요-주의사항-및-트러블슈팅)
14. [향후 개발 계획](#14-향후-개발-계획)

---

## 1. 프로젝트 개요

### 🙏 앱 소개
**Intercesso**는 기독교 공동체를 위한 **중보기도 공유 플랫폼**입니다.  
"함께 기도하는 공동체"를 슬로건으로, 개인 기도 제목을 관리하고 서로를 위해 중보기도 할 수 있는 모바일 앱입니다.

### 핵심 기능
| 기능 | 설명 |
|------|------|
| **기도 관리** | 기도 제목 작성, 수정, 삭제, 상태 변경 (기도중 → 응답받음 → 감사) |
| **그룹** | 교회/셀/소모임/가족 그룹 생성, 초대코드로 참여 |
| **중보기도** | 다른 사용자에게 중보기도 요청 보내기/받기 (전체공개/그룹/개인) |
| **작정기도** | 7/21/40/50/100일 기간 설정, 매일 체크인 기능 |
| **기도 응답** | 응답받은 기도 간증 기록, 공개 피드 공유 |
| **통계 대시보드** | 기도 횟수, 응답률, 카테고리별 통계, 연속 기도일 |
| **알림** | 중보기도 요청, 댓글, 기도 참여 알림 |
| **소셜 로그인** | 구글 OAuth, 카카오 로그인 |
| **계정 찾기** | 닉네임으로 이메일 찾기, 비밀번호 재설정 |
| **계정 삭제** | 개인정보 처리 방침에 따른 계정 완전 삭제 |

### 앱 기본 정보
```
패키지명(Bundle ID):  com.intercesso.intercesso
앱 이름:              Intercesso
버전:                 1.0.0+1 (v19 빌드)
최소 Android:         API 21 (Android 5.0 Lollipop)
슬로건:               함께 기도하는 공동체
```

---

## 2. 기술 스택

### 📱 Frontend — Flutter 앱
```
Flutter:              3.x (최신 stable)
Dart:                 3.3.0+
상태관리:             Provider (ChangeNotifier)
라우팅:               go_router 13.x
HTTP 클라이언트:      dio ^5.4.0 + http ^1.2.0
로컬 저장소:          shared_preferences + flutter_secure_storage
소셜 로그인:          google_sign_in (Flutter 패키지)
이미지 처리:          cached_network_image, image_picker
UI 컴포넌트:          shimmer, flutter_svg, cupertino_icons
날짜/시간:            intl, timeago
```

### 🖥️ Backend — Node.js
```
Runtime:              Node.js 20.x
Framework:            Express.js 4.18.x
언어:                 TypeScript 5.3.x
인증:                 JWT (jsonwebtoken 9.x) + bcryptjs
DB 클라이언트:        @supabase/supabase-js 2.39.x
소셜 인증:            google-auth-library 10.x
보안 미들웨어:        helmet, cors
로깅:                 morgan
파일 업로드:          multer
기타:                 axios, uuid, pg
```

### 🗄️ 데이터베이스 & 인프라
```
데이터베이스:         Supabase (PostgreSQL) — 클라우드 관리형
백엔드 배포:          Railway (Node.js 서버) — 항상 켜짐 24/7
소스코드 관리:        GitHub — silliju/intercesso-backend
앱 배포:              Google Play Store (준비 중)
```

---

## 3. 시스템 아키텍처

```
┌─────────────────────────────────────────────────────┐
│                Flutter 앱 (Android)                   │
│                                                       │
│  Screens  →  Providers  →  Services  →  ApiClient    │
│  (화면)      (상태관리)     (비즈로직)    (HTTP 요청)  │
└──────────────────────────────────┬──────────────────┘
                                   │ HTTPS / REST API
                    ┌──────────────▼─────────────────────────┐
                    │         Railway 백엔드                   │
                    │  https://intercesso-backend-             │
                    │  production-5f72.up.railway.app          │
                    │                                          │
                    │  Express.js (TypeScript)                 │
                    │  ├── /api/auth        (인증)             │
                    │  ├── /api/prayers     (기도)             │
                    │  ├── /api/groups      (그룹)             │
                    │  ├── /api/intercessions (중보기도)        │
                    │  ├── /api/users       (사용자)           │
                    │  ├── /api/notifications (알림)           │
                    │  ├── /api/statistics  (통계)             │
                    │  ├── /api/answers/feed (기도응답)         │
                    │  ├── /terms           (이용약관)          │
                    │  └── /privacy         (개인정보처리방침)   │
                    └──────────────┬───────────────────────────┘
                                   │ Supabase JS SDK
                    ┌──────────────▼───────────────────────────┐
                    │         Supabase                          │
                    │  (PostgreSQL 클라우드 데이터베이스)         │
                    │  URL: ypqbkqflikdjickyywvc.supabase.co   │
                    │                                          │
                    │  테이블:                                  │
                    │  users, prayers, prayer_participants,    │
                    │  prayer_comments, groups, group_members,  │
                    │  intercession_requests, notifications,    │
                    │  user_statistics, prayer_answers,        │
                    │  prayer_answer_comments                  │
                    └──────────────────────────────────────────┘

외부 서비스:
  Google OAuth  → 구글 소셜 로그인 (ID Token 검증)
  Kakao API     → 카카오 소셜 로그인 (Access Token 검증)
```

---

## 4. 백엔드 파일 구조 및 역할

```
backend/
├── src/                          ← TypeScript 소스 (Railway가 직접 실행 안 함)
│   ├── index.ts                  ← 🚀 서버 진입점
│   ├── config/
│   │   └── supabase.ts           ← Supabase 클라이언트 초기화
│   ├── controllers/              ← 📦 비즈니스 로직 처리
│   │   ├── auth.controller.ts    ← 회원가입, 로그인, 토큰 갱신
│   │   ├── social_auth.controller.ts ← 구글/카카오 소셜 로그인
│   │   ├── prayer.controller.ts  ← 기도 CRUD, 참여, 댓글, 작정기도
│   │   ├── group.controller.ts   ← 그룹 CRUD, 초대코드, 멤버 관리
│   │   ├── intercession.controller.ts ← 중보기도 요청/응답
│   │   ├── user.controller.ts    ← 프로필 조회/수정, 계정 삭제
│   │   ├── notification.controller.ts ← 알림 목록, 읽음 처리
│   │   ├── statistics.controller.ts   ← 대시보드 통계
│   │   └── prayer_answer.controller.ts ← 기도 응답/간증
│   ├── routes/                   ← 🛣️ URL 라우팅 정의
│   │   ├── auth.routes.ts        ← /api/auth/**
│   │   ├── prayer.routes.ts      ← /api/prayers/**
│   │   ├── group.routes.ts       ← /api/groups/**
│   │   ├── intercession.routes.ts ← /api/intercessions/**
│   │   ├── user.routes.ts        ← /api/users/**
│   │   ├── notification.routes.ts ← /api/notifications/**
│   │   ├── statistics.routes.ts  ← /api/statistics/**
│   │   └── prayer_answer.routes.ts ← /api/prayers/:id/answer/**
│   ├── middleware/
│   │   └── auth.ts               ← 🔐 JWT 인증 미들웨어 (authenticate, optionalAuth)
│   ├── types/
│   │   └── index.ts              ← 📝 TypeScript 타입 정의 전체
│   └── utils/
│       └── response.ts           ← 📤 표준 API 응답 함수 (sendSuccess, sendError, sendPaginated)
├── dist/                         ← ⚙️ 컴파일된 JavaScript (Railway가 실행)
│   ├── index.js                  ← 컴파일된 서버 진입점
│   ├── config/, controllers/, routes/, middleware/, types/, utils/
│   └── (각 .ts의 .js 컴파일 버전 + .d.ts 타입 선언 + .map 소스맵)
├── .env                          ← 🔑 환경변수 (로컬 개발용, git 제외)
├── ecosystem.config.cjs          ← PM2 실행 설정 (샌드박스 개발용)
├── nixpacks.toml                 ← Railway 빌드 설정
├── railway.json                  ← Railway 배포 설정 (헬스체크, 재시작 정책)
├── package.json                  ← Node.js 패키지 및 스크립트
├── tsconfig.json                 ← TypeScript 컴파일 옵션
└── .gitignore                    ← node_modules, dist(❌제외 안 함!), .env 제외
```

### 각 파일 상세 역할

#### `src/index.ts` — 서버 진입점
- Express 앱 초기화, 미들웨어 등록 (helmet, cors, morgan)
- 모든 라우터 `/api/` 하위에 등록
- `/health` 헬스체크 엔드포인트
- `/terms`, `/privacy` HTML 페이지 서빙
- `/api/answers/feed` 기도 응답 공개 피드
- `runMigrations()` — 시작 시 DB 스키마 자동 보완 (누락 컬럼/테이블 체크)
- `PORT = process.env.PORT || 3000` — Railway가 자동으로 PORT 주입

#### `src/config/supabase.ts` — Supabase 클라이언트
- `supabase` (anon key) — 일반 쿼리용
- `supabaseAdmin` (service role key) — 관리자 권한 필요 작업 (계정 삭제 등)

#### `src/middleware/auth.ts` — JWT 인증
- `authenticate` — Bearer 토큰 필수 검증, 실패 시 401 반환
- `optionalAuth` — 토큰 있으면 파싱, 없어도 통과 (공개 기도 조회 등)

#### `src/utils/response.ts` — 표준 응답 포맷
- `sendSuccess(res, data, message, statusCode)` — 성공 응답
- `sendError(res, message, statusCode, errorCode)` — 에러 응답
- `sendPaginated(res, data, pagination)` — 페이지네이션 응답

---

## 5. Flutter 앱 파일 구조 및 역할

```
intercesso_app/
├── lib/
│   ├── main.dart                 ← 🚀 앱 진입점, Provider 설정
│   ├── config/
│   │   ├── constants.dart        ← 🔧 앱 전체 상수 (API URL, 색상, 카테고리 등)
│   │   └── theme.dart            ← 🎨 구버전 테마 (AppTheme.lightTheme 사용)
│   ├── theme/
│   │   └── app_theme.dart        ← 🎨 최신 테마 정의
│   ├── models/
│   │   └── models.dart           ← 📦 모든 데이터 모델 (UserModel, PrayerModel, GroupModel 등)
│   ├── providers/                ← 🔄 상태 관리 (ChangeNotifier)
│   │   ├── auth_provider.dart    ← 로그인 상태, 토큰 관리
│   │   ├── prayer_provider.dart  ← 기도 목록, 필터, 검색 상태
│   │   ├── group_provider.dart   ← 그룹 목록, 선택된 그룹 상태
│   │   └── notification_provider.dart ← 읽지 않은 알림 수
│   ├── services/                 ← 🌐 API 호출 로직 (비즈니스 레이어)
│   │   ├── api_service.dart      ← 구버전 API 서비스 (일부 기능)
│   │   ├── auth_service.dart     ← 로그인, 회원가입, 소셜 로그인
│   │   ├── prayer_service.dart   ← 기도 CRUD, 참여, 댓글, 작정기도
│   │   ├── group_service.dart    ← 그룹 CRUD, 초대코드
│   │   ├── intercession_service.dart ← 중보기도 요청/응답
│   │   ├── user_service.dart     ← 프로필, 계정 삭제
│   │   ├── notification_service.dart ← 알림 목록
│   │   ├── statistics_service.dart   ← 통계 대시보드
│   │   ├── prayer_answer_service.dart ← 기도 응답/간증
│   │   └── social_auth_service.dart  ← 구글/카카오 소셜 인증
│   ├── api/
│   │   └── api_client.dart       ← 🔗 Dio HTTP 클라이언트 (interceptor, 토큰 헤더)
│   ├── routes/
│   │   └── app_router.dart       ← 🛣️ go_router 라우팅 테이블 + 인증 리다이렉트
│   ├── screens/                  ← 📱 화면 (UI)
│   │   ├── splash_screen.dart    ← 앱 시작 스플래시 (자동 로그인 시도)
│   │   ├── onboarding/
│   │   │   └── onboarding_screen.dart ← 최초 실행 온보딩
│   │   ├── auth/
│   │   │   ├── login_screen.dart ← 로그인 (이메일+비밀번호, 구글, 카카오)
│   │   │   ├── signup_screen.dart ← 회원가입 (이용약관 동의 포함)
│   │   │   └── find_account_screen.dart ← 아이디/비밀번호 찾기
│   │   ├── main/
│   │   │   └── main_tab_screen.dart ← 하단 탭 네비게이션 (홈/기도/그룹/프로필)
│   │   ├── home/
│   │   │   └── home_screen.dart  ← 홈 (공개 기도 피드, 통계 요약)
│   │   ├── prayers/
│   │   │   └── prayers_screen.dart ← 내 기도 목록 (탭: 전체/기도중/응답받음/감사)
│   │   ├── prayer/
│   │   │   ├── create_prayer_screen.dart ← 기도 작성
│   │   │   ├── prayer_detail_screen.dart ← 기도 상세 (참여, 댓글, 상태변경, 응답)
│   │   │   └── prayer_edit_screen.dart   ← 기도 수정
│   │   ├── groups/
│   │   │   └── groups_screen.dart ← 그룹 목록
│   │   ├── group/
│   │   │   ├── create_group_screen.dart  ← 그룹 생성
│   │   │   └── group_detail_screen.dart  ← 그룹 상세 (멤버, 기도 목록)
│   │   ├── intercession/
│   │   │   └── intercession_screen.dart ← 중보기도 요청/받은 목록
│   │   ├── notifications/
│   │   │   └── notifications_screen.dart ← 알림 목록
│   │   ├── profile/
│   │   │   ├── profile_screen.dart ← 프로필 (내 기도통계, 계정 삭제)
│   │   │   └── edit_profile_screen.dart ← 프로필 수정
│   │   └── dashboard/
│   │       └── dashboard_screen.dart ← 통계 대시보드 (차트)
│   ├── widgets/
│   │   ├── common_widgets.dart   ← 공통 위젯 (버튼, 카드, 로딩 등)
│   │   └── prayer_answer_section.dart ← 기도 응답 섹션 위젯
│   └── utils/
│       ├── date_utils.dart       ← 날짜 포맷 유틸
│       └── helpers.dart          ← 기타 헬퍼 함수
├── android/
│   └── app/
│       ├── build.gradle          ← 앱 빌드 설정 (minSdk 21, targetSdk 34)
│       ├── google-services.json  ← Firebase 설정 (Google 로그인용)
│       └── src/main/
│           ├── AndroidManifest.xml ← 앱 권한, 딥링크 설정
│           └── res/mipmap-*/     ← 앱 아이콘 (mdpi~xxxhdpi)
├── assets/
│   ├── images/                   ← 앱 내 이미지
│   └── icons/                    ← 앱 내 아이콘
├── icon_master.png               ← 아이콘 원본 (고해상도)
├── icon_512.png                  ← 512x512 (Google Play 스토어용)
├── pubspec.yaml                  ← Flutter 패키지 의존성
└── build/app/outputs/flutter-apk/
    └── app-debug.apk             ← 빌드된 APK (v19)
```

### 화면 흐름 (네비게이션)
```
앱 시작
  └── /splash       → 자동 로그인 시도
        ├── 로그인됨  → /home (MainTabScreen)
        └── 미로그인  → /onboarding → /login

/login
  ├── 이메일/비밀번호 로그인
  ├── 구글 로그인
  ├── 카카오 로그인
  └── → /home 이동

/home (MainTabScreen) — 하단 탭
  ├── 탭 1: 홈 (공개 기도 피드)
  ├── 탭 2: 내 기도 목록
  ├── 탭 3: 그룹
  └── 탭 4: 프로필
        └── /dashboard (통계)

공통 딥링크 화면들:
  /prayer/create    → 기도 작성
  /prayer/:id       → 기도 상세
  /prayer/:id/edit  → 기도 수정
  /group/create     → 그룹 생성
  /group/:id        → 그룹 상세
  /notifications    → 알림 목록
  /profile/edit     → 프로필 수정
```

---

## 6. 웹앱 파일 구조 및 역할

```
web-app/
├── server.js             ← Express 정적 파일 서버 (포트 4000)
├── package.json          ← express 의존성
├── ecosystem.config.cjs  ← PM2 실행 설정
└── public/               ← 정적 파일 (외부 접근 가능)
    ├── index.html        ← 메인 랜딩 페이지
    ├── terms.html        ← 이용약관 (→ Railway에도 /terms로 동일 서빙)
    ├── privacy.html      ← 개인정보처리방침 (→ Railway /privacy)
    ├── docs.html         ← 기존 문서 페이지 (간략 버전)
    ├── manual.html       ← 사용 매뉴얼
    ├── railway-deploy.html ← Railway 배포 가이드 (개발용)
    ├── intercesso-v17.apk ← APK v17 다운로드
    ├── intercesso-v18.apk ← APK v18 다운로드
    ├── intercesso-v19.apk ← APK v19 다운로드 (최신)
    ├── icon_master.png   ← 앱 아이콘 원본
    └── icon_512.png      ← 앱 아이콘 512x512 (Play Store용)
```

> ⚠️ **웹앱은 샌드박스 전용입니다.** Railway 백엔드와 별개로, 샌드박스 환경에서만 실행됩니다.
> APK 다운로드 링크는 샌드박스가 켜져 있을 때만 작동합니다.

---

## 7. 데이터베이스 구조

Supabase (PostgreSQL)에서 관리됩니다.  
URL: `https://ypqbkqflikdjickyywvc.supabase.co`

### 테이블 목록

#### `users` — 사용자
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | 사용자 고유 ID |
| email | TEXT UNIQUE | 이메일 |
| password_hash | TEXT | bcrypt 암호화 비밀번호 |
| nickname | TEXT | 닉네임 |
| profile_id | TEXT UNIQUE | @멘션용 프로필 ID |
| profile_image_url | TEXT | 프로필 사진 URL |
| church_name | TEXT | 교회명 |
| denomination | TEXT | 교단 |
| bio | TEXT | 자기소개 |
| created_at | TIMESTAMPTZ | 가입일 |
| updated_at | TIMESTAMPTZ | 수정일 |
| last_login | TIMESTAMPTZ | 최근 로그인 |

#### `prayers` — 기도 제목
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | 기도 고유 ID |
| user_id | UUID FK→users | 작성자 |
| title | TEXT | 기도 제목 |
| content | TEXT | 기도 내용 |
| category | VARCHAR(20) | 건강/가정/진로/영적/사업/기타 |
| scope | VARCHAR(20) | public/friends/community/private |
| status | VARCHAR(20) | praying/answered/grateful |
| group_id | UUID FK→groups | 그룹 기도 (nullable) |
| is_covenant | BOOLEAN | 작정기도 여부 |
| covenant_days | INTEGER | 작정 기간 (7/21/40/50/100) |
| covenant_start_date | DATE | 작정 시작일 |
| target_type | VARCHAR(20) | 기도 대상 타입 |
| views_count | INTEGER | 조회수 |
| prayer_count | INTEGER | 함께기도 수 |
| created_at | TIMESTAMPTZ | 작성일 |
| updated_at | TIMESTAMPTZ | 수정일 |
| answered_at | TIMESTAMPTZ | 응답받은 날짜 |

#### `prayer_participants` — 기도 참여
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | |
| prayer_id | UUID FK→prayers | 기도 ID |
| user_id | UUID FK→users | 참여자 ID |
| created_at | TIMESTAMPTZ | 참여일 |

#### `prayer_comments` — 기도 댓글
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | |
| prayer_id | UUID FK→prayers | 기도 ID |
| user_id | UUID FK→users | 작성자 |
| content | TEXT | 댓글 내용 |
| created_at | TIMESTAMPTZ | 작성일 |
| updated_at | TIMESTAMPTZ | 수정일 |

#### `covenant_checkins` — 작정기도 체크인
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | |
| prayer_id | UUID FK→prayers | 기도 ID |
| user_id | UUID FK→users | 체크인 사용자 |
| checkin_date | DATE | 체크인 날짜 |
| created_at | TIMESTAMPTZ | |

#### `groups` — 그룹
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | |
| name | TEXT | 그룹명 |
| description | TEXT | 소개 |
| group_type | VARCHAR(20) | church/cell/gathering/family |
| creator_id | UUID FK→users | 생성자 |
| invite_code | TEXT UNIQUE | 초대 코드 |
| is_public | BOOLEAN | 공개 여부 |
| group_image_url | TEXT | 그룹 이미지 |
| member_count | INTEGER | 멤버 수 (캐시) |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

#### `group_members` — 그룹 멤버
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | |
| group_id | UUID FK→groups | 그룹 ID |
| user_id | UUID FK→users | 멤버 ID |
| role | VARCHAR(20) | admin/member |
| joined_at | TIMESTAMPTZ | 가입일 |

#### `intercession_requests` — 중보기도 요청
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | |
| prayer_id | UUID FK→prayers | 대상 기도 |
| requester_id | UUID FK→users | 요청자 |
| recipient_id | UUID FK→users | 수신자 (null=전체공개) |
| group_id | UUID FK→groups | 그룹 대상 (nullable) |
| status | VARCHAR(20) | pending/accepted/rejected |
| message | TEXT | 요청 메시지 |
| priority | VARCHAR(20) | high/normal/low |
| target_type | VARCHAR(20) | public/group/personal |
| created_at | TIMESTAMPTZ | |
| responded_at | TIMESTAMPTZ | |

#### `notifications` — 알림
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | |
| user_id | UUID FK→users | 수신자 |
| type | VARCHAR(50) | intercession_request/prayer_participation/comment/prayer_answered/group_invite |
| related_id | UUID | 관련 리소스 ID |
| title | TEXT | 알림 제목 |
| message | TEXT | 알림 내용 |
| is_read | BOOLEAN | 읽음 여부 |
| created_at | TIMESTAMPTZ | |

#### `user_statistics` — 사용자 통계
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | |
| user_id | UUID FK→users | 사용자 |
| total_prayers | INTEGER | 총 기도 수 |
| answered_prayers | INTEGER | 응답받은 기도 수 |
| grateful_prayers | INTEGER | 감사 기도 수 |
| total_participations | INTEGER | 함께기도 참여 수 |
| total_comments | INTEGER | 댓글 수 |
| streak_days | INTEGER | 연속 기도 일 수 |
| updated_at | TIMESTAMPTZ | |

#### `prayer_answers` — 기도 응답/간증 (마이그레이션 추가)
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | |
| prayer_id | UUID FK→prayers UNIQUE | 기도 ID (1:1) |
| user_id | UUID FK→users | 작성자 |
| content | TEXT | 간증 내용 |
| scope | VARCHAR(20) | public/group/private |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

#### `prayer_answer_comments` — 응답 댓글 (마이그레이션 추가)
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | |
| answer_id | UUID FK→prayer_answers | 응답 ID |
| user_id | UUID FK→users | 작성자 |
| content | TEXT | 댓글 내용 |
| created_at | TIMESTAMPTZ | |

---

## 8. API 엔드포인트 목록

**Base URL**: `https://intercesso-backend-production-5f72.up.railway.app`

### 인증 (`/api/auth`)
| Method | 경로 | 인증 | 설명 |
|--------|------|------|------|
| GET | `/api/auth/check-profile-id?id=xxx` | ❌ | 프로필ID 중복 체크 |
| POST | `/api/auth/signup` | ❌ | 회원가입 |
| POST | `/api/auth/login` | ❌ | 이메일/비밀번호 로그인 |
| POST | `/api/auth/logout` | ✅ | 로그아웃 |
| POST | `/api/auth/refresh` | ❌ | 토큰 갱신 |
| POST | `/api/auth/find-email` | ❌ | 닉네임으로 이메일 찾기 |
| POST | `/api/auth/forgot-password` | ❌ | 비밀번호 재설정 이메일 발송 |
| POST | `/api/auth/social/google` | ❌ | 구글 소셜 로그인 |
| POST | `/api/auth/social/kakao` | ❌ | 카카오 소셜 로그인 |

### 기도 (`/api/prayers`)
| Method | 경로 | 인증 | 설명 |
|--------|------|------|------|
| GET | `/api/prayers` | 선택 | 기도 목록 조회 (필터/페이지네이션) |
| GET | `/api/prayers/:id` | 선택 | 기도 상세 조회 |
| POST | `/api/prayers` | ✅ | 기도 작성 |
| PUT | `/api/prayers/:id` | ✅ | 기도 수정 |
| DELETE | `/api/prayers/:id` | ✅ | 기도 삭제 |
| POST | `/api/prayers/:id/participate` | ✅ | 함께기도 참여 |
| DELETE | `/api/prayers/:id/participate` | ✅ | 함께기도 취소 |
| POST | `/api/prayers/:id/comments` | ✅ | 댓글 작성 |
| DELETE | `/api/prayers/comments/:commentId` | ✅ | 댓글 삭제 |
| GET | `/api/prayers/:id/checkins` | ✅ | 작정기도 체크인 목록 |
| POST | `/api/prayers/:id/checkins` | ✅ | 작정기도 체크인 |
| GET | `/api/prayers/:id/answer` | 선택 | 기도 응답 조회 |
| POST | `/api/prayers/:id/answer` | ✅ | 기도 응답 작성 |
| PUT | `/api/prayers/:id/answer` | ✅ | 기도 응답 수정 |
| DELETE | `/api/prayers/:id/answer` | ✅ | 기도 응답 삭제 |
| POST | `/api/prayers/:id/answer/comments` | ✅ | 응답 댓글 작성 |
| DELETE | `/api/prayers/:id/answer/comments/:commentId` | ✅ | 응답 댓글 삭제 |

### 그룹 (`/api/groups`)
| Method | 경로 | 인증 | 설명 |
|--------|------|------|------|
| GET | `/api/groups` | ✅ | 내 그룹 목록 |
| POST | `/api/groups` | ✅ | 그룹 생성 |
| GET | `/api/groups/search?q=검색어` | ✅ | 그룹 검색 |
| POST | `/api/groups/join-by-code` | ✅ | 초대코드로 그룹 참여 |
| GET | `/api/groups/:id` | 선택 | 그룹 상세 조회 |
| PUT | `/api/groups/:id` | ✅ | 그룹 수정 |
| DELETE | `/api/groups/:id` | ✅ | 그룹 삭제 |
| POST | `/api/groups/:id/join` | ✅ | 그룹 가입 |
| DELETE | `/api/groups/:id/leave` | ✅ | 그룹 탈퇴 |
| GET | `/api/groups/:id/members` | ✅ | 그룹 멤버 목록 |
| GET | `/api/groups/:id/invite` | ✅ | 초대 코드 조회 |
| DELETE | `/api/groups/:id/members/:userId` | ✅ | 멤버 강퇴 (관리자) |

### 중보기도 (`/api/intercessions`)
| Method | 경로 | 인증 | 설명 |
|--------|------|------|------|
| GET | `/api/intercessions/search-users?q=검색어` | ✅ | 중보기도 요청 대상 사용자 검색 |
| POST | `/api/intercessions` | ✅ | 중보기도 요청 생성 |
| GET | `/api/intercessions/received` | ✅ | 받은 중보기도 목록 |
| GET | `/api/intercessions/public` | ✅ | 전체공개 중보기도 목록 |
| GET | `/api/intercessions/sent` | ✅ | 보낸 중보기도 목록 |
| PUT | `/api/intercessions/:id/respond` | ✅ | 중보기도 요청 응답 (수락/거절) |

### 사용자 (`/api/users`)
| Method | 경로 | 인증 | 설명 |
|--------|------|------|------|
| GET | `/api/users/me` | ✅ | 내 프로필 조회 |
| PUT | `/api/users/me` | ✅ | 내 프로필 수정 |
| DELETE | `/api/users/me` | ✅ | 계정 삭제 (완전 탈퇴) |
| GET | `/api/users/:id` | 선택 | 다른 사용자 프로필 조회 |
| GET | `/api/users/me/prayers` | ✅ | 내 기도 목록 |
| GET | `/api/users/me/statistics` | ✅ | 내 기도 통계 |

### 통계 (`/api/statistics`)
| Method | 경로 | 인증 | 설명 |
|--------|------|------|------|
| GET | `/api/statistics/dashboard` | ✅ | 대시보드 통계 (전체) |
| GET | `/api/statistics/prayers` | ✅ | 기도 통계 |
| GET | `/api/statistics/categories` | ✅ | 카테고리별 통계 |

### 알림 (`/api/notifications`)
| Method | 경로 | 인증 | 설명 |
|--------|------|------|------|
| GET | `/api/notifications` | ✅ | 알림 목록 |
| PUT | `/api/notifications/:id/read` | ✅ | 알림 읽음 처리 |
| PUT | `/api/notifications/read-all` | ✅ | 전체 읽음 처리 |
| DELETE | `/api/notifications/:id` | ✅ | 알림 삭제 |
| GET | `/api/notifications/preferences` | ✅ | 알림 설정 조회 |
| PUT | `/api/notifications/preferences` | ✅ | 알림 설정 변경 |

### 기타
| Method | 경로 | 인증 | 설명 |
|--------|------|------|------|
| GET | `/health` | ❌ | 헬스체크 `{"status":"ok"}` |
| GET | `/api/answers/feed` | ❌ | 공개 기도 응답 피드 |
| GET | `/terms` | ❌ | 이용약관 HTML 페이지 |
| GET | `/privacy` | ❌ | 개인정보처리방침 HTML 페이지 |

---

## 9. 데이터 타입 정의

### API 응답 포맷
```typescript
// 성공 응답
{
  success: true,
  statusCode: 200,
  message: "요청이 성공했습니다",
  data: { ... }
}

// 에러 응답
{
  success: false,
  statusCode: 401,
  message: "인증 토큰이 필요합니다",
  error: { code: "UNAUTHORIZED" }
}

// 페이지네이션 응답
{
  success: true,
  statusCode: 200,
  message: "조회 성공",
  data: [ ... ],
  pagination: {
    page: 1,
    limit: 10,
    total: 100,
    totalPages: 10
  }
}
```

### 주요 열거형 값
```
PrayerScope:    public | friends | community | private
PrayerStatus:   praying | answered | grateful
PrayerCategory: 건강 | 가정 | 진로 | 영적 | 사업 | 기타
GroupType:      church | cell | gathering | family
IntercessionStatus: pending | accepted | rejected
IntercessionPriority: high | normal | low
NotificationType: intercession_request | prayer_participation | comment | prayer_answered | group_invite
CovenantDays:   7 | 21 | 40 | 50 | 100
```

---

## 10. 환경변수 및 설정

### 백엔드 환경변수 (Railway Variables에 설정)
```env
NODE_ENV=production
PORT=(Railway 자동 주입 — 직접 설정 금지!)

# Supabase
SUPABASE_URL=https://ypqbkqflikdjickyywvc.supabase.co
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=YOUR_SUPABASE_SERVICE_ROLE_KEY

# JWT
JWT_SECRET=intercesso_jwt_secret_2026_secure_key
JWT_EXPIRES_IN=7d

# 소셜 로그인
GOOGLE_CLIENT_ID=777786565733-uklsbfk4i1mt4f7sa4daud7ih47t729b.apps.googleusercontent.com
KAKAO_REST_API_KEY=3853e9c9f28e388a2f4dc4cffed572b4
```

### Flutter 앱 상수 (`lib/config/constants.dart`)
```dart
// API URL (--dart-define으로 주입 가능)
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://intercesso-backend-production-5f72.up.railway.app/api'
);

// 앱 색상
primary:    0xFF00AAFF
secondary:  0xFF00C9A7

// 로컬 저장소 키
tokenKey:   'auth_token'
userIdKey:  'user_id'
userDataKey: 'user_data'
```

---

## 11. 배포 현황

### ✅ Railway 백엔드 (운영 중)
```
서비스:    Railway (무료→유료 전환 가능)
URL:       https://intercesso-backend-production-5f72.up.railway.app
GitHub:    https://github.com/silliju/intercesso-backend (main 브랜치 자동 배포)
포트:      Railway 자동 할당 (PORT 환경변수)
헬스체크:  /health (200 OK)
재시작:    ON_FAILURE 자동 재시작
```

### 📦 Flutter 앱 빌드 현황
```
최신 버전:   APK v19 (Debug Build)
API URL:     Railway 백엔드 연결됨
변경 내역:
  v17 - 초기 APK 빌드
  v18 - Railway URL 적용
  v19 - /terms, /privacy 링크 → Railway URL 변경
```

### ⏳ 미완료 항목
```
1. Release APK 빌드 (서명 필요)
   - 키스토어 파일 생성 필요
   - flutter build apk --release

2. Google Play Store 출시
   - 개발자 계정 등록 ($25)
   - 앱 메타데이터 작성
   - 스크린샷 준비 (최소 2장)
   - 512x512 아이콘 (icon_512.png 준비됨)
   - 1024x500 Feature Graphic 제작 필요

3. iOS 배포
   - Apple Developer 계정 필요 ($99/년)
   - Mac 또는 Codemagic 클라우드 빌드 필요
   - 빌드: flutter build ipa

4. FCM 푸시 알림
   - Firebase 설정 완료됨
   - 실제 알림 발송 로직 미구현
```

---

## 12. 로컬 개발 환경 복원 방법

### 샌드박스 복원 (GenSpark AI)
1. 백업 파일: `https://www.genspark.ai/api/files/s/5PInBZVX`
2. 새 샌드박스에서: "이 백업 파일로 프로젝트 복원하고 서비스 다시 시작해줘"
3. 자동으로 복원됨 (5~10분 소요)

### 서비스 재시작 (복원 후)
```bash
# 백엔드 (포트 3000)
cd /home/user/webapp/backend
pm2 start ecosystem.config.cjs

# 웹앱 (포트 4000)
cd /home/user/webapp/web-app
pm2 start ecosystem.config.cjs

# 확인
pm2 list
curl http://localhost:3000/health
curl http://localhost:4000/
```

### 코드 수정 후 Railway 배포
```bash
# 1. 소스 수정 후 빌드
cd /home/user/webapp/backend
npm run build  # tsc 컴파일

# 2. GitHub 푸시 → Railway 자동 배포
git add .
git commit -m "수정 내용"
git push origin main

# 3. Railway 자동 배포 완료 확인
curl https://intercesso-backend-production-5f72.up.railway.app/health
```

### Flutter APK 신규 빌드
```bash
cd /home/user/webapp/intercesso_app

# 개발용 (sandbox URL)
flutter build apk --debug

# Railway URL 사용 (배포용)
flutter build apk --debug \
  --dart-define=API_BASE_URL=https://intercesso-backend-production-5f72.up.railway.app/api \
  --dart-define=APP_WEB_URL=https://intercesso-backend-production-5f72.up.railway.app
```

---

## 13. 주요 주의사항 및 트러블슈팅

### ⚠️ Railway 배포 관련

#### PORT 설정 문제 (핵심!)
```
❌ 문제: Railway Variables에 PORT=3000 설정 → 앱이 잘못된 포트에서 실행됨
✅ 해결: Variables에서 PORT 변수 삭제. Railway가 PORT를 자동으로 주입함

코드에서는 반드시:
const PORT = process.env.PORT || 3000;
```

#### 도메인 변경 문제
```
❌ 문제: 포트 변경 후 도메인이 캐시돼서 404 반환
✅ 해결: Railway → Settings → Networking → 도메인 삭제 후 새로 생성
        새 도메인 예: intercesso-backend-production-5f72.up.railway.app
```

#### dist/ 포함 여부
```
현재 방식: dist/ 폴더를 git에 포함하여 Railway에 배포
nixpacks.toml: echo "Using pre-built dist" (TypeScript 재빌드 안 함)

⚠️ 주의: src/ 수정 후 반드시 npm run build 실행 후 dist/ 함께 커밋!
```

### ⚠️ Flutter 앱 관련

#### go_router 라우트 순서
```dart
// ❌ 충돌 발생 (/prayer/create가 /:id로 매칭됨)
GoRoute(path: '/prayer/:id', ...),
GoRoute(path: '/prayer/create', ...),

// ✅ 올바른 순서 (정적 라우트를 동적보다 먼저)
GoRoute(path: '/prayer/create', ...),
GoRoute(path: '/prayer/:id', ...),
```

#### API URL 변경 방법
```
lib/config/constants.dart의 defaultValue 수정 또는
빌드 시 --dart-define=API_BASE_URL=새URL 사용
```

#### 소셜 로그인 설정
```
구글 로그인:
  - android/app/google-services.json 있어야 함
  - OAuth Client ID: 777786565733-...apps.googleusercontent.com
  - SHA-1 인증서 지문 Google Console에 등록 필요

카카오 로그인:
  - AndroidManifest.xml에 카카오 딥링크 설정
  - Native App Key: 3853e9c9f28e388a2f4dc4cffed572b4
```

### ⚠️ Supabase 관련

#### DB 스키마 보완 (자동 마이그레이션)
```
백엔드 시작 시 runMigrations() 함수가 실행됨
다음 항목 자동 체크:
  - target_type 컬럼 (prayers 테이블)
  - group_id 컬럼 (prayers 테이블)
  - password_hash 컬럼 (users 테이블)
  - profile_id 컬럼 (users 테이블)
  - prayer_answers 테이블
  - prayer_answer_comments 테이블

누락 시 Supabase Dashboard SQL Editor에서 수동 실행 필요
→ database/migrations/002_prayer_answers.sql 참조
```

#### Service Role Key 보안
```
SUPABASE_SERVICE_ROLE_KEY는 절대 클라이언트(Flutter)에 노출 금지
백엔드 환경변수로만 사용 (계정 삭제 등 관리자 작업에 사용)
```

---

## 14. 향후 개발 계획

### 🔜 단기 (즉시 가능)
- [ ] **Release APK 빌드** — 키스토어 서명 적용
- [ ] **Google Play Store 출시** — 개발자 계정 등록
- [ ] **Feature Graphic 제작** — 1024×500 이미지 (Play Store 필수)
- [ ] **앱 스크린샷 준비** — 최소 2장 (각 화면 캡처)

### 🔜 중기 (1-3개월)
- [ ] **FCM 푸시 알림 구현** — 실제 기기 알림 발송
- [ ] **iOS 빌드** — Codemagic 클라우드 빌드 + App Store 출시
- [ ] **프로필 이미지 업로드** — Supabase Storage 또는 외부 CDN
- [ ] **기도 검색 기능 강화** — 제목+내용 전문 검색

### 🔜 장기
- [ ] **웹 버전** — 브라우저에서도 접근 가능하도록
- [ ] **다국어 지원** — 영어, 일본어
- [ ] **그룹 기도 라이브** — 실시간 기도 함께하기 기능
- [ ] **기도 통계 고도화** — 월별/연도별 리포트

---

## 📌 중요 URL 및 계정 정보

```
Railway 백엔드:    https://intercesso-backend-production-5f72.up.railway.app
GitHub 저장소:     https://github.com/silliju/intercesso-backend
Supabase 대시보드: https://app.supabase.com (ypqbkqflikdjickyywvc 프로젝트)
Railway 대시보드:  https://railway.app (silliju 계정으로 로그인)
이용약관 URL:      https://intercesso-backend-production-5f72.up.railway.app/terms
개인정보처리방침:   https://intercesso-backend-production-5f72.up.railway.app/privacy
Google Play Console: https://play.google.com/console
```

---

*문서 최종 업데이트: 2026년 3월 | 버전: APK v19 | Railway 배포 완료*
