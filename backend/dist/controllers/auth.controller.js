"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.findEmail = exports.forgotPassword = exports.refreshToken = exports.logout = exports.login = exports.signUp = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const uuid_1 = require("uuid");
const supabase_1 = __importDefault(require("../config/supabase"));
const response_1 = require("../utils/response");
const signUp = async (req, res) => {
    try {
        const { email, password, nickname, church_name, denomination, bio } = req.body;
        if (!email || !password || !nickname) {
            (0, response_1.sendError)(res, '이메일, 비밀번호, 닉네임은 필수입니다', 400, 'VALIDATION_ERROR');
            return;
        }
        // 이메일 중복 확인
        const { data: existingUser } = await supabase_1.default
            .from('users')
            .select('id')
            .eq('email', email)
            .single();
        if (existingUser) {
            (0, response_1.sendError)(res, '이미 사용 중인 이메일입니다', 400, 'EMAIL_DUPLICATE');
            return;
        }
        // Supabase Auth로 사용자 생성
        const { data: authData, error: authError } = await supabase_1.default.auth.admin.createUser({
            email,
            password,
            email_confirm: true,
        });
        if (authError || !authData.user) {
            (0, response_1.sendError)(res, '회원가입 중 오류가 발생했습니다', 500, 'AUTH_ERROR', authError?.message);
            return;
        }
        const userId = authData.user.id;
        // users 테이블에 프로필 생성
        const { data: newUser, error: profileError } = await supabase_1.default
            .from('users')
            .insert({
            id: userId,
            email,
            nickname,
            church_name: church_name || null,
            denomination: denomination || null,
            bio: bio || null,
        })
            .select()
            .single();
        if (profileError) {
            (0, response_1.sendError)(res, '프로필 생성 중 오류가 발생했습니다', 500, 'PROFILE_ERROR');
            return;
        }
        // user_statistics 초기화
        await supabase_1.default.from('user_statistics').insert({
            id: (0, uuid_1.v4)(),
            user_id: userId,
            total_prayers: 0,
            answered_prayers: 0,
            grateful_prayers: 0,
            total_participations: 0,
            total_comments: 0,
            streak_days: 0,
        });
        // notification_preferences 초기화
        await supabase_1.default.from('notification_preferences').insert({
            id: (0, uuid_1.v4)(),
            user_id: userId,
            all_notifications_enabled: true,
            intercession_request: true,
            prayer_participation: true,
            comment_notification: true,
            prayer_answered: true,
            group_notification: false,
        });
        // JWT 발급
        const token = jsonwebtoken_1.default.sign({ userId, email }, process.env.JWT_SECRET, { expiresIn: '7d' });
        (0, response_1.sendSuccess)(res, { user: newUser, token }, '회원가입이 완료되었습니다', 201);
    }
    catch (error) {
        (0, response_1.sendError)(res, '서버 오류가 발생했습니다', 500, 'SERVER_ERROR');
    }
};
exports.signUp = signUp;
const login = async (req, res) => {
    try {
        const { email, password } = req.body;
        if (!email || !password) {
            (0, response_1.sendError)(res, '이메일과 비밀번호를 입력해주세요', 400, 'VALIDATION_ERROR');
            return;
        }
        // Supabase Auth로 로그인
        const { data: authData, error: authError } = await supabase_1.default.auth.signInWithPassword({
            email,
            password,
        });
        if (authError || !authData.user) {
            (0, response_1.sendError)(res, '이메일 또는 비밀번호가 올바르지 않습니다', 401, 'INVALID_CREDENTIALS');
            return;
        }
        const userId = authData.user.id;
        // 사용자 프로필 조회
        const { data: user, error: userError } = await supabase_1.default
            .from('users')
            .select('*')
            .eq('id', userId)
            .single();
        if (userError || !user) {
            (0, response_1.sendError)(res, '사용자 정보를 찾을 수 없습니다', 404, 'USER_NOT_FOUND');
            return;
        }
        // 마지막 로그인 업데이트
        await supabase_1.default
            .from('users')
            .update({ last_login: new Date().toISOString() })
            .eq('id', userId);
        // JWT 발급
        const token = jsonwebtoken_1.default.sign({ userId, email }, process.env.JWT_SECRET, { expiresIn: '7d' });
        (0, response_1.sendSuccess)(res, { user, token }, '로그인 성공');
    }
    catch (error) {
        (0, response_1.sendError)(res, '서버 오류가 발생했습니다', 500, 'SERVER_ERROR');
    }
};
exports.login = login;
const logout = async (req, res) => {
    (0, response_1.sendSuccess)(res, null, '로그아웃 되었습니다');
};
exports.logout = logout;
const refreshToken = async (req, res) => {
    try {
        const { token } = req.body;
        if (!token) {
            (0, response_1.sendError)(res, '토큰이 필요합니다', 400, 'TOKEN_REQUIRED');
            return;
        }
        const payload = jsonwebtoken_1.default.verify(token, process.env.JWT_SECRET);
        const newToken = jsonwebtoken_1.default.sign({ userId: payload.userId, email: payload.email }, process.env.JWT_SECRET, { expiresIn: '7d' });
        (0, response_1.sendSuccess)(res, { token: newToken }, '토큰 갱신 성공');
    }
    catch {
        (0, response_1.sendError)(res, '유효하지 않은 토큰입니다', 401, 'INVALID_TOKEN');
    }
};
exports.refreshToken = refreshToken;
/**
 * 비밀번호 재설정 요청
 * - 이메일 존재 여부 확인
 * - Supabase Auth의 resetPasswordForEmail 사용
 * POST /api/auth/forgot-password
 * body: { email }
 */
const forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) {
            (0, response_1.sendError)(res, '이메일을 입력해주세요', 400, 'VALIDATION_ERROR');
            return;
        }
        // 가입된 이메일인지 확인
        const { data: user } = await supabase_1.default
            .from('users')
            .select('id, email')
            .eq('email', email)
            .single();
        if (!user) {
            // 보안상 존재 여부를 노출하지 않고 성공처럼 응답
            (0, response_1.sendSuccess)(res, null, '비밀번호 재설정 이메일을 발송했습니다. 이메일을 확인해주세요.');
            return;
        }
        // Supabase Auth 비밀번호 재설정 이메일 발송
        const { error } = await supabase_1.default.auth.resetPasswordForEmail(email, {
            redirectTo: `${process.env.FRONTEND_URL || 'https://intercesso.pages.dev'}/reset-password`,
        });
        if (error) {
            console.error('비밀번호 재설정 이메일 오류:', error);
            // rate limit 처리 (Supabase 무료 플랜은 시간당 이메일 발송 횟수 제한)
            if (error.status === 429 || error.code === 'over_email_send_rate_limit') {
                (0, response_1.sendError)(res, '이메일 발송 횟수가 초과되었습니다. 1시간 후 다시 시도해주세요.', 429, 'RATE_LIMIT');
                return;
            }
            (0, response_1.sendError)(res, '이메일 발송에 실패했습니다. 잠시 후 다시 시도해주세요.', 500, 'EMAIL_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, null, '비밀번호 재설정 이메일을 발송했습니다. 이메일을 확인해주세요.');
    }
    catch (error) {
        (0, response_1.sendError)(res, '서버 오류가 발생했습니다', 500, 'SERVER_ERROR');
    }
};
exports.forgotPassword = forgotPassword;
/**
 * 닉네임으로 이메일(아이디) 찾기
 * POST /api/auth/find-email
 * body: { nickname, church_name? }
 */
const findEmail = async (req, res) => {
    try {
        const { nickname, church_name } = req.body;
        if (!nickname) {
            (0, response_1.sendError)(res, '닉네임을 입력해주세요', 400, 'VALIDATION_ERROR');
            return;
        }
        let query = supabase_1.default
            .from('users')
            .select('email, nickname, church_name, created_at')
            .eq('nickname', nickname);
        if (church_name) {
            query = query.eq('church_name', church_name);
        }
        const { data: users, error } = await query;
        if (error || !users || users.length === 0) {
            (0, response_1.sendError)(res, '일치하는 계정을 찾을 수 없습니다', 404, 'USER_NOT_FOUND');
            return;
        }
        // 이메일 마스킹 처리 (보안: 앞 3자리 + *** + @ + 도메인)
        const maskedUsers = users.map((u) => {
            const [local, domain] = u.email.split('@');
            const masked = local.length > 3
                ? local.slice(0, 3) + '***'
                : local[0] + '***';
            return {
                email: `${masked}@${domain}`,
                nickname: u.nickname,
                church_name: u.church_name,
                created_at: u.created_at,
            };
        });
        (0, response_1.sendSuccess)(res, { users: maskedUsers }, '계정을 찾았습니다');
    }
    catch (error) {
        (0, response_1.sendError)(res, '서버 오류가 발생했습니다', 500, 'SERVER_ERROR');
    }
};
exports.findEmail = findEmail;
//# sourceMappingURL=auth.controller.js.map