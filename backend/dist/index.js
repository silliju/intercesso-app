"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const morgan_1 = __importDefault(require("morgan"));
const dotenv_1 = __importDefault(require("dotenv"));
const supabase_1 = __importDefault(require("./config/supabase"));
const auth_routes_1 = __importDefault(require("./routes/auth.routes"));
const prayer_routes_1 = __importDefault(require("./routes/prayer.routes"));
const user_routes_1 = __importDefault(require("./routes/user.routes"));
const group_routes_1 = __importDefault(require("./routes/group.routes"));
const intercession_routes_1 = __importDefault(require("./routes/intercession.routes"));
const notification_routes_1 = __importDefault(require("./routes/notification.routes"));
const statistics_routes_1 = __importDefault(require("./routes/statistics.routes"));
const gratitude_routes_1 = __importDefault(require("./routes/gratitude.routes"));
const choir_routes_1 = __importDefault(require("./routes/choir.routes"));
const prayer_answer_controller_1 = require("./controllers/prayer_answer.controller");
const auth_1 = require("./middleware/auth");
dotenv_1.default.config();
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3000;
// DB 마이그레이션 상태 확인 (로그 출력용)
async function runMigrations() {
    try {
        // intercession_requests target_type 컬럼 확인
        const { error: icError } = await supabase_1.default
            .from('intercession_requests')
            .select('target_type')
            .limit(0);
        if (icError && icError.message.includes('target_type')) {
            console.log('⚠️  DB 컬럼 부족 - Supabase Dashboard SQL Editor에서 실행 필요:');
            console.log(`
ALTER TABLE intercession_requests
  ADD COLUMN IF NOT EXISTS target_type TEXT DEFAULT 'individual',
  ADD COLUMN IF NOT EXISTS group_id UUID REFERENCES groups(id) ON DELETE SET NULL;
UPDATE intercession_requests SET target_type = 'individual' WHERE target_type IS NULL;
      `);
        }
        // users 테이블에 password_hash 컬럼 자동 추가 (자체 인증 지원)
        const { error: pwError } = await supabase_1.default
            .from('users')
            .select('password_hash')
            .limit(0);
        if (pwError && pwError.message.includes('password_hash')) {
            console.log('🔧 users.password_hash 컬럼 추가 시도...');
            // Supabase REST API로는 DDL 실행 불가 → 안내 출력
            console.log('⚠️  Supabase Dashboard SQL Editor에서 아래 SQL 실행 필요:');
            console.log(`
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS password_hash TEXT;
      `);
        }
        else {
            console.log('✅ users.password_hash 컬럼 확인 완료');
        }
        // prayer_answers 테이블 확인
        const { error: paError } = await supabase_1.default
            .from('prayer_answers')
            .select('id')
            .limit(0);
        if (paError && (paError.code === '42P01' || paError.message.includes('prayer_answers'))) {
            console.log('⚠️  prayer_answers 테이블 없음 - Supabase Dashboard SQL Editor에서 실행 필요:');
            console.log(`
-- 1. 기도 응답 테이블
CREATE TABLE IF NOT EXISTS public.prayer_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prayer_id UUID NOT NULL REFERENCES public.prayers(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content TEXT,
  scope VARCHAR(20) DEFAULT 'public' NOT NULL CHECK (scope IN ('public', 'group', 'private')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  UNIQUE(prayer_id)
);
CREATE INDEX IF NOT EXISTS idx_prayer_answers_prayer_id ON public.prayer_answers(prayer_id);
CREATE INDEX IF NOT EXISTS idx_prayer_answers_scope ON public.prayer_answers(scope);
CREATE INDEX IF NOT EXISTS idx_prayer_answers_created_at ON public.prayer_answers(created_at DESC);

-- 2. 응답 댓글 테이블
CREATE TABLE IF NOT EXISTS public.prayer_answer_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  answer_id UUID NOT NULL REFERENCES public.prayer_answers(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_prayer_answer_comments_answer_id ON public.prayer_answer_comments(answer_id);
CREATE INDEX IF NOT EXISTS idx_prayer_answer_comments_created_at ON public.prayer_answer_comments(created_at);
      `);
        }
        else {
            console.log('✅ DB 스키마 확인 완료 (prayer_answers, prayer_answer_comments)');
        }
        // users 테이블 profile_id 컬럼 확인
        const { error: pidError } = await supabase_1.default
            .from('users')
            .select('profile_id')
            .limit(0);
        if (pidError && pidError.message.includes('profile_id')) {
            console.log('⚠️  users.profile_id 컬럼 없음 - Supabase Dashboard SQL Editor에서 아래 SQL 실행 필요:');
            console.log(`
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS profile_id TEXT;

ALTER TABLE public.users
  ADD CONSTRAINT IF NOT EXISTS users_profile_id_format
  CHECK (profile_id IS NULL OR profile_id ~ '^[a-z0-9_.]{3,30}$');

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_profile_id
  ON public.users(profile_id)
  WHERE profile_id IS NOT NULL;
      `);
        }
        else {
            console.log('✅ users.profile_id 컬럼 확인 완료');
        }
        // users 테이블 fcm_token 컬럼 확인
        const { error: fcmError } = await supabase_1.default
            .from('users')
            .select('fcm_token')
            .limit(0);
        if (fcmError && fcmError.message.includes('fcm_token')) {
            console.log('⚠️  users.fcm_token 컬럼 없음 - Supabase Dashboard SQL Editor에서 아래 SQL 실행 필요:');
            console.log(`
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;

CREATE INDEX IF NOT EXISTS idx_users_fcm_token
  ON public.users(fcm_token)
  WHERE fcm_token IS NOT NULL;
      `);
        }
        else {
            console.log('✅ users.fcm_token 컬럼 확인 완료');
        }
        // gratitude_journals 테이블 확인
        const { error: gjError } = await supabase_1.default
            .from('gratitude_journals')
            .select('id')
            .limit(0);
        if (gjError && (gjError.code === '42P01' || gjError.message.includes('gratitude_journals'))) {
            console.log('⚠️  gratitude_journals 테이블 없음 - Supabase Dashboard SQL Editor에서 migrations/005_gratitude_journal.sql 실행 필요');
        }
        else {
            console.log('✅ gratitude_journals 테이블 확인 완료');
        }
    }
    catch {
        console.log('DB 확인 스킵');
    }
}
// 미들웨어
app.use((0, helmet_1.default)());
app.use((0, cors_1.default)({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use((0, morgan_1.default)('dev'));
app.use(express_1.default.json({ limit: '10mb' }));
app.use(express_1.default.urlencoded({ extended: true }));
// 헬스체크
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString(), service: 'Intercesso API' });
});
// 이용약관 페이지
app.get('/terms', (req, res) => {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(`<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>이용약관 - Intercesso</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans KR', sans-serif; background: #f8f9fa; color: #1a1a2e; line-height: 1.7; }
    .header { background: linear-gradient(135deg, #00aaff, #00c9a7); padding: 40px 24px; text-align: center; color: white; }
    .header h1 { font-size: 28px; font-weight: 800; margin-bottom: 8px; }
    .header p { font-size: 14px; opacity: 0.9; }
    .container { max-width: 800px; margin: 0 auto; padding: 32px 24px; }
    .section { background: white; border-radius: 16px; padding: 28px; margin-bottom: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); }
    .section h2 { font-size: 18px; font-weight: 700; color: #00aaff; margin-bottom: 16px; padding-bottom: 10px; border-bottom: 2px solid #e8f4ff; }
    .section h3 { font-size: 15px; font-weight: 600; color: #333; margin: 16px 0 8px; }
    .section p, .section li { font-size: 14px; color: #555; margin-bottom: 8px; }
    .section ul, .section ol { padding-left: 20px; }
    .section li { margin-bottom: 6px; }
    .highlight { background: #fff3cd; border-left: 4px solid #f59e0b; padding: 12px 16px; border-radius: 0 8px 8px 0; margin: 12px 0; font-size: 14px; color: #333; }
    .effective-date { text-align: center; color: #999; font-size: 13px; margin: 24px 0; }
    .contact-box { background: linear-gradient(135deg, #e8f4ff, #e0fff8); border-radius: 12px; padding: 20px; margin-top: 8px; }
    a { color: #00aaff; text-decoration: none; }
  </style>
</head>
<body>
  <div class="header">
    <div style="font-size:40px;margin-bottom:12px;">📜</div>
    <h1>이용약관</h1>
    <p>Intercesso - 함께 기도하는 공동체</p>
  </div>
  <div class="container">
    <p class="effective-date">시행일: 2025년 1월 1일 &nbsp;|&nbsp; 최종 수정일: 2025년 3월 1일</p>
    <div class="section"><h2>제1조 (목적)</h2><p>이 약관은 Intercesso(이하 "서비스")가 제공하는 기도 공유 플랫폼 서비스의 이용 조건 및 절차, 서비스 제공자와 이용자 간의 권리·의무 및 책임 사항을 규정함을 목적으로 합니다.</p></div>
    <div class="section"><h2>제2조 (서비스 이용 자격)</h2><ul><li>본 서비스는 만 14세 이상의 이용자가 이용할 수 있습니다.</li><li>만 14세 미만은 법정 대리인의 동의가 필요합니다.</li><li>이전에 서비스 이용이 제한된 이용자는 재가입이 제한될 수 있습니다.</li></ul></div>
    <div class="section"><h2>제3조 (서비스의 내용)</h2><p>Intercesso는 다음의 서비스를 제공합니다.</p><ul><li>개인 기도 제목 작성 및 관리</li><li>공동체 기도 공유 (공개/비공개 설정 가능)</li><li>중보기도 요청 및 수신</li><li>기도 그룹 생성 및 참여</li><li>기도 응답 기록 및 통계</li><li>작정기도 (기간 설정 기도) 기능</li></ul></div>
    <div class="section"><h2>제4조 (이용자의 의무)</h2><h3>이용자는 다음 행위를 해서는 안 됩니다.</h3><ul><li>타인의 개인정보 도용 또는 허위 정보 등록</li><li>타인을 비방하거나 명예를 훼손하는 내용 게시</li><li>종교적 혐오, 차별, 폭력적 내용 게시</li><li>광고·홍보·스팸 목적의 내용 게시</li><li>서비스의 안정적 운영을 방해하는 행위</li><li>서비스를 통해 수집한 타인의 정보를 무단 이용</li></ul><div class="highlight">⚠️ 위 금지 행위 적발 시 사전 통보 없이 계정이 정지 또는 삭제될 수 있습니다.</div></div>
    <div class="section"><h2>제5조 (콘텐츠의 권리)</h2><ul><li>이용자가 작성한 기도, 댓글 등 콘텐츠의 저작권은 이용자에게 있습니다.</li><li>서비스는 서비스 운영·개선 목적으로 이용자 콘텐츠를 활용할 수 있습니다.</li><li>이용자는 타인의 저작권을 침해하는 콘텐츠를 게시해서는 안 됩니다.</li><li>계정 삭제 시 이용자의 모든 콘텐츠는 즉시 삭제됩니다.</li></ul></div>
    <div class="section"><h2>제6조 (서비스의 변경 및 중단)</h2><ul><li>서비스는 운영상·기술상 필요에 따라 서비스 내용을 변경할 수 있습니다.</li><li>서비스 중단 시 최소 7일 전에 앱 내 공지를 통해 안내합니다.</li><li>천재지변, 서버 장애 등 불가피한 경우 사전 고지 없이 서비스가 중단될 수 있습니다.</li></ul></div>
    <div class="section"><h2>제7조 (책임의 제한)</h2><ul><li>서비스는 이용자 간의 기도 공유에서 발생하는 분쟁에 대해 책임지지 않습니다.</li><li>이용자가 게시한 개인정보 노출에 대해 서비스는 책임을 지지 않습니다.</li><li>서비스는 무료로 제공되며, 서비스 이용으로 인한 손해에 대한 책임은 제한됩니다.</li></ul></div>
    <div class="section"><h2>제8조 (계정 해지)</h2><ul><li>이용자는 언제든지 앱 내 설정에서 계정을 삭제할 수 있습니다.</li><li>계정 삭제 시 모든 데이터는 즉시 삭제되며 복구할 수 없습니다.</li><li>서비스는 약관 위반 이용자의 계정을 제한하거나 삭제할 수 있습니다.</li></ul></div>
    <div class="section"><h2>제9조 (분쟁 해결)</h2><p>서비스 이용과 관련한 분쟁은 대한민국 법률에 따라 처리되며, 관할 법원은 서비스 제공자의 본사 소재지 법원으로 합니다.</p></div>
    <div class="section"><h2>제10조 (문의)</h2><div class="contact-box"><p><strong>서비스명:</strong> Intercesso</p><p><strong>이메일:</strong> <a href="mailto:support@intercesso.app">support@intercesso.app</a></p><p style="margin-top:8px;"><a href="/privacy">개인정보처리방침 보기 →</a></p></div></div>
    <p class="effective-date" style="margin-top:32px;">본 약관은 2025년 1월 1일부터 시행됩니다.</p>
  </div>
</body>
</html>`);
});
// 개인정보처리방침 페이지
app.get('/privacy', (req, res) => {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(`<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>개인정보처리방침 - Intercesso</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans KR', sans-serif; background: #f8f9fa; color: #1a1a2e; line-height: 1.7; }
    .header { background: linear-gradient(135deg, #00aaff, #00c9a7); padding: 40px 24px; text-align: center; color: white; }
    .header h1 { font-size: 28px; font-weight: 800; margin-bottom: 8px; }
    .header p { font-size: 14px; opacity: 0.9; }
    .container { max-width: 800px; margin: 0 auto; padding: 32px 24px; }
    .section { background: white; border-radius: 16px; padding: 28px; margin-bottom: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); }
    .section h2 { font-size: 18px; font-weight: 700; color: #00aaff; margin-bottom: 16px; padding-bottom: 10px; border-bottom: 2px solid #e8f4ff; }
    .section h3 { font-size: 15px; font-weight: 600; color: #333; margin: 16px 0 8px; }
    .section p, .section li { font-size: 14px; color: #555; margin-bottom: 8px; }
    .section ul, .section ol { padding-left: 20px; }
    .section li { margin-bottom: 6px; }
    .highlight { background: #e8f4ff; border-left: 4px solid #00aaff; padding: 12px 16px; border-radius: 0 8px 8px 0; margin: 12px 0; font-size: 14px; color: #333; }
    .effective-date { text-align: center; color: #999; font-size: 13px; margin: 24px 0; }
    .contact-box { background: linear-gradient(135deg, #e8f4ff, #e0fff8); border-radius: 12px; padding: 20px; margin-top: 8px; }
    .contact-box p { font-size: 14px; color: #444; }
    a { color: #00aaff; text-decoration: none; }
  </style>
</head>
<body>
  <div class="header">
    <div style="font-size:40px;margin-bottom:12px;">🙏</div>
    <h1>개인정보처리방침</h1>
    <p>Intercesso - 함께 기도하는 공동체</p>
  </div>
  <div class="container">
    <p class="effective-date">시행일: 2025년 1월 1일 &nbsp;|&nbsp; 최종 수정일: 2025년 3월 1일</p>
    <div class="section"><h2>1. 개인정보처리방침의 목적</h2><p>Intercesso(이하 "서비스")는 이용자의 개인정보를 소중히 여기며, 「개인정보 보호법」 및 관련 법령을 준수합니다. 본 방침은 서비스가 수집하는 개인정보의 항목, 수집·이용 목적, 보유 기간 및 이용자의 권리를 안내합니다.</p></div>
    <div class="section"><h2>2. 수집하는 개인정보 항목</h2><h3>① 회원가입 시 수집 항목</h3><ul><li><strong>필수:</strong> 이메일 주소, 비밀번호(암호화 저장), 닉네임</li><li><strong>선택:</strong> 교회명, 교단, 자기소개, 프로필 사진</li></ul><h3>② 소셜 로그인 시 수집 항목</h3><ul><li><strong>구글 로그인:</strong> 구글 계정 이메일, 닉네임, 프로필 사진</li><li><strong>카카오 로그인:</strong> 카카오 계정 이메일, 닉네임, 프로필 사진</li></ul><h3>③ 서비스 이용 시 자동 수집 항목</h3><ul><li>앱 접속 로그, 기기 정보(OS 버전, 앱 버전)</li><li>서비스 이용 기록 (기도 작성, 댓글, 그룹 활동 등)</li></ul><div class="highlight">💡 Intercesso는 위치 정보, 연락처, 카메라에 직접 접근하지 않습니다. 프로필 사진 변경 시에만 기기 갤러리 접근 권한(선택)을 요청합니다.</div></div>
    <div class="section"><h2>3. 개인정보 수집·이용 목적</h2><ul><li>회원 가입 및 본인 확인</li><li>기도 공유 및 공동체 서비스 제공</li><li>중보기도 요청·수신 기능 운영</li><li>그룹 관리 및 초대 기능 운영</li><li>서비스 개선 및 오류 분석</li><li>불법 사용 방지 및 보안 유지</li></ul></div>
    <div class="section"><h2>4. 개인정보 보유 및 이용 기간</h2><ul><li><strong>회원 정보:</strong> 회원 탈퇴 시까지</li><li><strong>서비스 이용 기록:</strong> 탈퇴 후 즉시 삭제</li><li><strong>관련 법령에 따른 보존:</strong></li><ol style="margin-top:8px;"><li>전자상거래법: 소비자 불만·분쟁 처리 기록 3년</li><li>통신비밀보호법: 로그인 기록 3개월</li></ol></ul></div>
    <div class="section"><h2>5. 개인정보의 제3자 제공</h2><p>서비스는 이용자의 동의 없이 개인정보를 제3자에게 제공하지 않습니다. 단, 다음의 경우는 예외입니다.</p><ul><li>이용자가 사전에 동의한 경우</li><li>법령의 규정에 따른 경우</li></ul><h3>외부 서비스 연동</h3><ul><li><strong>Supabase:</strong> 데이터베이스 및 인증 서비스 (미국 소재)</li><li><strong>Google Firebase:</strong> 앱 분석 및 구글 로그인 (미국 소재)</li></ul></div>
    <div class="section"><h2>6. 이용자의 권리</h2><p>이용자는 언제든지 다음 권리를 행사할 수 있습니다.</p><ul><li>개인정보 열람 요청</li><li>개인정보 수정 요청 (앱 내 프로필 수정 메뉴)</li><li><strong>계정 삭제 및 탈퇴 (앱 내 설정 → 계정 삭제)</strong></li><li>개인정보 처리 정지 요청</li></ul><div class="highlight">🗑️ <strong>계정 삭제 방법:</strong> 앱 실행 → 프로필 탭 → 설정 → 계정 삭제<br>계정 삭제 시 모든 기도, 댓글, 그룹 데이터가 즉시 삭제되며 복구할 수 없습니다.</div></div>
    <div class="section"><h2>7. 개인정보 보호 조치</h2><ul><li>비밀번호는 단방향 암호화(bcrypt)로 저장</li><li>통신 구간 SSL/TLS 암호화 적용</li><li>JWT 기반 인증 토큰으로 접근 제어</li><li>최소 권한 원칙에 따른 데이터 접근 통제</li></ul></div>
    <div class="section"><h2>8. 쿠키 및 자동 수집 도구</h2><p>서비스는 앱 내에서 로그인 상태 유지를 위해 기기의 보안 저장소(Secure Storage)를 사용합니다. 웹 쿠키는 사용하지 않습니다.</p></div>
    <div class="section"><h2>9. 개인정보 보호책임자</h2><div class="contact-box"><p><strong>서비스명:</strong> Intercesso</p><p><strong>이메일:</strong> <a href="mailto:privacy@intercesso.app">privacy@intercesso.app</a></p><p style="margin-top:10px; color:#777; font-size:13px;">개인정보 관련 문의사항은 위 이메일로 연락 주시면 7일 이내에 답변드리겠습니다.</p></div></div>
    <div class="section"><h2>10. 방침 변경 안내</h2><p>본 개인정보처리방침은 법령 변경 또는 서비스 변경 시 개정될 수 있습니다. 변경 시 앱 내 공지 및 본 페이지를 통해 사전 안내합니다.</p></div>
    <p class="effective-date" style="margin-top:32px;">본 방침은 2025년 1월 1일부터 시행됩니다.</p>
  </div>
</body>
</html>`);
});
// API 라우터
app.use('/api/auth', auth_routes_1.default);
app.use('/api/prayers', prayer_routes_1.default);
app.use('/api/users', user_routes_1.default);
app.use('/api/groups', group_routes_1.default);
app.use('/api/intercessions', intercession_routes_1.default);
app.use('/api/notifications', notification_routes_1.default);
app.use('/api/statistics', statistics_routes_1.default);
app.use('/api/gratitude', gratitude_routes_1.default);
app.use('/api/choir', choir_routes_1.default);
// 기도 응답 피드
app.get('/api/answers/feed', auth_1.optionalAuth, prayer_answer_controller_1.getAnswerFeed);
// 404 핸들러
app.use((req, res) => {
    res.status(404).json({
        success: false,
        statusCode: 404,
        message: '요청한 경로를 찾을 수 없습니다',
        error: { code: 'NOT_FOUND' },
    });
});
// 에러 핸들러
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({
        success: false,
        statusCode: 500,
        message: '서버 내부 오류가 발생했습니다',
        error: { code: 'INTERNAL_SERVER_ERROR' },
    });
});
app.listen(PORT, () => {
    console.log(`🚀 Intercesso API Server running on port ${PORT}`);
    console.log(`📖 Health check: http://localhost:${PORT}/health`);
    console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
    runMigrations();
});
exports.default = app;
//# sourceMappingURL=index.js.map