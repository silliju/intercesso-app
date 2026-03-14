import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/choir_provider.dart';
import '../../models/choir_models.dart';

// ═══════════════════════════════════════════════════════════════
// 출석 체크 화면
// ═══════════════════════════════════════════════════════════════
class ChoirAttendanceScreen extends StatefulWidget {
  final String scheduleId;
  const ChoirAttendanceScreen({super.key, required this.scheduleId});

  @override
  State<ChoirAttendanceScreen> createState() =>
      _ChoirAttendanceScreenState();
}

class _ChoirAttendanceScreenState extends State<ChoirAttendanceScreen> {
  ChoirSection _filterSection = ChoirSection.all;
  bool _isSaving = false;

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
            title: '출석',
            scheduleType: ScheduleType.rehearsal,
            startTime: DateTime.now(),
            createdById: '',
            createdAt: '',
          ),
        );

        final attendances = choir.attendances;
        final filtered = _filterSection == ChoirSection.all
            ? attendances
            : attendances
                .where((a) => a.section == _filterSection)
                .toList();

        final presentCount = attendances
            .where((a) => a.status == AttendanceStatus.present)
            .length;
        final total = attendances.length;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(schedule.title),
            backgroundColor: AppTheme.surface,
            elevation: 0,
            actions: [
              TextButton(
                onPressed: _isSaving ? null : () => _saveAttendance(context),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text(
                        '저장',
                        style: TextStyle(
                          color: AppTheme.seonggadae,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
          body: Column(
            children: [
              // 출석 요약 바
              _buildSummaryBar(presentCount, total),
              // 파트 필터
              _buildSectionFilter(),
              // 출석 목록
              Expanded(
                child: choir.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? const Center(
                            child: Text(
                              '출석 데이터가 없어요',
                              style: TextStyle(
                                  color: AppTheme.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) =>
                                _buildAttendanceRow(ctx, filtered[i], choir),
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _markAllPresent(choir),
            backgroundColor: AppTheme.success,
            icon: const Icon(Icons.check_circle, color: Colors.white),
            label: const Text('전체 출석',
                style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  Widget _buildSummaryBar(int present, int total) {
    final rate = total > 0 ? present / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '출석 현황',
                style: AppTheme.sectionTitle,
              ),
              Text(
                '$present / $total명',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.seonggadae,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate,
              backgroundColor: AppTheme.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.seonggadae),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendDot(AppTheme.success, '출석'),
              const SizedBox(width: 16),
              _legendDot(AppTheme.error, '결석'),
              const SizedBox(width: 16),
              _legendDot(AppTheme.warning, '공결'),
              const Spacer(),
              Text(
                '${(rate * 100).round()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.seonggadae,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildSectionFilter() {
    return Container(
      color: AppTheme.surface,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoirSection.all,
            ChoirSection.soprano,
            ChoirSection.alto,
            ChoirSection.tenor,
            ChoirSection.bass,
          ].map((s) {
            final selected = _filterSection == s;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(s.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? AppTheme.seonggadae
                          : AppTheme.textSecondary,
                    )),
                selected: selected,
                onSelected: (_) => setState(() => _filterSection = s),
                selectedColor:
                    AppTheme.seonggadae.withOpacity(0.15),
                checkmarkColor: AppTheme.seonggadae,
                backgroundColor: AppTheme.background,
                side: BorderSide(
                  color: selected
                      ? AppTheme.seonggadae
                      : AppTheme.border,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAttendanceRow(BuildContext context,
      ChoirAttendanceModel attendance, ChoirProvider choir) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _statusBorderColor(attendance.status),
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor:
              _statusColor(attendance.status).withOpacity(0.15),
          child: Text(
            attendance.memberName.isNotEmpty
                ? attendance.memberName[0]
                : '?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _statusColor(attendance.status),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              attendance.memberName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${attendance.section.emoji} ${attendance.section.label}',
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        subtitle: attendance.note != null && attendance.note!.isNotEmpty
            ? Text(
                '📝 ${attendance.note}',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusButton(
                attendance, AttendanceStatus.present, choir, '✅'),
            _statusButton(
                attendance, AttendanceStatus.absent, choir, '❌'),
            _statusButton(
                attendance, AttendanceStatus.excused, choir, '📋'),
          ],
        ),
        onLongPress: () => _showNoteDialog(context, attendance, choir),
      ),
    );
  }

  Widget _statusButton(ChoirAttendanceModel attendance,
      AttendanceStatus status, ChoirProvider choir, String emoji) {
    final isSelected = attendance.status == status;
    return GestureDetector(
      onTap: () =>
          choir.updateAttendance(attendance.id, status),
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? _statusColor(status).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: _statusColor(status))
              : Border.all(color: Colors.transparent),
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return AppTheme.success;
      case AttendanceStatus.absent:  return AppTheme.error;
      case AttendanceStatus.excused: return AppTheme.warning;
    }
  }

  Color _statusBorderColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return AppTheme.success.withOpacity(0.3);
      case AttendanceStatus.absent:  return AppTheme.error.withOpacity(0.3);
      case AttendanceStatus.excused: return AppTheme.warning.withOpacity(0.3);
    }
  }

  void _markAllPresent(ChoirProvider choir) {
    for (final a in choir.attendances) {
      choir.updateAttendance(a.id, AttendanceStatus.present);
    }
  }

  Future<void> _showNoteDialog(BuildContext context,
      ChoirAttendanceModel attendance, ChoirProvider choir) async {
    final controller =
        TextEditingController(text: attendance.note ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${attendance.memberName} - 메모'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(hintText: '사유나 메모를 입력하세요'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.seonggadae),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (result != null) {
      choir.updateAttendance(attendance.id, attendance.status,
          note: result);
    }
    controller.dispose();
  }

  Future<void> _saveAttendance(BuildContext context) async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _isSaving = false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('출석이 저장되었습니다')),
      );
      context.pop();
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 출석 통계 화면
// ═══════════════════════════════════════════════════════════════
class ChoirAttendanceStatsScreen extends StatefulWidget {
  const ChoirAttendanceStatsScreen({super.key});

  @override
  State<ChoirAttendanceStatsScreen> createState() =>
      _ChoirAttendanceStatsScreenState();
}

class _ChoirAttendanceStatsScreenState
    extends State<ChoirAttendanceStatsScreen> {
  String _period = 'monthly';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final choir = context.read<ChoirProvider>();
      choir.loadAttendanceStats(choir.selectedChoir?.id ?? '',
          period: _period);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChoirProvider>(
      builder: (context, choir, _) {
        final stats = choir.stats;
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('출석 통계'),
            backgroundColor: AppTheme.surface,
            elevation: 0,
          ),
          body: choir.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // 기간 선택
                    _buildPeriodSelector(context, choir),
                    const SizedBox(height: 20),
                    // 전체 통계 카드
                    _buildOverallCard(stats),
                    const SizedBox(height: 16),
                    // 섹션별 통계
                    _buildSectionStats(stats),
                    const SizedBox(height: 16),
                    // 최근 일정별 출석
                    _buildRecentSchedules(context, choir),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildPeriodSelector(BuildContext context, ChoirProvider choir) {
    return Row(
      children: [
        Expanded(
          child: _periodBtn(context, '이번 달', 'monthly', choir),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _periodBtn(context, '이번 주', 'weekly', choir),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _periodBtn(context, '3개월', '3months', choir),
        ),
      ],
    );
  }

  Widget _periodBtn(BuildContext context, String label, String value,
      ChoirProvider choir) {
    final selected = _period == value;
    return GestureDetector(
      onTap: () {
        setState(() => _period = value);
        choir.loadAttendanceStats(
            choir.selectedChoir?.id ?? '',
            period: value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.seonggadae
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppTheme.seonggadae
                : AppTheme.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverallCard(AttendanceStats stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.seonggadae, AppTheme.seonggadaeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.seonggadae.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '전체 출석율',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            '${stats.attendanceRate.round()}%',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('일정', '${stats.totalSchedules}회', Colors.white),
              _statItem('출석', '${stats.presentCount}명', Colors.white),
              _statItem('결석', '${stats.absentCount}명', Colors.white70),
              _statItem('공결', '${stats.excusedCount}명', Colors.white70),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
      ],
    );
  }

  Widget _buildSectionStats(AttendanceStats stats) {
    final sections = [
      ChoirSection.soprano,
      ChoirSection.alto,
      ChoirSection.tenor,
      ChoirSection.bass,
    ];

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
          const Text(
            '파트별 출석율',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...sections.map((s) {
            final rate = stats.sectionRates[s.value] ?? 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${s.emoji} ${s.label}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${rate.round()}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.seonggadae,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: rate / 100,
                      backgroundColor: AppTheme.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _sectionColor(s),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _sectionColor(ChoirSection section) {
    switch (section) {
      case ChoirSection.soprano: return AppColors.info;
      case ChoirSection.alto:    return AppTheme.warning;
      case ChoirSection.tenor:   return AppTheme.primary;
      case ChoirSection.bass:    return AppTheme.success;
      default:                   return AppTheme.seonggadae;
    }
  }

  Widget _buildRecentSchedules(BuildContext context, ChoirProvider choir) {
    final schedules = choir.schedules.take(4).toList();
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
            '최근 일정 출석',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...schedules.map((s) {
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.seonggadae.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(s.scheduleType.emoji,
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
              title: Text(s.title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text(s.formattedDate,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
              trailing: GestureDetector(
                onTap: () =>
                    context.push('/choir/attendance/${s.id}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.seonggadae.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '보기',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.seonggadae,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              dense: true,
            );
          }),
        ],
      ),
    );
  }
}
