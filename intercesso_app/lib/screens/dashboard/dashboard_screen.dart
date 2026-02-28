import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _dashboard;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final response = await _api.get('/statistics/dashboard');
      setState(() {
        _dashboard = response['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _dashboard?['stats'];
    final recentPrayers = _dashboard?['recent_prayers'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('기도 통계')),
      body: _isLoading
          ? const LoadingWidget(message: '통계를 불러오는 중...')
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더 카드
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '나의 기도 여정',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '지금까지 ${stats?['total_prayers'] ?? 0}개의 기도를 드렸어요',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn('${stats?['streak_days'] ?? 0}🔥', '연속 기도'),
                              _buildStatColumn('${stats?['answer_rate'] ?? 0}%', '응답률'),
                              _buildStatColumn('${stats?['total_participations'] ?? 0}', '중보기도'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 통계 그리드
                    const Text(
                      '상세 통계',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        StatCard(
                          emoji: '🙏',
                          value: '${stats?['total_prayers'] ?? 0}',
                          label: '총 기도',
                          color: AppTheme.primary,
                        ),
                        StatCard(
                          emoji: '✅',
                          value: '${stats?['answered_prayers'] ?? 0}',
                          label: '응답받은 기도',
                          color: AppTheme.success,
                        ),
                        StatCard(
                          emoji: '🙌',
                          value: '${stats?['grateful_prayers'] ?? 0}',
                          label: '감사 기도',
                          color: AppTheme.warning,
                        ),
                        StatCard(
                          emoji: '💬',
                          value: '${stats?['total_comments'] ?? 0}',
                          label: '총 댓글',
                          color: AppTheme.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 최근 기도
                    if (recentPrayers.isNotEmpty) ...[
                      const Text(
                        '최근 기도',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      ...recentPrayers.take(5).map((p) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Text('🙏', style: TextStyle(fontSize: 16)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    p['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(p['status']).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getStatusLabel(p['status']),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _getStatusColor(p['status']),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'answered': return AppTheme.success;
      case 'grateful': return AppTheme.warning;
      default: return AppTheme.primary;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'answered': return '✅ 응답';
      case 'grateful': return '🙌 감사';
      default: return '🙏 기도중';
    }
  }
}
