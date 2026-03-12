import { Request, Response } from 'express';
import { AuthRequest } from '../middleware/auth';
/** 검색: 이름/지역으로 교회 조회. status = approved 또는 pending 포함 (사용자 등록 직후 선택 가능) */
export declare const searchChurches: (req: Request, res: Response) => Promise<void>;
/** 단건 조회 */
export declare const getChurchById: (req: Request, res: Response) => Promise<void>;
/** 교회 등록 (회원가입/찬양대에서 “우리 교회 등록” 시). 주소 중복 시 기존 교회 반환 가능 */
export declare const createChurch: (req: AuthRequest, res: Response) => Promise<void>;
//# sourceMappingURL=church.controller.d.ts.map