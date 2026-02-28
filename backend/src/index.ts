import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';

import authRoutes from './routes/auth.routes';
import prayerRoutes from './routes/prayer.routes';
import userRoutes from './routes/user.routes';
import groupRoutes from './routes/group.routes';
import intercessionRoutes from './routes/intercession.routes';
import notificationRoutes from './routes/notification.routes';
import statisticsRoutes from './routes/statistics.routes';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

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
});

export default app;
