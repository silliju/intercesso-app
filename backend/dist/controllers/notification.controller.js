"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getUnreadCount = exports.updateNotificationPreferences = exports.getNotificationPreferences = exports.deleteNotification = exports.markAllAsRead = exports.markAsRead = exports.getNotifications = void 0;
const supabase_1 = __importDefault(require("../config/supabase"));
const response_1 = require("../utils/response");
const getNotifications = async (req, res) => {
    try {
        const userId = req.user.userId;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const offset = (page - 1) * limit;
        const { data: notifications, count } = await supabase_1.default
            .from('notifications')
            .select('*', { count: 'exact' })
            .eq('user_id', userId)
            .order('created_at', { ascending: false })
            .range(offset, offset + limit - 1);
        (0, response_1.sendPaginated)(res, notifications || [], { page, limit, total: count || 0 });
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getNotifications = getNotifications;
const markAsRead = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { notificationId } = req.params;
        await supabase_1.default
            .from('notifications')
            .update({ is_read: true })
            .eq('id', notificationId)
            .eq('user_id', userId);
        (0, response_1.sendSuccess)(res, null, '알림을 읽었습니다');
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.markAsRead = markAsRead;
const markAllAsRead = async (req, res) => {
    try {
        const userId = req.user.userId;
        await supabase_1.default
            .from('notifications')
            .update({ is_read: true })
            .eq('user_id', userId)
            .eq('is_read', false);
        (0, response_1.sendSuccess)(res, null, '모든 알림을 읽었습니다');
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.markAllAsRead = markAllAsRead;
const deleteNotification = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { notificationId } = req.params;
        await supabase_1.default
            .from('notifications')
            .delete()
            .eq('id', notificationId)
            .eq('user_id', userId);
        (0, response_1.sendSuccess)(res, null, '알림이 삭제되었습니다');
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.deleteNotification = deleteNotification;
const getNotificationPreferences = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { data: prefs } = await supabase_1.default
            .from('notification_preferences')
            .select('*')
            .eq('user_id', userId)
            .single();
        (0, response_1.sendSuccess)(res, prefs);
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getNotificationPreferences = getNotificationPreferences;
const updateNotificationPreferences = async (req, res) => {
    try {
        const userId = req.user.userId;
        const updates = req.body;
        const { data: prefs, error } = await supabase_1.default
            .from('notification_preferences')
            .update({ ...updates, updated_at: new Date().toISOString() })
            .eq('user_id', userId)
            .select()
            .single();
        if (error) {
            (0, response_1.sendError)(res, '알림 설정 수정 실패', 500, 'UPDATE_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, prefs, '알림 설정이 변경되었습니다');
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.updateNotificationPreferences = updateNotificationPreferences;
const getUnreadCount = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { count } = await supabase_1.default
            .from('notifications')
            .select('*', { count: 'exact', head: true })
            .eq('user_id', userId)
            .eq('is_read', false);
        (0, response_1.sendSuccess)(res, { unread_count: count || 0 });
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getUnreadCount = getUnreadCount;
//# sourceMappingURL=notification.controller.js.map