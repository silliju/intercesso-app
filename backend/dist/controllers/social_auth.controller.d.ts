import { Request, Response } from 'express';
/**
 * 구글 로그인 처리
 *
 * 요청 body:
 *   - id_token: 구글 SDK에서 발급받은 ID 토큰
 *   - email: 구글 계정 이메일 (id_token에서도 추출 가능, 보조용)
 *   - nickname: 구글 표시 이름
 *
 * 처리 흐름:
 *   1. 구글 서버에 id_token 검증 요청
 *   2. 검증 성공 → 사용자 정보 추출
 *   3. DB에서 사용자 조회 or 자동 회원가입
 *   4. 내부 JWT 발급 후 반환
 */
export declare const googleLogin: (req: Request, res: Response) => Promise<void>;
/**
 * 카카오 로그인 처리
 *
 * 요청 body:
 *   - access_token: 카카오 SDK에서 발급받은 액세스 토큰
 *   - kakao_id: 카카오 고유 사용자 ID
 *   - email: 카카오 계정 이메일 (선택, 없을 수 있음)
 *   - nickname: 카카오 프로필 닉네임
 *
 * 처리 흐름:
 *   1. 카카오 서버에 access_token으로 사용자 정보 요청
 *   2. 검증 성공 → 사용자 정보 추출
 *   3. DB에서 사용자 조회 or 자동 회원가입
 *   4. 내부 JWT 발급 후 반환
 */
export declare const kakaoLogin: (req: Request, res: Response) => Promise<void>;
//# sourceMappingURL=social_auth.controller.d.ts.map