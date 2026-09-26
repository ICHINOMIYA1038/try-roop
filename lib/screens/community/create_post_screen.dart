import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/post.dart';
import '../../providers/providers.dart';

import '../../main.dart'; // For isDemoMode

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (build method remains same, omitting for brevity in replacement matching if I can match _submitPost only)
    // Actually, I'll replace the whole file content to be safe and easy, incorporating the imports.
    // Or just the imports and _submitPost?
    // I'll replace the whole file to ensure imports are at the top.
    
    final user = ref.watch(appUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('新規投稿'),
        actions: [
          TextButton(
            onPressed: _isSubmitting || _contentController.text.trim().isEmpty
                ? null
                : _submitPost,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '投稿',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[300],
                    child: Text(
                      user?.displayName?.isNotEmpty == true
                          ? user!.displayName![0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        hintText: '今何を考えていますか？',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      autofocus: true,
                      style: const TextStyle(fontSize: 16),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Spacer(),
                Text(
                  '${_contentController.text.length}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    final user = ref.read(appUserProvider).value;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final post = Post(
        id: isDemoMode ? 'demo_post_${DateTime.now().millisecondsSinceEpoch}' : '',
        authorId: user.uid,
        authorName: user.displayName ?? 'ユーザー',
        authorPhotoUrl: user.photoUrl,
        content: content,
        imageUrls: [],
        likeCount: 0,
        commentCount: 0,
        isPinned: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (isDemoMode) {
        addDemoPost(post);
        ref.invalidate(postsProvider);
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate network
      } else {
        await ref.read(firestoreServiceProvider).createPost(post);
        ref.invalidate(postsProvider);
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投稿しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
