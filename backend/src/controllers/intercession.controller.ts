import { Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import supabaseAdmin from '../config/supabase';
import { sendSuccess, sendError, sendPaginated } from '../utils/response';
import { AuthRequest } from '../middleware/auth';

/**
 * message 필드에 타입 정보 인코딩 (DB 스키마 변경 없이 target_type 구현)
 * [PUBLIC]      → 전체 공개 요청
 * [GROUP:uuid]  → 그룹 요청
 * (없음)        → 개인 요청
 */
function encodeMessage(target_type: string, group_id: string | undefined, message: string): string {
  const msg = message || '';
  if (target_type === 'public') return `[PUBLIC]${msg}`;
  if (target_type === 'group' && group_id) return `[GROUP:${group_id}]${msg}`;
  return msg;
}

function decodeMessage(rawMessage: string | null): { target_type: string; group_id?: string; message: string } {
  if (!rawMessage) return { target_type: 'individual', message: '' };
  if (rawMessage.startsWith('[PUBLIC]')) return { target_type: 'public', message: rawMessage.slice(8) };
  const groupMatch = rawMessage.match(/^\[GROUP:([^\]]+)\](.*)/s);
  if (groupMatch) return { target_type: 'group', group_id: groupMatch[1], message: groupMatch[2] };
  return { target_type: 'individual', message: rawMessage };
}

/**
 * 중보기도 요청 생성
 * target_type: 'individual' | 'group' | 'public'
 *   - individual: recipient_id 필수
 *   - group:      group_id 필수 (그룹 멤버 전체에게 개별 레코드 삽입)
 *   - public:     recipient_id = requester 자신 (더미), message 앞에 [PUBLIC] 태그
 */
export const createIntercessionRequest = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const {
      prayer_id,
      recipient_id,
      group_id,
      target_type = 'individual',
      message = '',
      priority = 'normal',
    } = req.body;

    if (!prayer_id) {
      sendError(res, '기도 ID는 필수입니다', 400, 'VALIDATION_ERROR');
      return;
    }
    if (target_type === 'individual' && !recipient_id) {
      sendError(res, '개인 요청은 대상자 ID가 필요합니다', 400, 'VALIDATION_ERROR');
      return;
    }
    if (target_type === 'group' && !group_id) {
      sendError(res, '그룹 요청은 그룹 ID가 필요합니다', 400, 'VALIDATION_ERROR');
      return;
    }

    // 요청자 닉네임 조회
    const { data: requesterUser } = await supabaseAdmin
      .from('users')
      .select('nickname')
      .eq('id', userId)
      .single();
    const requesterNick = requesterUser?.nickname || '누군가';

    // ── 그룹 브로드캐스트: 각 멤버에게 개별 레코드 삽입 ──
    if (target_type === 'group' && group_id) {
      const { data: members } = await supabaseAdmin
        .from('group_members')
        .select('user_id')
        .eq('group_id', group_id)
        .neq('user_id', userId); // 본인 제외

      if (!members || members.length === 0) {
        sendError(res, '그룹 멤버가 없습니다', 400, 'NO_MEMBERS');
        return;
      }

      const encodedMsg = encodeMessage('group', group_id, message);
      const rows = members.map((m) => ({
        id: uuidv4(),
        prayer_id,
        requester_id: userId,
        recipient_id: m.user_id,
        status: 'pending',
        message: encodedMsg,
        priority,
      }));

      const { error } = await supabaseAdmin.from('intercession_requests').insert(rows);
      if (error) {
        console.error('그룹 중보기도 요청 오류:', error);
        sendError(res, '그룹 중보기도 요청 실패', 500, 'CREATE_ERROR');
        return;
      }

      // 알림 일괄 발송
      const notifs = members.map((m) => ({
        id: uuidv4(),
        user_id: m.user_id,
        type: 'intercession_request',
        related_id: prayer_id,
        title: '그룹 중보기도 요청',
        message: `${requesterNick}님이 그룹에 중보기도를 요청했습니다 🙏`,
        is_read: false,
      }));
      await supabaseAdmin.from('notifications').insert(notifs)

      sendSuccess(res, { count: members.length }, `${members.length}명에게 중보기도 요청을 보냈습니다`, 201);
      return;
    }

    // ── 중복 요청 방지 (individual: 같은 기도+수신자에게 pending/accepted 요청이 이미 있으면 거부) ──
    if (target_type === 'individual' && recipient_id) {
      const { data: existing } = await supabaseAdmin
        .from('intercession_requests')
        .select('id, status')
        .eq('prayer_id', prayer_id)
        .eq('requester_id', userId)
        .eq('recipient_id', recipient_id)
        .in('status', ['pending', 'accepted'])
        .limit(1);
      if (existing && existing.length > 0) {
        sendError(res, '이미 같은 분에게 중보기도 요청을 보냈습니다', 409, 'DUPLICATE_REQUEST');
        return;
      }
    }

    // ── 전체공개: recipient_id = requester 자신 (NOT NULL 우회), message에 [PUBLIC] 태그 ──
    const encodedMsg = encodeMessage(target_type, undefined, message);
    const insertData = {
      id: uuidv4(),
      prayer_id,
      requester_id: userId,
      recipient_id: target_type === 'public' ? userId : recipient_id,
      status: 'pending',
      message: encodedMsg || null,
      priority,
    };

    const { data: request, error } = await supabaseAdmin
      .from('intercession_requests')
      .insert(insertData)
      .select()
      .single();

    if (error) {
      console.error('중보기도 요청 오류:', error);
      sendError(res, '중보기도 요청 실패', 500, 'CREATE_ERROR');
      return;
    }

    // 개인 요청이면 알림 발송
    if (target_type === 'individual' && recipient_id) {
      await supabaseAdmin.from('notifications').insert({
        id: uuidv4(),
        user_id: recipient_id,
        type: 'intercession_request',
        related_id: request.id,
        title: '중보기도 요청',
        message: `${requesterNick}님이 중보기도를 요청했습니다 🙏`,
        is_read: false,
      })
    }

    // 디코드된 정보 포함하여 반환
    const decoded = decodeMessage(request.message);
    sendSuccess(res, { ...request, target_type: decoded.target_type, group_id: decoded.group_id, message: decoded.message }, '중보기도 요청을 보냈습니다', 201);
  } catch (e) {
    console.error('createIntercessionRequest error:', e);
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

/** 받은 중보기도 요청 목록 (나에게 온 요청) */
export const getIntercessionRequests = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const offset = (page - 1) * limit;

    const { data: requests, count } = await supabaseAdmin
      .from('intercession_requests')
      .select(`
        *,
        prayer:prayers(id, title, content, status, category),
        requester:users!intercession_requests_requester_id_fkey(id, nickname, profile_image_url, church_name)
      `, { count: 'exact' })
      .eq('recipient_id', userId)
      .neq('requester_id', userId) // 전체공개 자기 자신 제외
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    // message 디코딩
    const items = (requests || []).map(r => {
      const decoded = decodeMessage(r.message);
      return { ...r, target_type: decoded.target_type, group_id: decoded.group_id, message: decoded.message };
    });

    sendPaginated(res, items, { page, limit, total: count || 0 });
  } catch (e) {
    console.error('getIntercessionRequests error:', e);
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

/** 전체공개 중보기도 요청 목록 */
export const getPublicIntercessionRequests = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const offset = (page - 1) * limit;

    // [PUBLIC] 태그가 있는 메시지를 검색
    const { data: requests, count } = await supabaseAdmin
      .from('intercession_requests')
      .select(`
        *,
        prayer:prayers(id, title, content, status, category, scope),
        requester:users!intercession_requests_requester_id_fkey(id, nickname, profile_image_url, church_name)
      `, { count: 'exact' })
      .like('message', '[PUBLIC]%')
      .eq('status', 'pending')
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    // message 디코딩
    const items = (requests || []).map(r => {
      const decoded = decodeMessage(r.message);
      return { ...r, target_type: 'public', message: decoded.message };
    });

    sendPaginated(res, items, { page, limit, total: count || 0 });
  } catch (e) {
    console.error('getPublicIntercessionRequests error:', e);
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

/** 보낸 중보기도 요청 목록 */
export const getSentRequests = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const status = req.query.status as string;
    const offset = (page - 1) * limit;

    let query = supabaseAdmin
      .from('intercession_requests')
      .select(`
        *,
        prayer:prayers(id, title, content, status, category),
        recipient:users!intercession_requests_recipient_id_fkey(id, nickname, profile_image_url)
      `, { count: 'exact' })
      .eq('requester_id', userId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (status) query = query.eq('status', status);

    const { data: requests, count } = await query;

    // message 디코딩 + 전체공개 중복 제거 (recipient_id = requester_id인 PUBLIC 요청은 대표 1건만)
    const seenPublicPrayers = new Set<string>();
    const items: any[] = [];
    for (const r of (requests || [])) {
      const decoded = decodeMessage(r.message);
      if (decoded.target_type === 'public') {
        // 같은 prayer_id의 PUBLIC 요청은 1건만 포함
        if (seenPublicPrayers.has(r.prayer_id)) continue;
        seenPublicPrayers.add(r.prayer_id);
        items.push({ ...r, target_type: 'public', group_id: undefined, message: decoded.message, recipient: null });
      } else {
        items.push({ ...r, target_type: decoded.target_type, group_id: decoded.group_id, message: decoded.message });
      }
    }

    sendPaginated(res, items, { page, limit, total: count || 0 });
  } catch (e) {
    console.error('getSentRequests error:', e);
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

/** 요청 수락/거절 */
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
      .select('recipient_id, requester_id, prayer_id, message')
      .eq('id', requestId)
      .single();

    if (!existing) {
      sendError(res, '요청을 찾을 수 없습니다', 404, 'NOT_FOUND');
      return;
    }

    const decoded = decodeMessage(existing.message);

    // 전체공개 요청: 누구나 수락 가능
    // 개인/그룹 요청: 수신자만 응답 가능
    if (decoded.target_type !== 'public' && existing.recipient_id !== userId) {
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

    // 요청자에게 수락 알림
    if (status === 'accepted') {
      const { data: respUser } = await supabaseAdmin
        .from('users').select('nickname').eq('id', userId).single();
      await supabaseAdmin.from('notifications').insert({
        id: uuidv4(),
        user_id: existing.requester_id,
        type: 'intercession_accepted',
        related_id: existing.prayer_id,
        title: '중보기도 수락',
        message: `${respUser?.nickname || '누군가'}님이 중보기도 요청을 수락했습니다 🙏`,
        is_read: false,
      })
    }

    sendSuccess(res, { ...request, target_type: decoded.target_type, message: decoded.message },
      `요청을 ${status === 'accepted' ? '수락' : '거절'}했습니다`);
  } catch (e) {
    console.error('respondIntercessionRequest error:', e);
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

/** 사용자 검색 (개인 요청 대상자 선택용) */
export const searchUsersForIntercession = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const q = (req.query.q as string || '').trim();
    if (q.length < 1) {
      sendSuccess(res, []);
      return;
    }
    const { data: users } = await supabaseAdmin
      .from('users')
      .select('id, nickname, profile_image_url, church_name')
      .neq('id', userId)
      .ilike('nickname', `%${q}%`)
      .limit(10);

    sendSuccess(res, users || []);
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};
