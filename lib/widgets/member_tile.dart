import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/app_user.dart';

class MemberTile extends StatelessWidget {
  final AppUser member;
  final VoidCallback? onTap;

  const MemberTile({
    super.key,
    required this.member,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[300],
        backgroundImage: member.photoUrl != null
            ? CachedNetworkImageProvider(member.photoUrl!)
            : null,
        child: member.photoUrl == null
            ? Text(
                member.displayName?.isNotEmpty == true
                    ? member.displayName![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        member.displayName ?? 'ユーザー',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '参加日: ${_formatDate(member.createdAt)}',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: member.isPremium
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    size: 14,
                    color: Colors.amber,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Premium',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}
