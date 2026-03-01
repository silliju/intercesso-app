// lib/config/constants.dart
class AppConstants {
  // API 설정 - 실제 배포 시 백엔드 URL로 교체
  static const String baseUrl = 'https://3000-iawt7nkbqrkyumj044b1d-2e77fc33.sandbox.novita.ai/api';

  // ─── 소셜 로그인 키 ───────────────────────────────────────
  // 구글 OAuth 클라이언트 ID (Google Cloud Console에서 발급)
  // 절대 공개 저장소(GitHub 등)에 올리지 마세요!
  static const String googleClientId =
      '777786565733-uklsbfk4i1mt4f7sa4daud7ih47t729b.apps.googleusercontent.com';

  // 카카오 네이티브 앱 키 (카카오 개발자 센터에서 발급)
  // main.dart의 KakaoSdk.init()에서 사용됩니다
  static const String kakaoNativeAppKey = '3853e9c9f28e388a2f4dc4cffed572b4';
  
  // 앱 정보
  static const String appName = 'Intercesso';
  static const String appSlogan = '함께 기도하는 공동체';
  
  // 색상
  static const int primaryColor = 0xFF00AAFF;
  static const int secondaryColor = 0xFF00C9A7;
  static const int successColor = 0xFF10B981;
  static const int warningColor = 0xFFF59E0B;
  static const int errorColor = 0xFFEF4444;
  
  // SharedPreferences 키
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';
  
  // 페이지네이션
  static const int defaultPageSize = 10;
  
  // 기도 카테고리
  static const List<String> prayerCategories = [
    '건강', '가정', '진로', '영적', '사업', '기타'
  ];
  
  // 공개 범위
  static const Map<String, String> scopeLabels = {
    'public': '전체 공개',
    'friends': '지인 공개',
    'community': '공동체',
    'private': '비공개',
  };
  
  // 기도 상태
  static const Map<String, String> statusLabels = {
    'praying': '기도중 🙏',
    'answered': '응답받음 ✅',
    'grateful': '감사 🙌',
  };
  
  // 그룹 유형
  static const Map<String, String> groupTypeLabels = {
    'church': '교회',
    'cell': '셀/구역',
    'gathering': '소모임',
    'family': '가족',
  };
  
  // 작정기도 기간
  static const List<int> covenantDayOptions = [7, 21, 40, 50, 100];
}
