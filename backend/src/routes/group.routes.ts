import { Router } from 'express';
import * as groupController from '../controllers/group.controller';
import { authenticate, optionalAuth } from '../middleware/auth';

const router = Router();

router.post('/', authenticate, groupController.createGroup);
router.get('/', authenticate, groupController.getMyGroups);
router.post('/join-by-code', authenticate, groupController.joinByInviteCode);
router.get('/:groupId', optionalAuth, groupController.getGroupById);
router.put('/:groupId', authenticate, groupController.updateGroup);
router.delete('/:groupId', authenticate, groupController.deleteGroup);
router.post('/:groupId/join', authenticate, groupController.joinGroup);
router.get('/:groupId/members', authenticate, groupController.getGroupMembers);
router.delete('/:groupId/members/:targetUserId', authenticate, groupController.removeMember);

export default router;
