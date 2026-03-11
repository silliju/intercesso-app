import '../models/church_model.dart';
import 'api_service.dart';

class ChurchService {
  final ApiService _api = ApiService();

  /// 교회 검색 (이름/지역)
  Future<List<ChurchModel>> search(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    final res = await _api.get(
      '/churches/search',
      queryParams: {'q': query.trim(), 'limit': limit.toString()},
    );
    final list = res['data'] as List<dynamic>? ?? [];
    return list.map((e) => ChurchModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 교회 단건 조회
  Future<ChurchModel?> getById(int churchId) async {
    final res = await _api.get('/churches/$churchId');
    final data = res['data'] as Map<String, dynamic>?;
    return data != null ? ChurchModel.fromJson(data) : null;
  }

  /// 교회 등록 (회원가입 중 비로그인 가능)
  Future<ChurchModel> create({
    required String name,
    String? denomination,
    String? pastorName,
    required String siDo,
    required String siGunGu,
    String? dong,
    String? detailAddress,
    String? roadAddress,
    String? jibunAddress,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'si_do': siDo,
      'si_gun_gu': siGunGu,
      if (denomination != null && denomination.isNotEmpty) 'denomination': denomination,
      if (pastorName != null && pastorName.isNotEmpty) 'pastor_name': pastorName,
      if (dong != null && dong.isNotEmpty) 'dong': dong,
      if (detailAddress != null && detailAddress.isNotEmpty) 'detail_address': detailAddress,
      if (roadAddress != null && roadAddress.isNotEmpty) 'road_address': roadAddress,
      if (jibunAddress != null && jibunAddress.isNotEmpty) 'jibun_address': jibunAddress,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
    final res = await _api.post('/churches', body: body);
    final data = res['data'] as Map<String, dynamic>;
    return ChurchModel.fromJson(data);
  }
}
