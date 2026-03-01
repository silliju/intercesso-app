"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkInCovenant = exports.getCovenantCheckins = exports.deleteComment = exports.createComment = exports.cancelParticipation = exports.participatePrayer = exports.deletePrayer = exports.updatePrayer = exports.createPrayer = exports.getPrayerById = exports.getPrayers = void 0;
const uuid_1 = require("uuid");
const supabase_1 = __importDefault(require("../config/supabase"));
const response_1 = require("../utils/response");
const getPrayers = async (req, res) => {
    try {
        const userId = req.user?.userId;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const scope = req.query.scope;
        const category = req.query.category;
        const status = req.query.status;
        const groupId = req.query.group_id;
        const offset = (page - 1) * limit;
        let query = supabase_1.default
            .from('prayers')
            .select(`
        *,
        user:users(id, nickname, profile_image_url, church_name),
        prayer_participations(count),
        comments(count)
      `, { count: 'exact' })
            .order('created_at', { ascending: false })
            .range(offset, offset + limit - 1);
        // 공개 범위 필터
        if (userId) {
            // 내 기도 + 공개 기도
            if (!scope || scope === 'all') {
                query = query.or(`user_id.eq.${userId},scope.eq.public`);
            }
            else if (scope === 'mine') {
                query = query.eq('user_id', userId);
            }
            else {
                query = query.eq('scope', scope);
            }
        }
        else {
            query = query.eq('scope', 'public');
        }
        if (category)
            query = query.eq('category', category);
        if (status)
            query = query.eq('status', status);
        if (groupId)
            query = query.eq('group_id', groupId);
        const { data: prayers, error, count } = await query;
        if (error) {
            (0, response_1.sendError)(res, '기도 목록 조회 실패', 500, 'FETCH_ERROR');
            return;
        }
        // prayer_participations[0].count → prayer_count, comments[0].count → comment_count 로 매핑
        const mapped = (prayers || []).map((p) => {
            const participationCount = Array.isArray(p.prayer_participations)
                ? (p.prayer_participations[0]?.count ?? p.prayer_count ?? 0)
                : (p.prayer_count ?? 0);
            const commentCount = Array.isArray(p.comments)
                ? (p.comments[0]?.count ?? 0)
                : 0;
            const { prayer_participations, comments, ...rest } = p;
            return {
                ...rest,
                prayer_count: participationCount,
                comment_count: commentCount,
            };
        });
        // 내 기도인 경우 is_participated 추가
        let result = mapped;
        if (userId) {
            const prayerIds = mapped.map((p) => p.id);
            if (prayerIds.length > 0) {
                const { data: participations } = await supabase_1.default
                    .from('prayer_participations')
                    .select('prayer_id')
                    .eq('user_id', userId)
                    .in('prayer_id', prayerIds);
                const participatedSet = new Set((participations || []).map((p) => p.prayer_id));
                result = mapped.map((p) => ({
                    ...p,
                    is_participated: participatedSet.has(p.id),
                }));
            }
        }
        (0, response_1.sendPaginated)(res, result, { page, limit, total: count || 0 });
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getPrayers = getPrayers;
const getPrayerById = async (req, res) => {
    try {
        const { prayerId } = req.params;
        const userId = req.user?.userId;
        const { data: prayer, error } = await supabase_1.default
            .from('prayers')
            .select(`
        *,
        user:users(id, nickname, profile_image_url, church_name),
        comments(
          id, content, created_at,
          user:users(id, nickname, profile_image_url)
        )
      `)
            .eq('id', prayerId)
            .single();
        if (error || !prayer) {
            (0, response_1.sendError)(res, '기도를 찾을 수 없습니다', 404, 'NOT_FOUND');
            return;
        }
        // 조회수 증가
        await supabase_1.default
            .from('prayers')
            .update({ views_count: (prayer.views_count || 0) + 1 })
            .eq('id', prayerId);
        // 내가 참여했는지 확인
        let is_participated = false;
        if (userId) {
            const { data: participation } = await supabase_1.default
                .from('prayer_participations')
                .select('id')
                .eq('prayer_id', prayerId)
                .eq('user_id', userId)
                .single();
            is_participated = !!participation;
        }
        (0, response_1.sendSuccess)(res, { ...prayer, is_participated });
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getPrayerById = getPrayerById;
const createPrayer = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { title, content, category, scope, group_id, is_covenant, covenant_days, covenant_start_date } = req.body;
        if (!title || !content) {
            (0, response_1.sendError)(res, '제목과 내용은 필수입니다', 400, 'VALIDATION_ERROR');
            return;
        }
        const { data: prayer, error } = await supabase_1.default
            .from('prayers')
            .insert({
            id: (0, uuid_1.v4)(),
            user_id: userId,
            title,
            content,
            category: category || '기타',
            scope: scope || 'public',
            status: 'praying',
            group_id: group_id || null,
            is_covenant: is_covenant || false,
            covenant_days: covenant_days || null,
            covenant_start_date: covenant_start_date || null,
            views_count: 0,
            prayer_count: 0,
        })
            .select()
            .single();
        if (error) {
            (0, response_1.sendError)(res, '기도 작성 실패', 500, 'CREATE_ERROR');
            return;
        }
        // 통계 업데이트 (비동기, 실패해도 무시)
        try {
            const { data: userStat } = await supabase_1.default
                .from('user_statistics')
                .select('total_prayers')
                .eq('user_id', userId)
                .single();
            if (userStat) {
                await supabase_1.default
                    .from('user_statistics')
                    .update({ total_prayers: (userStat.total_prayers || 0) + 1, updated_at: new Date().toISOString() })
                    .eq('user_id', userId);
            }
        }
        catch {
            // 통계 업데이트 실패해도 무시
        }
        (0, response_1.sendSuccess)(res, prayer, '기도가 작성되었습니다', 201);
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.createPrayer = createPrayer;
const updatePrayer = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { prayerId } = req.params;
        const updates = req.body;
        // 소유자 확인
        const { data: existing } = await supabase_1.default
            .from('prayers')
            .select('user_id')
            .eq('id', prayerId)
            .single();
        if (!existing || existing.user_id !== userId) {
            (0, response_1.sendError)(res, '수정 권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const updateData = { ...updates, updated_at: new Date().toISOString() };
        if (updates.status === 'answered') {
            updateData.answered_at = new Date().toISOString();
        }
        const { data: prayer, error } = await supabase_1.default
            .from('prayers')
            .update(updateData)
            .eq('id', prayerId)
            .select()
            .single();
        if (error) {
            (0, response_1.sendError)(res, '기도 수정 실패', 500, 'UPDATE_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, prayer, '기도가 수정되었습니다');
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.updatePrayer = updatePrayer;
const deletePrayer = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { prayerId } = req.params;
        const { data: existing } = await supabase_1.default
            .from('prayers')
            .select('user_id')
            .eq('id', prayerId)
            .single();
        if (!existing || existing.user_id !== userId) {
            (0, response_1.sendError)(res, '삭제 권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        await supabase_1.default.from('prayers').delete().eq('id', prayerId);
        (0, response_1.sendSuccess)(res, null, '기도가 삭제되었습니다');
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.deletePrayer = deletePrayer;
const participatePrayer = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { prayerId } = req.params;
        // 중복 참여 확인
        const { data: existing } = await supabase_1.default
            .from('prayer_participations')
            .select('id')
            .eq('prayer_id', prayerId)
            .eq('user_id', userId)
            .single();
        if (existing) {
            (0, response_1.sendError)(res, '이미 기도에 참여하셨습니다', 400, 'ALREADY_PARTICIPATED');
            return;
        }
        // 참여 기록
        await supabase_1.default.from('prayer_participations').insert({
            id: (0, uuid_1.v4)(),
            prayer_id: prayerId,
            user_id: userId,
            participated_at: new Date().toISOString(),
        });
        // 기도 카운트 증가
        const { data: prayer } = await supabase_1.default
            .from('prayers')
            .select('prayer_count, user_id')
            .eq('id', prayerId)
            .single();
        if (prayer) {
            await supabase_1.default
                .from('prayers')
                .update({ prayer_count: (prayer.prayer_count || 0) + 1 })
                .eq('id', prayerId);
            // 기도 작성자에게 알림
            if (prayer.user_id !== userId) {
                const { data: participantUser } = await supabase_1.default
                    .from('users')
                    .select('nickname')
                    .eq('id', userId)
                    .single();
                await supabase_1.default.from('notifications').insert({
                    id: (0, uuid_1.v4)(),
                    user_id: prayer.user_id,
                    type: 'prayer_participation',
                    related_id: prayerId,
                    title: '기도 참여 알림',
                    message: `${participantUser?.nickname || '누군가'}님이 회원님의 기도에 함께 기도했습니다 🙏`,
                    is_read: false,
                });
            }
        }
        (0, response_1.sendSuccess)(res, null, '기도에 참여했습니다 🙏');
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.participatePrayer = participatePrayer;
const cancelParticipation = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { prayerId } = req.params;
        await supabase_1.default
            .from('prayer_participations')
            .delete()
            .eq('prayer_id', prayerId)
            .eq('user_id', userId);
        // 기도 카운트 감소
        const { data: prayer } = await supabase_1.default
            .from('prayers')
            .select('prayer_count')
            .eq('id', prayerId)
            .single();
        if (prayer && prayer.prayer_count > 0) {
            await supabase_1.default
                .from('prayers')
                .update({ prayer_count: prayer.prayer_count - 1 })
                .eq('id', prayerId);
        }
        (0, response_1.sendSuccess)(res, null, '기도 참여가 취소되었습니다');
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.cancelParticipation = cancelParticipation;
const createComment = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { prayerId } = req.params;
        const { content } = req.body;
        if (!content) {
            (0, response_1.sendError)(res, '댓글 내용을 입력해주세요', 400, 'VALIDATION_ERROR');
            return;
        }
        const { data: comment, error } = await supabase_1.default
            .from('comments')
            .insert({
            id: (0, uuid_1.v4)(),
            prayer_id: prayerId,
            user_id: userId,
            content,
        })
            .select(`*, user:users(id, nickname, profile_image_url)`)
            .single();
        if (error) {
            (0, response_1.sendError)(res, '댓글 작성 실패', 500, 'CREATE_ERROR');
            return;
        }
        // 기도 작성자에게 알림
        const { data: prayer } = await supabase_1.default
            .from('prayers')
            .select('user_id')
            .eq('id', prayerId)
            .single();
        if (prayer && prayer.user_id !== userId) {
            const { data: commenterUser } = await supabase_1.default
                .from('users')
                .select('nickname')
                .eq('id', userId)
                .single();
            await supabase_1.default.from('notifications').insert({
                id: (0, uuid_1.v4)(),
                user_id: prayer.user_id,
                type: 'comment',
                related_id: prayerId,
                title: '댓글 알림',
                message: `${commenterUser?.nickname || '누군가'}님이 댓글을 남겼습니다`,
                is_read: false,
            });
        }
        (0, response_1.sendSuccess)(res, comment, '댓글이 작성되었습니다', 201);
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.createComment = createComment;
const deleteComment = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { commentId } = req.params;
        const { data: existing } = await supabase_1.default
            .from('comments')
            .select('user_id')
            .eq('id', commentId)
            .single();
        if (!existing || existing.user_id !== userId) {
            (0, response_1.sendError)(res, '삭제 권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        await supabase_1.default.from('comments').delete().eq('id', commentId);
        (0, response_1.sendSuccess)(res, null, '댓글이 삭제되었습니다');
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.deleteComment = deleteComment;
const getCovenantCheckins = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { prayerId } = req.params;
        const { data: checkins } = await supabase_1.default
            .from('covenant_checkins')
            .select('*')
            .eq('prayer_id', prayerId)
            .eq('user_id', userId)
            .order('day', { ascending: true });
        (0, response_1.sendSuccess)(res, checkins || []);
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getCovenantCheckins = getCovenantCheckins;
const checkInCovenant = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { prayerId } = req.params;
        const { day } = req.body;
        if (!day) {
            (0, response_1.sendError)(res, '날짜(day)가 필요합니다', 400, 'VALIDATION_ERROR');
            return;
        }
        const { data, error } = await supabase_1.default
            .from('covenant_checkins')
            .insert({
            id: (0, uuid_1.v4)(),
            prayer_id: prayerId,
            user_id: userId,
            day,
            checked_in_at: new Date().toISOString(),
        })
            .select()
            .single();
        if (error) {
            (0, response_1.sendError)(res, '이미 체크인했거나 오류가 발생했습니다', 400, 'CHECKIN_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, data, '체크인 완료!', 201);
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.checkInCovenant = checkInCovenant;
//# sourceMappingURL=prayer.controller.js.map