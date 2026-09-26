import 'package:flutter_test/flutter_test.dart';
import 'package:tryroop_campus_live_flutter/features/moderation/moderation_models.dart';

void main() {
  group('通報', () {
    test('同じ人が同じ対象を何度出しても同じIDになる', () {
      final a = Report.buildId(
        reporterId: 'u1',
        targetType: ReportTargetType.post,
        targetId: 'p1',
      );
      final b = Report.buildId(
        reporterId: 'u1',
        targetType: ReportTargetType.post,
        targetId: 'p1',
      );
      expect(a, b);
      expect(a, 'u1_post_p1');
    });

    test('対象が違えば別のIDになる', () {
      final post = Report.buildId(
        reporterId: 'u1',
        targetType: ReportTargetType.post,
        targetId: 'x',
      );
      final comment = Report.buildId(
        reporterId: 'u1',
        targetType: ReportTargetType.comment,
        targetId: 'x',
      );
      expect(post, isNot(comment));
    });

    test('保存して読み直しても値が変わらない', () {
      final r = Report(
        id: 'r1',
        reporterId: 'u1',
        targetType: ReportTargetType.comment,
        targetId: 'c1',
        targetAuthorId: 'u2',
        reason: ReportReason.harassment,
        createdAt: DateTime(2026, 9, 26),
      );
      final back = Report.fromMap(r.toMap(), 'r1');

      expect(back.targetType, ReportTargetType.comment);
      expect(back.reason, ReportReason.harassment);
      expect(back.targetAuthorId, 'u2');
      expect(back.status, ReportStatus.open);
    });

    test('知らない理由が来ても落ちない', () {
      final back = Report.fromMap({
        'reporterId': 'u1',
        'targetType': 'unknown',
        'targetId': 'x',
        'reason': 'unknown',
        'status': 'unknown',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      }, 'r');
      expect(back.reason, ReportReason.other);
      expect(back.targetType, ReportTargetType.post);
      expect(back.status, ReportStatus.open);
    });

    test('理由に表示名がある', () {
      expect(ReportReason.harassment.label, '誹謗中傷・嫌がらせ');
      for (final r in ReportReason.values) {
        expect(r.label, isNotEmpty);
      }
    });
  });

  group('ブロック', () {
    test('IDは自分と相手の組み合わせ', () {
      expect(BlockedUser.buildId('me', 'you'), 'me_you');
      expect(BlockedUser.buildId('me', 'you'),
          isNot(BlockedUser.buildId('you', 'me')));
    });

    test('保存して読み直せる', () {
      final b = BlockedUser(
        userId: 'me',
        blockedUserId: 'you',
        createdAt: DateTime(2026, 9, 26),
      );
      final back = BlockedUser.fromMap(b.toMap());
      expect(back.userId, 'me');
      expect(back.blockedUserId, 'you');
    });
  });
}
