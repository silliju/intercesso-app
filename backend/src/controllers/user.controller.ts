import { Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import supabaseAdmin from '../config/supabase';
import { sendSuccess, sendError } from '../utils/response';
import { AuthRequest } from '../middleware/auth';

export const getMe = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { data: user, error } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('id', userId)
      .single();

    if (error || !user) {
      sendError(res, '사용자를 찾을 수 없습니다', 404, 'NOT_FOUND');
      return;
    }

    sendSuccess(res, user);
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const updateMe = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { nickname, church_name, denomination, bio, profile_image_url } = req.body;

    const { data: user, error } = await supabaseAdmin
      .from('users')
      .update({
        nickname,
        church_name,
        denomination,
        bio,
        profile_image_url,
        updated_at: new Date().toISOString(),
      })
      .eq('id', userId)
      .select()
      .single();

    if (error) {
      sendError(res, '프로필 수정 실패', 500, 'UPDATE_ERROR');
      return;
    }

    sendSuccess(res, user, '프로필이 수정되었습니다');
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const getUserById = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { userId } = req.params;
    const { data: user, error } = await supabaseAdmin
      .from('users')
      .select('id, nickname, profile_image_url, church_name, denomination, bio, created_at')
      .eq('id', userId)
      .single();

    if (error || !user) {
      sendError(res, '사용자를 찾을 수 없습니다', 404, 'NOT_FOUND');
      return;
    }

    sendSuccess(res, user);
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const getUserStats = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { userId } = req.params;
    const { data: stats, error } = await supabaseAdmin
      .from('user_statistics')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (error || !stats) {
      sendError(res, '통계를 찾을 수 없습니다', 404, 'NOT_FOUND');
      return;
    }

    sendSuccess(res, stats);
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const getConnections = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { data: connections } = await supabaseAdmin
      .from('connections')
      .select(`
        id, connection_type, connected_at,
        friend:users!connections_friend_id_fkey(id, nickname, profile_image_url, church_name)
      `)
      .eq('user_id', userId);

    sendSuccess(res, connections || []);
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const addConnection = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { friend_id } = req.body;

    if (!friend_id) {
      sendError(res, '대상 사용자 ID가 필요합니다', 400, 'VALIDATION_ERROR');
      return;
    }

    const { data: existing } = await supabaseAdmin
      .from('connections')
      .select('id')
      .eq('user_id', userId)
      .eq('friend_id', friend_id)
      .single();

    if (existing) {
      sendError(res, '이미 연결된 사용자입니다', 400, 'ALREADY_CONNECTED');
      return;
    }

    await supabaseAdmin.from('connections').insert({
      id: uuidv4(),
      user_id: userId,
      friend_id,
      connection_type: 'friend',
      connected_at: new Date().toISOString(),
    });

    sendSuccess(res, null, '지인으로 추가되었습니다', 201);
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const searchUsers = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { q } = req.query;
    if (!q) {
      sendError(res, '검색어를 입력해주세요', 400, 'VALIDATION_ERROR');
      return;
    }

    const { data: users } = await supabaseAdmin
      .from('users')
      .select('id, nickname, profile_image_url, church_name')
      .ilike('nickname', `%${q}%`)
      .limit(20);

    sendSuccess(res, users || []);
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

// 계정 삭제 - 구글 플레이 정책 필수 요건
export const deleteMe = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;

    // 1. 내가 만든 그룹에서 나를 creator로 가진 그룹 확인
    const { data: myGroups } = await supabaseAdmin
      .from('groups')
      .select('id')
      .eq('creator_id', userId);

    // 2. 내가 만든 그룹 삭제 (group_members 포함)
    if (myGroups && myGroups.length > 0) {
      const groupIds = myGroups.map((g: any) => g.id);
      await supabaseAdmin.from('group_members').delete().in('group_id', groupIds);
      await supabaseAdmin.from('prayers').update({ group_id: null }).in('group_id', groupIds);
      await supabaseAdmin.from('groups').delete().in('id', groupIds);
    }

    // 3. 내 그룹 멤버십 삭제
    await supabaseAdmin.from('group_members').delete().eq('user_id', userId);

    // 4. 내 기도 참여 기록 삭제
    await supabaseAdmin.from('prayer_participations').delete().eq('user_id', userId);

    // 5. 내 댓글 삭제
    await supabaseAdmin.from('comments').delete().eq('user_id', userId);

    // 6. 내 중보기도 요청 삭제
    await supabaseAdmin.from('intercession_requests').delete().eq('requester_id', userId);
    await supabaseAdmin.from('intercession_requests').delete().eq('target_user_id', userId);

    // 7. 내 알림 삭제
    await supabaseAdmin.from('notifications').delete().eq('user_id', userId);

    // 8. 내 기도 체크인 삭제
    await supabaseAdmin.from('prayer_checkins').delete().eq('user_id', userId);

    // 9. 내 기도 삭제
    await supabaseAdmin.from('prayers').delete().eq('user_id', userId);

    // 10. 내 통계 삭제
    await supabaseAdmin.from('user_statistics').delete().eq('user_id', userId);

    // 11. 사용자 계정 삭제
    const { error } = await supabaseAdmin.from('users').delete().eq('id', userId);

    if (error) {
      sendError(res, '계정 삭제에 실패했습니다', 500, 'DELETE_ERROR');
      return;
    }

    sendSuccess(res, null, '계정이 삭제되었습니다');
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

// FCM 토큰 저장/갱신 (로그인 후 앱에서 호출)
export const updateFcmToken = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { token } = req.body;

    if (!token || typeof token !== 'string') {
      sendError(res, 'FCM 토큰이 필요합니다', 400, 'INVALID_TOKEN');
      return;
    }

    await supabaseAdmin
      .from('users')
      .update({ fcm_token: token })
      .eq('id', userId);

    sendSuccess(res, null, 'FCM 토큰이 저장되었습니다');
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

// FCM 토큰 삭제 (로그아웃 시 호출 → 불필요한 푸시 방지)
export const deleteFcmToken = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;

    await supabaseAdmin
      .from('users')
      .update({ fcm_token: null })
      .eq('id', userId);

    sendSuccess(res, null, 'FCM 토큰이 삭제되었습니다');
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};
