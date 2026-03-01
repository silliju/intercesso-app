"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.searchUsers = exports.addConnection = exports.getConnections = exports.getUserStats = exports.getUserById = exports.updateMe = exports.getMe = void 0;
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
//# sourceMappingURL=user.controller.js.map