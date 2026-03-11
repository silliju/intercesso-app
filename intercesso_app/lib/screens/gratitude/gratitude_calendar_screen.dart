import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/gratitude_provider.dart';
import 'create_gratitude_screen.dart';
import 'gratitude_detail_screen.dart';

class GratitudeCalendarScreen extends StatefulWidget {
  const GratitudeCalendarScreen({super.key});

  @override
  State<GratitudeCalendarScreen> createState() => _GratitudeCalendarScreenState();
}

class _GratitudeCalendarScreenState extends State<GratitudeCalendarScreen> {
  late int _year;
  late int _month;
  static const _gratitudeColor = Color(0xFF885CF6);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GratitudeProvider>().loadCalendar(year: _year, month: _month);
      context.read<GratitudeProvider>().loadStreak();
    });
  }

  void _previousMonth() {
    setState(() {
      if (_month == 1) { _month = 12; _year--; } else { _month--; }
    });
    context.read<GratitudeProvider>().loadCalendar(year: _year, month: _month);
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_year == now.year && _month == now.month) return; // 미래는 못 감
    setState(() {
      if (_month == 12) { _month = 1; _year++; } else { _month++; }
    });
    context.read<GratitudeProvider>().loadCalendar(year: _year, month: _month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.gamsa,
        foregroundColor: Colors.white,
        title: const Text('감사 캘린더'),
        elevation: 0,
      ),
      body: Consumer<GratitudeProvider>(
        builder: (_, provider, __) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStreakCard(provider),
                const SizedBox(height: 16),
                _buildCalendar(provider),
                const SizedBox(height: 16),
                _buildStatsCard(provider),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final provider = context.read<GratitudeProvider>();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateGratitudeScreen(existing: provider.todayJournal),
            ),
          );
          if (result == true) {
            final now = DateTime.now();
            provider.loadCalendar(year: _year, month: _month);
            provider.loadStreak();
          }
        },
        backgroundColor: _gratitudeColor,
        foregroundColor: Colors.white,
        icon: const Text('✨', style: TextStyle(fontSize: 18)),
        label: const Text('오늘 감사일기', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildStreakCard(GratitudeProvider provider) {
    final streak = provider.streak;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF885CF6), Color(0xFF6D3FD4)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _gratitudeColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStreakStat('🔥 연속', '${streak.currentStreak}일', Colors.white),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStreakStat('🏆 최고', '${streak.longestStreak}일', Colors.white),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStreakStat('📝 총계', '${streak.totalCount}번', Colors.white),
            ],
          ),
          const SizedBox(height: 14),
          _buildStreakProgress(streak.currentStreak),
          const SizedBox(height: 6),
          Text(
            _getStreakMessage(streak.currentStreak),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStreakProgress(int current) {
    // 다음 목표: 7, 21, 40, 100
    const milestones = [7, 21, 40, 100];
    int nextMilestone = milestones.firstWhere((m) => m > current, orElse: () => 100);
    if (current >= 100) nextMilestone = 100;
    final progress = (current / nextMilestone).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '다음 목표: ${nextMilestone}일',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(GratitudeProvider provider) {
    final calData = provider.calendarData;
    final entries = calData['entries'] as Map<String, dynamic>? ?? {};

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 월 네비게이션
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _previousMonth,
                  color: _gratitudeColor,
                ),
                Text(
                  '$_year년 $_month월',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: _isCurrentMonth() ? Colors.grey.shade300 : _gratitudeColor,
                  ),
                  onPressed: _isCurrentMonth() ? null : _nextMonth,
                ),
              ],
            ),
          ),
          // 요일 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['일', '월', '화', '수', '목', '금', '토']
                  .asMap()
                  .entries
                  .map((e) => Expanded(
                        child: Center(
                          child: Text(
                            e.value,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: e.key == 0
                                  ? Colors.red.shade300
                                  : e.key == 6
                                      ? Colors.blue.shade300
                                      : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          // 날짜 그리드
          if (provider.isCalendarLoading)
            const Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(),
            )
          else
            _buildDateGrid(entries),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDateGrid(Map<String, dynamic> entries) {
    final firstDay = DateTime(_year, _month, 1);
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=일, 1=월 ...
    final today = DateTime.now();
    final cells = <Widget>[];

    // 빈 칸
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    // 날짜
    for (int day = 1; day <= daysInMonth; day++) {
      final dateStr = '$_year-${_month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final entry = entries[dateStr];
      final isToday = today.year == _year && today.month == _month && today.day == day;
      final hasEntry = entry != null;

      cells.add(_DateCell(
        day: day,
        isToday: isToday,
        hasEntry: hasEntry,
        emotion: hasEntry ? entry['emotion'] : null,
        onTap: hasEntry
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GratitudeDetailScreen(journalId: entry['id']),
                  ),
                )
            : (isToday
                ? () async {
                    final provider = context.read<GratitudeProvider>();
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateGratitudeScreen(existing: provider.todayJournal),
                      ),
                    );
                    if (result == true) {
                      provider.loadCalendar(year: _year, month: _month);
                    }
                  }
                : null),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.85,
        children: cells,
      ),
    );
  }

  Widget _buildStatsCard(GratitudeProvider provider) {
    final calData = provider.calendarData;
    final totalThisMonth = calData['total_this_month'] ?? 0;
    final daysInMonth = DateTime(_year, _month + 1, 0).day;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_month}월 감사 통계',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  emoji: '📝',
                  label: '이번 달 작성',
                  value: '$totalThisMonth일',
                  color: _gratitudeColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(
                  emoji: '📊',
                  label: '이번 달 달성률',
                  value: '${(totalThisMonth / daysInMonth * 100).toStringAsFixed(0)}%',
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 달성률 바
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '이번 달 기록',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (totalThisMonth / daysInMonth).clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFF3F4F6),
                  valueColor: AlwaysStoppedAnimation<Color>(_gratitudeColor),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$daysInMonth일 중 $totalThisMonth일 작성',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _year == now.year && _month == now.month;
  }

  String _getStreakMessage(int streak) {
    if (streak == 0) return '오늘 첫 감사일기를 써보세요! 🌱';
    if (streak < 7) return '좋은 습관을 만들어가고 있어요! 🌱';
    if (streak < 21) return '1주일 달성! 이제 습관이 되어가고 있어요 🌿';
    if (streak < 40) return '3주 연속! 놀라운 인내력이에요 ✨';
    if (streak < 100) return '40일 넘게 지속! 진정한 감사의 삶이에요 🌟';
    return '100일 달성! 감사의 챔피언이에요 🏆';
  }
}

class _DateCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool hasEntry;
  final String? emotion;
  final VoidCallback? onTap;

  static const _emotionEmojis = {
    'joy': '😊',
    'peace': '🕊️',
    'moved': '😭',
    'thankful': '🙌',
  };

  const _DateCell({
    required this.day,
    required this.isToday,
    required this.hasEntry,
    this.emotion,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: hasEntry
                  ? const Color(0xFF885CF6)
                  : isToday
                      ? const Color(0xFFF5F3FF)
                      : Colors.transparent,
              shape: BoxShape.circle,
              border: isToday && !hasEntry
                  ? Border.all(color: const Color(0xFF885CF6), width: 2)
                  : null,
            ),
            child: Center(
              child: hasEntry && emotion != null
                  ? Text(
                      _emotionEmojis[emotion] ?? '✨',
                      style: const TextStyle(fontSize: 16),
                    )
                  : Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: (isToday || hasEntry) ? FontWeight.w800 : FontWeight.w400,
                        color: hasEntry
                            ? Colors.white
                            : isToday
                                ? const Color(0xFF6D3FD4)
                                : const Color(0xFF374151),
                      ),
                    ),
            ),
          ),
          if (hasEntry && emotion == null)
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(top: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF885CF6),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
