# Intercesso Backend — Cursor AI Rules

## 프로젝트 개요
Intercesso Flutter 앱의 REST API 백엔드.
- Node.js 20.x + Express 4.18 + TypeScript 5.3
- DB: Supabase PostgreSQL (supabaseAdmin / service_role key)
- 배포: Railway (dist/ 폴더 포함 커밋 방식)
- Flutter 앱: https://github.com/silliju/intercesso-app

---

## 핵심 규칙

### 1. 표준 응답 함수 — 반드시 사용
```typescript
import { sendSuccess, sendError, sendPaginated } from '../utils/response';

// ✅ 성공
sendSuccess(res, data);
sendSuccess(res, data, '생성 완료', 201);

// ✅ 에러
sendError(res, '에러 메시지', 400);
sendError(res, '서버 오류', 500, 'INTERNAL_ERROR');

// ✅ 페이지네이션
sendPaginated(res, items, { page, limit, total });

// ❌ 직접 사용 금지
res.json({ success: true, data: ... });
```

### 2. 인증 미들웨어
```typescript
import { authenticate, optionalAuth } from '../middleware/auth';

router.get('/protected', authenticate, handler);   // 필수
router.get('/public',    optionalAuth, handler);   // 선택

// 핸들러에서 userId 접근
const userId = req.user!.userId;
```

### 3. Supabase 쿼리 패턴
```typescript
// 항상 supabaseAdmin 사용 (RLS 우회)
import { supabaseAdmin } from '../config/supabase';

const { data, error } = await supabaseAdmin
  .from('table_name')
  .select('*, user:users(id, nickname, profile_image_url)')
  .eq('id', id)
  .single();

if (error || !data) return sendError(res, '조회 실패', 404);
sendSuccess(res, data);
```

### 4. 새 기능 추가 순서
```
1. src/routes/new.routes.ts    — Express 라우터 정의
2. src/controllers/new.controller.ts — 비즈니스 로직
3. src/index.ts                — app.use('/api/new', newRoutes) 등록
4. npm run build               — dist/ 재생성 (필수!)
5. git add . && git commit && git push origin main
```

### 5. 배포 워크플로우
```bash
# src/ 수정 후 반드시 이 순서
npm run build
git add .
git commit -m "feat/fix: 설명"
git push origin main
# → Railway 자동 재배포 (2~3분)
# → curl https://intercesso-backend-production-5f72.up.railway.app/health 로 확인
```

---

## 금지 사항

- ❌ Railway Variables에 `PORT` 수동 설정 (자동 주입)
- ❌ `src/` 수정 후 `npm run build` 없이 push
- ❌ `supabase` (anon key) 로 관리자 작업 → `supabaseAdmin` 사용
- ❌ `res.json()` 직접 사용 → sendSuccess/sendError 사용
- ❌ Flutter 앱 측에 `SUPABASE_SERVICE_ROLE_KEY` 전달/노출

---

## 환경변수 (.env)

```env
# PORT는 Railway가 자동 주입 → 절대 수동 설정 금지
NODE_ENV=production
SUPABASE_URL=https://ypqbkqflikdjickyywvc.supabase.co
SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...
JWT_SECRET=intercesso_jwt_secret_2026_secure_key
JWT_EXPIRES_IN=7d
GOOGLE_CLIENT_ID=777786565733-uklsbfk4i1mt4f7sa4daud7ih47t729b.apps.googleusercontent.com
KAKAO_REST_API_KEY=3853e9c9f28e388a2f4dc4cffed572b4
```

---

## 파일 구조

```
src/
├── index.ts                 ← 서버 진입점 (미들웨어, 라우터 등록)
├── config/supabase.ts       ← supabase + supabaseAdmin
├── controllers/             ← 비즈니스 로직 (DB 조회/수정)
├── routes/                  ← Express 라우터
├── middleware/auth.ts        ← authenticate / optionalAuth
├── types/index.ts           ← TypeScript 타입 전체
└── utils/
    ├── response.ts          ← sendSuccess / sendError / sendPaginated
    └── fcm.ts               ← FCM 유틸 (미완성 → 구현 필요)
```

---

## DB 마이그레이션 규칙

- 마이그레이션 파일: `migrations/00N_설명.sql`
- 실행: Supabase Dashboard → SQL Editor (직접 실행)
- **`migrations/006_choir_module_v2.sql`** — 찬양대 테이블 8개 (아직 미실행!)

---

## 현재 우선순위 작업

1. **🔴 `migrations/006_choir_module_v2.sql` Supabase 실행**
2. **🟡 `src/utils/fcm.ts` FCM 발송 구현** (firebase-admin 사용)
3. **🟡 찬양대 컨트롤러 예외처리 보강**
