import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/choir_provider.dart';
import '../../models/choir_models.dart';

// ═══════════════════════════════════════════════════════════════
// 찬양곡 관리 화면 (목록 + 등록 + 상세)
// ═══════════════════════════════════════════════════════════════
class ChoirSongScreen extends StatefulWidget {
  const ChoirSongScreen({super.key});

  @override
  State<ChoirSongScreen> createState() => _ChoirSongScreenState();
}

class _ChoirSongScreenState extends State<ChoirSongScreen> {
  String _searchQuery = '';
  String? _genreFilter;  // null = 전체
  String? _difficultyFilter;

  static const _genres = ['현대 찬양', '찬송가', '클래식', '복음성가', '기타'];
  static const _difficulties = ['easy', 'medium', 'hard'];

  @override
  Widget build(BuildContext context) {
    return Consumer<ChoirProvider>(
      builder: (context, choir, _) {
        final songs = _filtered(choir.songs);
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('찬양곡 관리'),
            backgroundColor: AppTheme.surface,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddSongSheet(context, choir),
                tooltip: '곡 추가',
              ),
            ],
          ),
          body: Column(
            children: [
              _buildSearchBar(),
              _buildFilterChips(),
              Expanded(
                child: songs.isEmpty
                    ? _buildEmpty()
                    : _buildSongList(context, songs, choir),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddSongSheet(context, choir),
            backgroundColor: const Color(0xFF885CF6),
            icon: const Icon(Icons.music_note, color: Colors.white),
            label: const Text('곡 추가',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }

  // ── 검색창 ──────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: '곡 제목, 작곡가 검색',
          prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
        ),
      ),
    );
  }

  // ── 필터 칩 ─────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          // 장르 필터
          _filterChip(
            label: _genreFilter ?? '장르 전체',
            active: _genreFilter != null,
            onTap: () => _showGenrePicker(),
          ),
          const SizedBox(width: 8),
          // 난이도 필터
          _filterChip(
            label: _difficultyFilter != null
                ? _diffLabel(_difficultyFilter!)
                : '난이도 전체',
            active: _difficultyFilter != null,
            onTap: () => _showDifficultyPicker(),
          ),
          if (_genreFilter != null || _difficultyFilter != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() {
                _genreFilter = null;
                _difficultyFilter = null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('초기화',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF885CF6).withOpacity(0.12)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF885CF6) : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? const Color(0xFF885CF6) : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── 곡 목록 ─────────────────────────────────────────────────
  Widget _buildSongList(
      BuildContext context, List<ChoirSongModel> songs, ChoirProvider choir) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: songs.length,
      itemBuilder: (ctx, i) => _buildSongCard(ctx, songs[i], choir),
    );
  }

  Widget _buildSongCard(
      BuildContext context, ChoirSongModel song, ChoirProvider choir) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showSongDetail(context, song, choir),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 아이콘
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF885CF6), Color(0xFFB084FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('🎵', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            song.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (song.difficulty != null)
                          _diffBadge(song.difficulty!),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (song.composer != null)
                      Text(
                        '작곡: ${song.composer}'
                            '${song.arranger != null ? ' / 편곡: ${song.arranger}' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    if (song.hymnBookRef != null)
                      Text(
                        song.hymnBookRef!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textLight,
                        ),
                      ),
                    const SizedBox(height: 6),
                    // 파트 + 장르
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (song.genre != null)
                          _tag(song.genre!, const Color(0xFF885CF6)),
                        ...song.parts.map((p) => _partTag(p)),
                      ],
                    ),
                  ],
                ),
              ),
              // YouTube 버튼
              if (song.youtubeUrl != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: IconButton(
                    icon: const Icon(
                      Icons.play_circle_filled,
                      color: Color(0xFFFF0000),
                      size: 30,
                    ),
                    onPressed: () => _openYoutube(song.youtubeUrl!),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _diffBadge(String diff) {
    final colors = {
      'easy': const Color(0xFF10B981),
      'medium': const Color(0xFFF59E0B),
      'hard': const Color(0xFFEF4444),
    };
    final color = colors[diff] ?? AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _diffLabel(diff),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _partTag(String part) {
    final map = {
      'soprano': ('소프라노', const Color(0xFFEC4899)),
      'alto': ('알토', const Color(0xFFEF4444)),
      'tenor': ('테너', const Color(0xFF3B82F6)),
      'bass': ('베이스', const Color(0xFF1D4ED8)),
    };
    final info = map[part] ?? (part, AppTheme.textSecondary);
    return _tag(info.$1, info.$2);
  }

  // ── 빈 상태 ─────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎼', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text(
            '등록된 찬양곡이 없어요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '찬양대에서 사용할 곡을 추가해보세요',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => _showAddSongSheet(context,
                Provider.of<ChoirProvider>(context, listen: false)),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('첫 곡 등록하기',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF885CF6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 곡 상세 바텀시트 ─────────────────────────────────────────
  void _showSongDetail(
      BuildContext context, ChoirSongModel song, ChoirProvider choir) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 핸들
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // 제목
                Row(
                  children: [
                    const Text('🎵', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        song.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppTheme.textSecondary),
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditSongSheet(context, song, choir);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFFEF4444)),
                      onPressed: () =>
                          _confirmDelete(context, song, choir),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 메타정보
                _detailRow('🎼', '장르', song.genre ?? '-'),
                if (song.composer != null)
                  _detailRow('✍️', '작곡', song.composer!),
                if (song.arranger != null)
                  _detailRow('🎹', '편곡', song.arranger!),
                if (song.hymnBookRef != null)
                  _detailRow('📖', '찬송가', song.hymnBookRef!),
                _detailRow('📊', '난이도', song.difficultyLabel),
                const SizedBox(height: 12),
                // 파트
                const Text('파트',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: song.parts.map((p) => _partTag(p)).toList(),
                ),
                // 노트
                if (song.notes != null && song.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('메모',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      song.notes!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
                // YouTube 링크
                if (song.youtubeUrl != null) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openYoutube(song.youtubeUrl!),
                      icon: const Icon(Icons.play_circle_filled,
                          color: Color(0xFFFF0000)),
                      label: const Text('YouTube에서 듣기'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            '$label:  ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ── 곡 추가 시트 ─────────────────────────────────────────────
  void _showAddSongSheet(BuildContext context, ChoirProvider choir) {
    _showSongFormSheet(context, choir, null);
  }

  void _showEditSongSheet(
      BuildContext context, ChoirSongModel song, ChoirProvider choir) {
    _showSongFormSheet(context, choir, song);
  }

  void _showSongFormSheet(
      BuildContext context, ChoirProvider choir, ChoirSongModel? existing) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final composerCtrl = TextEditingController(text: existing?.composer ?? '');
    final arrangerCtrl = TextEditingController(text: existing?.arranger ?? '');
    final hymnCtrl = TextEditingController(text: existing?.hymnBookRef ?? '');
    final youtubeCtrl =
        TextEditingController(text: existing?.youtubeUrl ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    String? selectedGenre = existing?.genre;
    String selectedDiff = existing?.difficulty ?? 'medium';
    final selectedParts = Set<String>.from(existing?.parts ?? []);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 40,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 핸들
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  existing == null ? '찬양곡 추가' : '곡 정보 수정',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                // 곡 제목 (필수)
                _formField(titleCtrl, '곡 제목 *', required: true),
                const SizedBox(height: 12),
                // 작곡가
                _formField(composerCtrl, '작곡가'),
                const SizedBox(height: 12),
                // 편곡자
                _formField(arrangerCtrl, '편곡자'),
                const SizedBox(height: 12),
                // 찬송가 번호
                _formField(hymnCtrl, '찬송가 번호 (예: 찬송가 19장)'),
                const SizedBox(height: 12),
                // YouTube URL
                _formField(youtubeCtrl, 'YouTube 링크',
                    hint: 'https://youtu.be/...'),
                const SizedBox(height: 16),
                // 장르 선택
                const Text('장르',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _genres.map((g) {
                    final active = selectedGenre == g;
                    return GestureDetector(
                      onTap: () => setSheetState(
                          () => selectedGenre = active ? null : g),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF885CF6).withOpacity(0.12)
                              : AppTheme.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? const Color(0xFF885CF6)
                                : AppTheme.border,
                          ),
                        ),
                        child: Text(
                          g,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? const Color(0xFF885CF6)
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // 난이도
                const Text('난이도',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: _difficulties.map((d) {
                    final active = selectedDiff == d;
                    final colors = {
                      'easy': const Color(0xFF10B981),
                      'medium': const Color(0xFFF59E0B),
                      'hard': const Color(0xFFEF4444),
                    };
                    final c = colors[d]!;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setSheetState(() => selectedDiff = d),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color:
                                active ? c.withOpacity(0.12) : AppTheme.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: active ? c : AppTheme.border),
                          ),
                          child: Center(
                            child: Text(
                              _diffLabel(d),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: active ? c : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // 파트 선택
                const Text('파트 (복수 선택)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['soprano', 'alto', 'tenor', 'bass']
                      .map((p) {
                    final active = selectedParts.contains(p);
                    return GestureDetector(
                      onTap: () => setSheetState(() {
                        if (active) {
                          selectedParts.remove(p);
                        } else {
                          selectedParts.add(p);
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF885CF6).withOpacity(0.12)
                              : AppTheme.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? const Color(0xFF885CF6)
                                : AppTheme.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (active)
                              const Icon(Icons.check,
                                  size: 14,
                                  color: Color(0xFF885CF6)),
                            if (active) const SizedBox(width: 4),
                            Text(
                              _partLabel(p),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? const Color(0xFF885CF6)
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // 메모
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: '메모 (선택)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                // 저장 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (titleCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content: Text('곡 제목을 입력해주세요')),
                              );
                              return;
                            }
                            setSheetState(() => isSaving = true);
                            try {
                              if (existing == null) {
                                await choir.addSong(
                                  title: titleCtrl.text.trim(),
                                  composer: composerCtrl.text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : composerCtrl.text.trim(),
                                  arranger: arrangerCtrl.text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : arrangerCtrl.text.trim(),
                                  hymnBookRef: hymnCtrl.text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : hymnCtrl.text.trim(),
                                  youtubeUrl: youtubeCtrl.text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : youtubeCtrl.text.trim(),
                                  genre: selectedGenre,
                                  difficulty: selectedDiff,
                                  parts: selectedParts.toList(),
                                  notes: notesCtrl.text.trim().isEmpty
                                      ? null
                                      : notesCtrl.text.trim(),
                                );
                              } else {
                                await choir.updateSong(
                                  songId: existing.id,
                                  title: titleCtrl.text.trim(),
                                  composer: composerCtrl.text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : composerCtrl.text.trim(),
                                  arranger: arrangerCtrl.text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : arrangerCtrl.text.trim(),
                                  hymnBookRef: hymnCtrl.text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : hymnCtrl.text.trim(),
                                  youtubeUrl: youtubeCtrl.text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : youtubeCtrl.text.trim(),
                                  genre: selectedGenre,
                                  difficulty: selectedDiff,
                                  parts: selectedParts.toList(),
                                  notes: notesCtrl.text.trim().isEmpty
                                      ? null
                                      : notesCtrl.text.trim(),
                                );
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              setSheetState(() => isSaving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                      content: Text('저장 실패: $e')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF885CF6),
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            existing == null ? '찬양곡 추가' : '수정 완료',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formField(
    TextEditingController ctrl,
    String label, {
    String? hint,
    bool required = false,
  }) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }

  // ── 삭제 확인 ─────────────────────────────────────────────────
  void _confirmDelete(
      BuildContext context, ChoirSongModel song, ChoirProvider choir) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('곡 삭제'),
        content: Text('"${song.title}" 을(를) 목록에서 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // dialog
              Navigator.pop(context); // detail sheet
              await choir.deleteSong(song.id);
            },
            child: const Text('삭제',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  // ── 필터 피커 ─────────────────────────────────────────────────
  void _showGenrePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const Text('장르 선택',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('전체'),
            trailing:
                _genreFilter == null ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() => _genreFilter = null);
              Navigator.pop(context);
            },
          ),
          ..._genres.map((g) => ListTile(
                title: Text(g),
                trailing: _genreFilter == g
                    ? const Icon(Icons.check,
                        color: Color(0xFF885CF6))
                    : null,
                onTap: () {
                  setState(() => _genreFilter = g);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDifficultyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const Text('난이도 선택',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('전체'),
            trailing: _difficultyFilter == null
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              setState(() => _difficultyFilter = null);
              Navigator.pop(context);
            },
          ),
          ..._difficulties.map((d) => ListTile(
                title: Text(_diffLabel(d)),
                trailing: _difficultyFilter == d
                    ? const Icon(Icons.check,
                        color: Color(0xFF885CF6))
                    : null,
                onTap: () {
                  setState(() => _difficultyFilter = d);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── 유틸 ─────────────────────────────────────────────────────
  List<ChoirSongModel> _filtered(List<ChoirSongModel> songs) {
    var result = songs;
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((s) =>
              s.title.contains(_searchQuery) ||
              (s.composer?.contains(_searchQuery) ?? false))
          .toList();
    }
    if (_genreFilter != null) {
      result = result.where((s) => s.genre == _genreFilter).toList();
    }
    if (_difficultyFilter != null) {
      result =
          result.where((s) => s.difficulty == _difficultyFilter).toList();
    }
    return result;
  }

  String _diffLabel(String diff) {
    switch (diff) {
      case 'easy':   return '쉬움';
      case 'medium': return '보통';
      case 'hard':   return '어려움';
      default:       return diff;
    }
  }

  String _partLabel(String part) {
    switch (part) {
      case 'soprano': return '소프라노';
      case 'alto':    return '알토';
      case 'tenor':   return '테너';
      case 'bass':    return '베이스';
      default:        return part;
    }
  }

  void _openYoutube(String url) {
    // TODO: url_launcher 패키지로 실제 URL 열기
    debugPrint('Opening YouTube: $url');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('YouTube: $url'),
        action: SnackBarAction(label: '확인', onPressed: () {}),
      ),
    );
  }
}
