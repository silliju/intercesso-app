import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import supabaseAdmin from '../config/supabase';
import { sendSuccess, sendError } from '../utils/response';
import { SignUpBody, LoginBody } from '../types';

// ─────────────────────────────────────────────────────────────
//  회원가입
//  전략: 자체 bcrypt 해싱 → users 테이블 직접 저장
//        Supabase Auth 이메일 발송 rate limit 완전 우회
// ─────────────────────────────────────────────────────────────
// profile_id 유효성 검사 (영문소문자, 숫자, 점, 언더스코어, 3~30자)
const PROFILE_ID_REGEX = /^[a-z0-9_.]{3,30}$/;

// ─────────────────────────────────────────────────────────────
//  profile_id 중복 체크 API
//  GET /api/auth/check-profile-id?id=xxx
// ─────────────────────────────────────────────────────────────
export const checkProfileId = async (req: Request, res: Response): Promise<void> => {
  try {
    const profileId = (req.query.id as string || '').trim().toLowerCase();

    if (!profileId) {
      sendError(res, 'profile_id를 입력해주세요', 400, 'VALIDATION_ERROR');
      return;
    }
    if (!PROFILE_ID_REGEX.test(profileId)) {
      sendSuccess(res, { available: false, reason: 'format' }, '영문 소문자, 숫자, 점(.), 언더스코어(_)만 사용 가능하며 3~30자여야 합니다');
      return;
    }

    // profile_id 컬럼 존재 여부 확인
    const hasColumn = await checkProfileIdColumn();
    if (!hasColumn) {
      // 컬럼 없으면 사용 가능으로 반환 (DB 마이그레이션 후 활성화)
      sendSuccess(res, { available: true, note: 'db_migration_pending' }, '사용 가능한 ID입니다');
      return;
    }

    const { data: existing } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('profile_id', profileId)
      .maybeSingle();

    if (existing) {
      sendSuccess(res, { available: false, reason: 'duplicate' }, '이미 사용 중인 ID입니다');
    } else {
      sendSuccess(res, { available: true }, '사용 가능한 ID입니다');
    }
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

// profile_id 컬럼 존재 여부 캐시 (서버 시작 후 한번만 체크)
let _profileIdColumnExists: boolean | null = null;

async function checkProfileIdColumn(): Promise<boolean> {
  if (_profileIdColumnExists !== null) return _profileIdColumnExists;
  const { error } = await supabaseAdmin
    .from('users')
    .select('profile_id')
    .limit(0);
  _profileIdColumnExists = !error || !error.message.includes('profile_id');
  return _profileIdColumnExists;
}

export const signUp = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password, nickname, church_name, denomination, bio } = req.body as SignUpBody;

    if (!email || !password || !nickname) {
      sendError(res, '이메일, 비밀번호, 닉네임은 필수입니다', 400, 'VALIDATION_ERROR');
      return;
    }
    if (password.length < 6) {
      sendError(res, '비밀번호는 6자 이상이어야 합니다', 400, 'VALIDATION_ERROR');
      return;
    }

    // 이메일 중복 확인
    const { data: existingUser } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('email', email)
      .maybeSingle();

    if (existingUser) {
      sendError(res, '이미 사용 중인 이메일입니다. 로그인을 시도해보세요.', 400, 'EMAIL_DUPLICATE');
      return;
    }

    // 비밀번호 해싱
    const hashedPw = await bcrypt.hash(password, 10);
    const userId = uuidv4();

    // users 테이블에 저장
    const insertData: any = {
      id: userId,
      email,
      nickname,
      church_name: church_name || null,
      denomination: denomination || null,
      bio: bio || null,
      password_hash: hashedPw,
    };

    const { data: newUser, error: profileError } = await supabaseAdmin
      .from('users')
      .insert(insertData)
      .select()
      .single();

    if (profileError) {
      console.error('회원가입 users 저장 오류:', profileError);
      sendError(res, '회원가입 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.', 500, 'SIGNUP_ERROR');
      return;
    }

    // user_statistics 초기화
    try {
      await supabaseAdmin.from('user_statistics').insert({
        id: uuidv4(),
        user_id: userId,
        total_prayers: 0,
        answered_prayers: 0,
        grateful_prayers: 0,
        total_participations: 0,
        total_comments: 0,
        streak_days: 0,
      });
    } catch (_) { /* 무시 */ }

    // notification_preferences 초기화
    try {
      await supabaseAdmin.from('notification_preferences').insert({
        id: uuidv4(),
        user_id: userId,
        all_notifications_enabled: true,
        intercession_request: true,
        prayer_participation: true,
        comment_notification: true,
        prayer_answered: true,
        group_notification: false,
      });
    } catch (_) { /* 무시 */ }

    // JWT 발급
    const token = jwt.sign(
      { userId, email },
      process.env.JWT_SECRET!,
      { expiresIn: '7d' }
    );

    sendSuccess(res, { user: newUser, token }, '회원가입이 완료되었습니다', 201);
  } catch (error) {
    console.error('signUp error:', error);
    sendError(res, '서버 오류가 발생했습니다', 500, 'SERVER_ERROR');
  }
};

// ─────────────────────────────────────────────────────────────
//  로그인
//  전략: users 테이블의 password_hash로 bcrypt 검증 (자체 인증)
//        password_hash가 없는 기존 계정은 Supabase Auth로 fallback
// ─────────────────────────────────────────────────────────────
export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body as LoginBody;

    if (!email || !password) {
      sendError(res, '이메일과 비밀번호를 입력해주세요', 400, 'VALIDATION_ERROR');
      return;
    }

    // users 테이블에서 사용자 조회
    const { data: user, error: userError } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('email', email)
      .maybeSingle();

    if (userError || !user) {
      sendError(res, '이메일 또는 비밀번호가 올바르지 않습니다', 401, 'INVALID_CREDENTIALS');
      return;
    }

    const userId = user.id;
    let authenticated = false;

    // 자체 bcrypt 해시가 있으면 직접 검증
    if (user.password_hash) {
      authenticated = await bcrypt.compare(password, user.password_hash);
    } else {
      // 기존 Supabase Auth 계정 (password_hash 없음) → Supabase Auth로 검증
      const { data: authData, error: authError } = await supabaseAdmin.auth.signInWithPassword({
        email,
        password,
      });
      if (!authError && authData.user) {
        authenticated = true;
        // 이후 자체 인증으로 전환하기 위해 hash 저장
        const hashedPw = await bcrypt.hash(password, 10);
        try {
          await supabaseAdmin.from('users').update({ password_hash: hashedPw }).eq('id', userId);
        } catch (_) { /* 무시 */ }
      }
    }

    if (!authenticated) {
      sendError(res, '이메일 또는 비밀번호가 올바르지 않습니다', 401, 'INVALID_CREDENTIALS');
      return;
    }

    // 마지막 로그인 업데이트
    try {
      await supabaseAdmin
        .from('users')
        .update({ last_login: new Date().toISOString() })
        .eq('id', userId);
    } catch (_) { /* 무시 */ }

    // JWT 발급
    const token = jwt.sign(
      { userId, email },
      process.env.JWT_SECRET!,
      { expiresIn: '7d' }
    );

    // password_hash 필드 제거 후 반환
    const { password_hash, ...safeUser } = user as any;
    sendSuccess(res, { user: safeUser, token }, '로그인 성공');
  } catch (error) {
    console.error('login error:', error);
    sendError(res, '서버 오류가 발생했습니다', 500, 'SERVER_ERROR');
  }
};

export const logout = async (req: Request, res: Response): Promise<void> => {
  sendSuccess(res, null, '로그아웃 되었습니다');
};

export const refreshToken = async (req: Request, res: Response): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      sendError(res, '토큰이 필요합니다', 401, 'NO_TOKEN');
      return;
    }
    const oldToken = authHeader.split(' ')[1];
    const decoded = jwt.verify(oldToken, process.env.JWT_SECRET!) as any;
    const newToken = jwt.sign(
      { userId: decoded.userId, email: decoded.email },
      process.env.JWT_SECRET!,
      { expiresIn: '7d' }
    );
    sendSuccess(res, { token: newToken }, '토큰이 갱신되었습니다');
  } catch {
    sendError(res, '유효하지 않은 토큰입니다', 401, 'INVALID_TOKEN');
  }
};

export const findEmail = async (req: Request, res: Response): Promise<void> => {
  try {
    const { nickname, church_name } = req.body;
    if (!nickname) {
      sendError(res, '닉네임을 입력해주세요', 400, 'VALIDATION_ERROR');
      return;
    }
    let query = supabaseAdmin.from('users').select('email, nickname, church_name, created_at').eq('nickname', nickname);
    if (church_name) query = query.eq('church_name', church_name);
    const { data: users } = await query.limit(1);
    if (!users || users.length === 0) {
      sendError(res, '해당 닉네임의 사용자를 찾을 수 없습니다', 404, 'USER_NOT_FOUND');
      return;
    }
    const u = users[0];
    const [localPart, domain] = u.email.split('@');
    const maskedEmail = localPart.slice(0, 3) + '***@' + domain;
    sendSuccess(res, { email: maskedEmail, nickname: u.nickname, church_name: u.church_name, created_at: u.created_at }, '이메일을 찾았습니다');
  } catch {
    sendError(res, '서버 오류가 발생했습니다', 500, 'SERVER_ERROR');
  }
};

export const forgotPassword = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email } = req.body;
    if (!email) {
      sendError(res, '이메일을 입력해주세요', 400, 'VALIDATION_ERROR');
      return;
    }
    const { data: user } = await supabaseAdmin.from('users').select('id').eq('email', email).maybeSingle();
    if (!user) {
      // 보안상 동일 응답
      sendSuccess(res, null, '비밀번호 재설정 이메일을 발송했습니다.');
      return;
    }
    const { error } = await supabaseAdmin.auth.resetPasswordForEmail(email, {
      redirectTo: `${process.env.FRONTEND_URL || 'https://intercesso.app'}/reset-password`,
    });
    if (error) {
      if (error.message?.includes('rate limit') || (error as any).code === 'over_email_send_rate_limit') {
        sendError(res, '이메일 발송 횟수가 초과되었습니다. 1시간 후 다시 시도해주세요.', 429, 'RATE_LIMIT');
        return;
      }
      console.error('forgotPassword 이메일 발송 오류:', error);
      sendError(res, '이메일 발송에 실패했습니다. 잠시 후 다시 시도해주세요.', 500, 'EMAIL_ERROR');
      return;
    }
    sendSuccess(res, null, '비밀번호 재설정 이메일을 발송했습니다.');
  } catch {
    sendError(res, '서버 오류가 발생했습니다', 500, 'SERVER_ERROR');
  }
};
