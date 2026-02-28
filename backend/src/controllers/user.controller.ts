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
