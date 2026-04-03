import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(context);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
              // Mark all as read logic could go here
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notificationService.getNotificationsStream(authService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: AppTheme.subtext(context))),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(context, notification, notificationService);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, 
    NotificationModel notification, 
    NotificationService service,
  ) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case 'join_request':
        icon = Icons.home_work_rounded;
        color = Colors.blue;
        break;
      case 'room_request':
        icon = Icons.door_front_door_rounded;
        color = Colors.green;
        break;
      case 'maintenance_update':
        icon = Icons.build_circle_rounded;
        color = Colors.orange;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = AppTheme.primary(context);
    }

    return Dismissible(
      key: Key(notification.id),
      onDismissed: (_) => service.deleteNotification(notification.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: notification.isRead ? Colors.transparent : color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: ListTile(
          onTap: () {
            if (!notification.isRead) service.markAsRead(notification.id);
            // Navigate based on type if needed
          },
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.message,
                style: TextStyle(fontSize: 14, color: AppTheme.subtext(context)),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM d, h:mm a').format(notification.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
