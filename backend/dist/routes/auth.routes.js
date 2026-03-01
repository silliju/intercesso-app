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
const authController = __importStar(require("../controllers/auth.controller"));
// 소셜 로그인 컨트롤러 import
const socialAuthController = __importStar(require("../controllers/social_auth.controller"));
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
// ─── 기본 이메일/비밀번호 인증 ────────────────────────────
router.post('/signup', authController.signUp);
router.post('/login', authController.login);
router.post('/logout', auth_1.authenticate, authController.logout);
router.post('/refresh', authController.refreshToken);
// ─── 소셜 로그인 ──────────────────────────────────────────
// 구글 로그인: Flutter앱에서 구글 id_token을 받아 JWT 발급
// POST /api/auth/social/google
// body: { id_token, email, nickname }
router.post('/social/google', socialAuthController.googleLogin);
// 카카오 로그인: Flutter앱에서 카카오 access_token을 받아 JWT 발급
// POST /api/auth/social/kakao
// body: { access_token, kakao_id, email, nickname }
router.post('/social/kakao', socialAuthController.kakaoLogin);
exports.default = router;
//# sourceMappingURL=auth.routes.js.map