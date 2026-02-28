// ============================================================
// social_auth.controller.ts - 소셜 로그인 컨트롤러
// ============================================================
// 역할: 구글/카카오 소셜 로그인 처리
//   1. 앱(Flutter)에서 받은 소셜 토큰을 검증
//   2. 신규 사용자면 자동으로 회원가입 처리
//   3. 기존 사용자면 로그인 처리
//   4. 내부 JWT 토큰 발급 후 반환
//
// 흐름:
//   Flutter앱 → 소셜SDK로 토큰 획득 → 백엔드로 전송
//   → 백엔드에서 소셜서버에 토큰 검증 → DB에 사용자 저장/조회
//   → JWT 발급 → Flutter앱으로 반환
// ============================================================

import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { OAuth2Client } from 'google-auth-library';
import axios from 'axios';
import { v4 as uuidv4 } from 'uuid';
import supabaseAdmin from '../config/supabase';
import { sendSuccess, sendError } from '../utils/response';

// 구글 OAuth2 클라이언트 초기화
// GOOGLE_CLIENT_ID: Google Cloud Console에서 발급받은 웹/Android 클라이언트 ID
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// ─────────────────────────────────────────────────────────────
// 공통 유틸: 사용자 조회 또는 자동 생성
// ─────────────────────────────────────────────────────────────

/**
 * 소셜 로그인 사용자를 DB에서 찾거나 없으면 새로 생성합니다.
 * @param email - 소셜 계정 이메일
 * @param nickname - 소셜 계정 닉네임
 * @param provider - 로그인 제공자 ('google' | 'kakao')
 * @param providerId - 소셜 플랫폼의 고유 사용자 ID
 * @returns DB에 저장된 사용자 객체
 */
async function findOrCreateSocialUser(
  email: string,
  nickname: string,
  provider: string,
  providerId: string
) {
  // 1) 이미 가입된 이메일이 있는지 확인
  const { data: existingUser } = await supabaseAdmin
    .from('users')
    .select('*')
    .eq('email', email)
    .single();

  if (existingUser) {
    // 기존 사용자 → 마지막 로그인 시간만 업데이트
    await supabaseAdmin
      .from('users')
      .update({ last_login: new Date().toISOString() })
      .eq('id', existingUser.id);
    return existingUser;
  }

  // 2) 신규 사용자 → Supabase Auth에 계정 생성 (비밀번호 없이)
  const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
    email,
    email_confirm: true, // 소셜 로그인은 이메일 인증 생략
    user_metadata: { provider, provider_id: providerId },
  });

  if (authError || !authData.user) {
    throw new Error(`Supabase Auth 생성 실패: ${authError?.message}`);
  }

  const userId = authData.user.id;

  // 3) users 테이블에 프로필 저장
  const { data: newUser, error: profileError } = await supabaseAdmin
    .from('users')
    .insert({
      id: userId,
      email,
      // 닉네임 중복 방지를 위해 소셜ID 뒷자리 4자리 추가
      nickname: nickname || `사용자${providerId.slice(-4)}`,
      provider,           // 가입 경로 저장 ('google' | 'kakao')
      provider_id: providerId,
    })
    .select()
    .single();

  if (profileError) {
    throw new Error(`프로필 생성 실패: ${profileError.message}`);
  }

  // 4) 통계 초기화 (신규 가입 시 필요)
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

  // 5) 알림 설정 초기화
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

  return newUser;
}

/**
 * 사용자 정보로 JWT 토큰을 생성합니다.
 * @param userId - DB 사용자 ID
 * @param email - 사용자 이메일
 * @returns JWT 문자열 (7일 유효)
 */
function generateJWT(userId: string, email: string): string {
  return jwt.sign(
    { userId, email },
    process.env.JWT_SECRET!,
    { expiresIn: '7d' }
  );
}

// ─────────────────────────────────────────────────────────────
// 구글 소셜 로그인 API
// POST /api/auth/social/google
// ─────────────────────────────────────────────────────────────

/**
 * 구글 로그인 처리
 *
 * 요청 body:
 *   - id_token: 구글 SDK에서 발급받은 ID 토큰
 *   - email: 구글 계정 이메일 (id_token에서도 추출 가능, 보조용)
 *   - nickname: 구글 표시 이름
 *
 * 처리 흐름:
 *   1. 구글 서버에 id_token 검증 요청
 *   2. 검증 성공 → 사용자 정보 추출
 *   3. DB에서 사용자 조회 or 자동 회원가입
 *   4. 내부 JWT 발급 후 반환
 */
export const googleLogin = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id_token, access_token, email, nickname, profile_image_url } = req.body;

    let googleUserId: string;
    let verifiedEmail: string;
    let verifiedNickname: string;

    if (id_token) {
      // Flutter 앱: id_token 방식 (Google Sign-In SDK)
      try {
        const ticket = await googleClient.verifyIdToken({
          idToken: id_token,
          audience: process.env.GOOGLE_CLIENT_ID,
        });
        const payload = ticket.getPayload();
        if (!payload || !payload.sub) throw new Error('페이로드 없음');
        googleUserId = payload.sub;
        verifiedEmail = payload.email || email;
        verifiedNickname = payload.name || nickname || verifiedEmail.split('@')[0];
      } catch (verifyError) {
        sendError(res, '유효하지 않은 구글 토큰입니다', 401, 'INVALID_GOOGLE_TOKEN');
        return;
      }
    } else if (access_token) {
      // 웹: access_token 방식 (OAuth2 Implicit Flow)
      try {
        const userInfoRes = await axios.get('https://www.googleapis.com/oauth2/v3/userinfo', {
          headers: { Authorization: `Bearer ${access_token}` },
        });
        const info = userInfoRes.data;
        googleUserId = info.sub;
        verifiedEmail = info.email || email;
        verifiedNickname = info.name || nickname || verifiedEmail?.split('@')[0] || '구글사용자';
      } catch (e) {
        sendError(res, '구글 사용자 정보 조회 실패', 401, 'INVALID_GOOGLE_TOKEN');
        return;
      }
    } else {
      sendError(res, '구글 토큰이 필요합니다', 400, 'MISSING_TOKEN');
      return;
    }

    if (!verifiedEmail) {
      sendError(res, '구글 계정에서 이메일을 가져올 수 없습니다', 400, 'EMAIL_REQUIRED');
      return;
    }

    // ─── 사용자 조회 or 생성 ──────────────────────────────
    const user = await findOrCreateSocialUser(
      verifiedEmail,
      verifiedNickname,
      'google',
      googleUserId
    );

    // ─── JWT 발급 ─────────────────────────────────────────
    const token = generateJWT(user.id, user.email);

    sendSuccess(res, { user, token }, '구글 로그인 성공');
  } catch (error: any) {
    console.error('[구글 로그인 오류]', error);
    sendError(res, '구글 로그인 처리 중 오류가 발생했습니다', 500, 'SERVER_ERROR');
  }
};

// ─────────────────────────────────────────────────────────────
// 카카오 소셜 로그인 API
// POST /api/auth/social/kakao
// ─────────────────────────────────────────────────────────────

/**
 * 카카오 로그인 처리
 *
 * 요청 body:
 *   - access_token: 카카오 SDK에서 발급받은 액세스 토큰
 *   - kakao_id: 카카오 고유 사용자 ID
 *   - email: 카카오 계정 이메일 (선택, 없을 수 있음)
 *   - nickname: 카카오 프로필 닉네임
 *
 * 처리 흐름:
 *   1. 카카오 서버에 access_token으로 사용자 정보 요청
 *   2. 검증 성공 → 사용자 정보 추출
 *   3. DB에서 사용자 조회 or 자동 회원가입
 *   4. 내부 JWT 발급 후 반환
 */
export const kakaoLogin = async (req: Request, res: Response): Promise<void> => {
  try {
    const { access_token, code, redirect_uri, kakao_id, email: clientEmail, nickname: clientNickname } = req.body;

    // access_token 또는 인가코드(code) 중 하나 필요
    let finalAccessToken = access_token;

    // 웹에서 인가코드(code)로 왔을 경우 access_token으로 교환
    if (!finalAccessToken && code) {
      try {
        // redirect_uri: 클라이언트에서 전달하거나 origin 헤더에서 추출
        const origin = req.headers.origin || '';
        const callbackUri = redirect_uri || (origin ? origin + '/' : null);
        
        if (!callbackUri) {
          sendError(res, '카카오 redirect_uri가 필요합니다', 400, 'MISSING_REDIRECT_URI');
          return;
        }

        console.log('[카카오] 인가코드 교환 시도, redirect_uri:', callbackUri);
        
        const tokenRes = await axios.post('https://kauth.kakao.com/oauth/token', null, {
          params: {
            grant_type: 'authorization_code',
            client_id: process.env.KAKAO_REST_API_KEY,
            redirect_uri: callbackUri,
            code,
          },
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        });
        finalAccessToken = tokenRes.data.access_token;
      } catch (tokenError: any) {
        console.error('[카카오 토큰 교환 오류]', tokenError?.response?.data);
        sendError(res, '카카오 인가코드 처리 실패', 401, 'KAKAO_TOKEN_EXCHANGE_FAILED');
        return;
      }
    }

    if (!finalAccessToken) {
      sendError(res, '카카오 액세스 토큰 또는 인가코드가 필요합니다', 400, 'MISSING_TOKEN');
      return;
    }

    // ─── 카카오 토큰 검증 (카카오 서버에 사용자 정보 요청) ──
    let kakaoUserId: string;
    let kakaoEmail: string;
    let kakaoNickname: string;

    try {
      const kakaoResponse = await axios.get('https://kapi.kakao.com/v2/user/me', {
        headers: {
          Authorization: `Bearer ${finalAccessToken}`,
          'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8',
        },
      });

      const kakaoUser = kakaoResponse.data;
      kakaoUserId = kakaoUser.id?.toString() || kakao_id;
      kakaoEmail = kakaoUser.kakao_account?.email || clientEmail || '';
      kakaoNickname = kakaoUser.kakao_account?.profile?.nickname
        || kakaoUser.properties?.nickname
        || clientNickname
        || '카카오사용자';
    } catch (kakaoError: any) {
      console.error('[카카오 API 오류]', kakaoError?.response?.data || kakaoError.message);
      sendError(res, '유효하지 않은 카카오 토큰입니다', 401, 'INVALID_KAKAO_TOKEN');
      return;
    }

    // 이메일이 없는 경우 카카오ID 기반으로 가상 이메일 생성
    // (카카오는 이메일 제공 동의가 선택사항)
    if (!kakaoEmail) {
      kakaoEmail = `kakao_${kakaoUserId}@kakao.intercesso.app`;
    }

    // ─── 사용자 조회 or 생성 ──────────────────────────────
    const user = await findOrCreateSocialUser(
      kakaoEmail,
      kakaoNickname,
      'kakao',
      kakaoUserId
    );

    // ─── JWT 발급 ─────────────────────────────────────────
    const token = generateJWT(user.id, user.email);

    sendSuccess(res, { user, token }, '카카오 로그인 성공');
  } catch (error: any) {
    console.error('[카카오 로그인 오류]', error);
    sendError(res, '카카오 로그인 처리 중 오류가 발생했습니다', 500, 'SERVER_ERROR');
  }
};
