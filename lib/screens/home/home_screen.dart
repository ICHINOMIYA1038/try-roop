import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/providers.dart';
import '../../models/video.dart';
import '../../models/category.dart';
import '../../models/text_lesson.dart';
import '../../models/event.dart';
import '../../widgets/video_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _categoryCount = 0;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _initTabController(List<Category> categories) {
    final newCount = categories.length + 1;
    if (_categoryCount != newCount) {
      _tabController?.dispose();
      _categoryCount = newCount;
      _tabController = TabController(
        length: newCount, // +1 for "すべて" tab
        vsync: this,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final appUser = ref.watch(appUserProvider).value;
    final isPremium = ref.watch(isPremiumProvider).value ?? false;

    return categoriesAsync.when(
      data: (categories) {
        _initTabController(categories);

        return Scaffold(
          // Background color handled by theme (Color(0xFFF9F7F4))
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'こんにちは${appUser?.displayName != null ? '、\n${appUser!.displayName}さん' : ''}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: -0.5,
                                color: Color(0xFF433D39), // Warm dark grey
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isPremium
                                    ? const Color(0xFFFF8A3D).withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isPremium ? 'プレミアム会員' : '無料会員',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isPremium
                                      ? const Color(0xFFFF8A3D)
                                      : const Color(0xFF8C8681),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFF8A3D).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFFE5DCD5),
                            backgroundImage: appUser?.photoUrl != null
                                ? CachedNetworkImageProvider(appUser!.photoUrl!)
                                : null,
                            child: appUser?.photoUrl == null
                                ? const Icon(Icons.person,
                                    color: Colors.white, size: 28)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Upgrade Banner (for free users)
                if (!isPremium)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: GestureDetector(
                      onTap: () => context.push('/subscription'),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFF8A3D), Color(0xFFFF6B35)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF8A3D).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.auto_awesome,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'プレミアム会員になる',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'すべての動画が見放題になります',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Category Tabs (Pill/Chip Style)
                TabBar(
                  controller: _tabController!,
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF8C8681), // Warm grey
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: const Color(0xFFFF8A3D),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8A3D).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  tabs: [
                    const Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('すべて'),
                      ),
                    ),
                    ...categories.map((c) => Tab(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(c.name),
                          ),
                        )),
                  ],
                ),
                
                const SizedBox(height: 16),

                // Category Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController!,
                    children: [
                      _AllVideosTab(isPremium: isPremium),
                      ...categories.map(
                        (category) => _CategoryVideosTab(
                          category: category,
                          isPremium: isPremium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

// Tab for showing all videos
class _AllVideosTab extends ConsumerWidget {
  final bool isPremium;

  const _AllVideosTab({required this.isPremium});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(videosProvider);
    final freeTextLessons = ref.watch(freeTextLessonsProvider);
    final eventsAsync = ref.watch(eventsProvider);

    return videosAsync.when(
      data: (videos) {
        final freeVideos =
            videos.where((v) => v.accessLevel == AccessLevel.free).toList();
        final premiumVideos =
            videos.where((v) => v.accessLevel == AccessLevel.premium).toList();

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            // Free Videos Section
            if (freeVideos.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '無料コンテンツ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: freeVideos.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < freeVideos.length - 1 ? 12 : 0,
                      ),
                      child: VideoCard(
                        video: freeVideos[index],
                        onTap: () =>
                            context.push('/video/${freeVideos[index].id}'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Text Lessons Section
            if (freeTextLessons.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.article,
                          color: Color(0xFFFF8A3D),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'テキスト学習',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.push('/text-lessons'),
                      child: const Text(
                        'すべて見る',
                        style: TextStyle(color: Color(0xFFFF8A3D)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: freeTextLessons.length > 5 ? 5 : freeTextLessons.length,
                  itemBuilder: (context, index) {
                    final lesson = freeTextLessons[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < freeTextLessons.length - 1 ? 12 : 0,
                      ),
                      child: _TextLessonCard(
                        lesson: lesson,
                        onTap: () => context.push('/text-lesson/${lesson.id}'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Events Section
            _buildEventsSection(context, eventsAsync),

            // Premium Videos Section
            if (premiumVideos.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      'プレミアムコンテンツ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A3D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: premiumVideos.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < premiumVideos.length - 1 ? 12 : 0,
                      ),
                      child: VideoCard(
                        video: premiumVideos[index],
                        isLocked: !isPremium,
                        onTap: () {
                          if (isPremium) {
                            context.push('/video/${premiumVideos[index].id}');
                          } else {
                            context.push('/subscription');
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEventsSection(BuildContext context, AsyncValue<List<Event>> eventsAsync) {
    return eventsAsync.when(
      data: (events) {
        final upcomingEvents = events
            .where((e) => e.isUpcoming)
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));

        if (upcomingEvents.isEmpty) return const SizedBox.shrink();

        final displayEvents = upcomingEvents.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.event,
                        color: Color(0xFFFF8A3D),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'イベント',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push('/events'),
                    child: const Text(
                      'すべて見る',
                      style: TextStyle(color: Color(0xFFFF8A3D)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: displayEvents.length,
                itemBuilder: (context, index) {
                  final event = displayEvents[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < displayEvents.length - 1 ? 12 : 0,
                    ),
                    child: _EventPreviewCard(
                      event: event,
                      onTap: () => context.push('/event/${event.id}'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}

// Card for event preview on home screen
class _EventPreviewCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _EventPreviewCard({
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A433D39),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Date block
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${event.startAt.month}/${event.startAt.day}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF8A3D),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Event type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.isOnline
                        ? const Color(0xFFE3F2FD)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        event.isOnline ? Icons.videocam : Icons.location_on,
                        size: 12,
                        color: event.isOnline
                            ? const Color(0xFF1976D2)
                            : const Color(0xFF388E3C),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.eventTypeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: event.isOnline
                              ? const Color(0xFF1976D2)
                              : const Color(0xFF388E3C),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Capacity
                if (event.isFull)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '満席',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  )
                else
                  Text(
                    '残り${event.availableSpots}席',
                    style: TextStyle(
                      fontSize: 11,
                      color: event.availableSpots <= 5
                          ? Colors.orange.shade700
                          : Colors.grey.shade600,
                      fontWeight: event.availableSpots <= 5
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF433D39),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  event.timeFormatted,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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

// Card for text lesson preview on home screen
class _TextLessonCard extends StatelessWidget {
  final TextLesson lesson;
  final VoidCallback onTap;

  const _TextLessonCard({
    required this.lesson,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF433D39).withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A3D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.article_rounded,
                    color: Color(0xFFFF8A3D),
                    size: 20,
                  ),
                ),
                const Spacer(),
                Text(
                  '約${lesson.estimatedReadingMinutes}分',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8C8681), // Warm grey
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              lesson.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF433D39),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Tab for showing videos of a specific category
class _CategoryVideosTab extends ConsumerWidget {
  final Category category;
  final bool isPremium;

  const _CategoryVideosTab({
    required this.category,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(videosProvider);

    return videosAsync.when(
      data: (allVideos) {
        final videos =
            allVideos.where((v) => v.categoryId == category.id).toList();

        if (videos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'このカテゴリにはまだ動画がありません',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            final isLocked =
                !isPremium && video.accessLevel == AccessLevel.premium;

            return VideoCard(
              video: video,
              isLocked: isLocked,
              onTap: () {
                if (isLocked) {
                  context.push('/subscription');
                } else {
                  context.push('/video/${video.id}');
                }
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
