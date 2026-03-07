import { Response } from 'express';
import supabaseAdmin from '../config/supabase';
import { sendSuccess, sendError, sendPaginated } from '../utils/response';
import { AuthRequest } from '../middleware/auth';

// ============================================================
// 감사일기 CRUD
// ============================================================

/**
 * 감사일기 작성 (하루 1개, upsert 방식)
 * POST /api/gratitude
 */
export const createGratitudeJournal = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    if (!userId) { sendError(res, '인증 필요', 401); return; }

    const { gratitude_1, gratitude_2, gratitude_3, emotion, linked_prayer_id, scope, journal_date } = req.body;

    if (!gratitude_1 || !gratitude_1.trim()) {
      sendError(res, '첫 번째 감사 내용은 필수입니다', 400);
      return;
    }

    const today = journal_date || new Date().toISOString().split('T')[0];

    // upsert: 같은 날 이미 있으면 수정
    const { data, error } = await supabaseAdmin
      .from('gratitude_journals')
      .upsert({
        user_id: userId,
        gratitude_1: gratitude_1.trim(),
        gratitude_2: gratitude_2?.trim() || null,
        gratitude_3: gratitude_3?.trim() || null,
        emotion: emotion || null,
        linked_prayer_id: linked_prayer_id || null,
        scope: scope || 'private',
        journal_date: today,
        updated_at: new Date().toISOString(),
      }, { onConflict: 'user_id,journal_date' })
      .select(`
        *,
        user:users(id, nickname, profile_image_url, church_name),
        linked_prayer:prayers(id, title, status)
      `)
      .single();

    if (error) {
      console.error('감사일기 저장 오류:', error);
      sendError(res, '감사일기 저장 실패', 500, 'DB_ERROR', error.message);
      return;
    }

    // 스트릭 업데이트
    await updateStreak(userId, today);

    sendSuccess(res, data, '감사일기가 저장되었습니다', 201);
  } catch (err: any) {
    console.error('createGratitudeJournal error:', err);
    sendError(res, '서버 오류', 500, 'SERVER_ERROR', err.message);
  }
};

/**
 * 내 감사일기 목록
 * GET /api/gratitude/my?page=1&limit=20
 */
export const getMyGratitudeJournals = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    if (!userId) { sendError(res, '인증 필요', 401); return; }

    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const offset = (page - 1) * limit;

    const { data, error, count } = await supabaseAdmin
      .from('gratitude_journals')
      .select(`
        *,
        linked_prayer:prayers(id, title, status),
        gratitude_reactions(reaction_type, count()),
        gratitude_comments(count())
      `, { count: 'exact' })
      .eq('user_id', userId)
      .order('journal_date', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) { sendError(res, '조회 실패', 500, 'DB_ERROR', error.message); return; }

    sendPaginated(res, data || [], { page, limit, total: count || 0 }, '내 감사일기 목록');
  } catch (err: any) {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR', err.message);
  }
};

/**
 * 오늘의 감사일기 조회
 * GET /api/gratitude/today
 */
export const getTodayJournal = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    if (!userId) { sendError(res, '인증 필요', 401); return; }

    const today = new Date().toISOString().split('T')[0];

    const { data, error } = await supabaseAdmin
      .from('gratitude_journals')
      .select(`
        *,
        linked_prayer:prayers(id, title, status)
      `)
      .eq('user_id', userId)
      .eq('journal_date', today)
      .maybeSingle();

    if (error) { sendError(res, '조회 실패', 500, 'DB_ERROR', error.message); return; }

    sendSuccess(res, data, '오늘의 감사일기');
  } catch (err: any) {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR', err.message);
  }
};

/**
 * 특정 감사일기 상세 조회
 * GET /api/gratitude/:journalId
 */
export const getGratitudeJournalById = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    const { journalId } = req.params;

    const { data, error } = await supabaseAdmin
      .from('gratitude_journals')
      .select(`
        *,
        user:users(id, nickname, profile_image_url, church_name),
        linked_prayer:prayers(id, title, status, content),
        gratitude_reactions(id, user_id, reaction_type),
        gratitude_comments(
          id, content, created_at,
          user:users(id, nickname, profile_image_url)
        )
      `)
      .eq('id', journalId)
      .single();

    if (error || !data) {
      sendError(res, '감사일기를 찾을 수 없습니다', 404);
      return;
    }

    // 비공개면 본인만 조회 가능
    if (data.scope === 'private' && data.user_id !== userId) {
      sendError(res, '접근 권한이 없습니다', 403);
      return;
    }

    // 그룹 공개면 같은 그룹 멤버만 조회 가능 (추후 구현 가능)
    // 지금은 로그인 사용자라면 허용

    // 내가 한 반응 표시
    const myReactions = data.gratitude_reactions
      ?.filter((r: any) => r.user_id === userId)
      .map((r: any) => r.reaction_type) || [];

    sendSuccess(res, { ...data, my_reactions: myReactions }, '감사일기 상세');
  } catch (err: any) {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR', err.message);
  }
};

/**
 * 감사일기 수정
 * PUT /api/gratitude/:journalId
 */
export const updateGratitudeJournal = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    if (!userId) { sendError(res, '인증 필요', 401); return; }

    const { journalId } = req.params;
    const { gratitude_1, gratitude_2, gratitude_3, emotion, linked_prayer_id, scope } = req.body;

    // 본인 확인
    const { data: existing } = await supabaseAdmin
      .from('gratitude_journals')
      .select('id, user_id')
      .eq('id', journalId)
      .single();

    if (!existing || existing.user_id !== userId) {
      sendError(res, '수정 권한이 없습니다', 403);
      return;
    }

    const updates: any = { updated_at: new Date().toISOString() };
    if (gratitude_1 !== undefined) updates.gratitude_1 = gratitude_1.trim();
    if (gratitude_2 !== undefined) updates.gratitude_2 = gratitude_2?.trim() || null;
    if (gratitude_3 !== undefined) updates.gratitude_3 = gratitude_3?.trim() || null;
    if (emotion !== undefined) updates.emotion = emotion;
    if (linked_prayer_id !== undefined) updates.linked_prayer_id = linked_prayer_id || null;
    if (scope !== undefined) updates.scope = scope;

    const { data, error } = await supabaseAdmin
      .from('gratitude_journals')
      .update(updates)
      .eq('id', journalId)
      .select(`
        *,
        linked_prayer:prayers(id, title, status)
      `)
      .single();

    if (error) { sendError(res, '수정 실패', 500, 'DB_ERROR', error.message); return; }

    sendSuccess(res, data, '감사일기가 수정되었습니다');
  } catch (err: any) {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR', err.message);
  }
};

/**
 * 감사일기 삭제
 * DELETE /api/gratitude/:journalId
 */
export const deleteGratitudeJournal = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    if (!userId) { sendError(res, '인증 필요', 401); return; }

    const { journalId } = req.params;

    const { data: existing } = await supabaseAdmin
      .from('gratitude_journals')
      .select('id, user_id')
      .eq('id', journalId)
      .single();

    if (!existing || existing.user_id !== userId) {
      sendError(res, '삭제 권한이 없습니다', 403);
      return;
    }

    await supabaseAdmin
      .from('gratitude_journals')
      .delete()
      .eq('id', journalId);

    sendSuccess(res, null, '감사일기가 삭제되었습니다');
  } catch (err: any) {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR', err.message);
  }
};

// ============================================================
// 소셜 피드
// ============================================================

/**
 * 감사 피드 조회 (그룹/팔로우/전체)
 * GET /api/gratitude/feed?tab=group|following|public&page=1&limit=20
 */
export const getGratitudeFeed = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    if (!userId) { sendError(res, '인증 필요', 401); return; }

    const tab = (req.query.tab as string) || 'group';
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const offset = (page - 1) * limit;

    let query = supabaseAdmin
      .from('gratitude_journals')
      .select(`
        *,
        user:users(id, nickname, profile_image_url, church_name),
        linked_prayer:prayers(id, title, status),
        gratitude_reactions(reaction_type),
        gratitude_comments(count())
      `, { count: 'exact' })
      .neq('scope', 'private')
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (tab === 'group') {
      // 내가 속한 그룹의 멤버들 감사일기
      const { data: myGroups } = await supabaseAdmin
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId);

      const groupIds = myGroups?.map((g: any) => g.group_id) || [];

      if (groupIds.length === 0) {
        sendPaginated(res, [], { page, limit, total: 0 }, '그룹 감사 피드');
        return;
      }

      // 그룹 멤버 목록 가져오기
      const { data: groupMembers } = await supabaseAdmin
        .from('group_members')
        .select('user_id')
        .in('group_id', groupIds);

      const memberIds = [...new Set(groupMembers?.map((m: any) => m.user_id) || [])];
      memberIds.push(userId); // 본인도 포함

      query = query.in('user_id', memberIds).in('scope', ['group', 'public']);
    } else if (tab === 'following') {
      // 팔로우한 사람들 (user_connections 테이블 활용)
      const { data: following } = await supabaseAdmin
        .from('user_connections')
        .select('connected_user_id')
        .eq('user_id', userId)
        .eq('connection_type', 'following');

      const followingIds = following?.map((f: any) => f.connected_user_id) || [];
      followingIds.push(userId);

      query = query.in('user_id', followingIds);
    } else {
      // 전체 공개
      query = query.eq('scope', 'public');
    }

    const { data, error, count } = await query;

    if (error) { sendError(res, '피드 조회 실패', 500, 'DB_ERROR', error.message); return; }

    // 내 반응 여부 표시
    const journalIds = (data || []).map((j: any) => j.id);
    let myReactionsMap: Record<string, string[]> = {};

    if (journalIds.length > 0) {
      const { data: myReactions } = await supabaseAdmin
        .from('gratitude_reactions')
        .select('journal_id, reaction_type')
        .eq('user_id', userId)
        .in('journal_id', journalIds);

      myReactions?.forEach((r: any) => {
        if (!myReactionsMap[r.journal_id]) myReactionsMap[r.journal_id] = [];
        myReactionsMap[r.journal_id].push(r.reaction_type);
      });
    }

    const enrichedData = (data || []).map((j: any) => {
      const reactionCounts = { grace: 0, empathy: 0 };
      j.gratitude_reactions?.forEach((r: any) => {
        if (r.reaction_type === 'grace') reactionCounts.grace++;
        if (r.reaction_type === 'empathy') reactionCounts.empathy++;
      });
      const commentCount = j.gratitude_comments?.[0]?.count || 0;

      return {
        ...j,
        reaction_counts: reactionCounts,
        comment_count: commentCount,
        my_reactions: myReactionsMap[j.id] || [],
        gratitude_reactions: undefined,
        gratitude_comments: undefined,
      };
    });

    sendPaginated(res, enrichedData, { page, limit, total: count || 0 }, '감사 피드');
  } catch (err: any) {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR', err.message);
  }
};

// ============================================================
// 반응 (grace / empathy)
// ============================================================

/**
 * 반응 추가/취소 (토글)
 * POST /api/gratitude/:journalId/reactions
 */
export const toggleReaction = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    if (!userId) { sendError(res, '인증 필요', 401); return; }

    const { journalId } = req.params;
    const { reaction_type } = req.body; // 'grace' | 'empathy'

    if (!['grace', 'empathy'].includes(reaction_type)) {
      sendError(res, '올바른 반응 타입이 아닙니다 (grace | empathy)', 400);
      return;
    }

    // 이미 반응했는지 확인
    const { data: existing } = await supabaseAdmin
      .from('gratitude_reactions')
      .select('id')
      .eq('journal_id', journalId)
      .eq('user_id', userId)
      .eq('reaction_type', reaction_type)
      .maybeSingle();

    if (existing) {
      // 취소
      await supabaseAdmin
        .from('gratitude_reactions')
        .delete()
        .eq('id', existing.id);

      sendSuccess(res, { toggled: false, reaction_type }, '반응이 취소되었습니다');
    } else {
      // 추가
      const { data, error } = await supabaseAdmin
        .from('gratitude_reactions')
        .insert({ journal_id: journalId, user_id: userId, reaction_type })
        .select()
        .single();

      if (error) { sendError(res, '반응 저장 실패', 500, 'DB_ERROR', error.message); return; }

      sendSuccess(res, { toggled: true, reaction_type, data }, '반응이 추가되었습니다', 201);
    }
  } catch (err: any) {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR', err.message);
  }
};

// ============================================================
// 댓글
// ============================================================

/**
 * 댓글 작성
 * POST /api/gratitude/:journalId/comments
 */
export const addComment = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    if (!userId) { sendError(res, '인증 필요', 401); return; }

    const { journalId } = req.params;
    const { content } = req.body;

    if (!content?.trim()) {
      sendError(res, '댓글 내용을 입력해주세요', 400);
      return;
    }

    const { data, error } = await supabaseAdmin
      .from('gratitude_comments')
      .insert({ journal_id: journalId, user_id: userId, content: content.trim() })
      .select(`
        *,
        user:users(id, nickname, profile_image_url)
      `)
      .single();

    if (error) { sendError(res, '댓글 저장 실패', 500, 'DB_ERROR', error.message); return; }

    sendSuccess(res, data, '댓글이 작성되었습니다', 201);
  } catch (err: any) {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR', err.message);
  }
};

/**
 * 댓글 삭제
 * DELETE /api/gratitude/comments/:commentId
 */
export const deleteComment = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    if (!userId) { sendError(res, '인증 필요', 401); return; }

    const { commentId } = req.params;

    const { data: comment } = await supabaseAdmin
      .from('gratitude_comments')
      .select('id, user_id')
      .eq('id', commentId)
      .single();

    if (!comment || comment.user_id !== userId) {
      sendError(res, '삭제 권한이 없습니다', 403);
      return;
    }

    await supabaseAdmin.from('gratitude_comments').delete().eq('id', commentId);

    sendSuccess(res, null, '댓글이 삭제되었습니다');
  } catch (err: any) {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR', err.message);
  }
};

// ============================================================
// 스트릭 & 통계
// ============================================================

/**
 * 스트릭 정보 조회
 * GET /api/gratitude/streak
 */
export const getStreak = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    if (!userId) { sendError(res, '인증 필요', 401); return; }

    const { data, error } = await supabaseAdmin
      .from('gratitude_streaks')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle();

    sendSuccess(res, data || {
      user_id: userId,
      current_streak: 0,
      longest_streak: 0,
      last_journal_date: null,
      total_count: 0,
    }, '스트릭 정보');
  } catch (err: any) {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR', err.message);
  }
};

/**
 * 캘린더 데이터 조회 (특정 년-월)
 * GET /api/gratitude/calendar?year=2026&month=3
 */
export const getCalendar = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    if (!userId) { sendError(res, '인증 필요', 401); return; }

    const year = parseInt(req.query.year as string) || new Date().getFullYear();
    const month = parseInt(req.query.month as string) || new Date().getMonth() + 1;

    const startDate = `${year}-${String(month).padStart(2, '0')}-01`;
    const endDate = new Date(year, month, 0).toISOString().split('T')[0]; // 말일

    const { data, error } = await supabaseAdmin
      .from('gratitude_journals')
      .select('id, journal_date, emotion, scope')
      .eq('user_id', userId)
      .gte('journal_date', startDate)
      .lte('journal_date', endDate)
      .order('journal_date', { ascending: true });

    if (error) { sendError(res, '캘린더 조회 실패', 500, 'DB_ERROR', error.message); return; }

    // 날짜 → 일기 맵
    const calendarMap: Record<string, any> = {};
    (data || []).forEach((j: any) => {
      calendarMap[j.journal_date] = {
        id: j.id,
        emotion: j.emotion,
        has_entry: true,
      };
    });

    sendSuccess(res, {
      year,
      month,
      entries: calendarMap,
      total_this_month: data?.length || 0,
    }, '캘린더 데이터');
  } catch (err: any) {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR', err.message);
  }
};

// ============================================================
// 내부 유틸: 스트릭 업데이트
// ============================================================
async function updateStreak(userId: string, journalDate: string): Promise<void> {
  try {
    const { data: existing } = await supabaseAdmin
      .from('gratitude_streaks')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle();

    const today = journalDate;

    if (!existing) {
      // 최초 생성
      await supabaseAdmin.from('gratitude_streaks').insert({
        user_id: userId,
        current_streak: 1,
        longest_streak: 1,
        last_journal_date: today,
        total_count: 1,
      });
      return;
    }

    const lastDate = existing.last_journal_date;
    if (!lastDate) {
      await supabaseAdmin.from('gratitude_streaks').update({
        current_streak: 1,
        longest_streak: Math.max(1, existing.longest_streak),
        last_journal_date: today,
        total_count: existing.total_count + 1,
        updated_at: new Date().toISOString(),
      }).eq('user_id', userId);
      return;
    }

    const lastDateObj = new Date(lastDate);
    const todayObj = new Date(today);
    const diffDays = Math.round((todayObj.getTime() - lastDateObj.getTime()) / (1000 * 60 * 60 * 24));

    let newStreak = existing.current_streak;
    let newTotal = existing.total_count;

    if (diffDays === 0) {
      // 오늘 이미 작성 (수정)
      return;
    } else if (diffDays === 1) {
      // 연속 작성
      newStreak = existing.current_streak + 1;
      newTotal = existing.total_count + 1;
    } else {
      // 끊김
      newStreak = 1;
      newTotal = existing.total_count + 1;
    }

    const newLongest = Math.max(newStreak, existing.longest_streak);

    await supabaseAdmin.from('gratitude_streaks').update({
      current_streak: newStreak,
      longest_streak: newLongest,
      last_journal_date: today,
      total_count: newTotal,
      updated_at: new Date().toISOString(),
    }).eq('user_id', userId);
  } catch (err) {
    console.error('updateStreak error:', err);
  }
}
