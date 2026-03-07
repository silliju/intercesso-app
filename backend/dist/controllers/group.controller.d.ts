import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
export declare const createGroup: (req: AuthRequest, res: Response) => Promise<void>;
export declare const getMyGroups: (req: AuthRequest, res: Response) => Promise<void>;
export declare const getGroupById: (req: AuthRequest, res: Response) => Promise<void>;
export declare const updateGroup: (req: AuthRequest, res: Response) => Promise<void>;
export declare const deleteGroup: (req: AuthRequest, res: Response) => Promise<void>;
export declare const joinGroup: (req: AuthRequest, res: Response) => Promise<void>;
export declare const getGroupMembers: (req: AuthRequest, res: Response) => Promise<void>;
export declare const removeMember: (req: AuthRequest, res: Response) => Promise<void>;
export declare const joinByInviteCode: (req: AuthRequest, res: Response) => Promise<void>;
export declare const leaveGroup: (req: AuthRequest, res: Response) => Promise<void>;
export declare const searchGroups: (req: AuthRequest, res: Response) => Promise<void>;
export declare const getInviteCode: (req: AuthRequest, res: Response) => Promise<void>;
//# sourceMappingURL=group.controller.d.ts.map