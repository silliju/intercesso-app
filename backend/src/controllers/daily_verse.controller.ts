import { Response } from 'express';
import supabaseAdmin from '../config/supabase';
import { sendError, sendSuccess } from '../utils/response';
import { AuthRequest } from '../middleware/auth';

type DailyVerse = {
  verse_date: string;
  text: string;
  reference: string;
};

/** 한국(Asia/Seoul) 기준 오늘 날짜 YYYY-MM-DD */
function getTodayDateString(): string {
  return new Date().toLocaleDateString('en-CA', { timeZone: 'Asia/Seoul' });
}

export const getTodayDailyVerse = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const today = getTodayDateString(); // 한국 시간 기준 오늘, 예: 2026-03-14

    const { data, error } = await supabaseAdmin
      .from('daily_verse')
      .select('verse_date, text, reference')
      .eq('verse_date', today)
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

