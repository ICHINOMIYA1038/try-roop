import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../widgets/error_view.dart';

/// ブロックした相手の一覧と解除。
///
/// ブロックできるだけで解除できないと、押すのが怖くて使われない。
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedAsync = ref.watch(blockedUserIdsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ブロックしたユーザー')),
      body: blockedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e),
        data: (ids) {
          if (ids.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'ブロックしているユーザーはいません。',
                  style: TextStyle(color: Color(0xFF8C8681)),
                ),
              ),
            );
          }

          final list = ids.toList()..sort();
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _BlockedTile(userId: list[i]),
          );
        },
      ),
    );
  }
}

class _BlockedTile extends ConsumerWidget {
  final String userId;

  const _BlockedTile({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(memberProvider(userId)).value;

    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFE5DCD5),
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(user?.displayName ?? 'ユーザー'),
      trailing: TextButton(
        onPressed: () => _unblock(context, ref),
        child: const Text('解除'),
      ),
    );
  }

  Future<void> _unblock(BuildContext context, WidgetRef ref) async {
    final me = ref.read(currentUserProvider)?.uid;
    if (me == null) return;

    try {
      await ref.read(firestoreServiceProvider).unblockUser(me, userId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ブロックを解除しました')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('解除できませんでした')),
      );
    }
  }
}
