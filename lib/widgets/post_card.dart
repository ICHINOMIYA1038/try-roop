import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../models/like.dart';
import '../providers/providers.dart';

class PostCard extends ConsumerWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasLiked = ref.watch(hasLikedProvider(
      (type: LikeTargetType.post, targetId: post.id),
    )).value ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: post.authorPhotoUrl != null
                        ? CachedNetworkImageProvider(post.authorPhotoUrl!)
                        : null,
                    child: post.authorPhotoUrl == null
                        ? Text(
                            post.authorName.isNotEmpty
                                ? post.authorName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 18,
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
                                fontSize: 14,
                              ),
                            ),
                            if (post.isPinned) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.push_pin,
                                size: 14,
                                color: Theme.of(context).primaryColor,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _formatDate(post.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.content,
                style: const TextStyle(fontSize: 15),
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
              ),
              if (post.hasImages) ...[
                const SizedBox(height: 12),
                _buildImageGrid(),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  InkWell(
                    onTap: onLike,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Icon(
                            hasLiked ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: hasLiked ? Colors.red : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likeCount}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: onComment,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.commentCount}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildImageGrid() {
    if (post.imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: post.imageUrls.first,
          fit: BoxFit.cover,
          height: 200,
          width: double.infinity,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: post.imageUrls.length > 4 ? 4 : post.imageUrls.length,
      itemBuilder: (context, index) {
        if (index == 3 && post.imageUrls.length > 4) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrls[index],
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '+${post.imageUrls.length - 4}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: post.imageUrls[index],
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.year}/${date.month}/${date.day}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}日前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}時間前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }
}
