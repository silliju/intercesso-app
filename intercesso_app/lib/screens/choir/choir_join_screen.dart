import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/choir_provider.dart';
import '../../models/choir_models.dart';

// ═══════════════════════════════════════════════════════════════
// 찬양대 참여 화면 (초대 코드 / 링크)
// ═══════════════════════════════════════════════════════════════
class ChoirJoinScreen extends StatefulWidget {
  final String? initialCode; // 딥링크로 들어올 경우 코드 자동 입력
  const ChoirJoinScreen({super.key, this.initialCode});

  @override
  State<ChoirJoinScreen> createState() => _ChoirJoinScreenState();
}

class _ChoirJoinScreenState extends State<ChoirJoinScreen> {
  final _codeController = TextEditingController();
  bool _isSearching = false;
  bool _isJoining = false;
  ChoirModel? _foundChoir; // 코드로 찾은 찬양대 정보
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) {
      _codeController.text = widget.initialCode!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _searchChoir());
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('찬양대 참여'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 안내
            _buildHeader(),
            const SizedBox(height: 32),

            // 코드 입력
            _buildCodeInput(),
            const SizedBox(height: 16),

            // 검색 버튼
            _buildSearchButton(),
            const SizedBox(height: 24),

            // 찬양대 검색 결과
            if (_foundChoir != null) _buildChoirCard(),
            if (_errorMessage != null) _buildErrorCard(),

            const SizedBox(height: 32),

            // 구분선
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '또는',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),

            // 찬양대 만들기 링크
            _buildCreateLink(),
          ],
        ),
      ),
    );
  }

  // ── 상단 안내 ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.seonggadae.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.group_add,
              size: 32, color: AppTheme.seonggadae),
        ),
        const SizedBox(height: 20),
        const Text(
          '초대 코드로 참여하기',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '지휘자 또는 관리자에게 받은\n8자리 초대 코드를 입력해주세요',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ── 코드 입력 필드 ────────────────────────────────────────────
  Widget _buildCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '초대 코드',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          maxLength: 8,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: '초대 코드 입력',
            hintStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              letterSpacing: 4,
              color: AppTheme.textLight,
            ),
            counterText: '',
            suffixIcon: _codeController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _codeController.clear();
                      setState(() {
                        _foundChoir = null;
                        _errorMessage = null;
                      });
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.content_paste,
                        size: 18, color: AppTheme.textSecondary),
                    onPressed: _pasteFromClipboard,
                    tooltip: '클립보드에서 붙여넣기',
                  ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppTheme.seonggadae, width: 2),
            ),
          ),
          onChanged: (_) {
            setState(() {
              _foundChoir = null;
              _errorMessage = null;
            });
          },
          onSubmitted: (_) => _searchChoir(),
        ),
      ],
    );
  }

  // ── 검색 버튼 ─────────────────────────────────────────────────
  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSearching ? null : _searchChoir,
        icon: _isSearching
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.search, color: Colors.white),
        label: Text(
          _isSearching ? '검색 중...' : '찬양대 검색',
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.seonggadae,
          padding: const EdgeInsets.symmetric(vertical: 14),
          disabledBackgroundColor:
              AppTheme.seonggadae.withOpacity(0.5),
        ),
      ),
    );
  }

  // ── 찬양대 결과 카드 ──────────────────────────────────────────
  Widget _buildChoirCard() {
    final choir = _foundChoir!;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: AppTheme.seonggadae.withOpacity(0.3),
                width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.seonggadae.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.seonggadae, AppTheme.seonggadaeDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.music_note,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          choir.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          choir.churchName ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '✓ 찾았어요',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoItem('단원', '${choir.memberCount}명'),
                  if (choir.worshipType != null)
                    _infoItem('예배', choir.worshipType!),
                  _infoItem('상태', '모집 중'),
                ],
              ),
              if (choir.description != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    choir.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 가입 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isJoining ? null : _joinChoir,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isJoining
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text(
                    '🎵 가입 신청하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '관리자 승인 후 참여가 완료됩니다',
          style:
              TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
              fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  // ── 에러 카드 ─────────────────────────────────────────────────
  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppTheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 찬양대 만들기 링크 ────────────────────────────────────────
  Widget _buildCreateLink() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.seonggadae.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add,
                color: AppTheme.seonggadae, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '찬양대가 없으신가요?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '새 찬양대를 만들어보세요',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              context.push('/choir/create');
            },
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.seonggadae),
            child: const Text('만들기'),
          ),
        ],
      ),
    );
  }

  // ── 액션 ─────────────────────────────────────────────────────
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      final code = data!.text!.trim().toUpperCase();
      _codeController.text = code;
      setState(() {});
    }
  }

  Future<void> _searchChoir() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _errorMessage = '초대 코드를 입력해주세요');
      return;
    }
    if (code.length < 6) {
      setState(() => _errorMessage = '올바른 초대 코드 형식이 아니에요 (6~8자리)');
      return;
    }

    setState(() {
      _isSearching = true;
      _foundChoir = null;
      _errorMessage = null;
    });

    try {
      // 실제 API: 초대 코드로 찬양대 정보 조회
      final choirProvider = context.read<ChoirProvider>();
      final data = await choirProvider.lookupChoirByCode(code);

      if (!mounted) return;

      if (data == null) {
        setState(() => _errorMessage = '해당 코드의 찬양대를 찾을 수 없어요\n코드를 다시 확인해주세요');
      } else {
        setState(() {
          _foundChoir = ChoirModel(
            id: data['id'] ?? '',
            name: data['name'] ?? '',
            description: data['description'],
            churchName: data['church_name'],
            worshipType: data['worship_type'],
            ownerId: data['owner_id'] ?? '',
            inviteCode: data['invite_code'],
            memberCount: data['member_count'] ?? 0,
            createdAt: data['created_at'] ?? '',
          );
        });
      }
    } catch (e) {
      setState(() => _errorMessage = '검색 중 오류가 발생했어요\n잠시 후 다시 시도해주세요');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _joinChoir() async {
    if (_foundChoir == null) return;
    setState(() => _isJoining = true);

    try {
      // 실제 API: 초대 코드로 가입 신청
      final code = _foundChoir!.inviteCode ?? _codeController.text.trim().toUpperCase();
      final choirProvider = context.read<ChoirProvider>();
      final ok = await choirProvider.joinChoirByCode(code);

      if (!mounted) return;

      if (!ok) {
        setState(() => _isJoining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(choirProvider.errorMessage ?? '가입 신청에 실패했어요')),
        );
        return;
      }

      if (mounted) {
        // 성공 다이얼로그
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle,
                      color: AppTheme.success, size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  '가입 신청 완료!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_foundChoir!.name}에\n가입 신청을 보냈어요\n\n관리자 승인 후 참여가 완료됩니다',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/choir');
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success),
                    child: const Text('확인',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isJoining = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했어요: $e')),
        );
      }
    }
  }
}
