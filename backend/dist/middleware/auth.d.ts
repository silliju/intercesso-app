import { Request, Response, NextFunction } from 'express';
import { JwtPayload } from '../types';
export interface AuthRequest extends Request {
    user?: JwtPayload;
}
export declare const authenticate: (req: AuthRequest, res: Response, next: NextFunction) => void;
export declare const optionalAuth: (req: AuthRequest, res: Response, next: NextFunction) => void;
//# sourceMappingURL=auth.d.ts.map