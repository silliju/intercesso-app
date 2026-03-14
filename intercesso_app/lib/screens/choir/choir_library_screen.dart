import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/choir_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/choir_models.dart';
import '../../utils/url_utils.dart';

// ═══════════════════════════════════════════════════════════════
// 자료실 화면 (악보 + 영상 + 파일)
// ═══════════════════════════════════════════════════════════════
class ChoirLibraryScreen extends StatefulWidget {
  const ChoirLibraryScreen({super.key});

  @override
  State<ChoirLibraryScreen> createState() => _ChoirLibraryScreenState();
}

class _ChoirLibraryScreenState extends State<ChoirLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChoirProvider, AuthProvider>(
      builder: (context, choir, auth, _) {
        final isAdmin = choir.isAdmin(auth.user?.id) || choir.isOwner(auth.user?.id);
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('자료실'),
            backgroundColor: AppTheme.surface,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppTheme.seonggadae,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.seonggadae,
              tabs: const [
                Tab(text: '악보'),
                Tab(text: '영상'),
                Tab(text: '전체'),
              ],
            ),
          ),
          floatingActionButton: isAdmin
              ? FloatingActionButton(
                  onPressed: () => _showUploadSheet(context),
                  backgroundColor: AppTheme.seonggadae,
                  child: const Icon(Icons.upload, color: Colors.white),
                )
              : null,
          body: Column(
            children: [
              // 검색창
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: '제목 검색',
                    prefixIcon: const Icon(Icons.search,
                        size: 20, color: AppTheme.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () =>
                                setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFileList(choir, 'score'),
                    _buildFileList(choir, 'video'),
                    _buildFileList(choir, null),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileList(ChoirProvider choir, String? fileType) {
    var files = fileType != null
        ? choir.files.where((f) => f.fileType == fileType).toList()
        : choir.files;

    if (_searchQuery.isNotEmpty) {
      files = files
          .where((f) => f.title.contains(_searchQuery))
          .toList();
    }

    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              fileType == 'score'
                  ? Icons.music_note
                  : fileType == 'video'
                      ? Icons.videocam
                      : Icons.folder,
              size: 48,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              fileType == 'score'
                  ? '등록된 악보가 없어요'
                  : fileType == 'video'
                      ? '등록된 영상이 없어요'
                      : '파일이 없어요',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: files.length,
      itemBuilder: (ctx, i) => _buildFileCard(ctx, files[i]),
    );
  }

  Widget _buildFileCard(BuildContext context, ChoirFileModel file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _fileTypeColor(file.fileType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(file.typeEmoji,
                style: const TextStyle(fontSize: 20)),
          ),
        ),
        title: Text(
          file.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _fileTypeColor(file.fileType)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    file.typeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: _fileTypeColor(file.fileType),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                if (file.targetSection != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.seonggadae.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      file.targetSection!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.seonggadae,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${file.uploaderName} · ${file.timeAgo}',
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (file.youtubeUrl != null)
              IconButton(
                icon: const Icon(Icons.play_circle_filled,
                    color: AppTheme.error, size: 28),
                onPressed: () => _openUrl(file.youtubeUrl!),
              )
            else if (file.fileUrl != null)
              IconButton(
                icon: const Icon(Icons.download,
                    color: AppTheme.textSecondary, size: 22),
                onPressed: () => _openUrl(file.fileUrl!),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _fileTypeColor(String type) {
    switch (type) {
      case 'score':    return AppTheme.primary;
      case 'video':    return AppTheme.error;
      case 'audio':    return AppTheme.success;
      case 'document': return AppTheme.warning;
      default:         return AppTheme.seonggadae;
    }
  }

  void _openUrl(String url) => openUrl(context, url);

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final choir = context.read<ChoirProvider>();
        return _UploadFileSheet(choir: choir);
      },
    );
  }
}

// ── 자료 등록 바텀시트 ─────────────────────────────────────────
class _UploadFileSheet extends StatefulWidget {
  final ChoirProvider choir;
  const _UploadFileSheet({required this.choir});

  @override
  State<_UploadFileSheet> createState() => _UploadFileSheetState();
}

class _UploadFileSheetState extends State<_UploadFileSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String _fileType = 'score';
  bool _isLoading = false;

  static const _types = [
    ('score', '🎵 악보'),
    ('video', '🎬 영상'),
    ('document', '📄 문서'),
    ('audio', '🎧 음원'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('제목을 입력해주세요')));
      return;
    }
    if (_urlCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('링크 또는 URL을 입력해주세요')));
      return;
    }

    setState(() => _isLoading = true);

    final isVideo = _fileType == 'video';
    final ok = await widget.choir.createFile(
      title: _titleCtrl.text.trim(),
      fileType: _fileType,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      youtubeUrl: isVideo ? _urlCtrl.text.trim() : null,
      fileUrl: isVideo ? null : _urlCtrl.text.trim(),
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 자료가 등록됐어요!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.choir.errorMessage ?? '등록에 실패했어요')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('자료 등록',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 12),
            // 유형 선택
            const Text('자료 유형',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _types.map((t) {
                final selected = _fileType == t.$1;
                return ChoiceChip(
                  label: Text(t.$2,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? AppTheme.seonggadae : AppTheme.textSecondary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      )),
                  selected: selected,
                  onSelected: (_) => setState(() => _fileType = t.$1),
                  selectedColor: AppTheme.seonggadae.withOpacity(0.12),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: '제목 *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlCtrl,
              decoration: InputDecoration(
                labelText: _fileType == 'video' ? 'YouTube URL *' : '파일 URL *',
                hintText: _fileType == 'video'
                    ? 'https://youtu.be/...'
                    : 'https://drive.google.com/...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: '설명 (선택)',
                hintText: '파트별 설명 등',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.seonggadae,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('자료 등록',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
