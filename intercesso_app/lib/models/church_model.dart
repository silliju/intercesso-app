/// 교회 검색/등록용 모델 (churches 테이블)
class ChurchModel {
  final int churchId;
  final String name;
  final String? denomination;
  final String? pastorName;
  final String? siDo;
  final String? siGunGu;
  final String? dong;
  final String? detailAddress;
  final String? roadAddress;
  final String? jibunAddress;
  final double? latitude;
  final double? longitude;
  final String? status;

  ChurchModel({
    required this.churchId,
    required this.name,
    this.denomination,
    this.pastorName,
    this.siDo,
    this.siGunGu,
    this.dong,
    this.detailAddress,
    this.roadAddress,
    this.jibunAddress,
    this.latitude,
    this.longitude,
    this.status,
  });

  factory ChurchModel.fromJson(Map<String, dynamic> json) {
    return ChurchModel(
      churchId: (json['church_id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      denomination: json['denomination'] as String?,
      pastorName: json['pastor_name'] as String?,
      siDo: json['si_do'] as String?,
      siGunGu: json['si_gun_gu'] as String?,
      dong: json['dong'] as String?,
      detailAddress: json['detail_address'] as String?,
      roadAddress: json['road_address'] as String?,
      jibunAddress: json['jibun_address'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'church_id': churchId,
        'name': name,
        'denomination': denomination,
        'pastor_name': pastorName,
        'si_do': siDo,
        'si_gun_gu': siGunGu,
        'dong': dong,
        'detail_address': detailAddress,
        'road_address': roadAddress,
        'jibun_address': jibunAddress,
        'latitude': latitude,
        'longitude': longitude,
        'status': status,
      };

  /// 표시용 한 줄 주소 (시/도 시/군/구 동 등)
  String get addressLine {
    final parts = [siDo, siGunGu, if (dong != null && dong!.isNotEmpty) dong];
    return parts.where((e) => e != null && e.toString().isNotEmpty).join(' ');
  }
}
