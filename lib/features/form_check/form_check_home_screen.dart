import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../services/share_service.dart';
import '../../widgets/error_view.dart';
import 'form_check_screen.dart';
import 'form_session.dart';
import 'pose_metrics.dart';

/// フォーム測定の入口。種目を選んで測り、これまでの記録を見る。
class FormCheckHomeScreen extends ConsumerWidget {
  const FormCheckHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(formSessionsProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('フォームを測る')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '全身が映るところにスマホを置いて、3歩ほど離れてください。'
            '映像は端末の中だけで処理され、どこにも送られません。',
            style: TextStyle(color: Color(0xFF8C8681), height: 1.6),
          ),
          const SizedBox(height: 20),
          for (final kind in ExerciseKind.values) ...[
            _ExerciseCard(kind: kind),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 20),
          const Text(
            'これまでの記録',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          sessionsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'まだ記録がありません。',
                    style: TextStyle(color: Color(0xFF8C8681)),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < sessions.length; i++)
                    _SessionTile(
                      session: sessions[i],
                      // 同じ種目のひとつ前と比べる。
                      previous: sessions
                          .skip(i + 1)
                          .where((s) => s.kind == sessions[i].kind)
                          .firstOrNull,
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(error: e),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ExerciseKind kind;

  const _ExerciseCard({required this.kind});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(
          kind == ExerciseKind.squat
              ? Icons.accessibility_new
              : Icons.sports_martial_arts,
          color: const Color(0xFFFF8A3D),
          size: 32,
        ),
        title: Text(
          kind.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          kind == ExerciseKind.squat
              ? '回数と、いちばん深くしゃがめた角度を測ります'
              : '回数と、足がどこまで上がったかを測ります',
          style: const TextStyle(fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FormCheckScreen(kind: kind),
          ),
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final FormSession session;
  final FormSession? previous;

  const _SessionTile({required this.session, this.previous});

  @override
  Widget build(BuildContext context) {
    final improvement = session.improvementOver(previous);
    final symmetry = session.symmetry;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  session.kind.label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  _formatDate(session.recordedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8C8681),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.ios_share, size: 18),
                  tooltip: '結果を共有',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => ShareService.shareFormResult(session),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${session.reps}回  /  ${_best(session)}'),
            if (improvement != null && improvement.abs() > 0.01) ...[
              const SizedBox(height: 4),
              Text(
                improvement > 0
                    ? '前回より良くなっています'
                    : '前回より下がっています',
                style: TextStyle(
                  fontSize: 12,
                  color: improvement > 0 ? Colors.green : Colors.orange,
                ),
              ),
            ],
            if (symmetry != null && !symmetry.isBalanced) ...[
              const SizedBox(height: 4),
              Text(
                '${symmetry.weakerSide == Side.left ? '左' : '右'}が'
                '${(symmetry.imbalanceRatio * 100).round()}%ぶん届いていません',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _best(FormSession session) {
    final value = session.bestValue;
    if (value == null) return '—';
    return switch (session.kind) {
      ExerciseKind.squat => 'いちばん深く ${value.round()}度',
      ExerciseKind.kick => 'いちばん高く ${classifyKickHeight(value).label}',
    };
  }

  String _formatDate(DateTime d) => '${d.month}/${d.day} '
      '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}
