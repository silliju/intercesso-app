import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import {
  createGratitudeJournal,
  getMyGratitudeJournals,
  getTodayJournal,
  getGratitudeJournalById,
  updateGratitudeJournal,
  deleteGratitudeJournal,
  getGratitudeFeed,
  toggleReaction,
  addComment,
  deleteComment,
  getStreak,
  getCalendar,
} from '../controllers/gratitude.controller';

const router = Router();

// 모든 라우트 인증 필요
router.use(authenticate);

// ── 감사일기 CRUD ──
router.post('/', createGratitudeJournal);                    // 작성/수정 (upsert)
router.get('/my', getMyGratitudeJournals);                   // 내 일기 목록
router.get('/today', getTodayJournal);                       // 오늘 일기
router.get('/streak', getStreak);                            // 스트릭 정보
router.get('/calendar', getCalendar);                        // 캘린더 데이터
router.get('/feed', getGratitudeFeed);                       // 소셜 피드
router.get('/:journalId', getGratitudeJournalById);          // 상세 조회
router.put('/:journalId', updateGratitudeJournal);           // 수정
router.delete('/:journalId', deleteGratitudeJournal);        // 삭제

// ── 반응 ──
router.post('/:journalId/reactions', toggleReaction);        // 반응 토글

// ── 댓글 ──
router.post('/:journalId/comments', addComment);             // 댓글 작성
router.delete('/comments/:commentId', deleteComment);        // 댓글 삭제

export default router;
