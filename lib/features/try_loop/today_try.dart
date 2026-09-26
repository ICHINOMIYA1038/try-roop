/// ホームに出す「今日のTRY」。
class TodayTry {
  /// 「15分ボクササイズ」のような、挑戦の名前。
  final String title;

  /// 所要時間（分）。計画の「15分」を前面に出すために持つ。
  final int minutes;

  /// 遷移先の ID。
  final String targetId;

  /// LIVE への挑戦か、録画への挑戦か。
  final bool isLive;

  /// まだ触れたことのないジャンルか。初挑戦は強く誘う。
  final bool isNewGenre;

  const TodayTry({
    required this.title,
    required this.minutes,
    required this.targetId,
    required this.isLive,
    this.isNewGenre = false,
  });

  factory TodayTry.live(String title, int minutes, String id) =>
      TodayTry(title: title, minutes: minutes, targetId: id, isLive: true);

  factory TodayTry.video(String title, int minutes, String id,
          {bool isNewGenre = false}) =>
      TodayTry(
        title: title,
        minutes: minutes,
        targetId: id,
        isLive: false,
        isNewGenre: isNewGenre,
      );

  /// 「今日は「15分ボクササイズ」に挑戦！」
  ///
  /// 所要時間は別に出す。題名に「15分」が入っていることが多く、
  /// 前に付けると「15分「15分ボクササイズ」」と重なるため。
  String get invitation => '今日は「$title」に挑戦！';

  /// 所要時間の表示。題名にすでに入っていれば出さない。
  String? get durationLabel {
    if (minutes <= 0) return null;
    if (title.contains('$minutes分')) return null;
    return '$minutes分';
  }
}
