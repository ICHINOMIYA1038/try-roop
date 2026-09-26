import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/app_links.dart';
import '../../config/legal_urls.dart';
import '../../providers/providers.dart';
import '../../services/review_prompt_service.dart';
import '../../services/share_service.dart';
import '../../services/live_reminder_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ログアウト',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アカウント削除'),
        content: const Text(
          'アカウントを削除すると、すべてのデータが失われます。この操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '削除する',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;

    try {
      // 先に Firestore 側を消す。認証を消してしまうと権限が無くなり、
      // 表示名や投稿が残ったままになる。
      await ref.read(firestoreServiceProvider).deleteUserData(uid);
      await ref.read(authServiceProvider).deleteAccount();
      if (context.mounted) {
        context.go('/login');
      }
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      final message = switch (e.code) {
        'reauth-cancelled' => '確認のためのログインが中止されたため、削除を取り消しました',
        'unsupported-provider' => 'この方法ではアプリから削除できません。お問い合わせください',
        _ => 'アカウントを削除できませんでした。時間をおいてお試しください',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アカウントを削除できませんでした')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(appUserProvider).value;
    final firebaseUser = ref.watch(currentUserProvider);
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    final unreadCount = ref.watch(unreadNotificationCountProvider).value ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Use theme background
      appBar: AppBar(
        title: const Text(
          'プロフィール',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF433D39).withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFE5DCD5),
                    backgroundImage: appUser?.photoUrl != null
                        ? CachedNetworkImageProvider(appUser!.photoUrl!)
                        : null,
                    child: appUser?.photoUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    appUser?.displayName ?? firebaseUser?.displayName ?? 'ユーザー',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF433D39),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appUser?.email ?? firebaseUser?.email ?? '',
                    style: const TextStyle(
                      color: Color(0xFF8C8681),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _TryStats(),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isPremium
                          ? const Color(0xFFFF8A3D).withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPremium ? Icons.star : Icons.star_border,
                          color: isPremium
                              ? const Color(0xFFFF8A3D)
                              : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPremium ? 'プレミアム会員' : '無料会員',
                          style: TextStyle(
                            color: isPremium
                                ? const Color(0xFFFF8A3D)
                                : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Subscription CTA (for free users)
            if (!isPremium)
              GestureDetector(
                onTap: () => context.push('/subscription'),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8A3D), Color(0xFFFF6B35)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8A3D).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rocket_launch,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'プレミアム会員にアップグレード',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'すべてのコンテンツにアクセス',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Learning Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF433D39).withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    title: '通知',
                    onTap: () => context.push('/notifications'),
                    trailing: unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const _MenuDivider(),
                  _MenuItem(
                    icon: Icons.dashboard_outlined,
                    title: '学習ダッシュボード',
                    onTap: () => context.push('/dashboard'),
                  ),
                  const _MenuDivider(),
                  _MenuItem(
                    icon: Icons.bookmark_border,
                    title: 'ブックマーク',
                    onTap: () => context.push('/bookmarks'),
                  ),
                  const _MenuDivider(),
                  _MenuItem(
                    icon: Icons.emoji_events_outlined,
                    title: 'バッジコレクション',
                    onTap: () => context.push('/badges'),
                  ),
                  const _MenuDivider(),
                  _MenuItem(
                    icon: Icons.people_outline,
                    title: 'メンバー一覧',
                    onTap: () => context.push('/members'),
                  ),
                ],
              ),
            ),

            // Admin Section (管理者のみ表示)
            if (ref.watch(isAdminProvider)) ...[
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF433D39).withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings,
                              color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '管理者メニュー',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _MenuDivider(),
                    _MenuItem(
                      icon: Icons.article_outlined,
                      title: 'テキスト教材管理',
                      onTap: () => context.push('/admin/text-lessons'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Settings Menu Items
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF433D39).withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.subscriptions_outlined,
                    title: 'サブスクリプション管理',
                    onTap: () => context.push('/subscription'),
                  ),
                  const _MenuDivider(),
                  const _LiveReminderToggle(),
                  const _MenuDivider(),
                  _MenuItem(
                    icon: Icons.campaign_outlined,
                    title: 'お知らせ',
                    onTap: () => context.push('/announcements'),
                  ),
                  const _MenuDivider(),
                  // 口コミとレビューの導線。どちらも今までアプリ内に無かった。
                  _MenuItem(
                    icon: Icons.ios_share,
                    title: '友だちに教える',
                    onTap: () => ShareService.shareApp(),
                  ),
                  const _MenuDivider(),
                  _MenuItem(
                    icon: Icons.star_outline,
                    title: 'このアプリを評価する',
                    onTap: () =>
                        ReviewPromptService.openStoreListing(AppLinks.appStoreId),
                  ),
                  const _MenuDivider(),
                  _MenuItem(
                    icon: Icons.help_outline,
                    title: 'ヘルプ・お問い合わせ',
                    onTap: () =>
                        openExternalUrl(context, LegalUrls.supportContact),
                  ),
                  const _MenuDivider(),
                  _MenuItem(
                    icon: Icons.description_outlined,
                    title: '利用規約',
                    onTap: () =>
                        openExternalUrl(context, LegalUrls.termsOfService),
                  ),
                  const _MenuDivider(),
                  _MenuItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'プライバシーポリシー',
                    onTap: () =>
                        openExternalUrl(context, LegalUrls.privacyPolicy),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout / Delete
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF433D39).withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.logout,
                    title: 'ログアウト',
                    textColor: Colors.red,
                    onTap: () => _signOut(context, ref),
                  ),
                  const _MenuDivider(),
                  _MenuItem(
                    icon: Icons.delete_forever,
                    title: 'アカウント削除',
                    textColor: Colors.red,
                    onTap: () => _deleteAccount(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Version
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Color(0xFF8C8681),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: const Color(0xFF433D39).withOpacity(0.05),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: textColor ?? const Color(0xFF433D39),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor ?? const Color(0xFF433D39),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[300],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// TRY の実績。計画の「今月12回TRYしました」にあたる部分。
class _TryStats extends ConsumerWidget {
  const _TryStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(trySummaryProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _TryStat(label: '今月のTRY', value: '${summary.thisMonth}'),
        _TryStat(label: '連続日数', value: '${summary.streakDays}'),
        _TryStat(label: '挑戦ジャンル', value: '${summary.categories.length}'),
      ],
    );
  }
}

class _TryStat extends StatelessWidget {
  final String label;
  final String value;

  const _TryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF8A3D),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF8C8681)),
        ),
      ],
    );
  }
}

/// LIVE のお知らせを受け取るかどうか。
///
/// LIVE は1回15分で、始まってから気づいても間に合わない。
class _LiveReminderToggle extends ConsumerStatefulWidget {
  const _LiveReminderToggle();

  @override
  ConsumerState<_LiveReminderToggle> createState() =>
      _LiveReminderToggleState();
}

class _LiveReminderToggleState extends ConsumerState<_LiveReminderToggle> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    LiveReminderService.isEnabled().then((v) {
      if (mounted) setState(() => _enabled = v);
    });
  }

  Future<void> _toggle(bool value) async {
    if (!value) {
      await LiveReminderService.disable();
      if (mounted) setState(() => _enabled = false);
      return;
    }

    final ok = await LiveReminderService.enable();
    if (!mounted) return;

    if (!ok) {
      setState(() => _enabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('通知が許可されていません。設定アプリから許可してください。'),
        ),
      );
      return;
    }

    setState(() => _enabled = true);
    // いまの予定をもとに通知を入れる。
    final schedules = ref.read(liveSchedulesProvider).value ?? const [];
    await LiveReminderService.sync(schedules);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: const Icon(Icons.notifications_active_outlined,
          color: Color(0xFF8C8681)),
      title: const Text('LIVEのお知らせ', style: TextStyle(fontSize: 15)),
      subtitle: const Text(
        '始まる15分前に通知します',
        style: TextStyle(fontSize: 12),
      ),
      trailing: Switch(
        value: _enabled ?? false,
        onChanged: _enabled == null ? null : _toggle,
        activeThumbColor: const Color(0xFFFF8A3D),
      ),
    );
  }
}
