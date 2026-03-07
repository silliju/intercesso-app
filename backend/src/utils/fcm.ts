import * as admin from 'firebase-admin';

let firebaseInitialized = false;

/**
 * Firebase Admin SDK 초기화
 * FIREBASE_SERVICE_ACCOUNT_JSON 환경변수에 서비스 계정 JSON 문자열 필요
 */
function initFirebase() {
  if (firebaseInitialized) return true;

  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!serviceAccountJson) {
    console.warn('⚠️  FIREBASE_SERVICE_ACCOUNT_JSON 환경변수가 없습니다. 푸시 알림이 비활성화됩니다.');
    return false;
  }

  try {
    const serviceAccount = JSON.parse(serviceAccountJson);
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }
    firebaseInitialized = true;
    console.log('✅ Firebase Admin SDK 초기화 완료');
    return true;
  } catch (err) {
    console.error('❌ Firebase 초기화 실패:', err);
    return false;
  }
}

export interface PushPayload {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * 단일 기기에 푸시 알림 발송
 */
export async function sendPush(payload: PushPayload): Promise<boolean> {
  if (!initFirebase()) return false;

  try {
    await admin.messaging().send({
      token: payload.token,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data || {},
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    });
    return true;
  } catch (err: any) {
    // 토큰 무효 시 조용히 무시 (앱 삭제/로그아웃 등)
    if (
      err.code === 'messaging/invalid-registration-token' ||
      err.code === 'messaging/registration-token-not-registered'
    ) {
      console.log('📵 FCM 토큰 무효 (앱 삭제됨):', payload.token.slice(0, 20) + '...');
    } else {
      console.error('❌ FCM 전송 실패:', err.message);
    }
    return false;
  }
}

/**
 * 여러 기기에 동시 발송 (최대 500개)
 */
export async function sendPushMultiple(
  tokens: string[],
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<void> {
  if (!initFirebase() || tokens.length === 0) return;

  const validTokens = tokens.filter(t => t && t.length > 0);
  if (validTokens.length === 0) return;

  try {
    const messages = validTokens.map(token => ({
      token,
      notification: { title, body },
      data: data || {},
      android: {
        priority: 'high' as const,
        notification: {
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
      },
    }));

    // 500개씩 나눠서 발송
    const chunks = [];
    for (let i = 0; i < messages.length; i += 500) {
      chunks.push(messages.slice(i, i + 500));
    }

    for (const chunk of chunks) {
      const response = await admin.messaging().sendEach(chunk);
      console.log(`📨 FCM 발송: 성공 ${response.successCount}, 실패 ${response.failureCount}`);
    }
  } catch (err: any) {
    console.error('❌ FCM 다중 전송 실패:', err.message);
  }
}
