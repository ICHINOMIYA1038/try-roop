import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../main.dart' show isDemoMode;
import '../../models/event.dart';
import '../../models/event_participation.dart';
import '../../providers/providers.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventProvider(eventId));
    final participationAsync = ref.watch(eventParticipationProvider(eventId));

    return eventAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('エラーが発生しました: $error')),
      ),
      data: (event) {
        if (event == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('イベントが見つかりませんでした')),
          );
        }

        final participation = participationAsync.value;

        return Scaffold(
          backgroundColor: const Color(0xFFF9F7F4),
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, event),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEventInfo(event),
                    const Divider(height: 1),
                    _buildDescription(event),
                    if (event.isOnline && event.meetingUrl != null)
                      _buildMeetingInfo(event),
                    if (event.isOffline && event.location != null)
                      _buildLocationInfo(event),
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context, ref, event, participation),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Event event) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (event.imageUrl != null)
              CachedNetworkImage(
                imageUrl: event.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade300,
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.event, size: 48, color: Colors.white),
                ),
              )
            else
              Container(
                color: const Color(0xFFFF8A3D),
                child: const Icon(Icons.event, size: 48, color: Colors.white),
              ),
            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xB3000000), // Black with 70% opacity
                  ],
                ),
              ),
            ),
            // Event type badge
            Positioned(
              top: 100,
              left: 16,
              child: _buildEventTypeBadge(event),
            ),
            // Title
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Text(
                event.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypeBadge(Event event) {
    final isOnline = event.isOnline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFF1976D2) : const Color(0xFF388E3C),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.videocam : Icons.location_on,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            event.eventTypeLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfo(Event event) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Date and time
          _buildInfoRow(
            icon: Icons.calendar_today,
            title: '日時',
            content: '${event.startAt.year}年${event.startAt.month}月${event.startAt.day}日 ${event.timeFormatted}',
            subtitle: '(${event.durationFormatted})',
          ),
          const SizedBox(height: 16),
          // Capacity
          _buildCapacityRow(event),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String content,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFF8A3D),
            size: 20,
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
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF433D39),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCapacityRow(Event event) {
    final progress = event.currentParticipants / event.capacity;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.people,
            color: Color(0xFFFF8A3D),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '参加者',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${event.currentParticipants}/${event.capacity}人',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF433D39),
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    event.isFull ? Colors.red.shade400 : const Color(0xFFFF8A3D),
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                event.isFull
                    ? '満席です'
                    : '残り${event.availableSpots}席',
                style: TextStyle(
                  fontSize: 12,
                  color: event.isFull
                      ? Colors.red.shade600
                      : event.availableSpots <= 5
                          ? Colors.orange.shade700
                          : Colors.grey.shade600,
                  fontWeight: event.isFull || event.availableSpots <= 5
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(Event event) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '詳細',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF433D39),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            event.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Color(0xFF433D39),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingInfo(Event event) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '参加方法',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF433D39),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.videocam,
                  color: Color(0xFF1976D2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'オンライン参加',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      Text(
                        '登録後にミーティングURLをお送りします',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(Event event) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '会場',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF433D39),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFF388E3C),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event.location!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF433D39),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    Event event,
    EventParticipation? participation,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000), // Black with 5% opacity
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: _buildActionButton(context, ref, event, participation),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    Event event,
    EventParticipation? participation,
  ) {
    // Already registered
    if (participation != null && participation.isConfirmed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF388E3C), size: 20),
                SizedBox(width: 8),
                Text(
                  '参加登録済み',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF388E3C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showCancelDialog(context, ref, event),
            child: Text(
              '参加をキャンセル',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }

    // On waitlist
    if (participation != null && participation.isWaitlisted) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'キャンセル待ち (${participation.waitlistPosition}番目)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showCancelDialog(context, ref, event),
            child: Text(
              'キャンセル待ちを取り消す',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }

    // Past event
    if (event.isPast) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'このイベントは終了しました',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Can register
    if (event.canRegister) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _registerForEvent(context, ref, event),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8A3D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'イベントに登録する',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Can join waitlist
    if (event.canJoinWaitlist) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _registerForEvent(context, ref, event),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'キャンセル待ちに登録する',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Registration closed
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '登録受付は終了しました',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _registerForEvent(BuildContext context, WidgetRef ref, Event event) async {
    try {
      if (isDemoMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              event.isFull ? 'キャンセル待ちに登録しました' : 'イベントに登録しました',
            ),
            backgroundColor: const Color(0xFF388E3C),
          ),
        );
        return;
      }

      final user = ref.read(currentUserProvider);
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ログインが必要です'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await ref.read(firestoreServiceProvider).registerForEvent(user.uid, event.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              event.isFull ? 'キャンセル待ちに登録しました' : 'イベントに登録しました',
            ),
            backgroundColor: const Color(0xFF388E3C),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCancelDialog(BuildContext context, WidgetRef ref, Event event) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('参加をキャンセル'),
        content: const Text('本当にこのイベントへの参加をキャンセルしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('戻る'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('キャンセルする'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        if (isDemoMode) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('参加をキャンセルしました'),
              ),
            );
          }
          return;
        }

        final user = ref.read(currentUserProvider);
        if (user == null) return;

        await ref.read(firestoreServiceProvider).cancelEventRegistration(user.uid, event.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('参加をキャンセルしました'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('エラーが発生しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
