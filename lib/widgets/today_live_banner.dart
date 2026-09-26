import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/legal_urls.dart';
import '../models/live_schedule.dart';
import '../providers/providers.dart';
import '../services/analytics_service.dart';

/// ホームの「本日のLIVE」。
///
/// Try Loop は LIVE が中心のサービスなので、アプリを開いた時点で
/// 今日の配信が分かる状態にする。配信そのものは YouTube 限定配信なので、
/// 参加ボタンから外部で開く。
class TodayLiveBanner extends ConsumerWidget {
  const TodayLiveBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayLiveSchedulesProvider);

    return todayAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) {
        debugPrint('today live: $e');
        return const SizedBox.shrink();
      },
      data: (schedules) {
        if (schedules.isEmpty) return const _NoLiveToday();
        // 配信中があればそれを最優先で見せる。
        final live = schedules.firstWhere(
          (s) => s.isLive,
          orElse: () => schedules.first,
        );
        return _LiveCard(schedule: live, moreCount: schedules.length - 1);
      },
    );
  }
}

class _LiveCard extends StatelessWidget {
  final LiveSchedule schedule;
  final int moreCount;

  const _LiveCard({required this.schedule, required this.moreCount});

  @override
  Widget build(BuildContext context) {
    final isLive = schedule.isLive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLive
                ? [const Color(0xFFE53935), const Color(0xFFD81B60)]
                : [const Color(0xFFFF8A3D), const Color(0xFFFF6B35)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isLive) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  isLive ? '配信中' : '本日のLIVE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  '${schedule.formattedTime}〜  ${schedule.duration}分',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              schedule.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _join(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF433D39),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(isLive ? 'いま参加する' : '配信ページを開く'),
                  ),
                ),
                if (moreCount > 0) ...[
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => context.push('/live'),
                    child: Text(
                      'ほか$moreCount件',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _join(BuildContext context) async {
    final url = schedule.streamUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配信URLがまだ設定されていません')),
      );
      return;
    }
    AnalyticsService.liveJoined(schedule.id, live: schedule.isLive);
    await openExternalUrl(context, url);
  }
}

/// 今日の配信が無い日でも、次の予定への導線は残す。
class _NoLiveToday extends ConsumerWidget {
  const _NoLiveToday();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(upcomingLiveSchedulesProvider).value;
    final hasNext = next != null && next.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => context.push('/live'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5DCD5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.podcasts, color: Color(0xFFFF8A3D)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasNext
                      ? '次のLIVEは ${next.first.formattedDateTime}'
                      : '今日のLIVEはお休みです',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF8C8681)),
            ],
          ),
        ),
      ),
    );
  }
}
