import 'package:flutter/material.dart';

import '../models/chapter.dart';

class ChapterList extends StatelessWidget {
  final List<Chapter> chapters;
  final int currentChapterIndex;
  final Function(Chapter) onChapterTap;

  const ChapterList({
    super.key,
    required this.chapters,
    required this.currentChapterIndex,
    required this.onChapterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.list, size: 20),
              const SizedBox(width: 8),
              Text(
                'チャプター (${chapters.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chapters.length,
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            final isActive = index == currentChapterIndex;

            return InkWell(
              onTap: () => onChapterTap(chapter),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFFF8A3D).withOpacity(0.1)
                      : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color: isActive
                          ? const Color(0xFFFF8A3D)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Play indicator or chapter number
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFFF8A3D)
                            : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isActive
                            ? const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 18,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Time
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        chapter.startTimeFormatted,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    Expanded(
                      child: Text(
                        chapter.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive
                              ? const Color(0xFFFF8A3D)
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
