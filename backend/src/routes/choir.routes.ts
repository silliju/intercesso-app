import { Router } from 'express';
import * as choirController from '../controllers/choir.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

// ── 찬양대 CRUD ─────────────────────────────────────────────
router.post('/', authenticate, choirController.createChoir);
router.get('/my', authenticate, choirController.getMyChoirs);
router.get('/join-by-code', authenticate, choirController.getChoirByInviteCode);
router.post('/join-by-code', authenticate, choirController.joinByInviteCode);
router.get('/:choirId', authenticate, choirController.getChoirById);
router.put('/:choirId', authenticate, choirController.updateChoir);
router.delete('/:choirId', authenticate, choirController.deleteChoir);

// ── 초대 코드 ──────────────────────────────────────────────
router.get('/:choirId/invite', authenticate, choirController.getInviteCode);
router.post('/:choirId/invite/refresh', authenticate, choirController.refreshInviteCode);

// ── 멤버 관리 ──────────────────────────────────────────────
router.get('/:choirId/members', authenticate, choirController.getMembers);
router.put('/:choirId/members/:memberId', authenticate, choirController.updateMember);
router.delete('/:choirId/members/:memberId', authenticate, choirController.removeMember);
router.post('/:choirId/members/:memberId/approve', authenticate, choirController.approveMember);

// ── 일정 CRUD ─────────────────────────────────────────────
router.get('/:choirId/schedules', authenticate, choirController.getSchedules);
router.post('/:choirId/schedules', authenticate, choirController.createSchedule);
router.get('/:choirId/schedules/:scheduleId', authenticate, choirController.getScheduleById);
router.put('/:choirId/schedules/:scheduleId', authenticate, choirController.updateSchedule);
router.delete('/:choirId/schedules/:scheduleId', authenticate, choirController.deleteSchedule);

// ── 출석 관리 ─────────────────────────────────────────────
router.get('/:choirId/schedules/:scheduleId/attendance', authenticate, choirController.getAttendance);
router.put('/:choirId/schedules/:scheduleId/attendance', authenticate, choirController.updateAttendance);
router.get('/:choirId/attendance-stats', authenticate, choirController.getAttendanceStats);

// ── 찬양곡 CRUD ───────────────────────────────────────────
router.get('/:choirId/songs', authenticate, choirController.getSongs);
router.post('/:choirId/songs', authenticate, choirController.createSong);
router.put('/:choirId/songs/:songId', authenticate, choirController.updateSong);
router.delete('/:choirId/songs/:songId', authenticate, choirController.deleteSong);

// ── 공지사항 CRUD ─────────────────────────────────────────
router.get('/:choirId/notices', authenticate, choirController.getNotices);
router.post('/:choirId/notices', authenticate, choirController.createNotice);
router.put('/:choirId/notices/:noticeId', authenticate, choirController.updateNotice);
router.delete('/:choirId/notices/:noticeId', authenticate, choirController.deleteNotice);

// ── 자료실 CRUD ───────────────────────────────────────────
router.get('/:choirId/files', authenticate, choirController.getFiles);
router.post('/:choirId/files', authenticate, choirController.createFile);
router.delete('/:choirId/files/:fileId', authenticate, choirController.deleteFile);

export default router;
