import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
export declare const getDashboard: (req: AuthRequest, res: Response) => Promise<void>;
export declare const getPrayerCharts: (req: AuthRequest, res: Response) => Promise<void>;
export declare const getCommunityStats: (req: AuthRequest, res: Response) => Promise<void>;
export declare const getMyStatistics: (req: AuthRequest, res: Response) => Promise<void>;
export declare const getUserStatistics: (req: AuthRequest, res: Response) => Promise<void>;
//# sourceMappingURL=statistics.controller.d.ts.map