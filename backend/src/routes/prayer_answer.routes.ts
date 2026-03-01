import { Router } from 'express';
import * as answerController from '../controllers/prayer_answer.controller';
import { authenticate, optionalAuth } from '../middleware/auth';

const router = Router({ mergeParams: true }); // mergeParams: prayerId 상속

// ── 기도 응답 CRUD ─────────────────────────────────
router.get('/',         optionalAuth, answerController.getPrayerAnswer);       // 응답 조회
router.post('/',        authenticate, answerController.upsertPrayerAnswer);    // 응답 등록/수정
router.delete('/',      authenticate, answerController.deletePrayerAnswer);    // 응답 삭제

// ── 응답 댓글 ──────────────────────────────────────
router.post('/comments',          authenticate, answerController.createAnswerComment);  // 댓글 등록
router.delete('/comments/:commentId', authenticate, answerController.deleteAnswerComment); // 댓글 삭제

export default router;
