import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
export declare const getPrayers: (req: AuthRequest, res: Response) => Promise<void>;
export declare const getPrayerById: (req: AuthRequest, res: Response) => Promise<void>;
export declare const createPrayer: (req: AuthRequest, res: Response) => Promise<void>;
export declare const updatePrayer: (req: AuthRequest, res: Response) => Promise<void>;
export declare const deletePrayer: (req: AuthRequest, res: Response) => Promise<void>;
export declare const participatePrayer: (req: AuthRequest, res: Response) => Promise<void>;
export declare const cancelParticipation: (req: AuthRequest, res: Response) => Promise<void>;
export declare const createComment: (req: AuthRequest, res: Response) => Promise<void>;
export declare const deleteComment: (req: AuthRequest, res: Response) => Promise<void>;
export declare const getCovenantCheckins: (req: AuthRequest, res: Response) => Promise<void>;
export declare const checkInCovenant: (req: AuthRequest, res: Response) => Promise<void>;
//# sourceMappingURL=prayer.controller.d.ts.map