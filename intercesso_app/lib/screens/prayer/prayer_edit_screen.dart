import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/prayer_service.dart';
import '../../models/models.dart';

class PrayerEditScreen extends StatefulWidget {
  final String prayerId;
  const PrayerEditScreen({super.key, required this.prayerId});

  @override
  State<PrayerEditScreen> createState() => _PrayerEditScreenState();
}

class _PrayerEditScreenState extends State<PrayerEditScreen> {
  final PrayerService _service = PrayerService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  PrayerModel? _prayer;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _category = '기타';
  String _scope = 'public';

  final List<Map<String, String>> _categories = [
    {'value': '건강', 'emoji': '💊'},
    {'value': '가정', 'emoji': '🏠'},
    {'value': '진로', 'emoji': '🎯'},
    {'value': '영적', 'emoji': '✝️'},
    {'value': '사업', 'emoji': '💼'},
    {'value': '기타', 'emoji': '🙏'},
  ];

  final List<Map<String, String>> _scopes = [
    {'value': 'public',    'label': '전체 공개',  'icon': '🌐'},
    {'value': 'friends',   'label': '지인 공개',  'icon': '👥'},
    {'value': 'community', 'label': '공동체',     'icon': '⛪'},
    {'value': 'private',   'label': '비공개',     'icon': '🔒'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPrayer();
  }

  Future<void> _loadPrayer() async {
    try {
      final prayer = await _service.getPrayerById(widget.prayerId);
      _titleController.text = prayer.title;
      _contentController.text = prayer.content;
      setState(() {
        _prayer = prayer;
        _category = prayer.category ?? '기타';
        _scope = prayer.scope ?? 'public';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) { _showSnack('제목을 입력해주세요', isError: true); return; }
    if (content.isEmpty) { _showSnack('내용을 입력해주세요', isError: true); return; }

    setState(() => _isSubmitting = true);
    try {
      await _service.updatePrayer(
        widget.prayerId,
        title: title,
        content: content,
        category: _category,
        scope: _scope,
      );
      if (mounted) {
        _showSnack('기도가 수정되었습니다 ✏️');
        context.pop();
      }
    } catch (e) {
      if (mounted) _showSnack('수정에 실패했습니다', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingWidget(message: '기도를 불러오는 중...'));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('기도 수정'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                : const Text('저장', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            _label('제목 *'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: _inputDeco('기도 제목을 입력하세요'),
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),

            // 내용
            _label('내용 *'),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              decoration: _inputDeco('기도 내용을 자세히 적어주세요'),
              maxLines: 6,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),

            // 카테고리
            _label('카테고리'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _category == cat['value'];
                return GestureDetector(
                  onTap: () => setState(() => _category = cat['value']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : AppTheme.surface,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : AppTheme.border,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '${cat['emoji']} ${cat['value']}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 공개 범위
            _label('공개 범위'),
            const SizedBox(height: 10),
            Container(
              decoration: AppTheme.cardDecoration,
              child: Column(
                children: _scopes.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  final isSelected = _scope == s['value'];
                  return Column(
                    children: [
                      ListTile(
                        leading: Text(s['icon']!, style: const TextStyle(fontSize: 20)),
                        title: Text(s['label']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppTheme.primary)
                            : const Icon(Icons.circle_outlined, color: AppTheme.border),
                        onTap: () => setState(() => _scope = s['value']!),
                      ),
                      if (i < _scopes.length - 1)
                        const Divider(height: 1, indent: 56),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            // 저장 버튼
            GradientButton(
              text: '수정 완료',
              onPressed: _handleSubmit,
              isLoading: _isSubmitting,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary));

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppTheme.textLight),
    filled: true,
    fillColor: AppTheme.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
