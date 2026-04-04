import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // ── Date grouping ─────────────────────────────────────────────────────────
  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return 'Earlier';
  }

  Map<String, List<NotificationModel>> _groupNotifications(
      List<NotificationModel> notifications) {
    final Map<String, List<NotificationModel>> grouped = {};
    for (final n in notifications) {
      final label = _dateLabel(n.createdAt);
      grouped.putIfAbsent(label, () => []).add(n);
    }
    return grouped;
  }

  // ── Type → visual config ──────────────────────────────────────────────────
  ({IconData icon, LinearGradient gradient, Color accent}) _typeConfig(
      String type, BuildContext context) {
    switch (type) {
      case 'join_request':
        return (
          icon: Icons.home_work_rounded,
          gradient: AppTheme.cyanGradient,
          accent: const Color(0xFF06B6D4),
        );
      case 'room_request':
        return (
          icon: Icons.door_front_door_rounded,
          gradient: AppTheme.emeraldGradient,
          accent: const Color(0xFF059669),
        );
      case 'maintenance_update':
        return (
          icon: Icons.build_circle_rounded,
          gradient: AppTheme.amberGradient,
          accent: const Color(0xFFF59E0B),
        );
      default:
        return (
          icon: Icons.notifications_rounded,
          gradient: AppTheme.isDark(context)
              ? AppTheme.darkPrimaryGradient
              : AppTheme.primaryGradient,
          accent: AppTheme.primary(context),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final notificationService =
        Provider.of<NotificationService>(context);
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: _NotificationsAppBar(),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notificationService
            .getNotificationsStream(authService.currentUser!.uid),
        builder: (context, snapshot) {
          // Loading state — shimmer skeleton
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _ShimmerList(isDark: isDark);
          }

          final notifications = snapshot.data ?? [];

          // Empty state
          if (notifications.isEmpty) {
            return _EmptyState();
          }

          // Grouped list
          final grouped = _groupNotifications(notifications);
          const sectionOrder = ['Today', 'Yesterday', 'Earlier'];

          return ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              for (final section in sectionOrder)
                if (grouped.containsKey(section)) ...[
                  _SectionHeader(label: section),
                  const SizedBox(height: 8),
                  for (final notification in grouped[section]!)
                    _NotificationCard(
                      notification: notification,
                      service: notificationService,
                      typeConfig: _typeConfig(notification.type, context),
                    ),
                  const SizedBox(height: 8),
                ],
            ],
          );
        },
      ),
    );
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────

class _NotificationsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return AppBar(
      backgroundColor: AppTheme.bg(context),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Notifications',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: AppTheme.text(context),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Mark all as read logic could go here
          },
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primary(context),
          ),
          child: Text(
            'Mark all read',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary(context),
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 2),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.subtext(context),
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

// ─── Notification card ────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final NotificationService service;
  final ({IconData icon, LinearGradient gradient, Color accent}) typeConfig;

  const _NotificationCard({
    required this.notification,
    required this.service,
    required this.typeConfig,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final isUnread = !notification.isRead;
    final accent = typeConfig.accent;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => service.deleteNotification(notification.id),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          gradient: AppTheme.roseGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 26),
            const SizedBox(height: 4),
            Text(
              'Delete',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () {
          if (isUnread) service.markAsRead(notification.id);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isUnread
                ? accent.withValues(
                    alpha: isDark ? 0.08 : 0.05)
                : AppTheme.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                color: isUnread
                    ? accent
                    : accent.withValues(alpha: 0.25),
                width: 4,
              ),
            ),
            boxShadow: AppTheme.cardShadow(context),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient icon container
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: typeConfig.gradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(
                            alpha: isDark ? 0.35 : 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    typeConfig.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 14),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: isUnread
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: AppTheme.text(context),
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(
                                  left: 8, top: 3),
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.subtext(context),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('MMM d, h:mm a')
                            .format(notification.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.subtext(context)
                              .withValues(alpha: 0.7),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final primary = AppTheme.primary(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: isDark ? 0.10 : 0.07),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'All caught up!',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.text(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all up to date.\nNew notifications will appear here.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.subtext(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer skeleton ─────────────────────────────────────────────────────────

class _ShimmerList extends StatelessWidget {
  final bool isDark;
  const _ShimmerList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    final highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.10);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 6,
        itemBuilder: (context, index) => _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: AppTheme.primary(context).withValues(alpha: 0.3),
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 13,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 11,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 90,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
