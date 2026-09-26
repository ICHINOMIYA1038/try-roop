import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/legal_urls.dart';
import '../../models/live_schedule.dart';
import '../../providers/providers.dart';
import '../../services/analytics_service.dart';
import '../../widgets/error_view.dart';

/// LIVE の予定一覧。
///
/// 週のどの曜日に何があるかが分かることが目的なので、日付ごとにまとめる。
class LiveScheduleScreen extends ConsumerWidget {
  const LiveScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(liveSchedulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('LIVEの予定')),
      body: schedulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e),
        data: (all) {
          final now = DateTime.now();
          // 終わった配信は見逃し配信側で見るので、ここには出さない。
          final upcoming = all
              .where((s) =>
                  !s.isEnded &&
                  s.scheduledAt
                      .isAfter(DateTime(now.year, now.month, now.day)))
              .toList()
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

          if (upcoming.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'これからのLIVEはまだ登録されていません。',
                  style: TextStyle(color: Color(0xFF8C8681)),
                ),
              ),
            );
          }

          final byDay = <String, List<LiveSchedule>>{};
          for (final s in upcoming) {
            final day = s.formattedDateTime.split(' ').first;
            byDay.putIfAbsent(day, () => []).add(s);
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              for (final entry in byDay.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF433D39),
                    ),
                  ),
                ),
                for (final s in entry.value) _ScheduleTile(schedule: s),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final LiveSchedule schedule;

  const _ScheduleTile({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              schedule.formattedTime,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFFFF8A3D),
              ),
            ),
            Text(
              '${schedule.duration}分',
              style: const TextStyle(fontSize: 11, color: Color(0xFF8C8681)),
            ),
          ],
        ),
        title: Text(
          schedule.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: schedule.description.isEmpty
            ? null
            : Text(
                schedule.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
        trailing: schedule.isLive
            ? const Chip(
                label: Text('配信中', style: TextStyle(color: Colors.white)),
                backgroundColor: Color(0xFFE53935),
                visualDensity: VisualDensity.compact,
              )
            : const Icon(Icons.open_in_new, size: 18),
        onTap: () => _open(context),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
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
