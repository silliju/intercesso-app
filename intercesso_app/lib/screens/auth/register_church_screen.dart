import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/church_service.dart';
import '../../utils/address_search_popup.dart';
import '../../widgets/daum_address_webview.dart';

/// 회원가입 중 "교회가 없어요. 직접 등록하기" 시 표시.
/// 주소는 다음(카카오) 주소 API WebView로 검색 후 선택 시 폼에 자동 입력.
class RegisterChurchScreen extends StatefulWidget {
  const RegisterChurchScreen({super.key});

  @override
  State<RegisterChurchScreen> createState() => _RegisterChurchScreenState();
}

class _RegisterChurchScreenState extends State<RegisterChurchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _denominationCtrl = TextEditingController();
  final _pastorCtrl = TextEditingController();
  final _addressKeywordCtrl = TextEditingController();
  final _siDoCtrl = TextEditingController();
  final _siGunGuCtrl = TextEditingController();
  final _dongCtrl = TextEditingController();
  final _detailAddressCtrl = TextEditingController();
  final _roadAddressCtrl = TextEditingController();
  final _jibunAddressCtrl = TextEditingController();

  bool _isSubmitting = false;

  final _churchService = ChurchService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _denominationCtrl.dispose();
    _pastorCtrl.dispose();
    _addressKeywordCtrl.dispose();
    _siDoCtrl.dispose();
    _siGunGuCtrl.dispose();
    _dongCtrl.dispose();
    _detailAddressCtrl.dispose();
    _roadAddressCtrl.dispose();
    _jibunAddressCtrl.dispose();
    super.dispose();
  }

  Future<void> _openAddressSearch() async {
    final baseUrl = AppConstants.addressSearchPageUrl;
    final keyword = _addressKeywordCtrl.text.trim();
    final url = keyword.isEmpty ? baseUrl : '$baseUrl?q=${Uri.encodeComponent(keyword)}';

    // 웹(Chrome)에서는 팝업 + postMessage로 주소 선택 결과 수신 (캐시 방지용 쿼리 추가)
    if (kIsWeb) {
      final popupUrl = '$url${url.contains('?') ? '&' : '?'}_=${DateTime.now().millisecondsSinceEpoch}';
      final result = await openAddressSearchPopup(popupUrl);
      if (result == null || !mounted) return;
      setState(() {
        _siDoCtrl.text = result['sido']?.toString() ?? '';
        _siGunGuCtrl.text = result['sigungu']?.toString() ?? '';
        _dongCtrl.text = result['bname']?.toString() ?? '';
        _roadAddressCtrl.text = result['roadAddress']?.toString() ?? '';
        _jibunAddressCtrl.text = result['jibunAddress']?.toString() ?? '';
        final building = result['buildingName']?.toString() ?? '';
        if (building.isNotEmpty) _detailAddressCtrl.text = building;
      });
      return;
    }

    // 모바일(Android/iOS)에서는 WebView 사용
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => DaumAddressWebView(url: url),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _siDoCtrl.text = result['sido']?.toString() ?? '';
      _siGunGuCtrl.text = result['sigungu']?.toString() ?? '';
      _dongCtrl.text = result['bname']?.toString() ?? '';
      _roadAddressCtrl.text = result['roadAddress']?.toString() ?? '';
      _jibunAddressCtrl.text = result['jibunAddress']?.toString() ?? '';
      final building = result['buildingName']?.toString() ?? '';
      if (building.isNotEmpty) _detailAddressCtrl.text = building;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final siDo = _siDoCtrl.text.trim();
    final siGunGu = _siGunGuCtrl.text.trim();
    if (name.isEmpty || siDo.isEmpty || siGunGu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('교회명, 시/도, 시/군/구는 필수입니다'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final church = await _churchService.create(
        name: name,
        denomination: _denominationCtrl.text.trim().isEmpty ? null : _denominationCtrl.text.trim(),
        pastorName: _pastorCtrl.text.trim().isEmpty ? null : _pastorCtrl.text.trim(),
        siDo: siDo,
        siGunGu: siGunGu,
        dong: _dongCtrl.text.trim().isEmpty ? null : _dongCtrl.text.trim(),
        detailAddress: _detailAddressCtrl.text.trim().isEmpty ? null : _detailAddressCtrl.text.trim(),
        roadAddress: _roadAddressCtrl.text.trim().isEmpty ? null : _roadAddressCtrl.text.trim(),
        jibunAddress: _jibunAddressCtrl.text.trim().isEmpty ? null : _jibunAddressCtrl.text.trim(),
      );
      if (mounted) context.pop(church);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('ApiException: ', '')),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('우리 교회 등록'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  '등록된 교회가 없을 때 직접 등록합니다. 주소는 정확히 입력해 주세요.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                _label('교회명', required: true),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    hintText: '예: 베다니교회, 충신교회',
                    prefixIcon: Icon(Icons.church_outlined, color: AppTheme.textLight, size: 20),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? '교회명을 입력해 주세요' : null,
                ),
                const SizedBox(height: 16),
                _label('교단', required: false),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _denominationCtrl,
                  decoration: const InputDecoration(
                    hintText: '예: 기독교대한감리회, 장로교(선택)',
                  ),
                ),
                const SizedBox(height: 16),
                _label('담임목사', required: false),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _pastorCtrl,
                  decoration: const InputDecoration(
                    hintText: '선택사항',
                  ),
                ),
                const SizedBox(height: 16),
                _label('주소 키워드', required: false),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addressKeywordCtrl,
                  decoration: const InputDecoration(
                    hintText: '예: 강남역, 역삼로 1, 사랑의교회',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _label('주소', required: true),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _openAddressSearch,
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('주소 찾기'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '다음 주소 검색에서 선택하면 자동으로 입력됩니다.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _siDoCtrl,
                  decoration: const InputDecoration(
                    labelText: '시/도',
                    hintText: '예: 서울특별시, 경기도',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? '시/도를 입력해 주세요' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _siGunGuCtrl,
                  decoration: const InputDecoration(
                    labelText: '시/군/구',
                    hintText: '예: 강남구, 수원시 영통구',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? '시/군/구를 입력해 주세요' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _dongCtrl,
                  decoration: const InputDecoration(
                    labelText: '동/읍/면 (선택)',
                    hintText: '예: 역삼동',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _detailAddressCtrl,
                  decoration: const InputDecoration(
                    labelText: '상세 주소 (번지, 건물명 등)',
                    hintText: '예: 테헤란로 123, 5층',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _roadAddressCtrl,
                  decoration: const InputDecoration(
                    labelText: '도로명 주소 (선택)',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _jibunAddressCtrl,
                  decoration: const InputDecoration(
                    labelText: '지번 주소 (선택)',
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('등록하고 이 교회 선택하기'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, {required bool required}) => Text(
        text + (required ? ' *' : ''),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      );
}
