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
dotenv_1.default.config();
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3000;
// DB 마이그레이션 상태 확인 (로그 출력용)
async function runMigrations() {
    try {
        const { error } = await supabase_1.default
            .from('intercession_requests')
            .select('target_type')
            .limit(0);
        if (error && error.message.includes('target_type')) {
            console.log('⚠️  DB 컬럼 부족 - Supabase Dashboard SQL Editor에서 실행 필요:');
            console.log(`
ALTER TABLE intercession_requests
  ADD COLUMN IF NOT EXISTS target_type TEXT DEFAULT 'individual',
  ADD COLUMN IF NOT EXISTS group_id UUID REFERENCES groups(id) ON DELETE SET NULL;
UPDATE intercession_requests SET target_type = 'individual' WHERE target_type IS NULL;
      `);
        }
        else {
            console.log('✅ DB 스키마 확인 완료');
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