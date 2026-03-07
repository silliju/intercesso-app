import { Router } from 'express';
import * as userController from '../controllers/user.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

router.get('/me', authenticate, userController.getMe);
router.put('/me', authenticate, userController.updateMe);
router.delete('/me', authenticate, userController.deleteMe);  // 계정 삭제 (구글 플레이 필수)
router.post('/me/fcm-token', authenticate, userController.updateFcmToken);  // FCM 토큰 저장/갱신
router.delete('/me/fcm-token', authenticate, userController.deleteFcmToken); // FCM 토큰 삭제 (로그아웃 시)
router.get('/search', authenticate, userController.searchUsers);
router.get('/me/connections', authenticate, userController.getConnections);
router.post('/me/connections', authenticate, userController.addConnection);
router.get('/:userId', userController.getUserById);
router.get('/:userId/stats', userController.getUserStats);

export default router;
