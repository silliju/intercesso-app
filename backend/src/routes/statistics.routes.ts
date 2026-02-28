import { Router } from 'express';
import * as statsController from '../controllers/statistics.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

router.get('/dashboard', authenticate, statsController.getDashboard);
router.get('/prayers', authenticate, statsController.getPrayerCharts);
router.get('/community/:groupId', authenticate, statsController.getCommunityStats);

export default router;
