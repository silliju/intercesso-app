import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/gratitude_provider.dart';
import '../../providers/prayer_provider.dart';

class CreateGratitudeScreen extends StatefulWidget {
  final GratitudeModel? existing; // 오늘 이미 작성한 경우 수정 모드
  const CreateGratitudeScreen({super.key, this.existing});

  @override
  State<CreateGratitudeScreen> createState() => _CreateGratitudeScreenState();
}

class _CreateGratitudeScreenState extends State<CreateGratitudeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _g1Controller = TextEditingController();
  final _g2Controller = TextEditingController();
  final _g3Controller = TextEditingController();

  String? _selectedEmotion;
  String _scope = 'private';
  String? _linkedPrayerId;
  String? _linkedPrayerTitle;
  bool _isSaving = false;

  static const _emotions = [
    {'key': 'joy', 'label': '기쁨', 'emoji': '😊'},
    {'key': 'peace', 'label': '평안', 'emoji': '🕊️'},
    {'key': 'moved', 'label': '감격', 'emoji': '😭'},
    {'key': 'thankful', 'label': '감사', 'emoji': '🙌'},
  ];

  static const _scopes = [
    {'key': 'private', 'label': '나만 보기', 'icon': Icons.lock_outline},
    {'key': 'group', 'label': '그룹 공개', 'icon': Icons.group_outlined},
    {'key': 'public', 'label': '전체 공개', 'icon': Icons.public_outlined},
  ];

  // 은혜 기록 색상 (가이드: 감사는 gamsa, 찬양/특수는 seonggadae)
  static Color get _gratitudeColor => AppTheme.seonggadae;
  static Color get _gratitudeLightColor => AppTheme.gamsaLight;
  static Color get _gratitudeAccentColor => AppTheme.seonggadaeDark;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _g1Controller.text = e.gratitude1;
      _g2Controller.text = e.gratitude2 ?? '';
      _g3Controller.text = e.gratitude3 ?? '';
      _selectedEmotion = e.emotion;
      _scope = e.scope;
      _linkedPrayerId = e.linkedPrayerId;
      // 연결된 기도 제목도 함께 로드
      if (e.linkedPrayer != null) {
        _linkedPrayerTitle = e.linkedPrayer!['title']?.toString();
      }
    }
  }

  @override
  void dispose() {
    _g1Controller.dispose();
    _g2Controller.dispose();
    _g3Controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final provider = context.read<GratitudeProvider>();
    final journal = await provider.saveJournal(
      gratitude1: _g1Controller.text.trim(),
      gratitude2: _g2Controller.text.trim().isEmpty ? null : _g2Controller.text.trim(),
      gratitude3: _g3Controller.text.trim().isEmpty ? null : _g3Controller.text.trim(),
      emotion: _selectedEmotion,
      linkedPrayerId: _linkedPrayerId,
      scope: _scope,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;
    if (journal != null) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Text('🙏', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('은혜 기록이 저장되었어요! 🎵', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: _gratitudeAccentColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? '저장 실패'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildGratitudeSection(),
                  const SizedBox(height: 16),
                  _buildEmotionSection(),
                  const SizedBox(height: 16),
                  _buildPrayerLinkSection(),
                  const SizedBox(height: 16),
                  _buildScopeSection(),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: _gratitudeColor,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.seonggadae, AppTheme.seonggadaeDark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _todayDateString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '오늘의 은혜 기록 🎵',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    '오늘 받은 은혜 3가지를 기록해 보세요',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGratitudeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildGratitudeField(
              controller: _g1Controller,
              number: 1,
              hint: '오늘 받은 첫 번째 은혜를 써보세요',
              required: true,
              showDivider: true,
            ),
            _buildGratitudeField(
              controller: _g2Controller,
              number: 2,
              hint: '두 번째 받은 은혜 (선택)',
              required: false,
              showDivider: true,
            ),
            _buildGratitudeField(
              controller: _g3Controller,
              number: 3,
              hint: '세 번째 받은 은혜 (선택)',
              required: false,
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGratitudeField({
    required TextEditingController controller,
    required int number,
    required String hint,
    required bool required,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.seonggadae, AppTheme.seonggadaeDark],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                  validator: required
                      ? (v) => (v == null || v.trim().isEmpty) ? '첫 번째 감사 내용을 입력해주세요' : null
                      : null,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: AppColors.borderLight),
      ],
    );
  }

  Widget _buildEmotionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '오늘의 감정',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emotions.map((e) {
                final isSelected = _selectedEmotion == e['key'];
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedEmotion = isSelected ? null : e['key'] as String;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? _gratitudeColor : AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: isSelected ? _gratitudeColor : AppTheme.border,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e['emoji'] as String, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          e['label'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.primaryContrast : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerLinkSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.link_rounded, color: AppTheme.primary, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  '기도 응답과 연결하기',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Text(
                  '선택',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
            if (_linkedPrayerId != null && _linkedPrayerTitle != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.volunteer_activism_rounded, color: AppTheme.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _linkedPrayerTitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _linkedPrayerId = null;
                        _linkedPrayerTitle = null;
                      }),
                      child: const Icon(Icons.close_rounded, color: AppTheme.primary, size: 18),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _selectLinkedPrayer,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.grey.shade400, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '기도제목 선택하기',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScopeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '공개 범위',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _scopes.map((s) {
                final isSelected = _scope == s['key'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _scope = s['key'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(
                        right: s['key'] != 'public' ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? _gratitudeLightColor : AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _gratitudeColor : AppTheme.border,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            s['icon'] as IconData,
                            color: isSelected ? _gratitudeAccentColor : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? _gratitudeAccentColor : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _gratitudeColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  '🎵 은혜 기록하기',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }

  String _todayDateString() {
    final now = DateTime.now();
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[now.weekday - 1];
    return '${now.year}년 ${now.month}월 ${now.day}일 $weekday요일';
  }

  Future<void> _selectLinkedPrayer() async {
    final prayerProvider = context.read<PrayerProvider>();
    // 내 기도 목록에서 선택
    final prayers = prayerProvider.homePrayers;
    if (prayers.isEmpty) return;

    final selected = await showModalBottomSheet<PrayerModel>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PrayerSelectSheet(prayers: prayers),
    );

    if (selected != null) {
      setState(() {
        _linkedPrayerId = selected.id;
        _linkedPrayerTitle = selected.title;
      });
    }
  }
}

// ── 기도 선택 바텀시트 ─────────────────────────────────────────
class _PrayerSelectSheet extends StatelessWidget {
  final List<PrayerModel> prayers;
  const _PrayerSelectSheet({required this.prayers});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '기도제목 선택',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const Divider(height: 1),
          ...prayers.take(8).map((p) => ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.volunteer_activism_rounded, color: AppTheme.primary, size: 18),
                ),
                title: Text(
                  p.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  p.status == 'answered' ? '✅ 응답받음' : '🙏 기도 중',
                  style: TextStyle(
                    fontSize: 12,
                    color: p.status == 'answered' ? AppTheme.success : AppTheme.textSecondary,
                  ),
                ),
                onTap: () => Navigator.pop(context, p),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
