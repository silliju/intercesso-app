import { Request, Response } from 'express';
import supabaseAdmin from '../config/supabase';
import { sendSuccess, sendError } from '../utils/response';

interface AuthRequest extends Request {
  user?: { userId: string; email: string };
}

// ──────────────────────────────────────────────────────
// 기도 응답 등록 / 수정 (upsert)
// POST /api/prayers/:prayerId/answer
// body: { content?, scope? }
// ──────────────────────────────────────────────────────
export const upsertPrayerAnswer = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { prayerId } = req.params;
    const { content, scope = 'public' } = req.body;

    // 유효한 scope 값 검증
    if (!['public', 'group', 'private'].includes(scope)) {
      sendError(res, '공개 범위는 public, group, private 중 하나여야 합니다', 400, 'VALIDATION_ERROR');
      return;
    }

    // 기도 소유자 확인
    const { data: prayer } = await supabaseAdmin
      .from('prayers')
      .select('user_id, status')
      .eq('id', prayerId)
      .single();

    if (!prayer) {
      sendError(res, '기도를 찾을 수 없습니다', 404, 'NOT_FOUND');
      return;
    }

    if (prayer.user_id !== userId) {
      sendError(res, '본인의 기도에만 응답을 등록할 수 있습니다', 403, 'FORBIDDEN');
      return;
    }

    // 기도 상태를 answered로 변경
    await supabaseAdmin
      .from('prayers')
      .update({ status: 'answered', answered_at: new Date().toISOString(), updated_at: new Date().toISOString() })
      .eq('id', prayerId);

    // prayer_answers 테이블 존재 체크 (PGRST205)
    const { data: existing, error: checkError } = await supabaseAdmin
      .from('prayer_answers')
      .select('id')
      .eq('prayer_id', prayerId)
      .single();

    if (checkError && (checkError.code === 'PGRST205' || checkError.message?.includes('schema cache'))) {
      sendError(res, '기도 응답 기능을 사용하려면 Supabase SQL Editor에서 prayer_answers 테이블을 먼저 생성해주세요.', 503, 'TABLE_MISSING');
      return;
    }

    let answer;
    if (existing) {
      // 수정
      const { data, error } = await supabaseAdmin
        .from('prayer_answers')
        .update({ content: content ?? null, scope, updated_at: new Date().toISOString() })
        .eq('id', existing.id)
        .select('*, user:users(id, nickname, profile_image_url)')
        .single();
      if (error) { sendError(res, '응답 수정 실패', 500, 'UPDATE_ERROR'); return; }
      answer = data;
    } else {
      // 신규 등록
      const { data, error } = await supabaseAdmin
        .from('prayer_answers')
        .insert({ prayer_id: prayerId, user_id: userId, content: content ?? null, scope })
        .select('*, user:users(id, nickname, profile_image_url)')
        .single();
      if (error) { sendError(res, '응답 등록 실패', 500, 'INSERT_ERROR'); return; }
      answer = data;

      // 통계 업데이트 (실패해도 무시)
      try {
        await supabaseAdmin.rpc('increment_user_stat', {
          p_user_id: userId,
          p_column: 'answered_prayers',
        });
      } catch (_) { /* 무시 */ }
    }

    sendSuccess(res, answer, '기도 응답이 등록되었습니다', 201);
  } catch (err) {
    console.error('upsertPrayerAnswer error:', err);
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

// ──────────────────────────────────────────────────────
// 기도 응답 조회
// GET /api/prayers/:prayerId/answer
// ──────────────────────────────────────────────────────
export const getPrayerAnswer = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { prayerId } = req.params;
    const userId = req.user?.userId;

    const { data: answer, error } = await supabaseAdmin
      .from('prayer_answers')
      .select(`
        *,
        user:users(id, nickname, profile_image_url),
        comments:prayer_answer_comments(
          id, content, created_at,
          user:users(id, nickname, profile_image_url)
        )
      `)
      .eq('prayer_id', prayerId)
      .single();

    // 테이블 미생성 에러 (PGRST205)
    if (error && (error.code === 'PGRST205' || error.message?.includes('schema cache'))) {
      sendError(res, '기도 응답 기능 테이블이 아직 생성되지 않았습니다', 503, 'TABLE_MISSING');
      return;
    }

    if (error || !answer) {
      sendSuccess(res, null, '등록된 응답이 없습니다');
      return;
    }

    // 비공개 응답은 작성자 본인만 조회 가능
    if (answer.scope === 'private' && answer.user_id !== userId) {
      sendSuccess(res, null, '비공개 응답입니다');
      return;
    }

    // 댓글 최신순 정렬
    if (answer.comments) {
      answer.comments.sort((a: any, b: any) =>
        new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
      );
    }

    sendSuccess(res, answer, '조회 성공');
  } catch (err) {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

// ──────────────────────────────────────────────────────
// 기도 응답 삭제
// DELETE /api/prayers/:prayerId/answer
// ──────────────────────────────────────────────────────
export const deletePrayerAnswer = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { prayerId } = req.params;

    const { data: answer } = await supabaseAdmin
      .from('prayer_answers')
      .select('id, user_id')
      .eq('prayer_id', prayerId)
      .single();

    if (!answer) { sendError(res, '응답을 찾을 수 없습니다', 404, 'NOT_FOUND'); return; }
    if (answer.user_id !== userId) { sendError(res, '삭제 권한이 없습니다', 403, 'FORBIDDEN'); return; }

    await supabaseAdmin.from('prayer_answers').delete().eq('id', answer.id);
    sendSuccess(res, null, '응답이 삭제되었습니다');
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

// ──────────────────────────────────────────────────────
// 응답 댓글 등록
// POST /api/prayers/:prayerId/answer/comments
// body: { content }
// ──────────────────────────────────────────────────────
export const createAnswerComment = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { prayerId } = req.params;
    const { content } = req.body;

    if (!content?.trim()) {
      sendError(res, '댓글 내용을 입력해주세요', 400, 'VALIDATION_ERROR');
      return;
    }

    // answer 존재 확인 + scope 체크
    const { data: answer } = await supabaseAdmin
      .from('prayer_answers')
      .select('id, scope')
      .eq('prayer_id', prayerId)
      .single();

    if (!answer) { sendError(res, '응답을 찾을 수 없습니다', 404, 'NOT_FOUND'); return; }
    if (answer.scope === 'private') { sendError(res, '비공개 응답에는 댓글을 달 수 없습니다', 403, 'FORBIDDEN'); return; }

    const { data: comment, error } = await supabaseAdmin
      .from('prayer_answer_comments')
      .insert({ answer_id: answer.id, user_id: userId, content: content.trim() })
      .select('*, user:users(id, nickname, profile_image_url)')
      .single();

    if (error) { sendError(res, '댓글 등록 실패', 500, 'INSERT_ERROR'); return; }

    sendSuccess(res, comment, '댓글이 등록되었습니다', 201);
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

// ──────────────────────────────────────────────────────
// 응답 댓글 삭제
// DELETE /api/prayers/:prayerId/answer/comments/:commentId
// ──────────────────────────────────────────────────────
export const deleteAnswerComment = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { commentId } = req.params;

    const { data: comment } = await supabaseAdmin
      .from('prayer_answer_comments')
      .select('id, user_id')
      .eq('id', commentId)
      .single();

    if (!comment) { sendError(res, '댓글을 찾을 수 없습니다', 404, 'NOT_FOUND'); return; }
    if (comment.user_id !== userId) { sendError(res, '삭제 권한이 없습니다', 403, 'FORBIDDEN'); return; }

    await supabaseAdmin.from('prayer_answer_comments').delete().eq('id', commentId);
    sendSuccess(res, null, '댓글이 삭제되었습니다');
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

// ──────────────────────────────────────────────────────
// 공개 응답 피드 (홈용)
// GET /api/answers/feed?limit=10&page=1
// ──────────────────────────────────────────────────────
export const getAnswerFeed = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const limit = Math.min(parseInt(req.query.limit as string) || 10, 30);
    const page = parseInt(req.query.page as string) || 1;
    const offset = (page - 1) * limit;

    const { data, error, count } = await supabaseAdmin
      .from('prayer_answers')
      .select(`
        *,
        user:users(id, nickname, profile_image_url),
        prayer:prayers(id, title, category),
        comments:prayer_answer_comments(count)
      `, { count: 'exact' })
      .eq('scope', 'public')
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) { sendError(res, '피드 조회 실패', 500, 'FETCH_ERROR'); return; }

    sendSuccess(res, {
      answers: data || [],
      pagination: { page, limit, total: count || 0, totalPages: Math.ceil((count || 0) / limit) },
    }, '조회 성공');
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};
