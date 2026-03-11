import { Request, Response } from 'express';
import supabaseAdmin from '../config/supabase';
import { sendSuccess, sendError } from '../utils/response';
import { AuthRequest } from '../middleware/auth';

/** 검색: 이름/지역으로 교회 조회. status = approved 또는 pending 포함 (사용자 등록 직후 선택 가능) */
export const searchChurches = async (req: Request, res: Response): Promise<void> => {
  try {
    const q = (req.query.q as string || '').trim();
    const limit = Math.min(parseInt(req.query.limit as string, 10) || 20, 50);

    if (!q || q.length < 1) {
      sendSuccess(res, []);
      return;
    }

    const { data, error } = await supabaseAdmin
      .from('churches')
      .select('church_id, name, denomination, pastor_name, si_do, si_gun_gu, dong, road_address, jibun_address, status')
      .in('status', ['approved', 'pending'])
      .neq('status', 'deleted')
      .or(`name.ilike.%${q}%,si_do.ilike.%${q}%,si_gun_gu.ilike.%${q}%,dong.ilike.%${q}%`)
      .order('name')
      .limit(limit);

    if (error) {
      console.error('church search error:', error);
      sendError(res, '교회 검색 중 오류가 발생했습니다', 500, 'SEARCH_ERROR');
      return;
    }

    sendSuccess(res, data || []);
  } catch (err) {
    console.error(err);
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

/** 단건 조회 */
export const getChurchById = async (req: Request, res: Response): Promise<void> => {
  try {
    const churchId = parseInt(req.params.churchId, 10);
    if (isNaN(churchId)) {
      sendError(res, '유효하지 않은 교회 ID입니다', 400, 'VALIDATION_ERROR');
      return;
    }

    const { data, error } = await supabaseAdmin
      .from('churches')
      .select('*')
      .eq('church_id', churchId)
      .in('status', ['approved', 'pending'])
      .single();

    if (error || !data) {
      sendError(res, '교회를 찾을 수 없습니다', 404, 'NOT_FOUND');
      return;
    }

    sendSuccess(res, data);
  } catch (err) {
    console.error(err);
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};

/** 교회 등록 (회원가입/찬양대에서 “우리 교회 등록” 시). 주소 중복 시 기존 교회 반환 가능 */
export const createChurch = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const body = req.body as {
      name: string;
      denomination?: string;
      pastor_name?: string;
      si_do: string;
      si_gun_gu: string;
      dong?: string;
      detail_address?: string;
      road_address?: string;
      jibun_address?: string;
      latitude?: number;
      longitude?: number;
    };

    if (!body.name || !body.si_do || !body.si_gun_gu) {
      sendError(res, '교회명, 시/도, 시/군/구는 필수입니다', 400, 'VALIDATION_ERROR');
      return;
    }

    const detail = body.detail_address || '';
    const dong = body.dong || '';

    // 중복 확인: 동일 name + si_do + si_gun_gu + dong + detail_address
    const { data: existing } = await supabaseAdmin
      .from('churches')
      .select('church_id, name, status')
      .eq('name', body.name)
      .eq('si_do', body.si_do)
      .eq('si_gun_gu', body.si_gun_gu)
      .eq('dong', dong)
      .eq('detail_address', detail)
      .in('status', ['approved', 'pending'])
      .maybeSingle();

    if (existing) {
      sendSuccess(res, existing, '이미 등록된 교회입니다. 해당 교회를 선택해 주세요.', 200);
      return;
    }

    const { data: inserted, error } = await supabaseAdmin
      .from('churches')
      .insert({
        name: body.name,
        denomination: body.denomination || null,
        pastor_name: body.pastor_name || null,
        si_do: body.si_do,
        si_gun_gu: body.si_gun_gu,
        dong: dong || null,
        detail_address: detail || null,
        road_address: body.road_address || null,
        jibun_address: body.jibun_address || null,
        latitude: body.latitude ?? null,
        longitude: body.longitude ?? null,
        status: 'approved',
      })
      .select('church_id, name, denomination, pastor_name, si_do, si_gun_gu, dong, detail_address, road_address, jibun_address, status')
      .single();

    if (error) {
      if (error.code === '23505') {
        sendError(res, '같은 주소의 교회가 이미 등록되어 있습니다', 409, 'DUPLICATE_CHURCH');
        return;
      }
      console.error('church create error:', error);
      sendError(res, '교회 등록 중 오류가 발생했습니다', 500, 'CREATE_ERROR');
      return;
    }

    sendSuccess(res, inserted, '교회가 등록되었습니다', 201);
  } catch (err) {
    console.error(err);
    sendError(res, '서버 오류', 500, 'SERVER_ERROR');
  }
};
