import { Router } from 'express';
import * as intercessionController from '../controllers/intercession.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

// 사용자 검색 (개인 요청 대상자 선택)
router.get('/search-users', authenticate, intercessionController.searchUsersForIntercession);

// 중보기도 요청 생성 (전체공개/그룹/개인)
router.post('/', authenticate, intercessionController.createIntercessionRequest);

// 받은 중보기도 목록 (나에게 온 요청)
router.get('/received', authenticate, intercessionController.getIntercessionRequests);

// 전체공개 중보기도 목록
router.get('/public', authenticate, intercessionController.getPublicIntercessionRequests);

// 보낸 중보기도 요청 목록
router.get('/sent', authenticate, intercessionController.getSentRequests);

// 요청에 응답 (수락/거절)
router.put('/:requestId/respond', authenticate, intercessionController.respondIntercessionRequest);

// 하위 호환 라우트
router.post('/request', authenticate, intercessionController.createIntercessionRequest);
router.get('/requests', authenticate, intercessionController.getIntercessionRequests);
router.put('/requests/:requestId', authenticate, intercessionController.respondIntercessionRequest);

export default router;
