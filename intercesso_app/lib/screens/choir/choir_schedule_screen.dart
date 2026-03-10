import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/choir_provider.dart';
import '../../models/choir_models.dart';

// ═══════════════════════════════════════════════════════════════
// 일정 목록 화면
// ═══════════════════════════════════════════════════════════════
class ChoirSchedulesScreen extends StatefulWidget {
  const ChoirSchedulesScreen({super.key});

  @override
  State<ChoirSchedulesScreen> createState() => _ChoirSchedulesScreenState();
}

class _ChoirSchedulesScreenState extends State<ChoirSchedulesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ScheduleType? _filterType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        final now = DateTime.now();
        final upcoming = choir.schedules
            .where((s) => s.startTime.isAfter(now))
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        final past = choir.schedules
            .where((s) => s.startTime.isBefore(now))
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('일정'),
            backgroundColor: AppTheme.surface,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF885CF6),
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: const Color(0xFF885CF6),
              tabs: const [
                Tab(text: '예정'),
                Tab(text: '지난 일정'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddScheduleSheet(context, choir),
            backgroundColor: const Color(0xFF885CF6),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('일정 추가',
                style: TextStyle(color: Colors.white)),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildScheduleList(context, upcoming, choir, isUpcoming: true),
              _buildScheduleList(context, past, choir, isUpcoming: false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScheduleList(BuildContext context,
      List<ChoirScheduleModel> schedules, ChoirProvider choir,
      {required bool isUpcoming}) {
    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.calendar_today : Icons.history,
              size: 48,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? '예정된 일정이 없어요' : '지난 일정이 없어요',
              style: const TextStyle(
                  fontSize: 15, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    // 날짜별로 그룹핑
    final grouped = <String, List<ChoirScheduleModel>>{};
    for (final s in schedules) {
      final key =
          '${s.startTime.year}년 ${s.startTime.month}월';
      grouped.putIfAbsent(key, () => []).add(s);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 8),
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            ...entry.value.map((s) => _buildScheduleCard(context, s)),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildScheduleCard(
      BuildContext context, ChoirScheduleModel schedule) {
    return GestureDetector(
      onTap: () => context.push('/choir/schedule/${schedule.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // 날짜 박스
            Container(
              width: 50,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF885CF6).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${schedule.startTime.month}월',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF885CF6)),
                  ),
                  Text(
                    '${schedule.startTime.day}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF885CF6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          schedule.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (schedule.isConfirmed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '확정',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF885CF6).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${schedule.scheduleType.emoji} ${schedule.scheduleType.label}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF885CF6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        schedule.formattedTime,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      if (schedule.location != null) ...[
                        const Text(' · ',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                        Text(
                          schedule.location!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary),
                        ),
                      ],
                    ],
                  ),
                  if (schedule.songs.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '🎵 ${schedule.songs.map((s) => s.title).join(', ')}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }

  // ── 일정 추가 바텀시트 ────────────────────────────────────────
  void _showAddScheduleSheet(BuildContext context, ChoirProvider choir) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddScheduleSheet(choir: choir),
    );
  }
}

// ───────────────────────────────────────────────────────────────
// 일정 추가 바텀시트
// ───────────────────────────────────────────────────────────────
class _AddScheduleSheet extends StatefulWidget {
  final ChoirProvider choir;
  const _AddScheduleSheet({required this.choir});

  @override
  State<_AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends State<_AddScheduleSheet> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();
  ScheduleType _type = ScheduleType.rehearsal;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 0);

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  '일정 추가',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 제목
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '일정 제목 *',
                hintText: '예) 주일예배 찬양',
              ),
            ),
            const SizedBox(height: 12),
            // 타입 선택
            const Text('일정 종류',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ScheduleType.values.map((type) {
                final selected = _type == type;
                return ChoiceChip(
                  label: Text('${type.emoji} ${type.label}'),
                  selected: selected,
                  onSelected: (_) => setState(() => _type = type),
                  selectedColor: const Color(0xFF885CF6).withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: selected
                        ? const Color(0xFF885CF6)
                        : AppTheme.textSecondary,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w400,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // 날짜/시간
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            '${_date.month}/${_date.day}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _time,
                      );
                      if (picked != null) setState(() => _time = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            _time.format(context),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 장소
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '장소',
                hintText: '예) 본당, 찬양실',
              ),
            ),
            const SizedBox(height: 12),
            // 내용
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '내용 (선택)',
                hintText: '연습 곡목이나 안내사항을 입력하세요',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF885CF6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('일정 등록',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정 제목을 입력해주세요')),
      );
      return;
    }
    final choirId = widget.choir.selectedChoir?.id ?? '';
    final startTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    final ok = await widget.choir.addSchedule(
      choirId: choirId,
      title: _titleController.text.trim(),
      scheduleType: _type,
      startTime: startTime,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
    );
    if (ok && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정이 등록되었습니다')),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 일정 상세 화면
// ═══════════════════════════════════════════════════════════════
class ChoirScheduleDetailScreen extends StatefulWidget {
  final String scheduleId;
  const ChoirScheduleDetailScreen({super.key, required this.scheduleId});

  @override
  State<ChoirScheduleDetailScreen> createState() =>
      _ChoirScheduleDetailScreenState();
}

class _ChoirScheduleDetailScreenState
    extends State<ChoirScheduleDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChoirProvider>().loadAttendance(widget.scheduleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChoirProvider>(
      builder: (context, choir, _) {
        final schedule = choir.schedules.firstWhere(
          (s) => s.id == widget.scheduleId,
          orElse: () => ChoirScheduleModel(
            id: widget.scheduleId,
            choirId: '',
            title: '일정',
            scheduleType: ScheduleType.rehearsal,
            startTime: DateTime.now(),
            createdById: '',
            createdAt: '',
          ),
        );

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            slivers: [
              _buildDetailAppBar(context, schedule),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(schedule),
                      const SizedBox(height: 16),
                      if (schedule.songs.isNotEmpty) ...[
                        _buildSongsCard(schedule),
                        const SizedBox(height: 16),
                      ],
                      _buildAttendanceSummary(context, choir),
                      const SizedBox(height: 16),
                      _buildActionButtons(context, schedule),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailAppBar(
      BuildContext context, ChoirScheduleModel schedule) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: const Color(0xFF885CF6),
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF885CF6), Color(0xFF6D3FD4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${schedule.scheduleType.emoji} ${schedule.scheduleType.label}',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ChoirScheduleModel schedule) {
    return Container(
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
          _infoRow(Icons.calendar_today, '날짜', schedule.formattedDate),
          const Divider(height: 20),
          _infoRow(Icons.access_time, '시간', schedule.formattedTime),
          if (schedule.location != null) ...[
            const Divider(height: 20),
            _infoRow(Icons.location_on, '장소', schedule.location!),
          ],
          if (schedule.description != null) ...[
            const Divider(height: 20),
            _infoRow(Icons.notes, '내용', schedule.description!),
          ],
          const Divider(height: 20),
          _infoRow(
            Icons.check_circle_outline,
            '상태',
            schedule.isConfirmed ? '확정' : '미확정',
            valueColor: schedule.isConfirmed
                ? const Color(0xFF10B981)
                : AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSongsCard(ChoirScheduleModel schedule) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎵 찬양 곡목',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...schedule.songs.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF885CF6).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF885CF6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.value.title,
                      style: const TextStyle(
                          fontSize: 14, color: AppTheme.textPrimary),
                    ),
                  ),
                  if (e.value.youtubeUrl != null)
                    const Icon(Icons.play_circle_outline,
                        size: 18, color: Color(0xFFFF0000)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary(BuildContext context, ChoirProvider choir) {
    final total = choir.attendances.length;
    final present =
        choir.attendances.where((a) => a.status == AttendanceStatus.present).length;
    final absent =
        choir.attendances.where((a) => a.status == AttendanceStatus.absent).length;
    final excused =
        choir.attendances.where((a) => a.status == AttendanceStatus.excused).length;
    final rate = total > 0 ? (present / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '출석 현황',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    context.push('/choir/attendance/${widget.scheduleId}'),
                child: const Text('출석 체크'),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF885CF6)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statBox('출석율', '$rate%', const Color(0xFF10B981)),
              _statBox('출석', '$present명', const Color(0xFF2F6FED)),
              _statBox('결석', '$absent명', const Color(0xFFEF4444)),
              _statBox('공결', '$excused명', const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
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

  Widget _buildActionButtons(
      BuildContext context, ChoirScheduleModel schedule) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                context.push('/choir/attendance/${schedule.id}'),
            icon: const Icon(Icons.how_to_reg),
            label: const Text('출석 체크'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF885CF6),
              side: const BorderSide(color: Color(0xFF885CF6)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.share),
            label: const Text('공유'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF885CF6),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
