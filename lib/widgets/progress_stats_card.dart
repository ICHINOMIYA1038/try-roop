import 'package:flutter/material.dart';
import '../models/user_stats.dart';

class ProgressStatsCard extends StatelessWidget {
  final UserStats stats;

  const ProgressStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '学習の記録',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.timer_outlined,
                    label: '総学習時間',
                    value: stats.totalWatchTimeFormatted,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.school_outlined,
                    label: '完了コース',
                    value: '${stats.completedCourses}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.play_circle_outline,
                    label: '視聴動画数',
                    value: '${stats.completedVideos}',
                    color: Colors.purple,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.local_fire_department_outlined,
                    label: '連続日数',
                    value: '${stats.consecutiveDays}日',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressStatsRow extends StatelessWidget {
  final UserStats stats;

  const ProgressStatsRow({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniStatItem(
            label: '学習時間',
            value: stats.totalWatchTimeFormatted,
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey[300],
          ),
          _MiniStatItem(
            label: '完了コース',
            value: '${stats.completedCourses}',
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey[300],
          ),
          _MiniStatItem(
            label: '連続日数',
            value: '${stats.consecutiveDays}日',
          ),
        ],
      ),
    );
  }
}

class _MiniStatItem extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
