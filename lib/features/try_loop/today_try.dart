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

  /// 「今日は15分ボクササイズに挑戦！」
  String get invitation => '今日は$minutes分「$title」に挑戦！';
}
