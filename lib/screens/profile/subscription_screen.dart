import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../config/legal_urls.dart';
import '../../providers/providers.dart';
import '../../services/analytics_service.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.paywallViewed('subscription_screen');
  }

  Future<void> _purchase(Package package) async {
    setState(() => _isLoading = true);
    AnalyticsService.purchaseStarted(package.storeProduct.identifier);

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final success = await subscriptionService.purchasePackage(package);

      if (success) {
        AnalyticsService.purchaseCompleted(package.storeProduct.identifier);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('購入が完了しました！'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('購入を完了できませんでした')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final success = await subscriptionService.restorePurchases();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '購入が復元されました' : '復元する購入がありません'),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );

        if (success) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('購入を復元できませんでした')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final packagesAsync = ref.watch(packagesProvider);
    final isPremium = ref.watch(isPremiumProvider).value ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'プレミアム会員',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A3D), Color(0xFFFF6B35)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Try Loop メンバーシップ',
                    textAlign: TextAlign.center,
                    // 端末幅で折り返さない大きさにする。
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPremium
                        ? '現在プレミアム会員です'
                        : '15分のLIVEレッスンに参加できます',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Benefits
            // 未実装の機能は書かない。約束すると審査でも利用者からも問われる。
            const _BenefitItem(
              icon: Icons.podcasts,
              title: 'LIVEレッスンに参加できます',
              description: '1回15分。講師がその場で教えます',
            ),
            const _BenefitItem(
              icon: Icons.play_circle_filled,
              title: '見逃し配信が見られます',
              description: 'LIVEに出られなかった回も、あとから視聴できます',
            ),
            const _BenefitItem(
              icon: Icons.school,
              title: 'すべての講座が受け放題',
              description: '筋トレ・ボクササイズ・韓国語。第2回以降もすべて',
            ),
            const _BenefitItem(
              icon: Icons.checklist,
              title: '進捗とTRYの記録',
              description: 'どこまで進んだか、今月何回挑戦したかが残ります',
            ),

            const SizedBox(height: 32),

            // Packages
            if (!isPremium)
              packagesAsync.when(
                data: (packages) {
                  if (packages.isEmpty) {
                    return _PlanOutline(onRetry: () => ref.invalidate(packagesProvider));
                  }

                  return Column(
                    children: packages.map((package) {
                      return _PackageCard(
                        package: package,
                        isLoading: _isLoading,
                        onTap: () => _purchase(package),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) =>
                    _PlanOutline(onRetry: () => ref.invalidate(packagesProvider)),
              ),

            const SizedBox(height: 16),

            // Restore button
            if (!isPremium)
              TextButton(
                onPressed: _isLoading ? null : _restorePurchases,
                child: const Text(
                  '購入を復元',
                  style: TextStyle(color: Color(0xFFFF8A3D)),
                ),
              ),

            const SizedBox(height: 16),

            // Terms
            Text(
              '購読は自動更新されます。いつでもキャンセル可能です。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () =>
                      openExternalUrl(context, LegalUrls.termsOfService),
                  child: const Text(
                    '利用規約',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                Text('・', style: TextStyle(color: Colors.grey[500])),
                TextButton(
                  onPressed: () =>
                      openExternalUrl(context, LegalUrls.privacyPolicy),
                  child: const Text(
                    'プライバシーポリシー',
                    style: TextStyle(fontSize: 12),
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

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A3D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF8A3D),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
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
    );
  }
}

class _PackageCard extends StatelessWidget {
  final Package package;
  final bool isLoading;
  final VoidCallback onTap;

  const _PackageCard({
    required this.package,
    required this.isLoading,
    required this.onTap,
  });

  String get _packageTitle {
    switch (package.packageType) {
      case PackageType.monthly:
        return '月額プラン';
      case PackageType.annual:
        return '年額プラン';
      case PackageType.lifetime:
        return '買い切りプラン';
      default:
        return package.storeProduct.title;
    }
  }

  String? get _discount {
    if (package.packageType == PackageType.annual) {
      return '2ヶ月分お得！';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: package.packageType == PackageType.annual
                ? const Color(0xFFFF8A3D)
                : Colors.grey[300]!,
            width: package.packageType == PackageType.annual ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _packageTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_discount != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8A3D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _discount!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    package.storeProduct.priceString,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF8A3D),
                    ),
                  ),
                ],
              ),
            ),
            isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: 16,
                  ),
          ],
        ),
      ),
    );
  }
}

/// プランが取得できなかったときに出す概要。
///
/// 金額は伏せない（App Store の登録と同じ）。ただし購入は促さず、
/// 読み直しの導線だけ置く。ここで購入ボタンを出すと、押しても
/// 何も起きないことになる。
class _PlanOutline extends StatelessWidget {
  final VoidCallback onRetry;

  const _PlanOutline({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DCD5)),
      ),
      child: Column(
        children: [
          const Text(
            'Try Loop メンバーシップ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            '月額 ¥3,300',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF8A3D),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ただいまプランを読み込めませんでした。\n通信環境をご確認のうえ、もう一度お試しください。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.6),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('もう一度読み込む'),
          ),
        ],
      ),
    );
  }
}
