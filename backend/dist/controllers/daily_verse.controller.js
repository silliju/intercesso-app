"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getTodayDailyVerse = void 0;
const supabase_1 = __importDefault(require("../config/supabase"));
const response_1 = require("../utils/response");
function toBaseDateString(now = new Date()) {
    const m = String(now.getMonth() + 1).padStart(2, '0');
    const d = String(now.getDate()).padStart(2, '0');
    // 기준 윤년(2000)로 고정 저장/조회
    return `2000-${m}-${d}`;
}
const getTodayDailyVerse = async (req, res) => {
    try {
        const verseDate = toBaseDateString();
        const { data, error } = await supabase_1.default
            .from('daily_verse')
            .select('verse_date, text, reference')
            .eq('verse_date', verseDate)
            .single();
        if (error || !data) {
            (0, response_1.sendError)(res, '오늘의 말씀 조회 실패', 404, 'DAILY_VERSE_NOT_FOUND', error?.message);
            return;
        }
        (0, response_1.sendSuccess)(res, data, '오늘의 말씀 조회 성공');
    }
    catch {
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getTodayDailyVerse = getTodayDailyVerse;
//# sourceMappingURL=daily_verse.controller.js.map