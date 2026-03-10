import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/choir_provider.dart';
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
    return Consumer<ChoirProvider>(
      builder: (context, choir, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('자료실'),
            backgroundColor: AppTheme.surface,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF885CF6),
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: const Color(0xFF885CF6),
              tabs: const [
                Tab(text: '악보'),
                Tab(text: '영상'),
                Tab(text: '전체'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showUploadSheet(context),
            backgroundColor: const Color(0xFF885CF6),
            child: const Icon(Icons.upload, color: Colors.white),
          ),
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
                      color: const Color(0xFF885CF6).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      file.targetSection!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF885CF6),
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
                    color: Color(0xFFFF0000), size: 28),
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
      case 'score':    return const Color(0xFF2F6FED);
      case 'video':    return const Color(0xFFEF4444);
      case 'audio':    return const Color(0xFF10B981);
      case 'document': return const Color(0xFFF59E0B);
      default:         return const Color(0xFF885CF6);
    }
  }

  void _openUrl(String url) => openUrl(context, url);

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '자료 등록',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ...[
                ('🎵', '악보 업로드', '악보 파일을 업로드합니다', 'score'),
                ('🎬', '영상 링크', 'YouTube 링크를 등록합니다', 'video'),
                ('📄', '문서 업로드', '공지나 문서를 업로드합니다', 'document'),
                ('🎧', '음원 등록', '반주나 연습 음원을 등록합니다', 'audio'),
              ].map((item) {
                return ListTile(
                  leading: Text(item.$1,
                      style: const TextStyle(fontSize: 28)),
                  title: Text(item.$2,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(item.$3,
                      style: const TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 파일 업로드 처리
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
