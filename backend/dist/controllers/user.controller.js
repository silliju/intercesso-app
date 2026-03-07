"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteFcmToken = exports.updateFcmToken = exports.deleteMe = exports.searchUsers = exports.addConnection = exports.getConnections = exports.getUserStats = exports.getUserById = exports.updateMe = exports.getMe = void 0;
const uuid_1 = require("uuid");
const supabase_1 = __importDefault(require("../config/supabase"));
const response_1 = require("../utils/response");
const getMe = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { data: user, error } = await supabase_1.default
            .from('users')
            .select('*')
            .eq('id', userId)
            .single();
        if (error || !user) {
            (0, response_1.sendError)(res, '사용자를 찾을 수 없습니다', 404, 'NOT_FOUND');
            return;
        }
        (0, response_1.sendSuccess)(res, user);
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getMe = getMe;
const updateMe = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { nickname, church_name, denomination, bio, profile_image_url } = req.body;
        const { data: user, error } = await supabase_1.default
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
            (0, response_1.sendError)(res, '프로필 수정 실패', 500, 'UPDATE_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, user, '프로필이 수정되었습니다');
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.updateMe = updateMe;
const getUserById = async (req, res) => {
    try {
        const { userId } = req.params;
        const { data: user, error } = await supabase_1.default
            .from('users')
            .select('id, nickname, profile_image_url, church_name, denomination, bio, created_at')
            .eq('id', userId)
            .single();
        if (error || !user) {
            (0, response_1.sendError)(res, '사용자를 찾을 수 없습니다', 404, 'NOT_FOUND');
            return;
        }
        (0, response_1.sendSuccess)(res, user);
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getUserById = getUserById;
const getUserStats = async (req, res) => {
    try {
        const { userId } = req.params;
        const { data: stats, error } = await supabase_1.default
            .from('user_statistics')
            .select('*')
            .eq('user_id', userId)
            .single();
        if (error || !stats) {
            (0, response_1.sendError)(res, '통계를 찾을 수 없습니다', 404, 'NOT_FOUND');
            return;
        }
        (0, response_1.sendSuccess)(res, stats);
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getUserStats = getUserStats;
const getConnections = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { data: connections } = await supabase_1.default
            .from('connections')
            .select(`
        id, connection_type, connected_at,
        friend:users!connections_friend_id_fkey(id, nickname, profile_image_url, church_name)
      `)
            .eq('user_id', userId);
        (0, response_1.sendSuccess)(res, connections || []);
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getConnections = getConnections;
const addConnection = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { friend_id } = req.body;
        if (!friend_id) {
            (0, response_1.sendError)(res, '대상 사용자 ID가 필요합니다', 400, 'VALIDATION_ERROR');
            return;
        }
        const { data: existing } = await supabase_1.default
            .from('connections')
            .select('id')
            .eq('user_id', userId)
            .eq('friend_id', friend_id)
            .single();
        if (existing) {
            (0, response_1.sendError)(res, '이미 연결된 사용자입니다', 400, 'ALREADY_CONNECTED');
            return;
        }
        await supabase_1.default.from('connections').insert({
            id: (0, uuid_1.v4)(),
            user_id: userId,
            friend_id,
            connection_type: 'friend',
            connected_at: new Date().toISOString(),
        });
        (0, response_1.sendSuccess)(res, null, '지인으로 추가되었습니다', 201);
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.addConnection = addConnection;
const searchUsers = async (req, res) => {
    try {
        const { q } = req.query;
        if (!q) {
            (0, response_1.sendError)(res, '검색어를 입력해주세요', 400, 'VALIDATION_ERROR');
            return;
        }
        const { data: users } = await supabase_1.default
            .from('users')
            .select('id, nickname, profile_image_url, church_name')
            .ilike('nickname', `%${q}%`)
            .limit(20);
        (0, response_1.sendSuccess)(res, users || []);
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.searchUsers = searchUsers;
// 계정 삭제 - 구글 플레이 정책 필수 요건
const deleteMe = async (req, res) => {
    try {
        const userId = req.user.userId;
        // 1. 내가 만든 그룹에서 나를 creator로 가진 그룹 확인
        const { data: myGroups } = await supabase_1.default
            .from('groups')
            .select('id')
            .eq('creator_id', userId);
        // 2. 내가 만든 그룹 삭제 (group_members 포함)
        if (myGroups && myGroups.length > 0) {
            const groupIds = myGroups.map((g) => g.id);
            await supabase_1.default.from('group_members').delete().in('group_id', groupIds);
            await supabase_1.default.from('prayers').update({ group_id: null }).in('group_id', groupIds);
            await supabase_1.default.from('groups').delete().in('id', groupIds);
        }
        // 3. 내 그룹 멤버십 삭제
        await supabase_1.default.from('group_members').delete().eq('user_id', userId);
        // 4. 내 기도 참여 기록 삭제
        await supabase_1.default.from('prayer_participations').delete().eq('user_id', userId);
        // 5. 내 댓글 삭제
        await supabase_1.default.from('comments').delete().eq('user_id', userId);
        // 6. 내 중보기도 요청 삭제
        await supabase_1.default.from('intercession_requests').delete().eq('requester_id', userId);
        await supabase_1.default.from('intercession_requests').delete().eq('target_user_id', userId);
        // 7. 내 알림 삭제
        await supabase_1.default.from('notifications').delete().eq('user_id', userId);
        // 8. 내 기도 체크인 삭제
        await supabase_1.default.from('prayer_checkins').delete().eq('user_id', userId);
        // 9. 내 기도 삭제
        await supabase_1.default.from('prayers').delete().eq('user_id', userId);
        // 10. 내 통계 삭제
        await supabase_1.default.from('user_statistics').delete().eq('user_id', userId);
        // 11. 사용자 계정 삭제
        const { error } = await supabase_1.default.from('users').delete().eq('id', userId);
        if (error) {
            (0, response_1.sendError)(res, '계정 삭제에 실패했습니다', 500, 'DELETE_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, null, '계정이 삭제되었습니다');
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.deleteMe = deleteMe;
// FCM 토큰 저장/갱신 (로그인 후 앱에서 호출)
const updateFcmToken = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { token } = req.body;
        if (!token || typeof token !== 'string') {
            (0, response_1.sendError)(res, 'FCM 토큰이 필요합니다', 400, 'INVALID_TOKEN');
            return;
        }
        await supabase_1.default
            .from('users')
            .update({ fcm_token: token })
            .eq('id', userId);
        (0, response_1.sendSuccess)(res, null, 'FCM 토큰이 저장되었습니다');
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.updateFcmToken = updateFcmToken;
// FCM 토큰 삭제 (로그아웃 시 호출 → 불필요한 푸시 방지)
const deleteFcmToken = async (req, res) => {
    try {
        const userId = req.user.userId;
        await supabase_1.default
            .from('users')
            .update({ fcm_token: null })
            .eq('id', userId);
        (0, response_1.sendSuccess)(res, null, 'FCM 토큰이 삭제되었습니다');
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.deleteFcmToken = deleteFcmToken;
//# sourceMappingURL=user.controller.js.map