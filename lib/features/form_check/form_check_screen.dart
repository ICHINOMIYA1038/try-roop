import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart'
    as mlkit;

import '../../providers/providers.dart';
import '../../services/analytics_service.dart';
import 'form_check_controller.dart';
import 'form_session.dart';
import 'pose_adapter.dart';
import 'pose_metrics.dart';
import 'pose_overlay.dart';

/// フォームを測る画面。
///
/// 判定は [FormCheckController] が持っていて、ここはカメラと骨格検出を
/// つなぐだけ。シミュレータにはカメラが無いので、実機でしか動かない。
class FormCheckScreen extends ConsumerStatefulWidget {
  final ExerciseKind kind;

  const FormCheckScreen({super.key, required this.kind});

  @override
  ConsumerState<FormCheckScreen> createState() => _FormCheckScreenState();
}

class _FormCheckScreenState extends ConsumerState<FormCheckScreen> {
  CameraController? _camera;
  late final FormCheckController _measurement =
      FormCheckController(kind: widget.kind);
  late final mlkit.PoseDetector _detector = mlkit.PoseDetector(
    options: mlkit.PoseDetectorOptions(),
  );

  /// 1枚処理している間は次を受け取らない。溜め込むと表示が遅れる。
  bool _busy = false;
  bool _saving = false;
  /// 画面が閉じたあとに、処理中だったフレームが戻ってくることがある。
  bool _disposed = false;
  String? _setupError;

  /// 画面に重ねて描くための、直近の骨格と元画像の大きさ。
  PoseFrame? _lastFrame;
  Size _imageSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _measurement.addListener(_onMeasurementChanged);
    _setUpCamera();
  }

  @override
  void dispose() {
    _disposed = true;
    _measurement.removeListener(_onMeasurementChanged);

    // 映像の受け取りを止めてから閉じる。止める前に dispose すると、
    // 処理中のフレームと衝突して落ちることがある。
    final camera = _camera;
    _camera = null;
    _teardown(camera);

    _measurement.dispose();
    super.dispose();
  }

  Future<void> _teardown(CameraController? camera) async {
    if (camera != null) {
      try {
        if (camera.value.isStreamingImages) {
          await camera.stopImageStream();
        }
      } catch (e) {
        debugPrint('stopImageStream failed: $e');
      }
      await camera.dispose();
    }

    try {
      await _detector.close();
    } catch (e) {
      debugPrint('closing pose detector failed: $e');
    }
  }

  void _onMeasurementChanged() {
    if (!_disposed && mounted) setState(() {});
  }

  Future<void> _setUpCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _setupError = 'カメラが見つかりませんでした');
        return;
      }

      // 自分を映して確認するので前面カメラを優先する。
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) return;

      setState(() => _camera = controller);
      await controller.startImageStream(_onImage);
      AnalyticsService.formCheckStarted(widget.kind.name);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _setupError = e.code == 'CameraAccessDenied'
            ? 'カメラの使用が許可されていません。設定アプリから許可してください。'
            : 'カメラを起動できませんでした';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _setupError = 'カメラを起動できませんでした');
    }
  }

  Future<void> _onImage(CameraImage image) async {
    if (_busy || _disposed || !mounted) return;
    final camera = _camera;
    if (camera == null) return;

    _busy = true;
    try {
      final input = PoseAdapter.toInputImage(
        image,
        camera.description,
        _deviceOrientationDegrees(),
      );
      if (input == null) return;

      final poses = await _detector.processImage(input);
      if (_disposed || !mounted) return;

      if (poses.isEmpty) {
        _lastFrame = null;
        _measurement.onFrame(const PoseFrame({}));
        return;
      }

      final frame = PoseAdapter.toFrame(poses.first);
      _lastFrame = frame;
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      _measurement.onFrame(frame);
    } catch (e) {
      debugPrint('pose detection failed: $e');
    } finally {
      _busy = false;
    }
  }

  int _deviceOrientationDegrees() {
    return switch (_camera?.value.deviceOrientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeLeft => 90,
      DeviceOrientation.portraitDown => 180,
      DeviceOrientation.landscapeRight => 270,
      _ => 0,
    };
  }

  Future<void> _finish() async {
    if (_saving) return;

    final uid = ref.read(currentUserProvider)?.uid;
    if (_measurement.reps == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('まだ1回も計測できていません')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      if (uid != null) {
        final session = _measurement.buildSession(uid);
        await ref.read(firestoreServiceProvider).saveFormSession(session);
        AnalyticsService.formCheckSaved(widget.kind.name, _measurement.reps);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('記録を保存できませんでした')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${widget.kind.label}を測る'),
        actions: [
          TextButton(
            onPressed: _measurement.reset,
            child: const Text('やり直す', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _camera == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _saving ? null : _finish,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A3D),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_saving ? '保存しています…' : '終わって記録する'),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    final error = _setupError;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, height: 1.6),
          ),
        ),
      );
    }

    final camera = _camera;
    if (camera == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(camera),
        CustomPaint(
          painter: PoseOverlayPainter(
            frame: _lastFrame,
            imageSize: _imageSize,
            // 前面カメラは鏡像で表示されるので、線も合わせて返す。
            mirror: camera.description.lensDirection ==
                CameraLensDirection.front,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _Readout(
            kind: widget.kind,
            reps: _measurement.reps,
            current: _measurement.currentValue,
            best: _measurement.bestValue,
            tracking: _measurement.isTracking,
          ),
        ),
      ],
    );
  }
}

class _Readout extends StatelessWidget {
  final ExerciseKind kind;
  final int reps;
  final double? current;
  final double? best;
  final bool tracking;

  const _Readout({
    required this.kind,
    required this.reps,
    required this.current,
    required this.best,
    required this.tracking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: Colors.black.withValues(alpha: 0.55),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!tracking)
            const Text(
              '全身が映るように、3歩ほど離れてください',
              style: TextStyle(color: Colors.white70),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Stat(label: '回数', value: '$reps'),
                _Stat(label: 'いま', value: _format(current)),
                _Stat(label: 'ベスト', value: _format(best)),
              ],
            ),
        ],
      ),
    );
  }

  String _format(double? value) {
    if (value == null) return '—';
    return switch (kind) {
      ExerciseKind.squat => '${value.round()}度',
      ExerciseKind.kick => classifyKickLabel(value),
    };
  }

  static String classifyKickLabel(double ratio) {
    final level = classifyKickHeight(ratio);
    return level.label;
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
