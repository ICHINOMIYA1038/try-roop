import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:flutter/material.dart';

import 'pose_metrics.dart';

/// カメラ画像の座標を、画面上の座標に移す。
///
/// プレビューは [BoxFit.cover] で表示されるため、はみ出したぶんを
/// 差し引かないと骨格の線がずれる。前面カメラは鏡像なので左右も返す。
Offset projectPoint(
  PosePoint point,
  Size imageSize,
  Size widgetSize, {
  bool mirror = false,
}) {
  if (imageSize.width == 0 || imageSize.height == 0) {
    return Offset.zero;
  }

  final scale = math.max(
    widgetSize.width / imageSize.width,
    widgetSize.height / imageSize.height,
  );

  final scaledWidth = imageSize.width * scale;
  final scaledHeight = imageSize.height * scale;
  final dx = (widgetSize.width - scaledWidth) / 2;
  final dy = (widgetSize.height - scaledHeight) / 2;

  final x = point.x * scale + dx;
  final y = point.y * scale + dy;

  return Offset(mirror ? widgetSize.width - x : x, y);
}

/// 骨格をつなぐ線。測定に使っている関節だけを結ぶ。
const poseBones = <(Joint, Joint)>[
  (Joint.leftShoulder, Joint.rightShoulder),
  (Joint.leftShoulder, Joint.leftHip),
  (Joint.rightShoulder, Joint.rightHip),
  (Joint.leftHip, Joint.rightHip),
  (Joint.leftHip, Joint.leftKnee),
  (Joint.leftKnee, Joint.leftAnkle),
  (Joint.rightHip, Joint.rightKnee),
  (Joint.rightKnee, Joint.rightAnkle),
];

/// 骨格を重ねて描く。自分がちゃんと映っているかを確かめるために要る。
class PoseOverlayPainter extends CustomPainter {
  final PoseFrame? frame;
  final Size imageSize;
  final bool mirror;
  final Color color;

  const PoseOverlayPainter({
    required this.frame,
    required this.imageSize,
    this.mirror = false,
    this.color = const Color(0xFFFF8A3D),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame;
    if (f == null) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..color = Colors.white;

    for (final (a, b) in poseBones) {
      final pa = f[a];
      final pb = f[b];
      if (pa == null || pb == null) continue;

      canvas.drawLine(
        projectPoint(pa, imageSize, size, mirror: mirror),
        projectPoint(pb, imageSize, size, mirror: mirror),
        linePaint,
      );
    }

    for (final joint in Joint.values) {
      final p = f[joint];
      if (p == null) continue;
      canvas.drawCircle(
        projectPoint(p, imageSize, size, mirror: mirror),
        5,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(PoseOverlayPainter oldDelegate) {
    return oldDelegate.frame != frame ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.mirror != mirror;
  }
}
