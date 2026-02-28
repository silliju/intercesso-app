# Intercesso - 기도 공유 플랫폼 🙏

> "함께 기도하는 공동체" - 기독교 기도 공유 모바일 앱

---

## 📋 프로젝트 개요

**Intercesso**는 기독교 공동체를 위한 기도 공유 플랫폼입니다.  
기도를 작성하고, 공유하고, 함께 기도하며, 중보기도를 요청할 수 있는 모바일 앱입니다.

- **목표**: 1년 내 10,000명 사용자, DAU 30%
- **타겟**: 20-40대 기독교인, 교회 청년, 소그룹 리더
- **론칭 예정**: 2026년 6월

---

## 🏗️ 기술 스택

### 백엔드
- **Runtime**: Node.js + TypeScript
- **Framework**: Express.js
- **Database**: Supabase (PostgreSQL)
- **Auth**: Supabase Auth + JWT
- **ORM**: Supabase JS Client

### 프론트엔드 (Flutter)
- **Framework**: Flutter 3.27.4 (Dart 3.6.2)
- **State Management**: Provider
- **Navigation**: GoRouter
- **HTTP**: http 패키지
- **Storage**: SharedPreferences + Flutter Secure Storage

---

## 📁 프로젝트 구조

```
webapp/
├── backend/                    # Node.js/TypeScript 백엔드
│   ├── src/
│   │   ├── config/
│   │   │   └── supabase.ts     # Supabase 클라이언트 설정
│   │   ├── controllers/        # 비즈니스 로직
│   │   │   ├── auth.controller.ts
│   │   │   ├── prayer.controller.ts
│   │   │   ├── group.controller.ts
│   │   │   ├── intercession.controller.ts
│   │   │   ├── notification.controller.ts
│   │   │   ├── statistics.controller.ts
│   │   │   └── user.controller.ts
│   │   ├── middleware/
│   │   │   └── auth.ts         # JWT 인증 미들웨어
│   │   ├── routes/             # API 라우트
│   │   ├── types/              # TypeScript 타입 정의
│   │   ├── utils/              # 유틸리티 함수
│   │   └── index.ts            # 앱 엔트리포인트
│   ├── schema.sql              # Supabase DB 스키마 (14 테이블)
│   ├── .env                    # 환경변수 (Supabase 자격증명)
│   ├── ecosystem.config.cjs    # PM2 설정
│   └── package.json
│
└── intercesso_app/             # Flutter 모바일 앱
    ├── lib/
    │   ├── config/
    │   │   ├── constants.dart  # API URL, 상수 정의
    │   │   └── theme.dart      # 앱 테마
    │   ├── models/             # 데이터 모델
    │   │   └── models.dart     # User, Prayer, Group, Notification 등
    │   ├── providers/          # 상태 관리
    │   │   ├── auth_provider.dart
    │   │   └── prayer_provider.dart
    │   ├── services/           # API 통신 레이어
    │   │   ├── api_service.dart        # HTTP 클라이언트
    │   │   ├── auth_service.dart       # 인증
    │   │   ├── prayer_service.dart     # 기도
    │   │   ├── group_service.dart      # 그룹
    │   │   ├── intercession_service.dart # 중보기도
    │   │   ├── notification_service.dart # 알림
    │   │   └── user_service.dart       # 사용자
    │   ├── screens/            # UI 화면 (25개 화면)
    │   │   ├── splash_screen.dart
    │   │   ├── onboarding/
    │   │   ├── auth/           # 로그인, 회원가입
    │   │   ├── main/           # 메인 탭
    │   │   ├── home/           # 홈
    │   │   ├── prayer/         # 기도 목록/작성/상세/수정
    │   │   ├── intercession/   # 중보기도
    │   │   ├── group/          # 그룹 목록/상세/생성
    │   │   ├── profile/        # 프로필/수정
    │   │   ├── notifications/  # 알림
    │   │   └── dashboard/      # 대시보드/통계
    │   ├── routes/
    │   │   └── app_router.dart # GoRouter 설정
    │   ├── widgets/
    │   │   └── common_widgets.dart
    │   └── main.dart
    ├── assets/
    │   ├── images/
    │   └── icons/
    └── pubspec.yaml
```

---

## 🗄️ 데이터베이스 (14 테이블)

| 테이블 | 설명 |
|--------|------|
| `users` | 사용자 프로필 |
| `prayers` | 기도 게시물 |
| `prayer_participations` | 기도 참여 기록 |
| `comments` | 기도 댓글 |
| `intercession_requests` | 중보기도 요청 |
| `groups` | 기도 그룹 |
| `group_members` | 그룹 멤버십 |
| `connections` | 사용자 연결/친구 |
| `notifications` | 알림 |
| `notification_preferences` | 알림 설정 |
| `covenant_checkins` | 작정기도 체크인 |
| `blocked_users` | 차단 사용자 |
| `reports` | 신고 |
| `user_statistics` | 사용자 통계 |

---

## 🔌 API 엔드포인트

### 인증 (`/api/auth`)
| Method | Path | 설명 |
|--------|------|------|
| POST | `/signup` | 회원가입 |
| POST | `/login` | 로그인 |
| POST | `/logout` | 로그아웃 |
| POST | `/refresh` | 토큰 갱신 |

### 기도 (`/api/prayers`)
| Method | Path | 설명 |
|--------|------|------|
| GET | `/` | 기도 목록 |
| POST | `/` | 기도 작성 |
| GET | `/:id` | 기도 상세 |
| PUT | `/:id` | 기도 수정 |
| DELETE | `/:id` | 기도 삭제 |
| POST | `/:id/participate` | 기도 참여 |
| DELETE | `/:id/participate` | 기도 참여 취소 |
| POST | `/:id/comments` | 댓글 작성 |
| DELETE | `/comments/:id` | 댓글 삭제 |
| GET | `/:id/checkins` | 작정기도 체크인 목록 |
| POST | `/:id/checkins` | 작정기도 체크인 |

### 그룹 (`/api/groups`)
| Method | Path | 설명 |
|--------|------|------|
| GET | `/` | 내 그룹 목록 |
| POST | `/` | 그룹 생성 |
| GET | `/:id` | 그룹 상세 |
| PUT | `/:id` | 그룹 수정 |
| DELETE | `/:id` | 그룹 삭제 |
| POST | `/:id/join` | 그룹 가입 |
| POST | `/join-by-code` | 초대코드로 가입 |
| GET | `/:id/members` | 멤버 목록 |

### 중보기도 (`/api/intercessions`)
| Method | Path | 설명 |
|--------|------|------|
| POST | `/` | 중보기도 요청 |
| GET | `/received` | 받은 요청 목록 |
| GET | `/sent` | 보낸 요청 목록 |
| PUT | `/:id/respond` | 요청 응답 |

### 알림 (`/api/notifications`)
| Method | Path | 설명 |
|--------|------|------|
| GET | `/` | 알림 목록 |
| GET | `/unread-count` | 읽지 않은 알림 수 |
| PUT | `/read-all` | 전체 읽음 처리 |
| PUT | `/:id/read` | 알림 읽음 처리 |
| DELETE | `/:id` | 알림 삭제 |
| GET | `/preferences` | 알림 설정 조회 |
| PUT | `/preferences` | 알림 설정 변경 |

---

## 🚀 시작하기

### 1. Supabase 설정
1. [Supabase Dashboard](https://supabase.com)에서 `schema.sql` 내용을 SQL Editor에 붙여넣고 실행
2. Supabase Auth 활성화 확인

### 2. 백엔드 실행

```bash
cd webapp/backend

# 의존성 설치
npm install

# 빌드
npm run build

# PM2로 실행
pm2 start ecosystem.config.cjs

# 상태 확인
pm2 status
curl http://localhost:3000/health
```

### 3. Flutter 앱 설정

```bash
cd webapp/intercesso_app

# 의존성 설치
flutter pub get

# 개발 실행 (에뮬레이터)
flutter run

# 빌드
flutter build apk --release  # Android
flutter build ios --release   # iOS
```

### 4. 환경 변수 설정
`backend/.env`:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
JWT_SECRET=your_secure_jwt_secret
PORT=3000
```

Flutter `lib/config/constants.dart`:
```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:3000/api';
```

---

## ✅ 구현 완료 기능

### 백엔드
- [x] 회원가입/로그인/로그아웃 (JWT)
- [x] 기도 CRUD (작성/조회/수정/삭제)
- [x] 기도 참여/취소
- [x] 댓글 작성/삭제
- [x] 작정기도 체크인
- [x] 그룹 CRUD + 멤버 관리
- [x] 중보기도 요청/수락/거절
- [x] 알림 시스템 (실시간 DB 기반)
- [x] 알림 설정 관리
- [x] 사용자 통계

### Flutter 앱
- [x] 스플래시 화면
- [x] 온보딩 화면
- [x] 로그인/회원가입 화면
- [x] 홈 화면 (기도 피드)
- [x] 기도 목록/상세/작성/수정 화면
- [x] 중보기도 화면
- [x] 그룹 목록/상세/생성 화면
- [x] 프로필/수정 화면
- [x] 알림 화면
- [x] 대시보드/통계 화면
- [x] GoRouter 기반 네비게이션
- [x] Provider 상태 관리
- [x] API 서비스 레이어 (7개 서비스)
- [x] 데이터 모델 (6개 모델)

---

## 📱 화면 목록 (25개)

1. 스플래시 → 2. 온보딩 → 3. 로그인 → 4. 회원가입
5. 메인탭 (홈/기도/중보기도/그룹/마이)
6. 홈 피드 → 7. 기도 목록 → 8. 기도 상세 → 9. 기도 작성 → 10. 기도 수정
11. 중보기도 요청 목록
12. 그룹 목록 → 13. 그룹 상세 → 14. 그룹 생성
15. 프로필 → 16. 프로필 수정
17. 알림 목록
18. 대시보드/통계

---

## 🔒 보안

- JWT Bearer Token 인증 (7일 만료)
- Supabase Row Level Security (RLS) 지원
- 환경변수로 민감한 키 관리
- CORS, Helmet 보안 미들웨어

---

## 📝 배포 계획

- **백엔드**: Railway 또는 Render (Node.js)
- **데이터베이스**: Supabase (이미 설정됨)
- **앱 배포**: TestFlight (iOS), Firebase App Distribution (Android)
- **출시**: App Store / Google Play (2026년 6월)

---

## ⏳ 미완료 / 다음 단계

- [ ] 파일 업로드 (프로필 이미지, 그룹 이미지) - Supabase Storage 연동
- [ ] 푸시 알림 (FCM 연동)
- [ ] 실시간 알림 (Supabase Realtime)
- [ ] 소셜 로그인 (카카오, 구글)
- [ ] 그룹 채팅
- [ ] 검색 기능 (사용자, 기도)
- [ ] 프리미엄 기능 (결제)
- [ ] 앱 빌드/배포 파이프라인 구축

---

*Last Updated: 2026-02-26*
