import { Router } from 'express';
import * as statsController from '../controllers/statistics.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

router.get('/dashboard', authenticate, statsController.getDashboard);
router.get('/me', authenticate, statsController.getMyStatistics);       // 내 통계
router.get('/prayers', authenticate, statsController.getPrayerCharts);
router.get('/community/:groupId', authenticate, statsController.getCommunityStats);
router.get('/users/:userId', authenticate, statsController.getUserStatistics); // 특정 유저 통계

export default router;
