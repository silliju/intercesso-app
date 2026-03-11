import { Router } from 'express';
import * as churchController from '../controllers/church.controller';

const router = Router();

// 검색: GET /api/churches/search?q=검색어&limit=20
router.get('/search', churchController.searchChurches);

// 단건 조회: GET /api/churches/:churchId
router.get('/:churchId', churchController.getChurchById);

// 교회 등록 (비로그인 가능 - 회원가입 중 교회 등록 시)
router.post('/', churchController.createChurch);

export default router;
