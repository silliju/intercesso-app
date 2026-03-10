import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/choir_provider.dart';
import '../../models/choir_models.dart';

// ═══════════════════════════════════════════════════════════════
// 찬양대 생성 화면
// ═══════════════════════════════════════════════════════════════
class ChoirCreateScreen extends StatefulWidget {
  const ChoirCreateScreen({super.key});

  @override
  State<ChoirCreateScreen> createState() => _ChoirCreateScreenState();
}

class _ChoirCreateScreenState extends State<ChoirCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _churchController = TextEditingController();
  final _descController = TextEditingController();
  final _worshipTypeController = TextEditingController();

  bool _isLoading = false;
  int _currentStep = 0; // 0: 기본정보, 1: 상세정보, 2: 완료

  // 예배 종류 프리셋
  final List<String> _worshipPresets = [
    '주일예배',
    '수요예배',
    '새벽예배',
    '청년예배',
    '어린이예배',
    '특별예배',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _churchController.dispose();
    _descController.dispose();
    _worshipTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('찬양대 만들기'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // 스텝 인디케이터
          _buildStepIndicator(),
          // 폼 내용
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: _currentStep == 0
                    ? _buildStep1()
                    : _currentStep == 1
                        ? _buildStep2()
                        : _buildStep3(),
              ),
            ),
          ),
          // 하단 버튼
          _buildBottomButton(),
        ],
      ),
    );
  }

  // ── 스텝 인디케이터 ──────────────────────────────────────────
  Widget _buildStepIndicator() {
    final steps = ['기본 정보', '상세 설정', '완료'];
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final i = entry.key;
          final label = entry.value;
          final isDone = i < _currentStep;
          final isActive = i == _currentStep;

          return Expanded(
            child: Row(
              children: [
                // 스텝 원
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFF10B981)
                        : isActive
                            ? const Color(0xFF885CF6)
                            : AppTheme.border,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive
                        ? const Color(0xFF885CF6)
                        : AppTheme.textSecondary,
                  ),
                ),
                // 연결선 (마지막 제외)
                if (i < steps.length - 1) ...[
                  const Spacer(),
                  Container(
                    height: 1,
                    width: 20,
                    color: isDone
                        ? const Color(0xFF10B981)
                        : AppTheme.border,
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Step 1: 기본 정보 ────────────────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '찬양대 기본 정보를\n입력해주세요',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),

        // 찬양대 이름
        _fieldLabel('찬양대 이름 *'),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: '예) 주일예배 찬양대',
            prefixIcon: Icon(Icons.music_note, color: Color(0xFF885CF6)),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? '찬양대 이름을 입력해주세요' : null,
        ),
        const SizedBox(height: 20),

        // 교회 이름
        _fieldLabel('교회 이름 *'),
        TextFormField(
          controller: _churchController,
          decoration: const InputDecoration(
            hintText: '예) 사랑교회',
            prefixIcon: Icon(Icons.church, color: AppTheme.textSecondary),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? '교회 이름을 입력해주세요' : null,
        ),
        const SizedBox(height: 20),

        // 예배 종류
        _fieldLabel('예배 종류'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _worshipPresets.map((preset) {
            final isSelected =
                _worshipTypeController.text == preset;
            return GestureDetector(
              onTap: () => setState(
                  () => _worshipTypeController.text = preset),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF885CF6)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF885CF6)
                        : AppTheme.border,
                  ),
                ),
                child: Text(
                  preset,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _worshipTypeController,
          decoration: const InputDecoration(
            hintText: '직접 입력하거나 위에서 선택',
          ),
        ),
      ],
    );
  }

  // ── Step 2: 상세 설정 ────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '찬양대를 소개해주세요',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '(선택사항이에요)',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 32),

        // 찬양대 소개
        _fieldLabel('찬양대 소개'),
        TextFormField(
          controller: _descController,
          maxLines: 4,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: '찬양대를 소개하는 글을 입력해주세요\n예) 매주 주일 예배를 섬기는 찬양대입니다',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 24),

        // 안내 카드
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF885CF6).withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF885CF6).withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Color(0xFF885CF6)),
                  SizedBox(width: 6),
                  Text(
                    '찬양대 생성 후 할 수 있는 것',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF885CF6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...[
                '단원 초대 링크 및 코드 발급',
                '일정 등록 및 관리',
                '출석 체크 및 통계',
                '악보, 영상 자료 공유',
              ].map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Text(
                          item,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 3: 완료 ────────────────────────────────────────────
  Widget _buildStep3() {
    return Column(
      children: [
        const SizedBox(height: 40),
        // 완료 아이콘
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF885CF6), Color(0xFF6D3FD4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF885CF6).withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.music_note,
              size: 48, color: Colors.white),
        ),
        const SizedBox(height: 28),
        Text(
          '${_nameController.text}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          '찬양대가 생성될 준비가 됐어요!',
          style: TextStyle(
            fontSize: 15,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 32),

        // 요약 카드
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _summaryRow('🎵', '찬양대', _nameController.text),
              const Divider(height: 20),
              _summaryRow('⛪', '교회', _churchController.text),
              if (_worshipTypeController.text.isNotEmpty) ...[
                const Divider(height: 20),
                _summaryRow(
                    '🙏', '예배', _worshipTypeController.text),
              ],
              if (_descController.text.isNotEmpty) ...[
                const Divider(height: 20),
                _summaryRow('📝', '소개', _descController.text),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String emoji, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // ── 하단 버튼 ────────────────────────────────────────────────
  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          // 이전 버튼 (step 1 제외)
          if (_currentStep > 0) ...[
            OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: const BorderSide(color: AppTheme.border),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
              ),
              child: const Text('이전'),
            ),
            const SizedBox(width: 12),
          ],
          // 다음/완료 버튼
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _onNextPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep == 2
                    ? const Color(0xFF10B981)
                    : const Color(0xFF885CF6),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      _currentStep == 2 ? '✨ 찬양대 만들기' : '다음',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 버튼 액션 ────────────────────────────────────────────────
  Future<void> _onNextPressed() async {
    if (_currentStep == 0) {
      if (_formKey.currentState?.validate() ?? false) {
        setState(() => _currentStep = 1);
      }
    } else if (_currentStep == 1) {
      setState(() => _currentStep = 2);
    } else {
      // 최종 생성
      await _createChoir();
    }
  }

  Future<void> _createChoir() async {
    setState(() => _isLoading = true);
    try {
      final choir = context.read<ChoirProvider>();
      // TODO: 실제 API 호출로 교체
      final newChoir = ChoirModel(
        id: 'choir_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        churchName: _churchController.text.trim(),
        worshipType: _worshipTypeController.text.trim().isEmpty
            ? null
            : _worshipTypeController.text.trim(),
        ownerId: 'current_user',
        inviteCode: 'CODE${DateTime.now().millisecondsSinceEpoch % 10000}',
        inviteLinkActive: true,
        memberCount: 1,
        createdAt: DateTime.now().toIso8601String(),
      );

      choir.myChoirs.add(newChoir);
      choir.selectChoir(newChoir);

      if (mounted) {
        // 성공 스낵바
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 ${newChoir.name} 찬양대가 생성됐어요!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        // 찬양대 홈으로 이동
        context.go('/choir');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했어요: $e')),
        );
      }
    }
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
