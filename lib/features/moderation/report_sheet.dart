import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import 'moderation_models.dart';

/// 通報とブロックの入口。
///
/// App Store ガイドライン 1.2 は、利用者が作った内容を扱うアプリに
/// 「不適切な内容を報告する手段」と「迷惑な利用者をブロックする手段」を
/// 求めている。投稿とコメントの「…」からここを開く。
class ReportSheet extends ConsumerWidget {
  final ReportTargetType targetType;
  final String targetId;
  final String? targetAuthorId;
  final String? targetAuthorName;

  const ReportSheet({
    super.key,
    required this.targetType,
    required this.targetId,
    this.targetAuthorId,
    this.targetAuthorName,
  });

  static Future<void> show(
    BuildContext context, {
    required ReportTargetType targetType,
    required String targetId,
    String? targetAuthorId,
    String? targetAuthorName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReportSheet(
        targetType: targetType,
        targetId: targetId,
        targetAuthorId: targetAuthorId,
        targetAuthorName: targetAuthorName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider)?.uid;
    final isMine = me != null && me == targetAuthorId;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: Colors.redAccent),
            title: const Text('報告する'),
            subtitle: const Text('不適切な内容として運営に知らせます'),
            onTap: () {
              Navigator.pop(context);
              _pickReason(context, ref);
            },
          ),
          if (!isMine && targetAuthorId != null) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.redAccent),
              title: Text(
                targetAuthorName == null
                    ? 'このユーザーをブロック'
                    : '${targetAuthorName!}さんをブロック',
              ),
              subtitle: const Text('この人の投稿とコメントが表示されなくなります'),
              onTap: () {
                Navigator.pop(context);
                _confirmBlock(context, ref);
              },
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _pickReason(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'どの内容にあたりますか',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            for (final reason in ReportReason.values)
              ListTile(
                title: Text(reason.label),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _send(context, ref, reason);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _send(
    BuildContext context,
    WidgetRef ref,
    ReportReason reason,
  ) async {
    final me = ref.read(currentUserProvider)?.uid;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('報告にはログインが必要です')),
      );
      return;
    }

    try {
      await ref.read(firestoreServiceProvider).report(
            reporterId: me,
            targetType: targetType,
            targetId: targetId,
            targetAuthorId: targetAuthorId,
            reason: reason,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('報告しました。運営で確認します。')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('報告を送れませんでした')),
      );
    }
  }

  Future<void> _confirmBlock(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ブロックしますか'),
        content: const Text(
          'この人の投稿とコメントが表示されなくなります。'
          'あとでプロフィールから解除できます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ブロック', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    final me = ref.read(currentUserProvider)?.uid;
    final target = targetAuthorId;
    if (me == null || target == null) return;

    try {
      await ref.read(firestoreServiceProvider).blockUser(me, target);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ブロックしました')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ブロックできませんでした')),
      );
    }
  }
}
