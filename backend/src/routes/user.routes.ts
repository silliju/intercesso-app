import { Router } from 'express';
import * as userController from '../controllers/user.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

router.get('/me', authenticate, userController.getMe);
router.put('/me', authenticate, userController.updateMe);
router.get('/search', authenticate, userController.searchUsers);
router.get('/me/connections', authenticate, userController.getConnections);
router.post('/me/connections', authenticate, userController.addConnection);
router.get('/:userId', userController.getUserById);
router.get('/:userId/stats', userController.getUserStats);

export default router;
