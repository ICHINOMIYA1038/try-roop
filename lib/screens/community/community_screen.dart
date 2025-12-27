import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/like.dart';
import '../../providers/providers.dart';
import '../../widgets/post_card.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('コミュニティ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => context.push('/members'),
          ),
        ],
      ),
      body: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('まだ投稿がありません'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(postsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostCard(
                  post: post,
                  onTap: () => context.push('/post/${post.id}'),
                  onLike: () {
                    final user = ref.read(currentUserProvider);
                    if (user != null) {
                      ref.read(firestoreServiceProvider).toggleLike(
                        user.uid,
                        LikeTargetType.post,
                        post.id,
                      );
                    }
                  },
                  onComment: () => context.push('/post/${post.id}'),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラーが発生しました: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/post/create'),
        child: const Icon(Icons.edit),
      ),
    );
  }
}
