# Intercesso Flutter App — Cursor AI Rules

## 프로젝트 개요
기독교 공동체용 **중보기도 + 찬양대 관리** Flutter 앱.
- Flutter 3.27.4 / Dart >=3.3.0
- 상태관리: Provider (ChangeNotifier)
- 라우팅: go_router 13.x
- HTTP: ApiService (lib/services/api_service.dart)
- 백엔드: https://intercesso-backend-production-5f72.up.railway.app

---

## 핵심 규칙

### 1. 라우팅
- **go_router만 사용**. `Navigator.push` / `Navigator.pop` 금지.
- `context.push('/path')`, `context.pop()` 사용.
- **정적 라우트는 반드시 동적 라우트 앞에 등록**:
  ```dart
  // ✅ 올바른 순서
  GoRoute(path: '/prayer/create', ...),
  GoRoute(path: '/prayer/:id', ...),
  ```
- 새 라우트 추가 시 → `lib/routes/app_router.dart`에만 등록.

### 2. 상태관리
- **Provider만 사용**. Riverpod, Bloc, GetX 도입 금지.
- 화면에서 상태 접근:
  ```dart
  // 읽기만 할 때
  context.read<SomeProvider>().someMethod();
  // 상태 변화 구독
  Consumer<SomeProvider>(builder: (ctx, provider, _) { ... })
  Consumer2<ProviderA, ProviderB>(builder: (ctx, a, b, _) { ... })
  ```
- Provider는 `lib/providers/` 에만 위치.
- Service는 Provider에서만 호출. 화면(Screen)에서 직접 Service 호출 금지.

### 3. API 호출 패턴
```dart
// lib/services/ 의 서비스 클래스에서만 API 호출
// ApiService 사용
final _api = ApiService();

Future<SomeModel> fetchSomething(String id) async {
  final result = await _api.get('/endpoint/$id');
  return SomeModel.fromJson(result['data']);
}

// 에러 처리
try {
  final data = await _service.fetchSomething(id);
  setState(() => _item = data);
} catch (e) {
  if (mounted) setState(() => _errorMsg = e.toString());
}
```

### 4. 찬양대 권한 체크
```dart
// Consumer2 내부에서 항상 이 패턴으로 권한 확인
final isAdmin = choir.isAdmin(auth.user?.id) || choir.isOwner(auth.user?.id);

// FAB 표시
floatingActionButton: isAdmin ? FloatingActionButton(...) : null,

// 편집/삭제 버튼
if (isAdmin) IconButton(icon: Icon(Icons.edit), onPressed: _onEdit),
```

### 5. 새 화면(Screen) 작성 규칙
```dart
// 기본 골격
class SomeScreen extends StatefulWidget {
  const SomeScreen({super.key});
  @override
  State<SomeScreen> createState() => _SomeScreenState();
}

class _SomeScreenState extends State<SomeScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      // API 호출
    } catch (e) {
      // 에러 처리
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('제목')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }
}
```

### 6. 색상 시스템
```dart
// 앱 공통 (lib/config/constants.dart)
const primary   = Color(0xFF00AAFF);
const secondary = Color(0xFF00C9A7);
const success   = Color(0xFF10B981);
const warning   = Color(0xFFF59E0B);
const error     = Color(0xFFEF4444);

// 찬양대 모듈
const choirPurple      = Color(0xFF7C3AED);
const choirPurpleLight = Color(0xFFEDE9FE);

// 출석 상태
const attendPresent = Color(0xFF10B981);
const attendAbsent  = Color(0xFFEF4444);
const attendExcused = Color(0xFFF59E0B);
```

### 7. 모델 작성 규칙
```dart
// lib/models/models.dart 또는 lib/models/choir_models.dart 에 추가
class SomeModel {
  final String id;
  final String name;
  // nullable은 String?, int? 로 선언
  final String? description;

  const SomeModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory SomeModel.fromJson(Map<String, dynamic> json) {
    return SomeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
  };
}
```

### 8. 파일 위치 규칙
| 종류 | 위치 |
|------|------|
| 화면 | `lib/screens/{모듈}/` |
| 상태관리 | `lib/providers/` |
| API 호출 | `lib/services/` |
| 데이터 모델 | `lib/models/models.dart` 또는 `choir_models.dart` |
| 라우트 | `lib/routes/app_router.dart` |
| 공통 위젯 | `lib/widgets/` |
| 상수 | `lib/config/constants.dart` |
| 유틸 | `lib/utils/` |

---

## 백엔드 규칙 (intercesso-backend/)

### 1. 응답 형식 — 반드시 표준 함수 사용
```typescript
import { sendSuccess, sendError, sendPaginated } from '../utils/response';

// 성공
sendSuccess(res, data, '성공 메시지');
sendSuccess(res, data, '생성 완료', 201);

// 에러
sendError(res, '에러 메시지', 400);
sendError(res, '서버 오류', 500, 'INTERNAL_ERROR');

// 페이지네이션
sendPaginated(res, items, { page, limit, total });
```

### 2. 인증 미들웨어
```typescript
// 인증 필수
router.get('/path', authenticate, handler);

// 인증 선택 (비로그인도 접근 가능)
router.get('/public', optionalAuth, handler);

// 핸들러에서 유저 접근
const userId = req.user!.userId;
```

### 3. Supabase 쿼리 패턴
```typescript
// 항상 supabaseAdmin 사용 (RLS 우회)
import { supabaseAdmin } from '../config/supabase';

const { data, error } = await supabaseAdmin
  .from('table_name')
  .select('*, related_table(*)')
  .eq('user_id', userId)
  .order('created_at', { ascending: false });

if (error) return sendError(res, '조회 실패', 500);
if (!data || data.length === 0) return sendError(res, '없음', 404);
```

### 4. 새 라우트/컨트롤러 추가 패턴
```typescript
// 1. src/routes/new.routes.ts 생성
import { Router } from 'express';
import * as controller from '../controllers/new.controller';
import { authenticate } from '../middleware/auth';

const router = Router();
router.get('/', authenticate, controller.getAll);
router.post('/', authenticate, controller.create);
export default router;

// 2. src/index.ts 에 등록
import newRoutes from './routes/new.routes';
app.use('/api/new', newRoutes);

// 3. npm run build → dist/ 커밋 → push (중요!)
```

### 5. 배포 워크플로우
```bash
# 소스 수정 후
npm run build        # src/*.ts → dist/*.js
git add .
git commit -m "feat: 기능 설명"
git push origin main  # Railway 자동 재배포
```

---

## 금지 사항

### Flutter
- ❌ `Navigator.push` / `Navigator.pop` (go_router 사용)
- ❌ Screen에서 직접 ApiService 호출 (Provider → Service 통해서)
- ❌ `setState` 없이 상태 변경
- ❌ `mounted` 체크 없이 비동기 후 `setState` 호출
- ❌ 하드코딩 색상 (Colors.blue 등) → AppConstants 또는 const 상수 사용
- ❌ 새 상태관리 라이브러리 도입 (Riverpod, GetX, Bloc 등)

### 백엔드
- ❌ Railway Variables에 `PORT` 수동 설정
- ❌ `src/` 수정 후 `dist/` 없이 push (반드시 `npm run build` 먼저)
- ❌ `supabase` (anon key) 로 관리자 작업 → `supabaseAdmin` 사용
- ❌ `sendSuccess` / `sendError` 대신 `res.json()` 직접 사용
- ❌ Flutter 앱에 `SUPABASE_SERVICE_ROLE_KEY` 노출

---

## 자주 쓰는 명령어

```bash
# Flutter
flutter pub get
flutter analyze                          # 분석 (error/warning 0 유지)
flutter build apk --release \
  --dart-define=API_BASE_URL=https://intercesso-backend-production-5f72.up.railway.app/api

# 백엔드
npm run build                            # TypeScript 컴파일
npm run dev                              # 개발 서버 (nodemon)
git add . && git commit -m "" && git push origin main  # Railway 배포
```

---

## 현재 우선순위 작업

1. **🔴 Supabase 찬양대 마이그레이션** — `migrations/006_choir_module_v2.sql` SQL Editor 실행
2. **🔴 constants.dart baseUrl** — Railway URL로 변경 확인
3. **🔴 출석체크 FAB 'Page Not Found'** — `context.push('/choir/attendance/${schedule.id}')` 확인
4. **🟡 찬양대 출석 권한 분기** — 비관리자는 읽기전용
5. **🟡 감사일기 보라 테마** — `Color(0xFF885CF6)` 기반 리디자인
6. **🟡 FCM 발송 구현** — `src/utils/fcm.ts` + `firebase-admin` 활용
