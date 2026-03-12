import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/prayer_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/common_widgets.dart';

class CreatePrayerScreen extends StatefulWidget {
  final String? groupId;
  const CreatePrayerScreen({super.key, this.groupId});

  @override
  State<CreatePrayerScreen> createState() => _CreatePrayerScreenState();
}

class _CreatePrayerScreenState extends State<CreatePrayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedScope = 'public';
  String? _selectedCategory;
  bool _isCovenant = false;
  int? _covenantDays;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<PrayerProvider>();
    final prayer = await provider.createPrayer(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      category: _selectedCategory,
      scope: _selectedScope,
      groupId: widget.groupId,
      isCovenant: _isCovenant,
      covenantDays: _covenantDays,
    );

    setState(() => _isSubmitting = false);

    if (prayer != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🙏 기도가 작성되었습니다'),
          backgroundColor: AppTheme.success,
        ),
      );
      context.pop();
    } else if (mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기도 작성'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '완료',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              const Text('기도 제목', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '기도 제목을 입력하세요',
                  counterText: '',
                ),
                maxLength: 100,
                validator: (v) => v?.isEmpty == true ? '제목을 입력해주세요' : null,
              ),
              const SizedBox(height: 16),
              // 내용
              const Text('기도 내용', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: '기도 내용을 자세히 작성해주세요...',
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                validator: (v) => v?.isEmpty == true ? '내용을 입력해주세요' : null,
              ),
              const SizedBox(height: 20),
              // 카테고리
              const Text('카테고리', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.prayerCategories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = isSelected ? null : cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : AppTheme.border,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // 공개 범위
              const Text('공개 범위', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              ...AppConstants.scopeLabels.entries.map((entry) {
                final isSelected = _selectedScope == entry.key;
                return RadioListTile<String>(
                  value: entry.key,
                  groupValue: _selectedScope,
                  onChanged: (v) => setState(() => _selectedScope = v!),
                  title: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  activeColor: AppTheme.primary,
                  contentPadding: EdgeInsets.zero,
                );
              }),
              const SizedBox(height: 20),
              // 작정기도
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isCovenant ? AppTheme.primaryLight : AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isCovenant ? AppTheme.primary.withOpacity(0.3) : AppTheme.border,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('🕯️', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '작정기도',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '날짜를 정해 매일 기도하는 약속',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isCovenant,
                          onChanged: (v) => setState(() => _isCovenant = v),
                          activeColor: AppTheme.primary,
                        ),
                      ],
                    ),
                    if (_isCovenant) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text(
                        '기도 기간 선택',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: AppConstants.covenantDayOptions.map((days) {
                          final isSelected = _covenantDays == days;
                          return GestureDetector(
                            onTap: () => setState(() => _covenantDays = days),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primary : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primary : AppTheme.border,
                                ),
                              ),
                              child: Text(
                                '$days일',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                text: '기도 등록하기 🙏',
                onPressed: _handleSubmit,
                isLoading: _isSubmitting,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
