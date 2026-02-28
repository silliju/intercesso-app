// ============================================================
// social_auth_service.dart - 소셜 로그인 서비스
// ============================================================
// 역할: 구글 로그인, 카카오 로그인을 처리하는 서비스 클래스
// - 구글: google_sign_in 패키지 사용
// - 카카오: kakao_flutter_sdk_user 패키지 사용
// - 로그인 성공 시 소셜 토큰을 백엔드로 전달하여 JWT 발급
// ============================================================

import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'api_service.dart';
import '../config/constants.dart';

/// 소셜 로그인 결과 데이터 클래스
/// 백엔드로부터 받은 사용자 정보와 JWT 토큰을 담습니다
class SocialLoginResult {
  final String token;       // JWT 액세스 토큰
  final Map<String, dynamic> user; // 사용자 정보

  SocialLoginResult({required this.token, required this.user});
}

class SocialAuthService {
  final ApiService _api = ApiService();

  // ─────────────────────────────────────────────────────────
  // 구글 로그인
  // ─────────────────────────────────────────────────────────

  // 구글 로그인 인스턴스 생성
  // serverClientId: 웹 클라이언트 ID (백엔드 토큰 검증에 사용)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: AppConstants.googleClientId,
    scopes: ['email', 'profile'], // 이메일과 프로필 정보만 요청
  );

  /// 구글 로그인 실행
  /// 반환값: 성공 시 SocialLoginResult, 실패 시 null
  Future<SocialLoginResult?> signInWithGoogle() async {
    try {
      // 구글 로그인 팝업 열기
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // 사용자가 로그인 취소한 경우
        return null;
      }

      // 구글 인증 토큰 가져오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('구글 ID 토큰을 가져올 수 없습니다');
      }

      // 백엔드에 구글 토큰을 보내 JWT 발급 요청
      final response = await _api.post(
        '/auth/social/google',
        body: {
          'id_token': idToken,
          'email': googleUser.email,
          'nickname': googleUser.displayName ?? googleUser.email.split('@')[0],
        },
      );

      if (response['success'] == true) {
        return SocialLoginResult(
          token: response['data']['token'],
          user: response['data']['user'],
        );
      } else {
        throw ApiException(response['message'] ?? '구글 로그인에 실패했습니다');
      }
    } catch (e) {
      // 구글 SDK 오류 또는 네트워크 오류
      if (e is ApiException) rethrow;
      throw ApiException('구글 로그인 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  /// 구글 로그아웃
  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }

  // ─────────────────────────────────────────────────────────
  // 카카오 로그인
  // ─────────────────────────────────────────────────────────

  /// 카카오 로그인 실행
  /// 카카오톡 앱이 있으면 앱으로, 없으면 웹 브라우저로 로그인
  Future<SocialLoginResult?> signInWithKakao() async {
    try {
      OAuthToken token;

      // 카카오톡 앱 설치 여부 확인
      if (await isKakaoTalkInstalled()) {
        // 카카오톡 앱으로 로그인 (더 빠르고 편리)
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        // 카카오 계정(웹 브라우저)으로 로그인
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      // 카카오 사용자 정보 가져오기
      final User kakaoUser = await UserApi.instance.me();
      final String? email = kakaoUser.kakaoAccount?.email;
      final String? nickname =
          kakaoUser.kakaoAccount?.profile?.nickname;

      // 백엔드에 카카오 액세스 토큰을 보내 JWT 발급 요청
      final response = await _api.post(
        '/auth/social/kakao',
        body: {
          'access_token': token.accessToken,
          'kakao_id': kakaoUser.id.toString(),
          'email': email ?? '',
          'nickname': nickname ?? '카카오사용자',
        },
      );

      if (response['success'] == true) {
        return SocialLoginResult(
          token: response['data']['token'],
          user: response['data']['user'],
        );
      } else {
        throw ApiException(response['message'] ?? '카카오 로그인에 실패했습니다');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      // KakaoAuthException: 카카오 인증 오류
      // KakaoClientException: 클라이언트 설정 오류
      throw ApiException('카카오 로그인 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  /// 카카오 로그아웃
  Future<void> signOutKakao() async {
    try {
      await UserApi.instance.logout();
    } catch (e) {
      // 로그아웃 오류는 무시 (이미 로그아웃된 상태일 수 있음)
    }
  }
}
