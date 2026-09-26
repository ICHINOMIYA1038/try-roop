import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';

/// ホームの「今日のTRY」。
///
/// Try Loop の軸は「挑戦する → 続ける → また挑戦する」なので、
/// 今日やることを1つだけ名指しする。選ばせない。
class TodayTryCard extends ConsumerWidget {
  const TodayTryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayTryProvider);
    if (today == null) return const SizedBox.shrink();

    final summary = ref.watch(trySummaryProvider);
    final done = summary.doneToday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: done ? const Color(0xFF4CAF50) : const Color(0xFFE5DCD5),
            width: done ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  done ? '本日のTRY 完了' : '今日のTRY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: done
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF8A3D),
                  ),
                ),
                if (today.isNewGenre && !done) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8A3D).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'はじめてのジャンル',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8A3D),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (summary.streakDays > 1)
                  Text(
                    '${summary.streakDays}日連続',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8C8681),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              done ? 'おつかれさまでした。' : today.invitation,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF433D39),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '今月 ${summary.thisMonth} 回TRY',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8C8681),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => today.isLive
                      ? context.push('/live')
                      : context.push('/video/${today.targetId}'),
                  child: Text(done ? 'もう1回やる' : 'はじめる'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
