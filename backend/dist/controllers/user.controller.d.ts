import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
export declare const getMe: (req: AuthRequest, res: Response) => Promise<void>;
export declare const updateMe: (req: AuthRequest, res: Response) => Promise<void>;
export declare const getUserById: (req: AuthRequest, res: Response) => Promise<void>;
export declare const getUserStats: (req: AuthRequest, res: Response) => Promise<void>;
export declare const getConnections: (req: AuthRequest, res: Response) => Promise<void>;
export declare const addConnection: (req: AuthRequest, res: Response) => Promise<void>;
export declare const searchUsers: (req: AuthRequest, res: Response) => Promise<void>;
export declare const deleteMe: (req: AuthRequest, res: Response) => Promise<void>;
export declare const updateFcmToken: (req: AuthRequest, res: Response) => Promise<void>;
export declare const deleteFcmToken: (req: AuthRequest, res: Response) => Promise<void>;
//# sourceMappingURL=user.controller.d.ts.map