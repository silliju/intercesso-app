import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
/**
 * 감사일기 작성 (하루 1개, upsert 방식)
 * POST /api/gratitude
 */
export declare const createGratitudeJournal: (req: AuthRequest, res: Response) => Promise<void>;
/**
 * 내 감사일기 목록
 * GET /api/gratitude/my?page=1&limit=20
 */
export declare const getMyGratitudeJournals: (req: AuthRequest, res: Response) => Promise<void>;
/**
 * 오늘의 감사일기 조회
 * GET /api/gratitude/today
 */
export declare const getTodayJournal: (req: AuthRequest, res: Response) => Promise<void>;
/**
 * 특정 감사일기 상세 조회
 * GET /api/gratitude/:journalId
 */
export declare const getGratitudeJournalById: (req: AuthRequest, res: Response) => Promise<void>;
/**
 * 감사일기 수정
 * PUT /api/gratitude/:journalId
 */
export declare const updateGratitudeJournal: (req: AuthRequest, res: Response) => Promise<void>;
/**
 * 감사일기 삭제
 * DELETE /api/gratitude/:journalId
 */
export declare const deleteGratitudeJournal: (req: AuthRequest, res: Response) => Promise<void>;
/**
 * 감사 피드 조회 (그룹/팔로우/전체)
 * GET /api/gratitude/feed?tab=group|following|public&page=1&limit=20
 */
export declare const getGratitudeFeed: (req: AuthRequest, res: Response) => Promise<void>;
/**
 * 반응 추가/취소 (토글)
 * POST /api/gratitude/:journalId/reactions
 */
export declare const toggleReaction: (req: AuthRequest, res: Response) => Promise<void>;
/**
 * 댓글 작성
 * POST /api/gratitude/:journalId/comments
 */
export declare const addComment: (req: AuthRequest, res: Response) => Promise<void>;
/**
 * 댓글 삭제
 * DELETE /api/gratitude/comments/:commentId
 */
export declare const deleteComment: (req: AuthRequest, res: Response) => Promise<void>;
/**
 * 스트릭 정보 조회
 * GET /api/gratitude/streak
 */
export declare const getStreak: (req: AuthRequest, res: Response) => Promise<void>;
/**
 * 캘린더 데이터 조회 (특정 년-월)
 * GET /api/gratitude/calendar?year=2026&month=3
 */
export declare const getCalendar: (req: AuthRequest, res: Response) => Promise<void>;
//# sourceMappingURL=gratitude.controller.d.ts.map