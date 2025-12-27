import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../widgets/badge_chip.dart';

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBadgesAsync = ref.watch(badgesProvider);
    final userStatsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('バッジ図鑑'),
        centerTitle: true,
      ),
      body: allBadgesAsync.when(
        data: (allBadges) {
          final earnedBadgeIds = userStatsAsync.value?.badgeIds ?? [];
          final progress = earnedBadgeIds.length / allBadges.length;
          final percentage = (progress * 100).toInt();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '獲得率',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF8C8681),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$percentage',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFF8A3D),
                                      height: 1.0,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 6, left: 2),
                                    child: Text(
                                      '%',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF8A3D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE5DCD5),
                              ),
                            ),
                            child: Text(
                              '${earnedBadgeIds.length} / ${allBadges.length} 個',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF433D39),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: const Color(0xFFE5DCD5),
                          color: const Color(0xFFFF8A3D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final badge = allBadges[index];
                      final isEarned = earnedBadgeIds.contains(badge.id);

                      return BadgeCard(
                        badge: badge,
                        isEarned: isEarned,
                        onTap: () {
                          _showBadgeDetailDialog(context, badge, isEarned);
                        },
                      );
                    },
                    childCount: allBadges.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  void _showBadgeDetailDialog(BuildContext context, dynamic badge, bool isEarned) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F7F4),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isEarned
                      ? const Color(0xFFFF8A3D).withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                ),
                child: Text(
                  isEarned ? badge.iconUrl : '🔒',
                  style: const TextStyle(fontSize: 64),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEarned ? badge.name : '???',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF433D39),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isEarned ? badge.description : 'このバッジはまだ獲得していません。\n条件を満たしてロックを解除しましょう！',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8C8681),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (isEarned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '獲得済み',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8C8681),
                ),
                child: const Text('閉じる'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
