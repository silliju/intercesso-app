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
const answerController = __importStar(require("../controllers/prayer_answer.controller"));
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)({ mergeParams: true }); // mergeParams: prayerId 상속
// ── 기도 응답 CRUD ─────────────────────────────────
router.get('/', auth_1.optionalAuth, answerController.getPrayerAnswer); // 응답 조회
router.post('/', auth_1.authenticate, answerController.upsertPrayerAnswer); // 응답 등록/수정
router.delete('/', auth_1.authenticate, answerController.deletePrayerAnswer); // 응답 삭제
// ── 응답 댓글 ──────────────────────────────────────
router.post('/comments', auth_1.authenticate, answerController.createAnswerComment); // 댓글 등록
router.delete('/comments/:commentId', auth_1.authenticate, answerController.deleteAnswerComment); // 댓글 삭제
exports.default = router;
//# sourceMappingURL=prayer_answer.routes.js.map