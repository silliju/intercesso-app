import 'package:flutter/material.dart';
import '../config/theme.dart';

// 기도 카드 위젯 (보닥 스타일)
class PrayerCard extends StatelessWidget {
  final String title;
  final String content;
  final String? userNickname;
  final String? userImage;
  final String status;
  final String? category;
  final int prayerCount;
  final int? commentCount;
  final String createdAt;
  final bool isParticipated;
  final String? scope; // 공개 범위 뱃지 표시용 (null이면 미표시)
  final VoidCallback? onTap;
  final VoidCallback? onPrayTap;

  const PrayerCard({
    super.key,
    required this.title,
    required this.content,
    this.userNickname,
    this.userImage,
    required this.status,
    this.category,
    required this.prayerCount,
    this.commentCount,
    required this.createdAt,
    this.isParticipated = false,
    this.scope,
    this.onTap,
    this.onPrayTap,
  });

  String? get _scopeLabel {
    switch (scope) {
      case 'friends': return '👥 지인공개';
      case 'private': return '🔒 비공개';
      case 'community': return '⛪ 공동체';
      default: return null; // public은 뱃지 미표시
    }
  }

  Color get _scopeColor {
    switch (scope) {
      case 'friends': return AppTheme.seonggadae;
      case 'private': return AppTheme.textSecondary;
      case 'community': return AppTheme.success;
      default: return AppTheme.primary;
    }
  }

  String get _statusEmoji {
    switch (status) {
      case 'answered':
        return '✅';
      case 'grateful':
        return '🙌';
      default:
        return '🙏';
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'answered':
        return '응답받음';
      case 'grateful':
        return '감사';
      default:
        return '기도중';
    }
  }

  Color get _statusColor {
    switch (status) {
      case 'answered':
        return AppTheme.success;
      case 'grateful':
        return AppTheme.warning;
      default:
        return AppTheme.primary;
    }
  }

  String get _categoryEmoji {
    switch (category) {
      case '건강':
        return '💪';
      case '가정':
        return '🏠';
      case '진로':
        return '🎯';
      case '영적':
        return '✨';
      case '사업':
        return '💼';
      default:
        return '🙏';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 (유저 정보 + 상태)
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryLight,
                  backgroundImage:
                      userImage != null ? NetworkImage(userImage!) : null,
                  child: userImage == null
                      ? Text(
                          userNickname?.isNotEmpty == true
                              ? userNickname![0]
                              : '?',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userNickname ?? '익명',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        _formatTime(createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                // scope 뱃지 (지인공개/비공개/공동체만 표시)
                if (_scopeLabel != null)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _scopeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: _scopeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      _scopeLabel!,
                      style: TextStyle(
                        fontSize: 10,
                        color: _scopeColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                // 상태 뱃지
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    '$_statusEmoji $_statusLabel',
                    style: TextStyle(
                      fontSize: 11,
                      color: _statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 기도 제목
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // 기도 내용
            Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // 하단 정보
            Row(
              children: [
                if (category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      '$_categoryEmoji $category',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                // 함께 기도
                GestureDetector(
                  onTap: onPrayTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isParticipated
                          ? AppTheme.primaryLight
                          : AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🙏', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '$prayerCount',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isParticipated
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        size: 13, color: AppTheme.textLight),
                    const SizedBox(width: 3),
                    Text(
                      '${commentCount ?? 0}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      if (diff.inDays < 7) return '${diff.inDays}일 전';
      return '${date.month}월 ${date.day}일';
    } catch (_) {
      return '';
    }
  }
}

// 로딩 위젯
class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

// 빈 상태 위젯
class EmptyWidget extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonTap;

  const EmptyWidget({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (buttonText != null && onButtonTap != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onButtonTap,
              child: Text(buttonText!),
            ),
          ],
        ],
      ),
    );
  }
}

// 통계 카드 위젯
class StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color? color;

  const StatCard({
    super.key,
    required this.emoji,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primary).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color ?? AppTheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// 그라디언트 버튼 (하위 호환 유지)
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(text),
      ),
    );
  }
}

// 섹션 헤더 위젯
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          if (actionText != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                '$actionText >',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// 메뉴 아이템 위젯 (프로필 등에서 사용)
class MenuItemTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final Widget? trailing;

  const MenuItemTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.titleColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor ?? AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? AppTheme.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppTheme.textLight,
                ),
          ],
        ),
      ),
    );
  }
}
