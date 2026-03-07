import { Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import supabaseAdmin from '../config/supabase';
import { sendSuccess, sendError, sendPaginated } from '../utils/response';
import { AuthRequest } from '../middleware/auth';
import { CreateGroupBody } from '../types';

const generateInviteCode = () => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 8; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
};

export const createGroup = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { name, description, group_type, is_public = true } = req.body as CreateGroupBody;

    if (!name || !group_type) {
      sendError(res, '그룹명과 유형은 필수입니다', 400, 'VALIDATION_ERROR');
      return;
    }

    const inviteCode = generateInviteCode();

    const { data: group, error } = await supabaseAdmin
      .from('groups')
      .insert({
        id: uuidv4(),
        name,
        description: description || null,
        group_type,
        creator_id: userId,
        invite_code: inviteCode,
        member_count: 1,
        is_public,
      })
      .select()
      .single();

    if (error) {
      sendError(res, '그룹 생성 실패', 500, 'CREATE_ERROR');
      return;
    }

    // 생성자를 관리자로 추가
    await supabaseAdmin.from('group_members').insert({
      id: uuidv4(),
      group_id: group.id,
      user_id: userId,
      role: 'admin',
      joined_at: new Date().toISOString(),
    });

    sendSuccess(res, group, '그룹이 생성되었습니다', 201);
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const getMyGroups = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;

    const { data: memberships } = await supabaseAdmin
      .from('group_members')
      .select(`
        role,
        joined_at,
        group:groups(*)
      `)
      .eq('user_id', userId);

    const groups = (memberships || []).map((m: any) => ({
      ...m.group,
      user_role: m.role,
      joined_at: m.joined_at,
    }));

    sendSuccess(res, groups);
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const getGroupById = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    const { groupId } = req.params;

    const { data: group, error } = await supabaseAdmin
      .from('groups')
      .select(`*, creator:users(id, nickname, profile_image_url)`)
      .eq('id', groupId)
      .single();

    if (error || !group) {
      sendError(res, '그룹을 찾을 수 없습니다', 404, 'NOT_FOUND');
      return;
    }

    // 내 역할 확인
    let user_role = null;
    if (userId) {
      const { data: membership } = await supabaseAdmin
        .from('group_members')
        .select('role')
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .single();
      user_role = membership?.role || null;
    }

    sendSuccess(res, { ...group, user_role });
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const updateGroup = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { groupId } = req.params;

    // 관리자 확인
    const { data: membership } = await supabaseAdmin
      .from('group_members')
      .select('role')
      .eq('group_id', groupId)
      .eq('user_id', userId)
      .single();

    if (!membership || membership.role !== 'admin') {
      sendError(res, '수정 권한이 없습니다', 403, 'FORBIDDEN');
      return;
    }

    const { data: group, error } = await supabaseAdmin
      .from('groups')
      .update({ ...req.body, updated_at: new Date().toISOString() })
      .eq('id', groupId)
      .select()
      .single();

    if (error) {
      sendError(res, '그룹 수정 실패', 500, 'UPDATE_ERROR');
      return;
    }

    sendSuccess(res, group, '그룹이 수정되었습니다');
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const deleteGroup = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { groupId } = req.params;

    const { data: group } = await supabaseAdmin
      .from('groups')
      .select('creator_id')
      .eq('id', groupId)
      .single();

    if (!group || group.creator_id !== userId) {
      sendError(res, '삭제 권한이 없습니다', 403, 'FORBIDDEN');
      return;
    }

    await supabaseAdmin.from('groups').delete().eq('id', groupId);
    sendSuccess(res, null, '그룹이 삭제되었습니다');
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const joinGroup = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { groupId } = req.params;
    const { invite_code } = req.body;

    // 초대 코드 확인
    const { data: group } = await supabaseAdmin
      .from('groups')
      .select('id, invite_code, member_count, is_public')
      .eq('id', groupId)
      .single();

    if (!group) {
      sendError(res, '그룹을 찾을 수 없습니다', 404, 'NOT_FOUND');
      return;
    }

    if (!group.is_public && group.invite_code !== invite_code) {
      sendError(res, '유효하지 않은 초대 코드입니다', 400, 'INVALID_INVITE_CODE');
      return;
    }

    // 이미 가입 여부 확인
    const { data: existing } = await supabaseAdmin
      .from('group_members')
      .select('id')
      .eq('group_id', groupId)
      .eq('user_id', userId)
      .single();

    if (existing) {
      sendError(res, '이미 가입한 그룹입니다', 400, 'ALREADY_MEMBER');
      return;
    }

    await supabaseAdmin.from('group_members').insert({
      id: uuidv4(),
      group_id: groupId,
      user_id: userId,
      role: 'member',
      joined_at: new Date().toISOString(),
    });

    // 멤버 수 증가
    await supabaseAdmin
      .from('groups')
      .update({ member_count: (group.member_count || 0) + 1 })
      .eq('id', groupId);

    sendSuccess(res, null, '그룹에 가입했습니다');
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const getGroupMembers = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { groupId } = req.params;

    const { data: members } = await supabaseAdmin
      .from('group_members')
      .select(`
        role, joined_at,
        user:users(id, nickname, profile_image_url, church_name)
      `)
      .eq('group_id', groupId)
      .order('joined_at', { ascending: true });

    sendSuccess(res, members || []);
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const removeMember = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { groupId, targetUserId } = req.params;

    // 관리자 확인
    const { data: myMembership } = await supabaseAdmin
      .from('group_members')
      .select('role')
      .eq('group_id', groupId)
      .eq('user_id', userId)
      .single();

    if (!myMembership || myMembership.role !== 'admin') {
      // 본인 탈퇴는 허용
      if (targetUserId !== userId) {
        sendError(res, '권한이 없습니다', 403, 'FORBIDDEN');
        return;
      }
    }

    await supabaseAdmin
      .from('group_members')
      .delete()
      .eq('group_id', groupId)
      .eq('user_id', targetUserId);

    // 멤버 수 감소
    const { data: group } = await supabaseAdmin
      .from('groups')
      .select('member_count')
      .eq('id', groupId)
      .single();

    if (group && group.member_count > 0) {
      await supabaseAdmin
        .from('groups')
        .update({ member_count: group.member_count - 1 })
        .eq('id', groupId);
    }

    sendSuccess(res, null, '멤버가 제거되었습니다');
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const joinByInviteCode = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { invite_code } = req.body;

    if (!invite_code) {
      sendError(res, '초대 코드가 필요합니다', 400, 'VALIDATION_ERROR');
      return;
    }

    const { data: group } = await supabaseAdmin
      .from('groups')
      .select('*')
      .eq('invite_code', invite_code)
      .single();

    if (!group) {
      sendError(res, '유효하지 않은 초대 코드입니다', 404, 'INVALID_CODE');
      return;
    }

    const { data: existing } = await supabaseAdmin
      .from('group_members')
      .select('id')
      .eq('group_id', group.id)
      .eq('user_id', userId)
      .single();

    if (existing) {
      sendError(res, '이미 가입한 그룹입니다', 400, 'ALREADY_MEMBER');
      return;
    }

    await supabaseAdmin.from('group_members').insert({
      id: uuidv4(),
      group_id: group.id,
      user_id: userId,
      role: 'member',
      joined_at: new Date().toISOString(),
    });

    await supabaseAdmin
      .from('groups')
      .update({ member_count: (group.member_count || 0) + 1 })
      .eq('id', group.id);

    sendSuccess(res, group, '그룹에 가입했습니다');
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const leaveGroup = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { groupId } = req.params;

    // 그룹 존재 확인
    const { data: group, error: groupError } = await supabaseAdmin
      .from('groups')
      .select('id, creator_id, member_count')
      .eq('id', groupId)
      .single();

    if (groupError || !group) {
      sendError(res, '그룹을 찾을 수 없습니다', 404, 'GROUP_NOT_FOUND');
      return;
    }

    // 그룹 생성자는 탈퇴 불가
    if (group.creator_id === userId) {
      sendError(res, '그룹 생성자는 탈퇴할 수 없습니다. 그룹을 삭제하거나 관리자를 변경하세요.', 400, 'CREATOR_CANNOT_LEAVE');
      return;
    }

    // 멤버 여부 확인
    const { data: member } = await supabaseAdmin
      .from('group_members')
      .select('id')
      .eq('group_id', groupId)
      .eq('user_id', userId)
      .single();

    if (!member) {
      sendError(res, '가입하지 않은 그룹입니다', 400, 'NOT_MEMBER');
      return;
    }

    // 멤버 삭제
    await supabaseAdmin
      .from('group_members')
      .delete()
      .eq('group_id', groupId)
      .eq('user_id', userId);

    // member_count 감소
    await supabaseAdmin
      .from('groups')
      .update({ member_count: Math.max(0, (group.member_count || 1) - 1) })
      .eq('id', groupId);

    sendSuccess(res, null, '그룹에서 탈퇴했습니다');
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

// 그룹 검색
export const searchGroups = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { q } = req.query as { q?: string };
    if (!q || q.trim().length === 0) {
      sendSuccess(res, []);
      return;
    }

    const { data: groups, error } = await supabaseAdmin
      .from('groups')
      .select('*, creator:users(id, nickname)')
      .ilike('name', `%${q.trim()}%`)
      .eq('is_public', true)
      .limit(20);

    if (error) {
      sendError(res, '검색 중 오류가 발생했습니다', 500, 'SERVER_ERROR');
      return;
    }

    sendSuccess(res, groups || []);
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

// 초대 코드 조회 (관리자 전용)
export const getInviteCode = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { groupId } = req.params;

    // 관리자 확인
    const { data: membership } = await supabaseAdmin
      .from('group_members')
      .select('role')
      .eq('group_id', groupId)
      .eq('user_id', userId)
      .single();

    if (!membership || membership.role !== 'admin') {
      sendError(res, '권한이 없습니다', 403, 'FORBIDDEN');
      return;
    }

    const { data: group, error } = await supabaseAdmin
      .from('groups')
      .select('invite_code')
      .eq('id', groupId)
      .single();

    if (error || !group) {
      sendError(res, '그룹을 찾을 수 없습니다', 404, 'NOT_FOUND');
      return;
    }

    sendSuccess(res, { invite_code: group.invite_code });
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};
