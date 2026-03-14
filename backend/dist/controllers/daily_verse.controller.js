"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getTodayDailyVerse = void 0;
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const response_1 = require("../utils/response");
const YYYY_MM_DD = /^\d{4}-\d{2}-\d{2}$/;
/** 쿼리 date가 유효하면 사용, 없으면 서버(한국 시간) 오늘 */
function getVerseDate(queryDate) {
    if (queryDate && YYYY_MM_DD.test(queryDate))
        return queryDate;
    return new Date().toLocaleDateString('en-CA', { timeZone: 'Asia/Seoul' });
}
/** YYYY-MM-DD → MM-DD */
function toMmDd(dateStr) {
    const [, m, d] = dateStr.split('-');
    return `${m}-${d}`;
}
let cachedVerses = null;
function loadDailyVerses() {
    if (cachedVerses)
        return cachedVerses;
    const jsonPath = path_1.default.join(__dirname, '..', '..', 'data', 'daily_verses.json');
    const raw = fs_1.default.readFileSync(jsonPath, 'utf-8');
    cachedVerses = JSON.parse(raw);
    return cachedVerses;
}
const getTodayDailyVerse = async (req, res) => {
    try {
        const date = getVerseDate(req.query.date);
        const mmdd = toMmDd(date);
        const verses = loadDailyVerses();
        const entry = verses[mmdd];
        if (!entry) {
            (0, response_1.sendError)(res, '오늘의 말씀 조회 실패', 404, 'DAILY_VERSE_NOT_FOUND');
            return;
        }
        const data = {
            verse_date: date,
            text: entry.text,
            reference: entry.reference,
        };
        (0, response_1.sendSuccess)(res, data, '오늘의 말씀 조회 성공');
    }
    catch (err) {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR', err instanceof Error ? err.message : undefined);
    }
};
exports.getTodayDailyVerse = getTodayDailyVerse;
//# sourceMappingURL=daily_verse.controller.js.map