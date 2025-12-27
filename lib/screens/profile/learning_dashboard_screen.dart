import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/progress_stats_card.dart';
import '../../widgets/badge_chip.dart';
import '../../widgets/course_card.dart';

class LearningDashboardScreen extends ConsumerWidget {
  const LearningDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsAsync = ref.watch(userStatsProvider);
    final userBadgesAsync = ref.watch(userBadgesProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final progressListAsync = ref.watch(userCourseProgressListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('学習ダッシュボード'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            userStatsAsync.when(
              data: (stats) {
                if (stats == null) {
                  return const SizedBox.shrink();
                }
                return ProgressStatsCard(stats: stats);
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Badges
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '獲得バッジ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/badges'),
                    child: const Text('すべて見る'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 50,
              child: userBadgesAsync.when(
                data: (badges) {
                  if (badges.isEmpty) {
                    return const Center(
                      child: Text('まだバッジがありません'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: badges.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return BadgeChip(
                        badge: badges[index],
                        onTap: () => context.push('/badges'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SizedBox(height: 24),

            // In Progress Courses
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '進行中のコース',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            coursesAsync.when(
              data: (courses) {
                final progressList = progressListAsync.value ?? [];
                final inProgressCourses = courses.where((course) {
                  final progress = progressList
                      .where((p) => p.courseId == course.id)
                      .firstOrNull;
                  return progress != null &&
                      !progress.isCompleted &&
                      progress.progressPercent > 0;
                }).toList();

                if (inProgressCourses.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('進行中のコースはありません'),
                    ),
                  );
                }

                return SizedBox(
                  height: 240,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: inProgressCourses.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final course = inProgressCourses[index];
                      final progress = progressList
                          .where((p) => p.courseId == course.id)
                          .firstOrNull;
                      return SizedBox(
                        width: 280,
                        child: CourseCard(
                          course: course,
                          progressPercent: progress?.progressPercent,
                          onTap: () => context.push('/course/${course.id}'),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // Completed Courses
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '完了したコース',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            coursesAsync.when(
              data: (courses) {
                final progressList = progressListAsync.value ?? [];
                final completedCourses = courses.where((course) {
                  final progress = progressList
                      .where((p) => p.courseId == course.id)
                      .firstOrNull;
                  return progress != null && progress.isCompleted;
                }).toList();

                if (completedCourses.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('完了したコースはありません'),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: completedCourses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final course = completedCourses[index];
                    return CourseCard(
                      course: course,
                      progressPercent: 1.0,
                      onTap: () => context.push('/course/${course.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
