import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import supabaseAdmin from './config/supabase';

import authRoutes from './routes/auth.routes';
import prayerRoutes from './routes/prayer.routes';
import userRoutes from './routes/user.routes';
import groupRoutes from './routes/group.routes';
import intercessionRoutes from './routes/intercession.routes';
import notificationRoutes from './routes/notification.routes';
import statisticsRoutes from './routes/statistics.routes';
import { getAnswerFeed } from './controllers/prayer_answer.controller';
import { optionalAuth } from './middleware/auth';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// DB 마이그레이션 상태 확인 (로그 출력용)
async function runMigrations() {
  try {
    // intercession_requests target_type 컬럼 확인
    const { error: icError } = await supabaseAdmin
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
    const { error: pwError } = await supabaseAdmin
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
    } else {
      console.log('✅ users.password_hash 컬럼 확인 완료');
    }

    // prayer_answers 테이블 확인
    const { error: paError } = await supabaseAdmin
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
    } else {
      console.log('✅ DB 스키마 확인 완료 (prayer_answers, prayer_answer_comments)');
    }
  } catch {
    console.log('DB 확인 스킵');
  }
}

// 미들웨어
app.use(helmet());
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(morgan('dev'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// 헬스체크
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString(), service: 'Intercesso API' });
});

// API 라우터
app.use('/api/auth', authRoutes);
app.use('/api/prayers', prayerRoutes);
app.use('/api/users', userRoutes);
app.use('/api/groups', groupRoutes);
app.use('/api/intercessions', intercessionRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/statistics', statisticsRoutes);
// 기도 응답 피드
app.get('/api/answers/feed', optionalAuth as any, getAnswerFeed as any);

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
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
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

export default app;
