import 'package:flutter/material.dart' hide Badge;
import '../models/badge.dart';

class BadgeChip extends StatelessWidget {
  final Badge badge;
  final bool isEarned;
  final VoidCallback? onTap;

  const BadgeChip({
    super.key,
    required this.badge,
    this.isEarned = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isEarned
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEarned
                ? Theme.of(context).primaryColor.withOpacity(0.3)
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              badge.iconUrl,
              style: TextStyle(
                fontSize: 16,
                color: isEarned ? null : Colors.grey,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              badge.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isEarned ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BadgeCard extends StatelessWidget {
  final Badge badge;
  final bool isEarned;
  final VoidCallback? onTap;

  const BadgeCard({
    super.key,
    required this.badge,
    this.isEarned = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isEarned ? Colors.white : const Color(0xFFE5DCD5).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEarned ? const Color(0xFFFF8A3D).withOpacity(0.3) : Colors.transparent,
            width: 2,
          ),
          boxShadow: isEarned
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF8A3D).withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isEarned)
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF8A3D).withOpacity(0.05),
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isEarned
                        ? const Color(0xFFFF8A3D).withOpacity(0.1)
                        : Colors.white.withOpacity(0.5),
                  ),
                  child: Text(
                    isEarned ? badge.iconUrl : '🔒',
                    style: TextStyle(
                      fontSize: 32,
                      color: isEarned ? null : Colors.grey[400],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    isEarned ? badge.name : '???',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isEarned
                          ? const Color(0xFF433D39)
                          : const Color(0xFF8C8681),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
