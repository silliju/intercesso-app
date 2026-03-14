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
    const today = getTodayDateString(); // 예: 2026-03-14
    const verseDateFallback = `2000-${today.slice(5)}`;   // 2000-03-14

    const { data: dataCurrent, error: errCurrent } = await supabaseAdmin
      .from('daily_verse')
      .select('verse_date, text, reference')
      .eq('verse_date', today)
      .single();

    if (!errCurrent && dataCurrent) {
      sendSuccess<DailyVerse>(res, dataCurrent as DailyVerse, '오늘의 말씀 조회 성공');
      return;
    }

    const { data: dataFallback, error: errFallback } = await supabaseAdmin
      .from('daily_verse')
      .select('verse_date, text, reference')
      .eq('verse_date', verseDateFallback)
      .single();

    if (!errFallback && dataFallback) {
      sendSuccess<DailyVerse>(res, dataFallback as DailyVerse, '오늘의 말씀 조회 성공');
      return;
    }

    sendError(res, '오늘의 말씀 조회 실패', 404, 'DAILY_VERSE_NOT_FOUND', errCurrent?.message ?? errFallback?.message);
  } catch {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

