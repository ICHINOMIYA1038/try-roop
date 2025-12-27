import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/text_lesson.dart';
import '../../models/video.dart' show AccessLevel;
import '../../providers/providers.dart';

class AdminTextLessonListScreen extends ConsumerWidget {
  const AdminTextLessonListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(textLessonsProvider);
    final isAdmin = ref.watch(isAdminProvider);

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('アクセス拒否')),
        body: const Center(
          child: Text('管理者権限がありません'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('テキスト教材管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/admin/text-lessons/create'),
          ),
        ],
      ),
      body: lessonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
        data: (lessons) {
          if (lessons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '教材がありません',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push('/admin/text-lessons/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('新規作成'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return _LessonCard(lesson: lesson);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/text-lessons/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _LessonCard extends ConsumerWidget {
  final TextLesson lesson;

  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/admin/text-lessons/${lesson.id}/edit'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A3D).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.article_outlined,
                  color: Color(0xFFFF8A3D),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _AccessBadge(accessLevel: lesson.accessLevel),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.folder_outlined,
                          label: lesson.categoryId,
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.schedule,
                          label: '${lesson.estimatedReadingMinutes}分',
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.sort,
                          label: '順番: ${lesson.order}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('削除確認'),
                        content: Text('「${lesson.title}」を削除しますか？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('キャンセル'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('削除'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await ref
                          .read(firestoreServiceProvider)
                          .deleteTextLesson(lesson.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('削除しました')),
                        );
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('削除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessBadge extends StatelessWidget {
  final AccessLevel accessLevel;

  const _AccessBadge({required this.accessLevel});

  @override
  Widget build(BuildContext context) {
    final isPremium = accessLevel == AccessLevel.premium;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPremium ? const Color(0xFFFF8A3D) : Colors.green,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isPremium ? 'Premium' : 'Free',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
