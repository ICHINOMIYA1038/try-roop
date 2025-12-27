import 'package:flutter/material.dart';
import '../models/app_notification.dart';

class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: notification.isRead ? null : Theme.of(context).primaryColor.withOpacity(0.05),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _getTypeColor(notification.type).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _getTypeIcon(notification.type),
          color: _getTypeColor(notification.type),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            notification.body,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  notification.typeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: _getTypeColor(notification.type),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(notification.createdAt),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newVideo:
        return Icons.play_circle_outline;
      case NotificationType.newCourse:
        return Icons.school_outlined;
      case NotificationType.commentReply:
        return Icons.reply;
      case NotificationType.like:
        return Icons.favorite_border;
      case NotificationType.announcement:
        return Icons.campaign_outlined;
      case NotificationType.liveSchedule:
        return Icons.live_tv;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.newVideo:
        return Colors.blue;
      case NotificationType.newCourse:
        return Colors.purple;
      case NotificationType.commentReply:
        return Colors.green;
      case NotificationType.like:
        return Colors.red;
      case NotificationType.announcement:
        return Colors.orange;
      case NotificationType.liveSchedule:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.month}/${date.day}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}日前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}時間前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }
}
