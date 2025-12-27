import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_notification.dart';
import '../../providers/providers.dart';
import '../../widgets/notification_tile.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        actions: [
          TextButton(
            onPressed: () {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                ref.read(firestoreServiceProvider).markAllNotificationsAsRead(user.uid);
              }
            },
            child: const Text('すべて既読'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('通知はありません'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
            },
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationTile(
                  notification: notification,
                  onTap: () => _handleNotificationTap(context, ref, notification),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラーが発生しました: $error'),
        ),
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    // Mark as read
    ref.read(firestoreServiceProvider).markNotificationAsRead(notification.id);

    // Navigate based on type
    switch (notification.type) {
      case NotificationType.newVideo:
        final videoId = notification.data['videoId'];
        if (videoId != null) {
          context.push('/video/$videoId');
        }
        break;
      case NotificationType.newCourse:
        final courseId = notification.data['courseId'];
        if (courseId != null) {
          context.push('/course/$courseId');
        }
        break;
      case NotificationType.commentReply:
        final postId = notification.data['postId'];
        if (postId != null) {
          context.push('/post/$postId');
        }
        break;
      case NotificationType.like:
        final postId = notification.data['postId'];
        if (postId != null) {
          context.push('/post/$postId');
        }
        break;
      case NotificationType.announcement:
        final announcementId = notification.data['announcementId'];
        if (announcementId != null) {
          context.push('/announcement/$announcementId');
        }
        break;
      case NotificationType.liveSchedule:
        // Navigate to home where live schedules are shown
        break;
    }
  }
}
