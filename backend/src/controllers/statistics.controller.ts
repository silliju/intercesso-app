import { Response } from 'express';
import supabaseAdmin from '../config/supabase';
import { sendSuccess, sendError } from '../utils/response';
import { AuthRequest } from '../middleware/auth';

export const getDashboard = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;

    // user_statistics 테이블에서 통계 조회
    const { data: stats } = await supabaseAdmin
      .from('user_statistics')
      .select('*')
      .eq('user_id', userId)
      .single();

    // user_statistics가 없거나 비어있으면 prayers 테이블에서 직접 계산
    let totalPrayers = stats?.total_prayers ?? 0;
    let answeredPrayers = stats?.answered_prayers ?? 0;
    let totalParticipations = stats?.total_participations ?? 0;
    let streakDays = stats?.streak_days ?? 0;

    if (!stats) {
      // 내 기도 총 수
      const { count: myPrayerCount } = await supabaseAdmin
        .from('prayers')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId);
      totalPrayers = myPrayerCount ?? 0;

      // 응답받은 기도 수
      const { count: answeredCount } = await supabaseAdmin
        .from('prayers')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId)
        .eq('status', 'answered');
      answeredPrayers = answeredCount ?? 0;

      // 내가 함께 기도한 횟수 (prayer_participations)
      const { count: participCount } = await supabaseAdmin
        .from('prayer_participations')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId);
      totalParticipations = participCount ?? 0;

      // 연속 기도 일수 계산 (최근 기도 날짜 기준)
      const { data: recentPrayerDates } = await supabaseAdmin
        .from('prayers')
        .select('created_at')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .limit(30);

      if (recentPrayerDates && recentPrayerDates.length > 0) {
        const dates = recentPrayerDates.map((p: any) => p.created_at.split('T')[0]);
        const uniqueDates = [...new Set(dates)].sort().reverse();
        let streak = 0;
        const today = new Date().toISOString().split('T')[0];
        let checkDate = today;
        for (const d of uniqueDates) {
          if (d === checkDate) {
            streak++;
            const prev = new Date(checkDate);
            prev.setDate(prev.getDate() - 1);
            checkDate = prev.toISOString().split('T')[0];
          } else {
            break;
          }
        }
        streakDays = streak;
      }
    }

    // 최근 기도 (5개)
    const { data: recentPrayers } = await supabaseAdmin
      .from('prayers')
      .select('id, title, status, category, created_at, prayer_count')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(5);

    // 진행 중인 작정기도
    const { data: covenantPrayers } = await supabaseAdmin
      .from('prayers')
      .select(`
        id, title, covenant_days, covenant_start_date, created_at,
        covenant_checkins(count)
      `)
      .eq('user_id', userId)
      .eq('is_covenant', true)
      .eq('status', 'praying')
      .limit(3);

    // 최근 활동한 그룹
    const { data: groupMemberships } = await supabaseAdmin
      .from('group_members')
      .select(`group:groups(id, name, group_type, member_count)`)
      .eq('user_id', userId)
      .limit(3);

    const groups = (groupMemberships || []).map((m: any) => m.group);

    // 내 기도 응답률 계산
    const answerRate = totalPrayers > 0 ? Math.round((answeredPrayers / totalPrayers) * 100) : 0;

    sendSuccess(res, {
      stats: {
        total_prayers: totalPrayers,
        answered_prayers: answeredPrayers,
        total_participations: totalParticipations,
        streak_days: streakDays,
        answer_rate: answerRate,
        ...(stats || {}),
      },
      recent_prayers: recentPrayers || [],
      covenant_prayers: covenantPrayers || [],
      groups,
    });
  } catch (err) {
    console.error('getDashboard error:', err);
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const getPrayerCharts = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;
    const { period = 'week' } = req.query;

    let startDate = new Date();
    if (period === 'week') {
      startDate.setDate(startDate.getDate() - 7);
    } else if (period === 'month') {
      startDate.setMonth(startDate.getMonth() - 1);
    } else if (period === 'year') {
      startDate.setFullYear(startDate.getFullYear() - 1);
    }

    const { data: prayers } = await supabaseAdmin
      .from('prayers')
      .select('id, status, category, created_at')
      .eq('user_id', userId)
      .gte('created_at', startDate.toISOString());

    // 카테고리별 통계
    const categoryStats: Record<string, number> = {};
    const statusStats = { praying: 0, answered: 0, grateful: 0 };

    (prayers || []).forEach((p: any) => {
      if (p.category) {
        categoryStats[p.category] = (categoryStats[p.category] || 0) + 1;
      }
      if (p.status in statusStats) {
        (statusStats as any)[p.status]++;
      }
    });

    // 날짜별 기도 활동
    const dailyActivity: Record<string, number> = {};
    (prayers || []).forEach((p: any) => {
      const date = p.created_at.split('T')[0];
      dailyActivity[date] = (dailyActivity[date] || 0) + 1;
    });

    sendSuccess(res, {
      category_stats: categoryStats,
      status_stats: statusStats,
      daily_activity: dailyActivity,
      period,
    });
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

export const getCommunityStats = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { groupId } = req.params;

    // 그룹 기도 통계
    const { data: groupPrayers, count: totalGroupPrayers } = await supabaseAdmin
      .from('prayers')
      .select('id, status, category', { count: 'exact' })
      .eq('group_id', groupId);

    const answered = (groupPrayers || []).filter((p: any) => p.status === 'answered').length;
    const answerRate = totalGroupPrayers && totalGroupPrayers > 0
      ? Math.round((answered / totalGroupPrayers) * 100)
      : 0;

    // 카테고리별
    const categoryStats: Record<string, number> = {};
    (groupPrayers || []).forEach((p: any) => {
      if (p.category) {
        categoryStats[p.category] = (categoryStats[p.category] || 0) + 1;
      }
    });

    // 그룹 정보
    const { data: group } = await supabaseAdmin
      .from('groups')
      .select('id, name, member_count')
      .eq('id', groupId)
      .single();

    sendSuccess(res, {
      group,
      total_prayers: totalGroupPrayers || 0,
      answered_prayers: answered,
      answer_rate: answerRate,
      category_stats: categoryStats,
    });
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};
