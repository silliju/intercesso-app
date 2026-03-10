"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const choirController = __importStar(require("../controllers/choir.controller"));
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
// ── 찬양대 CRUD ─────────────────────────────────────────────
router.post('/', auth_1.authenticate, choirController.createChoir);
router.get('/my', auth_1.authenticate, choirController.getMyChoirs);
router.get('/join-by-code', auth_1.authenticate, choirController.getChoirByInviteCode);
router.post('/join-by-code', auth_1.authenticate, choirController.joinByInviteCode);
router.get('/:choirId', auth_1.authenticate, choirController.getChoirById);
router.put('/:choirId', auth_1.authenticate, choirController.updateChoir);
router.delete('/:choirId', auth_1.authenticate, choirController.deleteChoir);
// ── 초대 코드 ──────────────────────────────────────────────
router.get('/:choirId/invite', auth_1.authenticate, choirController.getInviteCode);
router.post('/:choirId/invite/refresh', auth_1.authenticate, choirController.refreshInviteCode);
// ── 멤버 관리 ──────────────────────────────────────────────
router.get('/:choirId/members', auth_1.authenticate, choirController.getMembers);
router.put('/:choirId/members/:memberId', auth_1.authenticate, choirController.updateMember);
router.delete('/:choirId/members/:memberId', auth_1.authenticate, choirController.removeMember);
router.post('/:choirId/members/:memberId/approve', auth_1.authenticate, choirController.approveMember);
// ── 일정 CRUD ─────────────────────────────────────────────
router.get('/:choirId/schedules', auth_1.authenticate, choirController.getSchedules);
router.post('/:choirId/schedules', auth_1.authenticate, choirController.createSchedule);
router.get('/:choirId/schedules/:scheduleId', auth_1.authenticate, choirController.getScheduleById);
router.put('/:choirId/schedules/:scheduleId', auth_1.authenticate, choirController.updateSchedule);
router.delete('/:choirId/schedules/:scheduleId', auth_1.authenticate, choirController.deleteSchedule);
// ── 출석 관리 ─────────────────────────────────────────────
router.get('/:choirId/schedules/:scheduleId/attendance', auth_1.authenticate, choirController.getAttendance);
router.put('/:choirId/schedules/:scheduleId/attendance', auth_1.authenticate, choirController.updateAttendance);
router.get('/:choirId/attendance-stats', auth_1.authenticate, choirController.getAttendanceStats);
// ── 찬양곡 CRUD ───────────────────────────────────────────
router.get('/:choirId/songs', auth_1.authenticate, choirController.getSongs);
router.post('/:choirId/songs', auth_1.authenticate, choirController.createSong);
router.put('/:choirId/songs/:songId', auth_1.authenticate, choirController.updateSong);
router.delete('/:choirId/songs/:songId', auth_1.authenticate, choirController.deleteSong);
// ── 공지사항 CRUD ─────────────────────────────────────────
router.get('/:choirId/notices', auth_1.authenticate, choirController.getNotices);
router.post('/:choirId/notices', auth_1.authenticate, choirController.createNotice);
router.put('/:choirId/notices/:noticeId', auth_1.authenticate, choirController.updateNotice);
router.delete('/:choirId/notices/:noticeId', auth_1.authenticate, choirController.deleteNotice);
// ── 자료실 CRUD ───────────────────────────────────────────
router.get('/:choirId/files', auth_1.authenticate, choirController.getFiles);
router.post('/:choirId/files', auth_1.authenticate, choirController.createFile);
router.delete('/:choirId/files/:fileId', auth_1.authenticate, choirController.deleteFile);
exports.default = router;
//# sourceMappingURL=choir.routes.js.map