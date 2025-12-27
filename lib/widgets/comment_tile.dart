import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/comment.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onReply;
  final VoidCallback? onLike;
  final bool isLiked;

  const CommentTile({
    super.key,
    required this.comment,
    this.onReply,
    this.onLike,
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: comment.isReply ? 48 : 16,
        right: 16,
        top: 8,
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: comment.isReply ? 14 : 18,
            backgroundColor: Colors.grey[300],
            backgroundImage: comment.authorPhotoUrl != null
                ? CachedNetworkImageProvider(comment.authorPhotoUrl!)
                : null,
            child: comment.authorPhotoUrl == null
                ? Text(
                    comment.authorName.isNotEmpty
                        ? comment.authorName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: comment.isReply ? 12 : 14,
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
                      comment.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: onLike,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: isLiked ? Colors.red : Colors.grey[600],
                            ),
                            if (comment.likeCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${comment.likeCount}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (!comment.isReply) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onReply,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            '返信',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.month}/${date.day}';
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
