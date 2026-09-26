import 'dart:math' as math;

/// 姿勢推定の結果から数字を取り出す部分。
///
/// ML Kit の型に依存させていないのは、端末なしで検証できるようにするため。
/// カメラまわりの繋ぎ込みは薄く保ち、判定はすべてここで行う。

/// 使う関節。ML Kit の 33 点のうち、測定に必要なものだけ。
enum Joint {
  nose,
  leftShoulder,
  rightShoulder,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

enum Side { left, right }

/// 画面上の 1 点。y は画像座標なので下に行くほど大きい。
class PosePoint {
  final double x;
  final double y;

  /// その点がどれくらい確からしいか (0.0〜1.0)。
  final double likelihood;

  const PosePoint(this.x, this.y, {this.likelihood = 1.0});
}

/// 1 フレームぶんの骨格。
class PoseFrame {
  final Map<Joint, PosePoint> points;

  /// この確からしさを下回る点は、無かったものとして扱う。
  final double minLikelihood;

  const PoseFrame(this.points, {this.minLikelihood = 0.5});

  PosePoint? operator [](Joint joint) {
    final p = points[joint];
    if (p == null || p.likelihood < minLikelihood) return null;
    return p;
  }

  bool has(Joint joint) => this[joint] != null;

  /// b を頂点とした a-b-c の角度（度）。まっすぐ伸びていれば 180 に近づく。
  double? angleAt(Joint a, Joint b, Joint c) {
    final pa = this[a];
    final pb = this[b];
    final pc = this[c];
    if (pa == null || pb == null || pc == null) return null;

    final abx = pa.x - pb.x;
    final aby = pa.y - pb.y;
    final cbx = pc.x - pb.x;
    final cby = pc.y - pb.y;

    final dot = abx * cbx + aby * cby;
    final magAb = math.sqrt(abx * abx + aby * aby);
    final magCb = math.sqrt(cbx * cbx + cby * cby);
    if (magAb == 0 || magCb == 0) return null;

    final cosine = (dot / (magAb * magCb)).clamp(-1.0, 1.0);
    return math.acos(cosine) * 180 / math.pi;
  }

  /// 膝の角度。スクワットの深さはこれで測る。
  double? kneeAngle(Side side) => side == Side.left
      ? angleAt(Joint.leftHip, Joint.leftKnee, Joint.leftAnkle)
      : angleAt(Joint.rightHip, Joint.rightKnee, Joint.rightAnkle);

  /// 肩と腰の中点を結んだ体幹の長さ。高さを体格で割るために使う。
  double? get torsoLength {
    final shoulder = _midpoint(Joint.leftShoulder, Joint.rightShoulder);
    final hip = _midpoint(Joint.leftHip, Joint.rightHip);
    if (shoulder == null || hip == null) return null;
    final d = (shoulder.y - hip.y).abs();
    return d == 0 ? null : d;
  }

  PosePoint? _midpoint(Joint a, Joint b) {
    final pa = this[a];
    final pb = this[b];
    if (pa == null || pb == null) return null;
    return PosePoint((pa.x + pb.x) / 2, (pa.y + pb.y) / 2);
  }

  /// 蹴った足の高さを、腰を 0、肩を 1 とした比率で返す。
  ///
  /// 体格や立ち位置で見かけの大きさが変わるため、実寸ではなく
  /// 自分の体を基準にした比で出す。
  double? kickHeightRatio(Side kickingSide) {
    final ankle =
        kickingSide == Side.left ? this[Joint.leftAnkle] : this[Joint.rightAnkle];
    final hip = _midpoint(Joint.leftHip, Joint.rightHip);
    final torso = torsoLength;
    if (ankle == null || hip == null || torso == null) return null;

    // y は下向きが正なので、腰より上なら差は正になる。
    return (hip.y - ankle.y) / torso;
  }
}

/// 蹴りの高さの段。
enum KickLevel { gedan, chudan, jodan }

extension KickLevelLabel on KickLevel {
  String get label => switch (this) {
        KickLevel.gedan => '下段',
        KickLevel.chudan => '中段',
        KickLevel.jodan => '上段',
      };
}

/// 腰を 0、肩を 1 とした比率から段を決める。
///
/// 腰より下なら下段、腰から肩の間なら中段、肩より上なら上段。
KickLevel classifyKickHeight(double ratio) {
  if (ratio < 0.0) return KickLevel.gedan;
  if (ratio < 1.0) return KickLevel.chudan;
  return KickLevel.jodan;
}

/// 反復回数を数える。
///
/// しきい値をひとつにすると、境目で数字が上下して二重に数えてしまう。
/// 下がりきったことと戻りきったことの両方を見てから 1 回とする。
class RepCounter {
  /// これより小さくなったら「下がりきった」
  final double downThreshold;

  /// これより大きくなったら「戻りきった」
  final double upThreshold;

  RepCounter({required this.downThreshold, required this.upThreshold})
      : assert(downThreshold < upThreshold);

  int _count = 0;
  bool _isDown = false;
  double? _extreme;
  final List<double> _depths = [];

  int get count => _count;

  /// 各回の最も深かった値。浅くなってきたかを見るために残す。
  List<double> get depths => List.unmodifiable(_depths);

  /// いま下がりきった状態かどうか。画面の表示に使う。
  bool get isDown => _isDown;

  /// 1 フレームぶんの値を入れる。1 回ぶん数えたら true を返す。
  bool add(double? value) {
    if (value == null) return false;

    if (!_isDown) {
      if (value <= downThreshold) {
        _isDown = true;
        _extreme = value;
      }
      return false;
    }

    // 下がっている間は、いちばん深いところを控えておく。
    if (_extreme == null || value < _extreme!) {
      _extreme = value;
    }

    if (value >= upThreshold) {
      _isDown = false;
      _count++;
      _depths.add(_extreme ?? value);
      _extreme = null;
      return true;
    }
    return false;
  }

  void reset() {
    _count = 0;
    _isDown = false;
    _extreme = null;
    _depths.clear();
  }
}

/// 左右の差。本人が気づいていないことが多く、測る値として意味がある。
class Symmetry {
  final double left;
  final double right;

  const Symmetry({required this.left, required this.right});

  double get difference => (left - right).abs();

  /// 大きい方を 1 としたときの、差の割合。
  double get imbalanceRatio {
    final larger = math.max(left.abs(), right.abs());
    if (larger == 0) return 0;
    return difference / larger;
  }

  /// 1 割以上ずれていたら、偏っているとみなす。
  bool get isBalanced => imbalanceRatio < 0.1;

  Side get weakerSide => left < right ? Side.left : Side.right;
}
