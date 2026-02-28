import { Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import supabaseAdmin from '../config/supabase';
import { sendSuccess, sendError, sendPaginated } from '../utils/response';
import { AuthRequest } from '../middleware/auth';

export const createIntercessionRequest = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { prayer_id, recipient_id, message, priority = 'normal' } = req.body;

    if (!prayer_id || !recipient_id) {
      sendError(res, '기도 ID와 대상자 ID는 필수입니다', 400, 'VALIDATION_ERROR');
      return;
    }

    const { data: request, error } = await supabaseAdmin
      .from('intercession_requests')
      .insert({
        id: uuidv4(),
        prayer_id,
        requester_id: userId,
        recipient_id,
        status: 'pending',
        message: message || null,
        priority,
      })
      .select()
      .single();

    if (error) {
      sendError(res, '중보기도 요청 실패', 500, 'CREATE_ERROR');
      return;
    }

    // 요청받은 사람에게 알림
    const { data: requesterUser } = await supabaseAdmin
      .from('users')
      .select('nickname')
      .eq('id', userId)
      .single();

    await supabaseAdmin.from('notifications').insert({
      id: uuidv4(),
      user_id: recipient_id,
      type: 'intercession_request',
      related_id: request.id,
      title: '중보기도 요청',
      message: `${requesterUser?.nickname || '누군가'}님이 중보기도를 요청했습니다 🙏`,
      is_read: false,
    });

    sendSuccess(res, request, '중보기도 요청을 보냈습니다', 201);
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const getIntercessionRequests = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 10;
    const offset = (page - 1) * limit;

    const { data: requests, count } = await supabaseAdmin
      .from('intercession_requests')
      .select(`
        *,
        prayer:prayers(id, title, content, status),
        requester:users!intercession_requests_requester_id_fkey(id, nickname, profile_image_url)
      `, { count: 'exact' })
      .eq('recipient_id', userId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    sendPaginated(res, requests || [], { page, limit, total: count || 0 });
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const getSentRequests = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 10;
    const status = req.query.status as string;
    const offset = (page - 1) * limit;

    let query = supabaseAdmin
      .from('intercession_requests')
      .select(`
        *,
        prayer:prayers(id, title, content, status),
        recipient:users!intercession_requests_recipient_id_fkey(id, nickname, profile_image_url)
      `, { count: 'exact' })
      .eq('requester_id', userId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (status) query = query.eq('status', status);

    const { data: requests, count } = await query;
    sendPaginated(res, requests || [], { page, limit, total: count || 0 });
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const respondIntercessionRequest = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { requestId } = req.params;
    const { status } = req.body; // 'accepted' | 'rejected'

    if (!status || !['accepted', 'rejected'].includes(status)) {
      sendError(res, '유효한 상태값이 필요합니다 (accepted/rejected)', 400, 'VALIDATION_ERROR');
      return;
    }

    const { data: existing } = await supabaseAdmin
      .from('intercession_requests')
      .select('recipient_id')
      .eq('id', requestId)
      .single();

    if (!existing || existing.recipient_id !== userId) {
      sendError(res, '권한이 없습니다', 403, 'FORBIDDEN');
      return;
    }

    const { data: request, error } = await supabaseAdmin
      .from('intercession_requests')
      .update({ status, responded_at: new Date().toISOString() })
      .eq('id', requestId)
      .select()
      .single();

    if (error) {
      sendError(res, '응답 처리 실패', 500, 'UPDATE_ERROR');
      return;
    }

    sendSuccess(res, request, `요청을 ${status === 'accepted' ? '수락' : '거절'}했습니다`);
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};
