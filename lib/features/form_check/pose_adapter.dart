import 'dart:io';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart'
    as mlkit;

import 'pose_metrics.dart';

/// ML Kit と、測定の計算を行う [PoseFrame] の橋渡し。
///
/// 計算側を ML Kit の型から切り離しておくと、端末が無くても検証できる。
/// ここは実機でしか通らないので、できるだけ薄くしてある。
class PoseAdapter {
  static const _jointMap = <mlkit.PoseLandmarkType, Joint>{
    mlkit.PoseLandmarkType.nose: Joint.nose,
    mlkit.PoseLandmarkType.leftShoulder: Joint.leftShoulder,
    mlkit.PoseLandmarkType.rightShoulder: Joint.rightShoulder,
    mlkit.PoseLandmarkType.leftHip: Joint.leftHip,
    mlkit.PoseLandmarkType.rightHip: Joint.rightHip,
    mlkit.PoseLandmarkType.leftKnee: Joint.leftKnee,
    mlkit.PoseLandmarkType.rightKnee: Joint.rightKnee,
    mlkit.PoseLandmarkType.leftAnkle: Joint.leftAnkle,
    mlkit.PoseLandmarkType.rightAnkle: Joint.rightAnkle,
  };

  static PoseFrame toFrame(mlkit.Pose pose) {
    final points = <Joint, PosePoint>{};

    for (final entry in _jointMap.entries) {
      final landmark = pose.landmarks[entry.key];
      if (landmark == null) continue;
      points[entry.value] = PosePoint(
        landmark.x,
        landmark.y,
        likelihood: landmark.likelihood,
      );
    }

    return PoseFrame(points);
  }

  /// カメラの1フレームを ML Kit が読める形に変換する。
  ///
  /// iOS と Android で並び方が違うため、対応している組み合わせ以外は
  /// null を返して読み飛ばす。
  static mlkit.InputImage? toInputImage(
    CameraImage image,
    CameraDescription camera,
    int deviceOrientationDegrees,
  ) {
    final rotation = _rotationFor(camera, deviceOrientationDegrees);
    if (rotation == null) return null;

    final format = mlkit.InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    // 対応しているのは iOS の BGRA8888 と Android の NV21 だけ。
    // どちらも平面が1枚なので、それ以外は扱わない。
    if (Platform.isIOS && format != mlkit.InputImageFormat.bgra8888) return null;
    if (Platform.isAndroid && format != mlkit.InputImageFormat.nv21) return null;
    if (image.planes.length != 1) return null;

    final plane = image.planes.first;

    return mlkit.InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: mlkit.InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  static mlkit.InputImageRotation? _rotationFor(
    CameraDescription camera,
    int deviceOrientationDegrees,
  ) {
    if (Platform.isIOS) {
      return mlkit.InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    }

    // Android は端末の向きとセンサーの向きを足し引きする。
    // 前面カメラは鏡像なので向きが逆になる。
    final sensor = camera.sensorOrientation;
    final rotationCompensation = camera.lensDirection == CameraLensDirection.front
        ? (sensor + deviceOrientationDegrees) % 360
        : (sensor - deviceOrientationDegrees + 360) % 360;

    return mlkit.InputImageRotationValue.fromRawValue(rotationCompensation);
  }
}
