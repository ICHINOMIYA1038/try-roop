import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/comment.dart';
import '../../models/like.dart';
import '../../providers/providers.dart';
import '../../widgets/comment_tile.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postProvider(widget.postId));
    final commentsAsync = ref.watch(commentsProvider(
      (type: CommentTargetType.post, targetId: widget.postId),
    ));
    final hasLiked = ref.watch(hasLikedProvider(
      (type: LikeTargetType.post, targetId: widget.postId),
    )).value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿'),
      ),
      body: postAsync.when(
        data: (post) {
          if (post == null) {
            return const Center(child: Text('投稿が見つかりません'));
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: post.authorPhotoUrl != null
                                      ? CachedNetworkImageProvider(
                                          post.authorPhotoUrl!)
                                      : null,
                                  child: post.authorPhotoUrl == null
                                      ? Text(
                                          post.authorName.isNotEmpty
                                              ? post.authorName[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            post.authorName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (post.isPinned) ...[
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.push_pin,
                                              size: 16,
                                              color:
                                                  Theme.of(context).primaryColor,
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        _formatDate(post.createdAt),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              post.content,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                            if (post.hasImages) ...[
                              const SizedBox(height: 16),
                              ...post.imageUrls.map((url) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        imageUrl: url,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    final user = ref.read(currentUserProvider);
                                    if (user != null) {
                                      ref.read(firestoreServiceProvider).toggleLike(
                                        user.uid,
                                        LikeTargetType.post,
                                        post.id,
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      children: [
                                        Icon(
                                          hasLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          size: 24,
                                          color: hasLiked
                                              ? Colors.red
                                              : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${post.likeCount}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 24,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${post.commentCount}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      // Comments
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          'コメント',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      commentsAsync.when(
                        data: (comments) {
                          if (comments.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'まだコメントがありません',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              return CommentTile(
                                comment: comments[index],
                              );
                            },
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, stack) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('エラー: $error'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Comment input
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'コメントを入力...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isSubmitting ? null : _submitComment,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.send,
                              color: Theme.of(context).primaryColor,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final user = ref.read(appUserProvider).value;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final comment = Comment(
        id: '',
        targetType: CommentTargetType.post,
        targetId: widget.postId,
        authorId: user.uid,
        authorName: user.displayName ?? 'ユーザー',
        authorPhotoUrl: user.photoUrl,
        content: content,
        likeCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(firestoreServiceProvider).createComment(comment);
      _commentController.clear();
      ref.invalidate(commentsProvider(
        (type: CommentTargetType.post, targetId: widget.postId),
      ));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
