import { Response } from 'express';
import supabaseAdmin from '../config/supabase';
import { sendError, sendSuccess } from '../utils/response';
import { AuthRequest } from '../middleware/auth';

type DailyVerse = {
  verse_date: string;
  text: string;
  reference: string;
};

function toBaseDateString(now = new Date()): string {
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  // 기준 윤년(2000)로 고정 저장/조회
  return `2000-${m}-${d}`;
}

export const getTodayDailyVerse = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const verseDate = toBaseDateString();

    const { data, error } = await supabaseAdmin
      .from('daily_verse')
      .select('verse_date, text, reference')
      .eq('verse_date', verseDate)
      .single();

    if (error || !data) {
      sendError(res, '오늘의 말씀 조회 실패', 404, 'DAILY_VERSE_NOT_FOUND', error?.message);
      return;
    }

    sendSuccess<DailyVerse>(res, data as DailyVerse, '오늘의 말씀 조회 성공');
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

