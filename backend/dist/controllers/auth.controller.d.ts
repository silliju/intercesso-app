import { Request, Response } from 'express';
export declare const signUp: (req: Request, res: Response) => Promise<void>;
export declare const login: (req: Request, res: Response) => Promise<void>;
export declare const logout: (req: Request, res: Response) => Promise<void>;
export declare const refreshToken: (req: Request, res: Response) => Promise<void>;
/**
 * 비밀번호 재설정 요청
 * - 이메일 존재 여부 확인
 * - Supabase Auth의 resetPasswordForEmail 사용
 * POST /api/auth/forgot-password
 * body: { email }
 */
export declare const forgotPassword: (req: Request, res: Response) => Promise<void>;
/**
 * 닉네임으로 이메일(아이디) 찾기
 * POST /api/auth/find-email
 * body: { nickname, church_name? }
 */
export declare const findEmail: (req: Request, res: Response) => Promise<void>;
//# sourceMappingURL=auth.controller.d.ts.map