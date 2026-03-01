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
// API 라우터
app.use('/api/auth', auth_routes_1.default);
app.use('/api/prayers', prayer_routes_1.default);
app.use('/api/users', user_routes_1.default);
app.use('/api/groups', group_routes_1.default);
app.use('/api/intercessions', intercession_routes_1.default);
app.use('/api/notifications', notification_routes_1.default);
app.use('/api/statistics', statistics_routes_1.default);
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