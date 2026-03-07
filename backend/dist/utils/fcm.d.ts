export interface PushPayload {
    token: string;
    title: string;
    body: string;
    data?: Record<string, string>;
}
/**
 * 단일 기기에 푸시 알림 발송
 */
export declare function sendPush(payload: PushPayload): Promise<boolean>;
/**
 * 여러 기기에 동시 발송 (최대 500개)
 */
export declare function sendPushMultiple(tokens: string[], title: string, body: string, data?: Record<string, string>): Promise<void>;
//# sourceMappingURL=fcm.d.ts.map