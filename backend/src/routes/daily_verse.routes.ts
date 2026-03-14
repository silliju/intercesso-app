import { Router } from 'express';
import * as dailyVerseController from '../controllers/daily_verse.controller';
import { optionalAuth } from '../middleware/auth';

const router = Router();

// GET /api/daily-verse/today
router.get('/today', optionalAuth, dailyVerseController.getTodayDailyVerse);

export default router;

