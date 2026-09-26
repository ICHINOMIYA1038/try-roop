import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryroop_campus_live_flutter/features/form_check/pose_metrics.dart';
import 'package:tryroop_campus_live_flutter/features/form_check/pose_overlay.dart';

void main() {
  group('座標の変換', () {
    test('縦横の比が同じなら、そのまま拡大される', () {
      final o = projectPoint(
        const PosePoint(50, 100),
        const Size(100, 200),
        const Size(200, 400),
      );
      expect(o.dx, closeTo(100, 0.001));
      expect(o.dy, closeTo(200, 0.001));
    });

    test('比が違うときは、はみ出したぶんを中央に寄せる', () {
      // 画像 100x100 を 200x100 の枠に cover で入れると、
      // 倍率2で縦が 200 になり、上下に 50 ずつはみ出す。
      final o = projectPoint(
        const PosePoint(50, 50),
        const Size(100, 100),
        const Size(200, 100),
      );
      expect(o.dx, closeTo(100, 0.001));
      expect(o.dy, closeTo(50, 0.001));
    });

    test('鏡像にすると左右が入れ替わる', () {
      final normal = projectPoint(
        const PosePoint(25, 50),
        const Size(100, 200),
        const Size(100, 200),
      );
      final mirrored = projectPoint(
        const PosePoint(25, 50),
        const Size(100, 200),
        const Size(100, 200),
        mirror: true,
      );
      expect(normal.dx, closeTo(25, 0.001));
      expect(mirrored.dx, closeTo(75, 0.001));
      expect(mirrored.dy, closeTo(normal.dy, 0.001));
    });

    test('画像のサイズが0でも落ちない', () {
      final o = projectPoint(
        const PosePoint(10, 10),
        const Size(0, 0),
        const Size(100, 100),
      );
      expect(o, Offset.zero);
    });
  });

  group('描画', () {
    test('骨格が無ければ描き直さない判断ができる', () {
      const a = PoseOverlayPainter(frame: null, imageSize: Size(1, 1));
      const b = PoseOverlayPainter(frame: null, imageSize: Size(1, 1));
      expect(a.shouldRepaint(b), isFalse);
    });

    test('骨格が変わったら描き直す', () {
      const a = PoseOverlayPainter(frame: null, imageSize: Size(1, 1));
      final b = PoseOverlayPainter(
        frame: const PoseFrame({Joint.nose: PosePoint(1, 1)}),
        imageSize: const Size(1, 1),
      );
      expect(b.shouldRepaint(a), isTrue);
    });

    testWidgets('骨格を重ねても例外にならない', (tester) async {
      final frame = PoseFrame(const {
        Joint.leftShoulder: PosePoint(30, 40),
        Joint.rightShoulder: PosePoint(70, 40),
        Joint.leftHip: PosePoint(35, 100),
        Joint.rightHip: PosePoint(65, 100),
        Joint.leftKnee: PosePoint(35, 150),
        Joint.leftAnkle: PosePoint(35, 190),
      });

      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 100,
            height: 200,
            child: CustomPaint(
              painter: PoseOverlayPainter(
                frame: frame,
                imageSize: const Size(100, 200),
                mirror: true,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
