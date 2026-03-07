"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_1 = require("../middleware/auth");
const gratitude_controller_1 = require("../controllers/gratitude.controller");
const router = (0, express_1.Router)();
// 모든 라우트 인증 필요
router.use(auth_1.authenticate);
// ── 감사일기 CRUD ──
router.post('/', gratitude_controller_1.createGratitudeJournal); // 작성/수정 (upsert)
router.get('/my', gratitude_controller_1.getMyGratitudeJournals); // 내 일기 목록
router.get('/today', gratitude_controller_1.getTodayJournal); // 오늘 일기
router.get('/streak', gratitude_controller_1.getStreak); // 스트릭 정보
router.get('/calendar', gratitude_controller_1.getCalendar); // 캘린더 데이터
router.get('/feed', gratitude_controller_1.getGratitudeFeed); // 소셜 피드
router.get('/:journalId', gratitude_controller_1.getGratitudeJournalById); // 상세 조회
router.put('/:journalId', gratitude_controller_1.updateGratitudeJournal); // 수정
router.delete('/:journalId', gratitude_controller_1.deleteGratitudeJournal); // 삭제
// ── 반응 ──
router.post('/:journalId/reactions', gratitude_controller_1.toggleReaction); // 반응 토글
// ── 댓글 ──
router.post('/:journalId/comments', gratitude_controller_1.addComment); // 댓글 작성
router.delete('/comments/:commentId', gratitude_controller_1.deleteComment); // 댓글 삭제
exports.default = router;
//# sourceMappingURL=gratitude.routes.js.map