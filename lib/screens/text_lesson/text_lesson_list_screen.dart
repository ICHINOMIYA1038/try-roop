import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/text_lesson.dart';
import '../../providers/providers.dart';

class TextLessonListScreen extends ConsumerStatefulWidget {
  const TextLessonListScreen({super.key});

  @override
  ConsumerState<TextLessonListScreen> createState() =>
      _TextLessonListScreenState();
}

class _TextLessonListScreenState extends ConsumerState<TextLessonListScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(textLessonsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isPremium = ref.watch(isPremiumProvider).value ?? false;

    return lessonsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('テキスト学習')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('テキスト学習')),
        body: Center(child: Text('エラーが発生しました: $error')),
      ),
      data: (lessons) {
        // Apply category filter
        var filteredLessons = lessons;
        if (_selectedCategoryId != null) {
          filteredLessons = lessons
              .where((l) => l.categoryId == _selectedCategoryId)
              .toList();
        }

        return _buildContent(
          context,
          filteredLessons,
          categoriesAsync,
          isPremium,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<TextLesson> filteredLessons,
    AsyncValue categoriesAsync,
    bool isPremium,
  ) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('テキスト学習'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: categoriesAsync.when(
                data: (categories) => Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('すべて'),
                      selected: _selectedCategoryId == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryId = null;
                        });
                      },
                    ),
                    ...categories.map((category) => FilterChip(
                          label: Text(category.name),
                          selected: _selectedCategoryId == category.id,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryId =
                                  selected ? category.id : null;
                            });
                          },
                        )),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
          const Divider(height: 1),
          // Lesson list
          Expanded(
            child: filteredLessons.isEmpty
                ? const Center(child: Text('レッスンがありません'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredLessons.length,
                    itemBuilder: (context, index) {
                      final lesson = filteredLessons[index];
                      final canAccess = lesson.isFree || isPremium;

                      return _LessonCard(
                        lesson: lesson,
                        canAccess: canAccess,
                        onTap: () {
                          if (canAccess) {
                            context.push('/text-lesson/${lesson.id}');
                          } else {
                            _showPremiumDialog(context);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プレミアム限定'),
        content: const Text('このレッスンはプレミアム会員限定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/subscription');
            },
            child: const Text('詳細を見る'),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final TextLesson lesson;
  final bool canAccess;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lesson,
    required this.canAccess,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: canAccess
                      ? const Color(0xFFFF8A3D).withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.article_outlined,
                  color: canAccess ? const Color(0xFFFF8A3D) : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lesson.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: canAccess ? null : Colors.grey,
                                ),
                          ),
                        ),
                        if (!lesson.isFree)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: canAccess
                                  ? const Color(0xFFFF8A3D)
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(4),
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
                    const SizedBox(height: 4),
                    Text(
                      lesson.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: canAccess ? Colors.grey[600] : Colors.grey,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '約${lesson.estimatedReadingMinutes}分',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right,
                color: canAccess ? Colors.grey : Colors.grey[300],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
