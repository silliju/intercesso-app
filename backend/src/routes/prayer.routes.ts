import { Router } from 'express';
import * as prayerController from '../controllers/prayer.controller';
import { authenticate, optionalAuth } from '../middleware/auth';

const router = Router();

router.get('/', optionalAuth, prayerController.getPrayers);
router.get('/:prayerId', optionalAuth, prayerController.getPrayerById);
router.post('/', authenticate, prayerController.createPrayer);
router.put('/:prayerId', authenticate, prayerController.updatePrayer);
router.delete('/:prayerId', authenticate, prayerController.deletePrayer);

// 기도 참여
router.post('/:prayerId/participate', authenticate, prayerController.participatePrayer);
router.delete('/:prayerId/participate', authenticate, prayerController.cancelParticipation);

// 댓글
router.post('/:prayerId/comments', authenticate, prayerController.createComment);
router.delete('/comments/:commentId', authenticate, prayerController.deleteComment);

// 작정기도
router.get('/:prayerId/checkins', authenticate, prayerController.getCovenantCheckins);
router.post('/:prayerId/checkins', authenticate, prayerController.checkInCovenant);

export default router;
