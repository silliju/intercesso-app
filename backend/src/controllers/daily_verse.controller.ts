import fs from 'fs';
import path from 'path';
import { Response } from 'express';
import { sendError, sendSuccess } from '../utils/response';
import { AuthRequest } from '../middleware/auth';

type DailyVerse = {
  verse_date: string;
  text: string;
  reference: string;
};

type DailyVersesMap = Record<string, { text: string; reference: string }>;

const YYYY_MM_DD = /^\d{4}-\d{2}-\d{2}$/;

/** 쿼리 date가 유효하면 사용, 없으면 서버(한국 시간) 오늘 */
function getVerseDate(queryDate?: string): string {
  if (queryDate && YYYY_MM_DD.test(queryDate)) return queryDate;
  return new Date().toLocaleDateString('en-CA', { timeZone: 'Asia/Seoul' });
}

/** YYYY-MM-DD → MM-DD */
function toMmDd(dateStr: string): string {
  const [, m, d] = dateStr.split('-');
  return `${m}-${d}`;
}

let cachedVerses: DailyVersesMap | null = null;

function loadDailyVerses(): DailyVersesMap {
  if (cachedVerses) return cachedVerses;
  const jsonPath = path.join(__dirname, '..', '..', 'data', 'daily_verses.json');
  const raw = fs.readFileSync(jsonPath, 'utf-8');
  cachedVerses = JSON.parse(raw) as DailyVersesMap;
  return cachedVerses;
}

export const getTodayDailyVerse = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const date = getVerseDate(req.query.date as string | undefined);
    const mmdd = toMmDd(date);
    const verses = loadDailyVerses();
    const entry = verses[mmdd];

    if (!entry) {
      sendError(res, '오늘의 말씀 조회 실패', 404, 'DAILY_VERSE_NOT_FOUND');
      return;
    }

    const data: DailyVerse = {
      verse_date: date,
      text: entry.text,
      reference: entry.reference,
    };
    sendSuccess<DailyVerse>(res, data, '오늘의 말씀 조회 성공');
  } catch (err) {
    sendError(res, '서버 오류', 500, 'SERVER_ERROR', err instanceof Error ? err.message : undefined);
  }
};

