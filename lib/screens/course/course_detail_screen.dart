import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/course.dart';
import '../../models/bookmark.dart';
import '../../providers/providers.dart';

class CourseDetailScreen extends ConsumerWidget {
  final String courseId;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseProvider(courseId));
    final progressAsync = ref.watch(courseProgressProvider(courseId));
    final hasBookmarked = ref.watch(hasBookmarkedProvider(
      (type: BookmarkTargetType.course, targetId: courseId),
    )).value ?? false;

    return courseAsync.when(
      data: (course) {
        if (course == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('コースが見つかりません')),
          );
        }

        final videos = ref.watch(courseVideosProvider(course));
        final progress = progressAsync.value;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                actions: [
                  IconButton(
                    icon: Icon(
                      hasBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    onPressed: () {
                      final user = ref.read(currentUserProvider);
                      if (user != null) {
                        ref.read(firestoreServiceProvider).toggleBookmark(
                          user.uid,
                          BookmarkTargetType.course,
                          courseId,
                        );
                      }
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      course.thumbnailUrl != null
                          ? CachedNetworkImage(
                              imageUrl: course.thumbnailUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(color: Colors.grey[300]),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getDifficultyColor(course.difficulty),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                course.difficultyLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              course.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Progress
              if (progress != null && progress.progressPercent > 0)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '進捗',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${(progress.progressPercent * 100).toInt()}%',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress.progressPercent,
                          backgroundColor: Colors.grey[300],
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ),

              // Course Info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.play_circle_outline,
                            label: '${course.videoCount}本の動画',
                          ),
                          const SizedBox(width: 12),
                          _InfoChip(
                            icon: Icons.timer_outlined,
                            label: course.totalDurationFormatted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        course.description,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Video List Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'カリキュラム',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${progress?.completedCount ?? 0}/${course.videoCount}完了',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Video List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final video = videos[index];
                    final isCompleted =
                        progress?.completedVideoIds.contains(video.id) ?? false;

                    return ListTile(
                      leading: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: video.youtubeThumbnail,
                              width: 80,
                              height: 45,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (isCompleted)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        video.durationFormatted,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      trailing: Icon(
                        Icons.play_arrow,
                        color: Theme.of(context).primaryColor,
                      ),
                      onTap: () => context.push(
                        '/video/${video.id}',
                        extra: {'courseId': courseId},
                      ),
                    );
                  },
                  childCount: videos.length,
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  // Find first unwatched video or start from beginning
                  final firstUnwatched = videos.firstWhere(
                    (v) => !(progress?.completedVideoIds.contains(v.id) ?? false),
                    orElse: () => videos.first,
                  );
                  context.push(
                    '/video/${firstUnwatched.id}',
                    extra: {'courseId': courseId},
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  progress != null && progress.progressPercent > 0
                      ? '続きから視聴'
                      : 'コースを開始',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('エラー: $error')),
      ),
    );
  }

  Color _getDifficultyColor(CourseDifficulty difficulty) {
    switch (difficulty) {
      case CourseDifficulty.beginner:
        return Colors.green;
      case CourseDifficulty.intermediate:
        return Colors.orange;
      case CourseDifficulty.advanced:
        return Colors.red;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
