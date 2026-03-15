import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _churchController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isSubmitting = false;
  /// 선택한 이미지 바이트 (웹/모바일 공통, Image.memory 사용)
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nicknameController.text = user.nickname;
      _churchController.text = user.churchName ?? '';
      _bioController.text = user.bio ?? '';
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _churchController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Widget _buildAvatarPlaceholder(dynamic user) {
    final nickname = user?.nickname?.toString() ?? '';
    return Container(
      width: 104,
      height: 104,
      color: AppTheme.primaryLight,
      alignment: Alignment.center,
      child: Text(
        nickname.isNotEmpty ? nickname[0] : '?',
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppTheme.primary),
                title: const Text('카메라로 촬영'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final img = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 70,
                    maxWidth: 512,
                    maxHeight: 512,
                  );
                  if (img != null) {
                    final bytes = await img.readAsBytes();
                    if (mounted) setState(() => _selectedImageBytes = bytes);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primary),
                title: const Text('갤러리에서 선택'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final img = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 70,
                    maxWidth: 512,
                    maxHeight: 512,
                  );
                  if (img != null) {
                    final bytes = await img.readAsBytes();
                    if (mounted) setState(() => _selectedImageBytes = bytes);
                  }
                },
              ),
              if (_selectedImageBytes != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppTheme.error),
                  title: const Text('사진 제거', style: TextStyle(color: AppTheme.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedImageBytes = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      String? profileImageUrl;

      // 이미지 선택된 경우 base64로 인코딩해서 전송
      if (_selectedImageBytes != null) {
        final base64Image = base64Encode(_selectedImageBytes!);
        profileImageUrl = 'data:image/jpeg;base64,$base64Image';
      }

      final body = <String, dynamic>{
        'nickname': _nicknameController.text.trim(),
        'church_name': _churchController.text.isEmpty ? null : _churchController.text.trim(),
        'bio': _bioController.text.isEmpty ? null : _bioController.text.trim(),
        if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      };

      final response = await _api.put('/users/me', body: body);

      // AuthProvider 유저 정보 갱신
      if (mounted && response['success'] == true) {
        await context.read<AuthProvider>().refreshUser();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 수정되었습니다'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('프로필 수정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 사진 선택 (선택한 파일 즉시 미리보기, 저장 후 URL도 정상 표시)
              Center(
                child: Stack(
                  children: [
                    SizedBox(
                      width: 104,
                      height: 104,
                      child: ClipOval(
                        child: _selectedImageBytes != null
                            ? Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                                width: 104,
                                height: 104,
                                errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(user),
                              )
                            : (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: user.profileImageUrl!,
                                    fit: BoxFit.cover,
                                    width: 104,
                                    height: 104,
                                    placeholder: (_, __) => _buildAvatarPlaceholder(user),
                                    errorWidget: (_, __, ___) => _buildAvatarPlaceholder(user),
                                  )
                                : _buildAvatarPlaceholder(user)),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('사진을 탭해서 변경하세요',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ),
              const SizedBox(height: 28),

              const Text('닉네임',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(hintText: '닉네임'),
                validator: (v) => v?.isEmpty == true ? '닉네임을 입력해주세요' : null,
              ),
              const SizedBox(height: 16),
              const Text('교회명',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _churchController,
                decoration: const InputDecoration(hintText: '교회 이름 (선택사항)'),
              ),
              const SizedBox(height: 16),
              const Text('자기소개',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(hintText: '간단한 자기소개 (선택사항)'),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              GradientButton(
                  text: '저장하기',
                  onPressed: _handleSubmit,
                  isLoading: _isSubmitting),
            ],
          ),
        ),
      ),
    );
  }
}
