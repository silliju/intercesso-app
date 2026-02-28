import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import supabaseAdmin from '../config/supabase';
import { sendSuccess, sendError } from '../utils/response';
import { SignUpBody, LoginBody } from '../types';

export const signUp = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password, nickname, church_name, denomination, bio } = req.body as SignUpBody;

    if (!email || !password || !nickname) {
      sendError(res, '이메일, 비밀번호, 닉네임은 필수입니다', 400, 'VALIDATION_ERROR');
      return;
    }

    // 이메일 중복 확인
    const { data: existingUser } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('email', email)
      .single();

    if (existingUser) {
      sendError(res, '이미 사용 중인 이메일입니다', 400, 'EMAIL_DUPLICATE');
      return;
    }

    // Supabase Auth로 사용자 생성
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });

    if (authError || !authData.user) {
      sendError(res, '회원가입 중 오류가 발생했습니다', 500, 'AUTH_ERROR', authError?.message);
      return;
    }

    const userId = authData.user.id;

    // users 테이블에 프로필 생성
    const { data: newUser, error: profileError } = await supabaseAdmin
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
      sendError(res, '프로필 생성 중 오류가 발생했습니다', 500, 'PROFILE_ERROR');
      return;
    }

    // user_statistics 초기화
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

    // notification_preferences 초기화
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

    // JWT 발급
    const token = jwt.sign(
      { userId, email },
      process.env.JWT_SECRET!,
      { expiresIn: '7d' }
    );

    sendSuccess(res, { user: newUser, token }, '회원가입이 완료되었습니다', 201);
  } catch (error) {
    sendError(res, '서버 오류가 발생했습니다', 500, 'SERVER_ERROR');
  }
};

export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body as LoginBody;

    if (!email || !password) {
      sendError(res, '이메일과 비밀번호를 입력해주세요', 400, 'VALIDATION_ERROR');
      return;
    }

    // Supabase Auth로 로그인
    const { data: authData, error: authError } = await supabaseAdmin.auth.signInWithPassword({
      email,
      password,
    });

    if (authError || !authData.user) {
      sendError(res, '이메일 또는 비밀번호가 올바르지 않습니다', 401, 'INVALID_CREDENTIALS');
      return;
    }

    const userId = authData.user.id;

    // 사용자 프로필 조회
    const { data: user, error: userError } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('id', userId)
      .single();

    if (userError || !user) {
      sendError(res, '사용자 정보를 찾을 수 없습니다', 404, 'USER_NOT_FOUND');
      return;
    }

    // 마지막 로그인 업데이트
    await supabaseAdmin
      .from('users')
      .update({ last_login: new Date().toISOString() })
      .eq('id', userId);

    // JWT 발급
    const token = jwt.sign(
      { userId, email },
      process.env.JWT_SECRET!,
      { expiresIn: '7d' }
    );

    sendSuccess(res, { user, token }, '로그인 성공');
  } catch (error) {
    sendError(res, '서버 오류가 발생했습니다', 500, 'SERVER_ERROR');
  }
};

export const logout = async (req: Request, res: Response): Promise<void> => {
  sendSuccess(res, null, '로그아웃 되었습니다');
};

export const refreshToken = async (req: Request, res: Response): Promise<void> => {
  try {
    const { token } = req.body;
    if (!token) {
      sendError(res, '토큰이 필요합니다', 400, 'TOKEN_REQUIRED');
      return;
    }

    const payload = jwt.verify(token, process.env.JWT_SECRET!) as any;
    const newToken = jwt.sign(
      { userId: payload.userId, email: payload.email },
      process.env.JWT_SECRET!,
      { expiresIn: '7d' }
    );

    sendSuccess(res, { token: newToken }, '토큰 갱신 성공');
  } catch {
    sendError(res, '유효하지 않은 토큰입니다', 401, 'INVALID_TOKEN');
  }
};
