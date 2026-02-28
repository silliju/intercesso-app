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
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  PrayerModel? _prayer;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPrayer();
  }

  Future<void> _loadPrayer() async {
    final prayer = await _service.getPrayerById(widget.prayerId);
    _titleController.text = prayer.title;
    _contentController.text = prayer.content;
    setState(() {
      _prayer = prayer;
      _isLoading = false;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await _service.updatePrayer(
        widget.prayerId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
      );
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기도가 수정되었습니다'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingWidget());
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('기도 수정'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            child: const Text('저장', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('제목', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: '기도 제목'),
                validator: (v) => v?.isEmpty == true ? '제목을 입력해주세요' : null,
              ),
              const SizedBox(height: 16),
              const Text('내용', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(hintText: '기도 내용'),
                maxLines: 8,
                validator: (v) => v?.isEmpty == true ? '내용을 입력해주세요' : null,
              ),
              const SizedBox(height: 32),
              GradientButton(text: '수정 완료', onPressed: _handleSubmit, isLoading: _isSubmitting),
            ],
          ),
        ),
      ),
    );
  }
}
