import { Request, Response } from 'express';
interface AuthRequest extends Request {
    user?: {
        userId: string;
        email: string;
    };
}
export declare const upsertPrayerAnswer: (req: AuthRequest, res: Response) => Promise<void>;
export declare const getPrayerAnswer: (req: AuthRequest, res: Response) => Promise<void>;
export declare const deletePrayerAnswer: (req: AuthRequest, res: Response) => Promise<void>;
export declare const createAnswerComment: (req: AuthRequest, res: Response) => Promise<void>;
export declare const deleteAnswerComment: (req: AuthRequest, res: Response) => Promise<void>;
export declare const getAnswerFeed: (req: AuthRequest, res: Response) => Promise<void>;
export {};
//# sourceMappingURL=prayer_answer.controller.d.ts.map