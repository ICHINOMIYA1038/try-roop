import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/feature_flags.dart';
import '../../models/bookmark.dart';
import '../../providers/providers.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ブックマーク'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '動画'),
            Tab(text: 'コース'),
            Tab(text: '投稿'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BookmarkList(targetType: BookmarkTargetType.video),
          _BookmarkList(targetType: BookmarkTargetType.course),
          _BookmarkList(targetType: BookmarkTargetType.post),
        ],
      ),
    );
  }
}

class _BookmarkList extends ConsumerWidget {
  final BookmarkTargetType targetType;

  const _BookmarkList({required this.targetType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show coming soon for video bookmarks when video content is disabled
    if (targetType == BookmarkTargetType.video && !FeatureFlags.isVideoContentEnabled) {
      return const _VideoComingSoonPlaceholder();
    }

    final bookmarksAsync = ref.watch(userBookmarksProvider(targetType));

    return bookmarksAsync.when(
      data: (bookmarks) {
        if (bookmarks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('ブックマークした${_getTypeName()}はありません'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookmarks.length,
          itemBuilder: (context, index) {
            final bookmark = bookmarks[index];
            return _BookmarkItem(
              bookmark: bookmark,
              onTap: () => _navigateToItem(context, bookmark),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラー: $error')),
    );
  }

  String _getTypeName() {
    switch (targetType) {
      case BookmarkTargetType.video:
        return '動画';
      case BookmarkTargetType.course:
        return 'コース';
      case BookmarkTargetType.post:
        return '投稿';
    }
  }

  void _navigateToItem(BuildContext context, Bookmark bookmark) {
    switch (bookmark.targetType) {
      case BookmarkTargetType.video:
        context.push('/video/${bookmark.targetId}');
        break;
      case BookmarkTargetType.course:
        context.push('/course/${bookmark.targetId}');
        break;
      case BookmarkTargetType.post:
        context.push('/post/${bookmark.targetId}');
        break;
    }
  }
}

class _BookmarkItem extends ConsumerWidget {
  final Bookmark bookmark;
  final VoidCallback onTap;

  const _BookmarkItem({
    required this.bookmark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load the actual item based on type
    switch (bookmark.targetType) {
      case BookmarkTargetType.video:
        final videoAsync = ref.watch(videoProvider(bookmark.targetId));
        return videoAsync.when(
          data: (video) {
            if (video == null) {
              return const SizedBox.shrink();
            }
            return Card(
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: video.youtubeThumbnail,
                    width: 80,
                    height: 45,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(video.durationFormatted),
                onTap: onTap,
              ),
            );
          },
          loading: () => const Card(
            child: ListTile(
              leading: SizedBox(
                width: 80,
                height: 45,
                child: Center(child: CircularProgressIndicator()),
              ),
              title: Text('読み込み中...'),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );

      case BookmarkTargetType.course:
        final courseAsync = ref.watch(courseProvider(bookmark.targetId));
        return courseAsync.when(
          data: (course) {
            if (course == null) {
              return const SizedBox.shrink();
            }
            return Card(
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: course.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: course.thumbnailUrl!,
                          width: 80,
                          height: 45,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 80,
                          height: 45,
                          color: Colors.grey[300],
                          child: const Icon(Icons.school),
                        ),
                ),
                title: Text(
                  course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${course.videoCount}本 / ${course.totalDurationFormatted}'),
                onTap: onTap,
              ),
            );
          },
          loading: () => const Card(
            child: ListTile(
              title: Text('読み込み中...'),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );

      case BookmarkTargetType.post:
        final postAsync = ref.watch(postProvider(bookmark.targetId));
        return postAsync.when(
          data: (post) {
            if (post == null) {
              return const SizedBox.shrink();
            }
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    post.authorName.isNotEmpty
                        ? post.authorName[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(
                  post.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(post.authorName),
                onTap: onTap,
              ),
            );
          },
          loading: () => const Card(
            child: ListTile(
              title: Text('読み込み中...'),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );
    }
  }
}

/// Placeholder widget for video section when video content is coming soon
class _VideoComingSoonPlaceholder extends StatelessWidget {
  const _VideoComingSoonPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8A3D).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.video_library_outlined,
                size: 48,
                color: Color(0xFFFF8A3D),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '動画コンテンツ準備中',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF433D39),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'もうしばらくお待ちください',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
