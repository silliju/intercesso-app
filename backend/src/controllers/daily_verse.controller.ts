import { Response } from 'express';
import supabaseAdmin from '../config/supabase';
import { sendError, sendSuccess } from '../utils/response';
import { AuthRequest } from '../middleware/auth';

type DailyVerse = {
  verse_date: string;
  text: string;
  reference: string;
};

const YYYY_MM_DD = /^\d{4}-\d{2}-\d{2}$/;

/** 쿼리 date가 유효하면 사용, 없으면 서버(한국 시간) 오늘 */
function getVerseDate(queryDate?: string): string {
  if (queryDate && YYYY_MM_DD.test(queryDate)) return queryDate;
  return new Date().toLocaleDateString('en-CA', { timeZone: 'Asia/Seoul' });
}

export const getTodayDailyVerse = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const date = getVerseDate(req.query.date as string | undefined);

    const { data, error } = await supabaseAdmin
      .from('daily_verse')
      .select('verse_date, text, reference')
      .eq('verse_date', date)
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

