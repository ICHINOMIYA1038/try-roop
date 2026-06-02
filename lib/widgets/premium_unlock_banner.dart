import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// 全ユーザーへのプレミアム解放中であることを伝えるバナー。
/// `config/premium_unlock.enabled == true` かつ `until` が未来の場合のみ表示。
/// それ以外は `SizedBox.shrink()` を返す。
class PremiumUnlockBanner extends ConsumerWidget {
  final EdgeInsetsGeometry padding;
  final bool compact;

  const PremiumUnlockBanner({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(24, 0, 24, 16),
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockAsync = ref.watch(premiumGlobalUnlockProvider);
    final unlocked = unlockAsync.valueOrNull ?? false;
    if (!unlocked) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF1E3), Color(0xFFFFE0C2)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF8A3D).withOpacity(0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFF8A3D),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.celebration,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎉 期間限定：プレミアム機能 全員無料解放中',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF7A3E14),
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 4),
                    Text(
                      'ローンチ記念で全コンテンツを開放しています。課金は不要です。',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF7A3E14).withOpacity(0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
