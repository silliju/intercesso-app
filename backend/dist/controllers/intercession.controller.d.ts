import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
/**
 * 중보기도 요청 생성
 * target_type: 'individual' | 'group' | 'public'
 *   - individual: recipient_id 필수
 *   - group:      group_id 필수 (그룹 멤버 전체에게 개별 레코드 삽입)
 *   - public:     recipient_id = requester 자신 (더미), message 앞에 [PUBLIC] 태그
 */
export declare const createIntercessionRequest: (req: AuthRequest, res: Response) => Promise<void>;
/** 받은 중보기도 요청 목록 (나에게 온 요청) */
export declare const getIntercessionRequests: (req: AuthRequest, res: Response) => Promise<void>;
/** 전체공개 중보기도 요청 목록 */
export declare const getPublicIntercessionRequests: (req: AuthRequest, res: Response) => Promise<void>;
/** 보낸 중보기도 요청 목록 */
export declare const getSentRequests: (req: AuthRequest, res: Response) => Promise<void>;
/** 요청 수락/거절 */
export declare const respondIntercessionRequest: (req: AuthRequest, res: Response) => Promise<void>;
/** 사용자 검색 (개인 요청 대상자 선택용) */
export declare const searchUsersForIntercession: (req: AuthRequest, res: Response) => Promise<void>;
//# sourceMappingURL=intercession.controller.d.ts.map