"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteFile = exports.createFile = exports.getFiles = exports.deleteNotice = exports.updateNotice = exports.createNotice = exports.getNotices = exports.deleteSong = exports.updateSong = exports.createSong = exports.getSongs = exports.getAttendanceStats = exports.updateAttendance = exports.getAttendance = exports.deleteSchedule = exports.updateSchedule = exports.getScheduleById = exports.createSchedule = exports.getSchedules = exports.approveMember = exports.removeMember = exports.updateMember = exports.getMembers = exports.joinByInviteCode = exports.getChoirByInviteCode = exports.refreshInviteCode = exports.getInviteCode = exports.deleteChoir = exports.updateChoir = exports.getChoirById = exports.getMyChoirs = exports.createChoir = void 0;
const uuid_1 = require("uuid");
const supabase_1 = __importDefault(require("../config/supabase"));
const response_1 = require("../utils/response");
// ── 유틸 ────────────────────────────────────────────────────
const generateInviteCode = () => {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return Array.from({ length: 8 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
};
const isChoirAdmin = async (choirId, userId) => {
    const { data } = await supabase_1.default
        .from('choir_members')
        .select('role')
        .eq('choir_id', choirId)
        .eq('user_id', userId)
        .single();
    return data?.role === 'conductor' || data?.role === 'section_leader' || data?.role === 'treasurer';
};
const isChoirOwner = async (choirId, userId) => {
    const { data } = await supabase_1.default
        .from('choirs')
        .select('owner_id')
        .eq('id', choirId)
        .single();
    return data?.owner_id === userId;
};
// ══════════════════════════════════════════════════════════════
// 찬양대 CRUD
// ══════════════════════════════════════════════════════════════
const createChoir = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { name, description, church_name, worship_type, image_url } = req.body;
        if (!name) {
            (0, response_1.sendError)(res, '찬양대 이름은 필수입니다', 400, 'VALIDATION_ERROR');
            return;
        }
        const inviteCode = generateInviteCode();
        const choirId = (0, uuid_1.v4)();
        const { data: choir, error } = await supabase_1.default
            .from('choirs')
            .insert({
            id: choirId,
            name,
            description: description || null,
            church_name: church_name || null,
            worship_type: worship_type || null,
            image_url: image_url || null,
            owner_id: userId,
            invite_code: inviteCode,
            invite_link_active: true,
            member_count: 1,
        })
            .select()
            .single();
        if (error) {
            console.error('choir create error:', error);
            (0, response_1.sendError)(res, '찬양대 생성 실패', 500, 'CREATE_ERROR');
            return;
        }
        // 생성자를 지휘자로 등록
        await supabase_1.default.from('choir_members').insert({
            id: (0, uuid_1.v4)(),
            choir_id: choirId,
            user_id: userId,
            role: 'conductor',
            section: 'all',
            status: 'active',
            joined_at: new Date().toISOString(),
        });
        (0, response_1.sendSuccess)(res, choir, '찬양대가 생성되었습니다', 201);
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.createChoir = createChoir;
const getMyChoirs = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { data: memberships, error } = await supabase_1.default
            .from('choir_members')
            .select(`
        role,
        section,
        joined_at,
        choir:choirs(*)
      `)
            .eq('user_id', userId)
            .eq('status', 'active');
        if (error) {
            (0, response_1.sendError)(res, '찬양대 목록 조회 실패', 500, 'FETCH_ERROR');
            return;
        }
        const choirs = (memberships || []).map((m) => ({
            ...m.choir,
            user_role: m.role,
            user_section: m.section,
            joined_at: m.joined_at,
        }));
        (0, response_1.sendSuccess)(res, choirs);
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getMyChoirs = getMyChoirs;
const getChoirById = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId } = req.params;
        // 멤버십 확인
        const { data: member } = await supabase_1.default
            .from('choir_members')
            .select('role')
            .eq('choir_id', choirId)
            .eq('user_id', userId)
            .single();
        if (!member) {
            (0, response_1.sendError)(res, '접근 권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { data: choir, error } = await supabase_1.default
            .from('choirs')
            .select('*')
            .eq('id', choirId)
            .single();
        if (error || !choir) {
            (0, response_1.sendError)(res, '찬양대를 찾을 수 없습니다', 404, 'NOT_FOUND');
            return;
        }
        (0, response_1.sendSuccess)(res, { ...choir, user_role: member.role });
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getChoirById = getChoirById;
const updateChoir = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId } = req.params;
        if (!(await isChoirOwner(choirId, userId)) && !(await isChoirAdmin(choirId, userId))) {
            (0, response_1.sendError)(res, '수정 권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { name, description, church_name, worship_type, image_url } = req.body;
        const { data, error } = await supabase_1.default
            .from('choirs')
            .update({
            ...(name && { name }),
            ...(description !== undefined && { description }),
            ...(church_name !== undefined && { church_name }),
            ...(worship_type !== undefined && { worship_type }),
            ...(image_url !== undefined && { image_url }),
            updated_at: new Date().toISOString(),
        })
            .eq('id', choirId)
            .select()
            .single();
        if (error) {
            (0, response_1.sendError)(res, '수정 실패', 500, 'UPDATE_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, data, '찬양대 정보가 수정되었습니다');
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.updateChoir = updateChoir;
const deleteChoir = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId } = req.params;
        if (!(await isChoirOwner(choirId, userId))) {
            (0, response_1.sendError)(res, '삭제 권한이 없습니다 (소유자만 가능)', 403, 'FORBIDDEN');
            return;
        }
        const { error } = await supabase_1.default.from('choirs').delete().eq('id', choirId);
        if (error) {
            (0, response_1.sendError)(res, '삭제 실패', 500, 'DELETE_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, null, '찬양대가 삭제되었습니다');
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.deleteChoir = deleteChoir;
// ══════════════════════════════════════════════════════════════
// 초대 코드
// ══════════════════════════════════════════════════════════════
const getInviteCode = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId } = req.params;
        if (!(await isChoirAdmin(choirId, userId)) && !(await isChoirOwner(choirId, userId))) {
            (0, response_1.sendError)(res, '권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { data, error } = await supabase_1.default
            .from('choirs')
            .select('invite_code, invite_link_active')
            .eq('id', choirId)
            .single();
        if (error || !data) {
            (0, response_1.sendError)(res, '찬양대를 찾을 수 없습니다', 404, 'NOT_FOUND');
            return;
        }
        (0, response_1.sendSuccess)(res, data);
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getInviteCode = getInviteCode;
const refreshInviteCode = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId } = req.params;
        if (!(await isChoirAdmin(choirId, userId)) && !(await isChoirOwner(choirId, userId))) {
            (0, response_1.sendError)(res, '권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const newCode = generateInviteCode();
        const { data, error } = await supabase_1.default
            .from('choirs')
            .update({ invite_code: newCode })
            .eq('id', choirId)
            .select('invite_code')
            .single();
        if (error) {
            (0, response_1.sendError)(res, '코드 갱신 실패', 500, 'UPDATE_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, data, '초대 코드가 갱신되었습니다');
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.refreshInviteCode = refreshInviteCode;
const getChoirByInviteCode = async (req, res) => {
    try {
        const { code } = req.query;
        if (!code) {
            (0, response_1.sendError)(res, '초대 코드를 입력해주세요', 400, 'VALIDATION_ERROR');
            return;
        }
        const { data: choir, error } = await supabase_1.default
            .from('choirs')
            .select('id, name, description, church_name, image_url, member_count, invite_link_active')
            .eq('invite_code', code.toUpperCase())
            .single();
        if (error || !choir) {
            (0, response_1.sendError)(res, '유효하지 않은 초대 코드입니다', 404, 'NOT_FOUND');
            return;
        }
        if (!choir.invite_link_active) {
            (0, response_1.sendError)(res, '비활성화된 초대 코드입니다', 400, 'INVITE_DISABLED');
            return;
        }
        (0, response_1.sendSuccess)(res, choir);
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getChoirByInviteCode = getChoirByInviteCode;
const joinByInviteCode = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { code, section } = req.body;
        if (!code) {
            (0, response_1.sendError)(res, '초대 코드를 입력해주세요', 400, 'VALIDATION_ERROR');
            return;
        }
        const { data: choir, error: choirError } = await supabase_1.default
            .from('choirs')
            .select('id, name, invite_link_active')
            .eq('invite_code', code.toUpperCase())
            .single();
        if (choirError || !choir) {
            (0, response_1.sendError)(res, '유효하지 않은 초대 코드입니다', 404, 'NOT_FOUND');
            return;
        }
        if (!choir.invite_link_active) {
            (0, response_1.sendError)(res, '비활성화된 초대 코드입니다', 400, 'INVITE_DISABLED');
            return;
        }
        // 이미 멤버인지 확인
        const { data: existing } = await supabase_1.default
            .from('choir_members')
            .select('id, status')
            .eq('choir_id', choir.id)
            .eq('user_id', userId)
            .single();
        if (existing) {
            if (existing.status === 'active') {
                (0, response_1.sendError)(res, '이미 소속된 찬양대입니다', 400, 'ALREADY_MEMBER');
            }
            else {
                (0, response_1.sendError)(res, '가입 신청 처리 중입니다', 400, 'PENDING');
            }
            return;
        }
        // 멤버 추가 (pending 상태 → 관리자 승인 필요)
        await supabase_1.default.from('choir_members').insert({
            id: (0, uuid_1.v4)(),
            choir_id: choir.id,
            user_id: userId,
            role: 'member',
            section: section || 'all',
            status: 'pending',
            joined_at: new Date().toISOString(),
        });
        (0, response_1.sendSuccess)(res, { choir_id: choir.id, choir_name: choir.name }, '가입 신청이 완료되었습니다. 관리자 승인 후 참여할 수 있습니다', 201);
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.joinByInviteCode = joinByInviteCode;
// ══════════════════════════════════════════════════════════════
// 멤버 관리
// ══════════════════════════════════════════════════════════════
const getMembers = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId } = req.params;
        const { status = 'active' } = req.query;
        // 소속 여부 확인
        const { data: myMembership } = await supabase_1.default
            .from('choir_members')
            .select('role')
            .eq('choir_id', choirId)
            .eq('user_id', userId)
            .single();
        if (!myMembership) {
            (0, response_1.sendError)(res, '접근 권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { data: members, error } = await supabase_1.default
            .from('choir_members')
            .select(`
        id,
        role,
        section,
        status,
        joined_at,
        user:users(id, nickname, profile_image_url, church_name)
      `)
            .eq('choir_id', choirId)
            .eq('status', status)
            .order('role')
            .order('joined_at');
        if (error) {
            (0, response_1.sendError)(res, '멤버 조회 실패', 500, 'FETCH_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, members || []);
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getMembers = getMembers;
const updateMember = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId, memberId } = req.params;
        const { role, section } = req.body;
        if (!(await isChoirAdmin(choirId, userId)) && !(await isChoirOwner(choirId, userId))) {
            (0, response_1.sendError)(res, '권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { data, error } = await supabase_1.default
            .from('choir_members')
            .update({
            ...(role && { role }),
            ...(section && { section }),
        })
            .eq('id', memberId)
            .eq('choir_id', choirId)
            .select()
            .single();
        if (error) {
            (0, response_1.sendError)(res, '멤버 수정 실패', 500, 'UPDATE_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, data, '멤버 정보가 수정되었습니다');
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.updateMember = updateMember;
const removeMember = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId, memberId } = req.params;
        if (!(await isChoirAdmin(choirId, userId)) && !(await isChoirOwner(choirId, userId))) {
            (0, response_1.sendError)(res, '권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { error } = await supabase_1.default
            .from('choir_members')
            .delete()
            .eq('id', memberId)
            .eq('choir_id', choirId);
        if (error) {
            (0, response_1.sendError)(res, '멤버 삭제 실패', 500, 'DELETE_ERROR');
            return;
        }
        // member_count 감소
        await supabase_1.default.rpc('decrement_choir_member_count', { p_choir_id: choirId });
        (0, response_1.sendSuccess)(res, null, '멤버가 제거되었습니다');
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.removeMember = removeMember;
const approveMember = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId, memberId } = req.params;
        if (!(await isChoirAdmin(choirId, userId)) && !(await isChoirOwner(choirId, userId))) {
            (0, response_1.sendError)(res, '권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { data, error } = await supabase_1.default
            .from('choir_members')
            .update({ status: 'active' })
            .eq('id', memberId)
            .eq('choir_id', choirId)
            .select()
            .single();
        if (error) {
            (0, response_1.sendError)(res, '승인 실패', 500, 'UPDATE_ERROR');
            return;
        }
        // member_count 증가
        await supabase_1.default.rpc('increment_choir_member_count', { p_choir_id: choirId });
        (0, response_1.sendSuccess)(res, data, '멤버가 승인되었습니다');
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.approveMember = approveMember;
// ══════════════════════════════════════════════════════════════
// 일정 CRUD
// ══════════════════════════════════════════════════════════════
const getSchedules = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId } = req.params;
        const { from, to, type } = req.query;
        const { data: member } = await supabase_1.default
            .from('choir_members')
            .select('role')
            .eq('choir_id', choirId)
            .eq('user_id', userId)
            .single();
        if (!member) {
            (0, response_1.sendError)(res, '접근 권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        let query = supabase_1.default
            .from('choir_schedules')
            .select(`
        *,
        songs:choir_schedule_songs(
          song:choir_songs(id, title, composer, genre)
        )
      `)
            .eq('choir_id', choirId)
            .order('start_time', { ascending: true });
        if (from)
            query = query.gte('start_time', from);
        if (to)
            query = query.lte('start_time', to);
        if (type)
            query = query.eq('schedule_type', type);
        const { data, error } = await query;
        if (error) {
            (0, response_1.sendError)(res, '일정 조회 실패', 500, 'FETCH_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, data || []);
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getSchedules = getSchedules;
const createSchedule = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId } = req.params;
        if (!(await isChoirAdmin(choirId, userId)) && !(await isChoirOwner(choirId, userId))) {
            (0, response_1.sendError)(res, '권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { title, schedule_type, location, start_time, end_time, description, song_ids } = req.body;
        if (!title || !schedule_type || !start_time) {
            (0, response_1.sendError)(res, '제목, 일정 유형, 시작 시간은 필수입니다', 400, 'VALIDATION_ERROR');
            return;
        }
        const scheduleId = (0, uuid_1.v4)();
        const { data: schedule, error } = await supabase_1.default
            .from('choir_schedules')
            .insert({
            id: scheduleId,
            choir_id: choirId,
            title,
            schedule_type,
            location: location || null,
            start_time,
            end_time: end_time || null,
            description: description || null,
            created_by: userId,
        })
            .select()
            .single();
        if (error) {
            (0, response_1.sendError)(res, '일정 생성 실패', 500, 'CREATE_ERROR');
            return;
        }
        // 곡 연결
        if (song_ids && song_ids.length > 0) {
            await supabase_1.default.from('choir_schedule_songs').insert(song_ids.map((songId, i) => ({
                id: (0, uuid_1.v4)(),
                schedule_id: scheduleId,
                song_id: songId,
                order_num: i + 1,
            })));
        }
        (0, response_1.sendSuccess)(res, schedule, '일정이 생성되었습니다', 201);
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.createSchedule = createSchedule;
const getScheduleById = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId, scheduleId } = req.params;
        const { data: member } = await supabase_1.default
            .from('choir_members')
            .select('role')
            .eq('choir_id', choirId)
            .eq('user_id', userId)
            .single();
        if (!member) {
            (0, response_1.sendError)(res, '접근 권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { data, error } = await supabase_1.default
            .from('choir_schedules')
            .select(`
        *,
        songs:choir_schedule_songs(
          order_num,
          song:choir_songs(*)
        ),
        attendance:choir_attendances(
          id, status, member_id,
          member:choir_members(
            user:users(id, nickname)
          )
        )
      `)
            .eq('id', scheduleId)
            .eq('choir_id', choirId)
            .single();
        if (error || !data) {
            (0, response_1.sendError)(res, '일정을 찾을 수 없습니다', 404, 'NOT_FOUND');
            return;
        }
        (0, response_1.sendSuccess)(res, data);
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getScheduleById = getScheduleById;
const updateSchedule = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId, scheduleId } = req.params;
        if (!(await isChoirAdmin(choirId, userId)) && !(await isChoirOwner(choirId, userId))) {
            (0, response_1.sendError)(res, '권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { title, schedule_type, location, start_time, end_time, description } = req.body;
        const { data, error } = await supabase_1.default
            .from('choir_schedules')
            .update({
            ...(title && { title }),
            ...(schedule_type && { schedule_type }),
            ...(location !== undefined && { location }),
            ...(start_time && { start_time }),
            ...(end_time !== undefined && { end_time }),
            ...(description !== undefined && { description }),
            updated_at: new Date().toISOString(),
        })
            .eq('id', scheduleId)
            .eq('choir_id', choirId)
            .select()
            .single();
        if (error) {
            (0, response_1.sendError)(res, '일정 수정 실패', 500, 'UPDATE_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, data, '일정이 수정되었습니다');
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.updateSchedule = updateSchedule;
const deleteSchedule = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId, scheduleId } = req.params;
        if (!(await isChoirAdmin(choirId, userId)) && !(await isChoirOwner(choirId, userId))) {
            (0, response_1.sendError)(res, '권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { error } = await supabase_1.default
            .from('choir_schedules')
            .delete()
            .eq('id', scheduleId)
            .eq('choir_id', choirId);
        if (error) {
            (0, response_1.sendError)(res, '일정 삭제 실패', 500, 'DELETE_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, null, '일정이 삭제되었습니다');
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.deleteSchedule = deleteSchedule;
// ══════════════════════════════════════════════════════════════
// 출석 관리
// ══════════════════════════════════════════════════════════════
const getAttendance = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId, scheduleId } = req.params;
        const { data: member } = await supabase_1.default
            .from('choir_members')
            .select('role')
            .eq('choir_id', choirId)
            .eq('user_id', userId)
            .single();
        if (!member) {
            (0, response_1.sendError)(res, '접근 권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { data, error } = await supabase_1.default
            .from('choir_attendances')
            .select(`
        id,
        status,
        note,
        marked_at,
        member:choir_members(
          id,
          role,
          section,
          user:users(id, nickname, profile_image_url)
        )
      `)
            .eq('schedule_id', scheduleId);
        if (error) {
            (0, response_1.sendError)(res, '출석 조회 실패', 500, 'FETCH_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, data || []);
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getAttendance = getAttendance;
const updateAttendance = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId, scheduleId } = req.params;
        const { attendances } = req.body;
        if (!(await isChoirAdmin(choirId, userId)) && !(await isChoirOwner(choirId, userId))) {
            (0, response_1.sendError)(res, '권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        if (!attendances || !Array.isArray(attendances)) {
            (0, response_1.sendError)(res, '출석 데이터가 필요합니다', 400, 'VALIDATION_ERROR');
            return;
        }
        // upsert 방식으로 한꺼번에 처리
        const upsertData = attendances.map((a) => ({
            id: (0, uuid_1.v4)(),
            schedule_id: scheduleId,
            member_id: a.member_id,
            status: a.status,
            note: a.note || null,
            marked_at: new Date().toISOString(),
            marked_by: userId,
        }));
        const { error } = await supabase_1.default
            .from('choir_attendances')
            .upsert(upsertData, { onConflict: 'schedule_id,member_id' });
        if (error) {
            (0, response_1.sendError)(res, '출석 저장 실패', 500, 'UPDATE_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, null, '출석이 저장되었습니다');
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.updateAttendance = updateAttendance;
const getAttendanceStats = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId } = req.params;
        const { period = 'monthly', year, month } = req.query;
        const { data: member } = await supabase_1.default
            .from('choir_members')
            .select('role')
            .eq('choir_id', choirId)
            .eq('user_id', userId)
            .single();
        if (!member) {
            (0, response_1.sendError)(res, '접근 권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const now = new Date();
        const targetYear = year ? parseInt(year) : now.getFullYear();
        const targetMonth = month ? parseInt(month) : now.getMonth() + 1;
        let fromDate;
        let toDate;
        if (period === 'monthly') {
            fromDate = `${targetYear}-${String(targetMonth).padStart(2, '0')}-01`;
            const lastDay = new Date(targetYear, targetMonth, 0).getDate();
            toDate = `${targetYear}-${String(targetMonth).padStart(2, '0')}-${lastDay}`;
        }
        else {
            fromDate = `${targetYear}-01-01`;
            toDate = `${targetYear}-12-31`;
        }
        // 해당 기간의 일정 수
        const { data: schedules } = await supabase_1.default
            .from('choir_schedules')
            .select('id')
            .eq('choir_id', choirId)
            .gte('start_time', fromDate)
            .lte('start_time', toDate + 'T23:59:59');
        const totalSchedules = schedules?.length || 0;
        // 출석 집계
        const { data: attendances } = await supabase_1.default
            .from('choir_attendances')
            .select(`
        status,
        member:choir_members(
          id,
          section,
          user:users(id, nickname)
        )
      `)
            .in('schedule_id', (schedules || []).map((s) => s.id));
        // 파트별 통계 계산
        const sectionStats = {};
        const memberStats = {};
        (attendances || []).forEach((a) => {
            const section = a.member?.section || 'all';
            const memberId = a.member?.id;
            const memberName = a.member?.user?.nickname || '알 수 없음';
            if (!sectionStats[section])
                sectionStats[section] = { total: 0, present: 0 };
            sectionStats[section].total++;
            if (a.status === 'present')
                sectionStats[section].present++;
            if (memberId) {
                if (!memberStats[memberId])
                    memberStats[memberId] = { name: memberName, total: 0, present: 0 };
                memberStats[memberId].total++;
                if (a.status === 'present')
                    memberStats[memberId].present++;
            }
        });
        (0, response_1.sendSuccess)(res, {
            period,
            from: fromDate,
            to: toDate,
            total_schedules: totalSchedules,
            section_stats: sectionStats,
            member_stats: memberStats,
        });
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getAttendanceStats = getAttendanceStats;
// ══════════════════════════════════════════════════════════════
// 찬양곡 CRUD
// ══════════════════════════════════════════════════════════════
const getSongs = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId } = req.params;
        const { genre, difficulty, search } = req.query;
        const { data: member } = await supabase_1.default
            .from('choir_members')
            .select('role')
            .eq('choir_id', choirId)
            .eq('user_id', userId)
            .single();
        if (!member) {
            (0, response_1.sendError)(res, '접근 권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        let query = supabase_1.default
            .from('choir_songs')
            .select('*')
            .eq('choir_id', choirId)
            .order('created_at', { ascending: false });
        if (genre)
            query = query.eq('genre', genre);
        if (difficulty)
            query = query.eq('difficulty', difficulty);
        if (search)
            query = query.ilike('title', `%${search}%`);
        const { data, error } = await query;
        if (error) {
            (0, response_1.sendError)(res, '곡 목록 조회 실패', 500, 'FETCH_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, data || []);
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getSongs = getSongs;
const createSong = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId } = req.params;
        const { data: member } = await supabase_1.default
            .from('choir_members')
            .select('role')
            .eq('choir_id', choirId)
            .eq('user_id', userId)
            .single();
        if (!member) {
            (0, response_1.sendError)(res, '접근 권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { title, composer, arranger, hymn_book_ref, youtube_url, genre, difficulty, parts, notes } = req.body;
        if (!title) {
            (0, response_1.sendError)(res, '곡 제목은 필수입니다', 400, 'VALIDATION_ERROR');
            return;
        }
        const { data, error } = await supabase_1.default
            .from('choir_songs')
            .insert({
            id: (0, uuid_1.v4)(),
            choir_id: choirId,
            title,
            composer: composer || null,
            arranger: arranger || null,
            hymn_book_ref: hymn_book_ref || null,
            youtube_url: youtube_url || null,
            genre: genre || null,
            difficulty: difficulty || 'medium',
            parts: parts || [],
            notes: notes || null,
            created_by: userId,
        })
            .select()
            .single();
        if (error) {
            (0, response_1.sendError)(res, '곡 등록 실패', 500, 'CREATE_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, data, '곡이 등록되었습니다', 201);
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.createSong = createSong;
const updateSong = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId, songId } = req.params;
        const { data: member } = await supabase_1.default
            .from('choir_members')
            .select('role')
            .eq('choir_id', choirId)
            .eq('user_id', userId)
            .single();
        if (!member) {
            (0, response_1.sendError)(res, '접근 권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { title, composer, arranger, hymn_book_ref, youtube_url, genre, difficulty, parts, notes } = req.body;
        const { data, error } = await supabase_1.default
            .from('choir_songs')
            .update({
            ...(title && { title }),
            ...(composer !== undefined && { composer }),
            ...(arranger !== undefined && { arranger }),
            ...(hymn_book_ref !== undefined && { hymn_book_ref }),
            ...(youtube_url !== undefined && { youtube_url }),
            ...(genre !== undefined && { genre }),
            ...(difficulty && { difficulty }),
            ...(parts && { parts }),
            ...(notes !== undefined && { notes }),
            updated_at: new Date().toISOString(),
        })
            .eq('id', songId)
            .eq('choir_id', choirId)
            .select()
            .single();
        if (error) {
            (0, response_1.sendError)(res, '곡 수정 실패', 500, 'UPDATE_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, data, '곡 정보가 수정되었습니다');
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.updateSong = updateSong;
const deleteSong = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId, songId } = req.params;
        if (!(await isChoirAdmin(choirId, userId)) && !(await isChoirOwner(choirId, userId))) {
            (0, response_1.sendError)(res, '권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { error } = await supabase_1.default
            .from('choir_songs')
            .delete()
            .eq('id', songId)
            .eq('choir_id', choirId);
        if (error) {
            (0, response_1.sendError)(res, '곡 삭제 실패', 500, 'DELETE_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, null, '곡이 삭제되었습니다');
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.deleteSong = deleteSong;
// ══════════════════════════════════════════════════════════════
// 공지사항 CRUD
// ══════════════════════════════════════════════════════════════
const getNotices = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId } = req.params;
        const { data: member } = await supabase_1.default
            .from('choir_members')
            .select('role')
            .eq('choir_id', choirId)
            .eq('user_id', userId)
            .single();
        if (!member) {
            (0, response_1.sendError)(res, '접근 권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { data, error } = await supabase_1.default
            .from('choir_notices')
            .select(`
        *,
        author:users(id, nickname, profile_image_url)
      `)
            .eq('choir_id', choirId)
            .order('is_pinned', { ascending: false })
            .order('created_at', { ascending: false });
        if (error) {
            (0, response_1.sendError)(res, '공지 조회 실패', 500, 'FETCH_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, data || []);
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getNotices = getNotices;
const createNotice = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId } = req.params;
        if (!(await isChoirAdmin(choirId, userId)) && !(await isChoirOwner(choirId, userId))) {
            (0, response_1.sendError)(res, '권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { title, content, is_pinned = false, target_section } = req.body;
        if (!title || !content) {
            (0, response_1.sendError)(res, '제목과 내용은 필수입니다', 400, 'VALIDATION_ERROR');
            return;
        }
        const { data, error } = await supabase_1.default
            .from('choir_notices')
            .insert({
            id: (0, uuid_1.v4)(),
            choir_id: choirId,
            author_id: userId,
            title,
            content,
            is_pinned,
            target_section: target_section || null,
        })
            .select()
            .single();
        if (error) {
            (0, response_1.sendError)(res, '공지 생성 실패', 500, 'CREATE_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, data, '공지가 등록되었습니다', 201);
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.createNotice = createNotice;
const updateNotice = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId, noticeId } = req.params;
        if (!(await isChoirAdmin(choirId, userId)) && !(await isChoirOwner(choirId, userId))) {
            (0, response_1.sendError)(res, '권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { title, content, is_pinned, target_section } = req.body;
        const { data, error } = await supabase_1.default
            .from('choir_notices')
            .update({
            ...(title && { title }),
            ...(content && { content }),
            ...(is_pinned !== undefined && { is_pinned }),
            ...(target_section !== undefined && { target_section }),
            updated_at: new Date().toISOString(),
        })
            .eq('id', noticeId)
            .eq('choir_id', choirId)
            .select()
            .single();
        if (error) {
            (0, response_1.sendError)(res, '공지 수정 실패', 500, 'UPDATE_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, data, '공지가 수정되었습니다');
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.updateNotice = updateNotice;
const deleteNotice = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId, noticeId } = req.params;
        if (!(await isChoirAdmin(choirId, userId)) && !(await isChoirOwner(choirId, userId))) {
            (0, response_1.sendError)(res, '권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { error } = await supabase_1.default
            .from('choir_notices')
            .delete()
            .eq('id', noticeId)
            .eq('choir_id', choirId);
        if (error) {
            (0, response_1.sendError)(res, '공지 삭제 실패', 500, 'DELETE_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, null, '공지가 삭제되었습니다');
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.deleteNotice = deleteNotice;
// ══════════════════════════════════════════════════════════════
// 자료실 CRUD
// ══════════════════════════════════════════════════════════════
const getFiles = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId } = req.params;
        const { file_type } = req.query;
        const { data: member } = await supabase_1.default
            .from('choir_members')
            .select('role')
            .eq('choir_id', choirId)
            .eq('user_id', userId)
            .single();
        if (!member) {
            (0, response_1.sendError)(res, '접근 권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        let query = supabase_1.default
            .from('choir_files')
            .select(`
        *,
        uploader:users(id, nickname)
      `)
            .eq('choir_id', choirId)
            .order('created_at', { ascending: false });
        if (file_type)
            query = query.eq('file_type', file_type);
        const { data, error } = await query;
        if (error) {
            (0, response_1.sendError)(res, '파일 조회 실패', 500, 'FETCH_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, data || []);
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.getFiles = getFiles;
const createFile = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId } = req.params;
        const { data: member } = await supabase_1.default
            .from('choir_members')
            .select('role')
            .eq('choir_id', choirId)
            .eq('user_id', userId)
            .single();
        if (!member) {
            (0, response_1.sendError)(res, '접근 권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { title, description, file_type, file_url, youtube_url, target_section } = req.body;
        if (!title || !file_type) {
            (0, response_1.sendError)(res, '제목과 파일 유형은 필수입니다', 400, 'VALIDATION_ERROR');
            return;
        }
        if (!file_url && !youtube_url) {
            (0, response_1.sendError)(res, '파일 URL 또는 YouTube URL이 필요합니다', 400, 'VALIDATION_ERROR');
            return;
        }
        const { data, error } = await supabase_1.default
            .from('choir_files')
            .insert({
            id: (0, uuid_1.v4)(),
            choir_id: choirId,
            title,
            description: description || null,
            file_type,
            file_url: file_url || null,
            youtube_url: youtube_url || null,
            target_section: target_section || null,
            uploaded_by: userId,
        })
            .select()
            .single();
        if (error) {
            (0, response_1.sendError)(res, '파일 등록 실패', 500, 'CREATE_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, data, '자료가 등록되었습니다', 201);
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.createFile = createFile;
const deleteFile = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { choirId, fileId } = req.params;
        if (!(await isChoirAdmin(choirId, userId)) && !(await isChoirOwner(choirId, userId))) {
            (0, response_1.sendError)(res, '권한이 없습니다', 403, 'FORBIDDEN');
            return;
        }
        const { error } = await supabase_1.default
            .from('choir_files')
            .delete()
            .eq('id', fileId)
            .eq('choir_id', choirId);
        if (error) {
            (0, response_1.sendError)(res, '파일 삭제 실패', 500, 'DELETE_ERROR');
            return;
        }
        (0, response_1.sendSuccess)(res, null, '자료가 삭제되었습니다');
    }
    catch (err) {
        console.error(err);
        (0, response_1.sendError)(res, '서버 오류', 500, 'SERVER_ERROR');
    }
};
exports.deleteFile = deleteFile;
//# sourceMappingURL=choir.controller.js.map