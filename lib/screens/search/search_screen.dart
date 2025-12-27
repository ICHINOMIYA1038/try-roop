import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/video.dart';
import '../../models/course.dart';
import '../../models/post.dart';
import '../../providers/providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '動画、コース、投稿を検索...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '動画'),
            Tab(text: 'コース'),
            Tab(text: '投稿'),
          ],
        ),
      ),
      body: searchResults.when(
        data: (results) {
          final videos = results['videos'] as List<Video>;
          final courses = results['courses'] as List<Course>;
          final posts = results['posts'] as List<Post>;

          if (_searchController.text.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('キーワードを入力して検索'),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Videos
              _buildVideoList(videos),
              // Courses
              _buildCourseList(courses),
              // Posts
              _buildPostList(posts),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildVideoList(List<Video> videos) {
    if (videos.isEmpty) {
      return const Center(child: Text('動画が見つかりません'));
    }

    return ListView.builder(
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return ListTile(
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
          trailing: video.isPremium
              ? const Icon(Icons.lock, size: 16, color: Colors.amber)
              : null,
          onTap: () => context.push('/video/${video.id}'),
        );
      },
    );
  }

  Widget _buildCourseList(List<Course> courses) {
    if (courses.isEmpty) {
      return const Center(child: Text('コースが見つかりません'));
    }

    return ListView.builder(
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return ListTile(
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
          subtitle: Text(
            '${course.videoCount}本 / ${course.totalDurationFormatted}',
          ),
          onTap: () => context.push('/course/${course.id}'),
        );
      },
    );
  }

  Widget _buildPostList(List<Post> posts) {
    if (posts.isEmpty) {
      return const Center(child: Text('投稿が見つかりません'));
    }

    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: Text(
              post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?',
            ),
          ),
          title: Text(
            post.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(post.authorName),
          onTap: () => context.push('/post/${post.id}'),
        );
      },
    );
  }
}
