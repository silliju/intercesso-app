import { Router } from 'express';
import * as authController from '../controllers/auth.controller';
// 소셜 로그인 컨트롤러 import
import * as socialAuthController from '../controllers/social_auth.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

// ─── 기본 이메일/비밀번호 인증 ────────────────────────────
router.post('/signup', authController.signUp);
router.post('/login', authController.login);
router.post('/logout', authenticate, authController.logout);
router.post('/refresh', authController.refreshToken);

// ─── 아이디/비밀번호 찾기 ──────────────────────────────────
router.post('/find-email', authController.findEmail);           // 닉네임으로 이메일 찾기
router.post('/forgot-password', authController.forgotPassword); // 비밀번호 재설정 이메일 발송

// ─── 소셜 로그인 ──────────────────────────────────────────
// 구글 로그인: Flutter앱에서 구글 id_token을 받아 JWT 발급
// POST /api/auth/social/google
// body: { id_token, email, nickname }
router.post('/social/google', socialAuthController.googleLogin);

// 카카오 로그인: Flutter앱에서 카카오 access_token을 받아 JWT 발급
// POST /api/auth/social/kakao
// body: { access_token, kakao_id, email, nickname }
router.post('/social/kakao', socialAuthController.kakaoLogin);

export default router;
