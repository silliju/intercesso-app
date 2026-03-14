# Railway 환경 변수 다시 등록 가이드 (intercesso-app)

아래 순서대로 하면 됩니다.

---

## 1단계: Railway 대시보드 들어가기

1. 브라우저에서 **https://railway.app** 접속 후 로그인
2. 왼쪽에서 **intercesso-app** 프로젝트 클릭
3. **intercesso-app** 서비스(백엔드가 배포된 서비스) 카드 클릭
4. 상단 탭에서 **Variables** 클릭

---

## 2단계: 변수 값 미리 준비하기

Railway에 붙여넣기 전에, **값이 비어 있는 항목**만 아래에서 복사해 두세요.

### 2-1. Supabase 키 (필수)

1. **https://supabase.com/dashboard** 접속 → 로그인
2. Intercesso용 **프로젝트** 선택 (URL이 `ypqbkqflikdjickyywvc` 인 프로젝트)
3. 왼쪽 아래 **Settings(톱니바퀴)** → **API**
4. 아래 두 개 복사해 메모장 등에 붙여넣기:
   - **Project URL** → 이걸 `SUPABASE_URL` 값으로 씀 (이미 아래 목록에 있으면 안 써도 됨)
   - **anon public** 키 (긴 문자열) → `SUPABASE_ANON_KEY` 값
   - **service_role** 키 (**Reveal** 눌러서 표시) → `SUPABASE_SERVICE_ROLE_KEY` 값  
     ⚠️ service_role은 절대 외부에 노출하지 마세요.

### 2-2. JWT 비밀키 (필수)

- 예전에 쓰던 값이 있으면 그대로 사용
- 없으면 **새로 하나 정하기**: 영문+숫자 조합 20자 이상  
  예: `intercesso_jwt_secret_2026_secure_key`  
  (한번 정하면 나중에 바꾸면 기존 로그인 전부 무효되므로 주의)

### 2-3. 그 외

- `GOOGLE_CLIENT_ID`, `KAKAO_REST_API_KEY`는 아래 목록에 이미 값이 있음 (그대로 사용 가능)
- `FRONTEND_URL`은 웹이 있다면 실제 주소로, 없다면 `https://intercesso.app` 등으로 두면 됨

---

## 3단계: Railway Variables에 넣기

### 방법 A) JSON 파일로 등록 (권장)

1. **템플릿 복사**  
   `docs/railway-env.template.json` 을 `docs/railway-env.json` 으로 복사합니다.
2. **값 채우기**  
   `docs/railway-env.json` 을 열어 `<...>` 자리를 Supabase 키·JWT_SECRET 등 **실제 값**으로 바꿉니다. (2단계에서 준비한 값 사용)
3. **붙여넣기용 텍스트 만들기**  
   프로젝트 루트에서 실행:
   ```bash
   node docs/railway-env-to-paste.js docs/railway-env.json
   ```
   터미널에 출력된 `KEY=value` 목록 **전체**를 복사합니다.
4. **Railway에 붙여넣기**  
   Variables 탭 → **Raw Editor** 클릭 → 복사한 내용 붙여넣기 → **저장**.

> ⚠️ `docs/railway-env.json` 에는 비밀키가 들어가므로 **Git에 커밋하지 마세요.**  
> `.gitignore` 에 `docs/railway-env.json` 이 있으면 안전합니다.

### 방법 B) 직접 붙여넣기

1. **Variables** 탭에서 **「Raw Editor」** 버튼 클릭  
   (또는 "Import from..." / "Bulk add" 같은 메뉴가 있으면 그걸로 한꺼번에 넣기 가능한지 확인)
2. 아래 **전체**를 복사해서 Raw Editor **텍스트 칸에 붙여넣기**
3. `<...>` 로 된 부분만 **2단계에서 준비한 실제 값**으로 바꾸기:
   - `SUPABASE_ANON_KEY=<...>` → `SUPABASE_ANON_KEY=eyJhbGci...` (본인 anon 키)
   - `SUPABASE_SERVICE_ROLE_KEY=<...>` → `SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...` (본인 service_role 키)
   - `JWT_SECRET=<...>` → `JWT_SECRET=intercesso_jwt_secret_2026_secure_key` (본인이 정한 비밀키)
4. **저장** (Save / Update Variables 등)

**붙여넣을 내용 (복사용):**

```
NODE_ENV=production
SUPABASE_URL=https://ypqbkqflikdjickyywvc.supabase.co
SUPABASE_ANON_KEY=<Supabase anon public 키>
SUPABASE_SERVICE_ROLE_KEY=<Supabase service_role 키>
JWT_SECRET=<본인 JWT 비밀키>
JWT_EXPIRES_IN=7d
GOOGLE_CLIENT_ID=777786565733-uklsbfk4i1mt4f7sa4daud7ih47t729b.apps.googleusercontent.com
KAKAO_REST_API_KEY=3853e9c9f28e388a2f4dc4cffed572b4
FRONTEND_URL=https://intercesso.app
```

**주의:**

- `PORT`는 Railway가 자동으로 넣으므로 **추가하지 마세요.**
- 줄 맨 앞뒤에 공백 없이, **한 줄에 하나씩** `이름=값` 형식으로만 넣기
- 값에 `=` 이 들어가면 그대로 두면 됨 (예: JWT 키 안의 `=`)

---

## 4단계: 푸시 알림만 쓸 때 추가 (선택)

푸시 알림(FCM)을 쓰는 경우에만 다음을 추가합니다.

1. **Firebase Console** → 프로젝트 설정 → **서비스 계정** → **키 생성** → JSON 다운로드
2. JSON 파일을 열어 **전체를 한 줄**로 만듦 (줄바꿈·들여쓰기 제거)
3. Railway Variables에 아래 한 줄 추가:

```
FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account","project_id":"...","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"...",...}
```

(위 `...` 자리에 실제 JSON 내용 한 줄이 들어갑니다.)

---

## 5단계: 재배포해서 적용하기

1. 같은 서비스 화면에서 **Deployments** 탭으로 이동
2. 맨 위 최신 배포 오른쪽 **⋮** (또는 "Redeploy") 클릭
3. **Redeploy** 선택
4. 배포가 끝날 때까지 대기 (몇 분 소요될 수 있음)
5. 상태가 **Success** / **Active** 로 바뀌면 환경 변수 적용 완료

변수를 저장할 때 Railway가 "변경 사항 적용을 위해 재배포할까요?"라고 묻는 경우, **예** 하면 5단계는 생략해도 됩니다.

---

## 6단계: Railway 정상 동작 확인

### 1) 대시보드에서 확인

- Railway → **Deployments** 탭에서 최신 배포 상태가 **Success** / **Active** 인지 확인
- **Metrics** 탭에서 CPU·메모리·요청이 찍히는지 확인

### 2) 헬스체크 URL로 확인

백엔드 서비스의 **공개 URL**을 알아야 합니다.

- Railway → 해당 서비스 → **Settings** → **Networking** (또는 **Domains**) 에서 **Public URL** 확인  
  예: `https://intercesso-app-production-xxxx.up.railway.app`  
  (프로젝트마다 `xxxx` 부분이 다를 수 있음)

아래 주소를 **브라우저**에 열거나, 터미널에서 실행:

```
https://<여기에_공개_URL>/health
```

**정상이면** 예시처럼 JSON이 보입니다:

```json
{"status":"ok","timestamp":"2026-03-11T...","service":"Intercesso API"}
```

**안 되면** (연결 실패, 5xx, 타임아웃) → 배포 실패·환경 변수 누락·헬스체크 실패 가능성 있음.

### 3) curl로 확인 (선택)

터미널에서 (공개 URL을 알고 있을 때):

```bash
curl https://<공개_URL>/health
```

`{"status":"ok",...}` 가 나오면 서버는 정상 기동된 것입니다.

### 4) 앱에서 확인

- 앱을 실행해서 **로그인**, **오늘의 말씀**, **중보 요청 목록** 등 API를 쓰는 화면이 에러 없이 동작하면 Railway 백엔드가 정상 동작하는 것입니다.

---

## 요약 체크리스트

- [ ] Railway → intercesso-app 서비스 → Variables
- [ ] Supabase에서 anon 키, service_role 키 복사
- [ ] JWT_SECRET 정해서 메모
- [ ] Raw Editor에 위 9줄 붙여넣고 `<...>` 만 실제 값으로 수정
- [ ] 저장
- [ ] Redeploy 한 번 실행
- [ ] 배포 성공 확인

이렇게 하면 환경 변수 다시 등록까지 완료됩니다.
