import 'package:flutter/material.dart';

import '../../services/share_service.dart';
import 'form_session.dart';
import 'pose_metrics.dart';

/// 測り終えた直後に出す結果。
///
/// 人に見せたくなるのは測った直後なので、共有はここに置く。
/// 履歴からも共有できるが、その頃には気持ちが冷めている。
class FormResultSheet extends StatelessWidget {
  final FormSession session;
  final FormSession? previous;

  const FormResultSheet({
    super.key,
    required this.session,
    this.previous,
  });

  static Future<void> show(
    BuildContext context, {
    required FormSession session,
    FormSession? previous,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FormResultSheet(session: session, previous: previous),
    );
  }

  @override
  Widget build(BuildContext context) {
    final improvement = session.improvementOver(previous);
    final symmetry = session.symmetry;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'おつかれさまでした',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Figure(label: '回数', value: '${session.reps}'),
                _Figure(label: _bestLabel(), value: _bestValue()),
              ],
            ),
            if (improvement != null && improvement.abs() > 0.01) ...[
              const SizedBox(height: 20),
              Text(
                improvement > 0 ? '前回より良くなっています' : '前回より下がっています',
                style: TextStyle(
                  color: improvement > 0 ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (symmetry != null && !symmetry.isBalanced) ...[
              const SizedBox(height: 12),
              Text(
                '${symmetry.weakerSide == Side.left ? '左' : '右'}が'
                '${(symmetry.imbalanceRatio * 100).round()}%ぶん届いていません',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.orange, fontSize: 13),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => ShareService.shareFormResult(session),
                icon: const Icon(Icons.ios_share, size: 18),
                label: const Text('結果を共有する'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A3D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _bestLabel() => switch (session.kind) {
        ExerciseKind.squat => 'いちばん深く',
        ExerciseKind.kick => 'いちばん高く',
      };

  String _bestValue() {
    final value = session.bestValue;
    if (value == null) return '—';
    return switch (session.kind) {
      ExerciseKind.squat => '${value.round()}度',
      ExerciseKind.kick => classifyKickHeight(value).label,
    };
  }
}

class _Figure extends StatelessWidget {
  final String label;
  final String value;

  const _Figure({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Color(0xFF433D39),
          ),
        ),
      ],
    );
  }
}
