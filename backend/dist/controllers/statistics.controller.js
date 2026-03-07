"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getUserStatistics = exports.getMyStatistics = exports.getCommunityStats = exports.getPrayerCharts = exports.getDashboard = void 0;
const supabase_1 = __importDefault(require("../config/supabase"));
const response_1 = require("../utils/response");
const getDashboard = async (req, res) => {
    try {
        const userId = req.user.userId;
        // ── 항상 prayers 테이블에서 실시간 계산 (user_statistics 캐시 무시) ──
        // 내 기도 총 수
        const { count: myPrayerCount } = await supabase_1.default
            .from('prayers')
            .select('id', { count: 'exact', head: true })
            .eq('user_id', userId);
        const totalPrayers = myPrayerCount ?? 0;
        // 응답받은 기도 수
        const { count: answeredCount } = await supabase_1.default
            .from('prayers')
            .select('id', { count: 'exact', head: true })
            .eq('user_id', userId)
            .eq('status', 'answered');
        const answeredPrayers = answeredCount ?? 0;
        // 감사 기도 수
        const { count: gratefulCount } = await supabase_1.default
            .from('prayers')
            .select('id', { count: 'exact', head: true })
            .eq('user_id', userId)
            .eq('status', 'grateful');
        const gratefulPrayers = gratefulCount ?? 0;
        // 내가 함께 기도한 횟수
        const { count: participCount } = await supabase_1.default
            .from('prayer_participations')
            .select('id', { count: 'exact', head: true })
            .eq('user_id', userId);
        const totalParticipations = participCount ?? 0;
        // 내가 작성한 댓글 수
        const { count: commentCount } = await supabase_1.default
            .from('comments')
            .select('id', { count: 'exact', head: true })
            .eq('user_id', userId);
        const totalComments = commentCount ?? 0;
        // 연속 기도 일수 계산
        const { data: recentPrayerDates } = await supabase_1.default
            .from('prayers')
            .select('created_at')
            .eq('user_id', userId)
            .order('created_at', { ascending: false })
            .limit(30);
        let streakDays = 0;
        if (recentPrayerDates && recentPrayerDates.length > 0) {
            const dates = recentPrayerDates.map((p) => p.created_at.split('T')[0]);
            const uniqueDates = [...new Set(dates)].sort().reverse();
            const today = new Date().toISOString().split('T')[0];
            let checkDate = today;
            for (const d of uniqueDates) {
                if (d === checkDate) {
                    streakDays++;
                    const prev = new Date(checkDate);
                    prev.setDate(prev.getDate() - 1);
                    checkDate = prev.toISOString().split('T')[0];
                }
                else {
                    break;
                }
            }
        }
        // 최근 기도 (5개) - 댓글 수와 참여 수 포함
        const { data: recentPrayersRaw } = await supabase_1.default
            .from('prayers')
            .select('id, title, status, category, created_at, prayer_count, prayer_participations(count), comments(count)')
            .eq('user_id', userId)
            .order('created_at', { ascending: false })
            .limit(5);
        const recentPrayers = (recentPrayersRaw || []).map((p) => {
            const participationCount = Array.isArray(p.prayer_participations)
                ? (p.prayer_participations[0]?.count ?? p.prayer_count ?? 0)
                : (p.prayer_count ?? 0);
            const commentCount = Array.isArray(p.comments) ? (p.comments[0]?.count ?? 0) : 0;
            const { prayer_participations, comments, ...rest } = p;
            return { ...rest, prayer_count: participationCount, comment_count: commentCount };
        });
        // 진행 중인 작정기도
        const { data: covenantPrayersRaw } = await supabase_1.default
            .from('prayers')
            .select(`
        id, title, covenant_days, covenant_start_date, created_at,
        covenant_checkins(count)
      `)
            .eq('user_id', userId)
            .eq('is_covenant', true)
            .eq('status', 'praying')
            .limit(3);
        const covenantPrayers = (covenantPrayersRaw || []).map((p) => {
            const checkinCount = Array.isArray(p.covenant_checkins) ? (p.covenant_checkins[0]?.count ?? 0) : 0;
            const { covenant_checkins, ...rest } = p;
            return { ...rest, checkin_count: checkinCount };
        });
        // 최근 활동한 그룹
        const { data: groupMemberships } = await supabase_1.default
            .from('group_members')
            .select(`group:groups(id, name, group_type, member_count)`)
            .eq('user_id', userId)
            .limit(3);
        const groups = (groupMemberships || []).map((m) => m.group);
        // 내 기도 응답률 계산
        const answerRate = totalPrayers > 0 ? Math.round((answeredPrayers / totalPrayers) * 100) : 0;
        (0, response_1.sendSuccess)(res, {
            stats: {
                total_prayers: totalPrayers,
                answered_prayers: answeredPrayers,
                grateful_prayers: gratefulPrayers,
                total_participations: totalParticipations,
                total_comments: totalComments,
                streak_days: streakDays,
                answer_rate: answerRate,
            },
            recent_prayers: recentPrayers,
            covenant_prayers: covenantPrayers,
            groups,
        });
    }
    catch (err) {
        console.error('getDashboard error:', err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getDashboard = getDashboard;
const getPrayerCharts = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { period = 'week' } = req.query;
        let startDate = new Date();
        if (period === 'week') {
            startDate.setDate(startDate.getDate() - 7);
        }
        else if (period === 'month') {
            startDate.setMonth(startDate.getMonth() - 1);
        }
        else if (period === 'year') {
            startDate.setFullYear(startDate.getFullYear() - 1);
        }
        const { data: prayers } = await supabase_1.default
            .from('prayers')
            .select('id, status, category, created_at')
            .eq('user_id', userId)
            .gte('created_at', startDate.toISOString());
        // 카테고리별 통계
        const categoryStats = {};
        const statusStats = { praying: 0, answered: 0, grateful: 0 };
        (prayers || []).forEach((p) => {
            if (p.category) {
                categoryStats[p.category] = (categoryStats[p.category] || 0) + 1;
            }
            if (p.status in statusStats) {
                statusStats[p.status]++;
            }
        });
        // 날짜별 기도 활동
        const dailyActivity = {};
        (prayers || []).forEach((p) => {
            const date = p.created_at.split('T')[0];
            dailyActivity[date] = (dailyActivity[date] || 0) + 1;
        });
        (0, response_1.sendSuccess)(res, {
            category_stats: categoryStats,
            status_stats: statusStats,
            daily_activity: dailyActivity,
            period,
        });
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getPrayerCharts = getPrayerCharts;
const getCommunityStats = async (req, res) => {
    try {
        const { groupId } = req.params;
        // 그룹 기도 통계
        const { data: groupPrayers, count: totalGroupPrayers } = await supabase_1.default
            .from('prayers')
            .select('id, status, category', { count: 'exact' })
            .eq('group_id', groupId);
        const answered = (groupPrayers || []).filter((p) => p.status === 'answered').length;
        const answerRate = totalGroupPrayers && totalGroupPrayers > 0
            ? Math.round((answered / totalGroupPrayers) * 100)
            : 0;
        // 카테고리별
        const categoryStats = {};
        (groupPrayers || []).forEach((p) => {
            if (p.category) {
                categoryStats[p.category] = (categoryStats[p.category] || 0) + 1;
            }
        });
        // 그룹 정보
        const { data: group } = await supabase_1.default
            .from('groups')
            .select('id, name, member_count')
            .eq('id', groupId)
            .single();
        (0, response_1.sendSuccess)(res, {
            group,
            total_prayers: totalGroupPrayers || 0,
            answered_prayers: answered,
            answer_rate: answerRate,
            category_stats: categoryStats,
        });
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getCommunityStats = getCommunityStats;
// 내 통계 조회 (getDashboard와 동일한 데이터)
const getMyStatistics = async (req, res) => {
    return (0, exports.getDashboard)(req, res);
};
exports.getMyStatistics = getMyStatistics;
// 특정 유저 통계 조회
const getUserStatistics = async (req, res) => {
    try {
        const { userId } = req.params;
        const { count: totalPrayers } = await supabase_1.default
            .from('prayers')
            .select('id', { count: 'exact', head: true })
            .eq('user_id', userId);
        const { count: answeredPrayers } = await supabase_1.default
            .from('prayers')
            .select('id', { count: 'exact', head: true })
            .eq('user_id', userId)
            .eq('status', 'answered');
        const { count: gratefulPrayers } = await supabase_1.default
            .from('prayers')
            .select('id', { count: 'exact', head: true })
            .eq('user_id', userId)
            .eq('status', 'grateful');
        const { count: totalParticipations } = await supabase_1.default
            .from('prayer_participations')
            .select('id', { count: 'exact', head: true })
            .eq('user_id', userId);
        const { count: totalComments } = await supabase_1.default
            .from('comments')
            .select('id', { count: 'exact', head: true })
            .eq('user_id', userId);
        const total = totalPrayers ?? 0;
        const answered = answeredPrayers ?? 0;
        const answerRate = total > 0 ? Math.round((answered / total) * 100) : 0;
        (0, response_1.sendSuccess)(res, {
            stats: {
                total_prayers: total,
                answered_prayers: answered,
                grateful_prayers: gratefulPrayers ?? 0,
                total_participations: totalParticipations ?? 0,
                total_comments: totalComments ?? 0,
                answer_rate: answerRate,
                streak_days: 0,
            },
        });
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getUserStatistics = getUserStatistics;
//# sourceMappingURL=statistics.controller.js.map