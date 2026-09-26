/// アプリ外に出すリンクをまとめる。
///
/// ディープリンクをまだ用意していないため、共有したときの行き先は
/// App Store のアプリページにしている。
class AppLinks {
  static const String appStoreId = '6759759681';
  static const String appStoreUrl =
      'https://apps.apple.com/jp/app/id$appStoreId';
  static const String siteUrl = 'https://try-roop.com';

  /// レビュー投稿画面を直接開くリンク。
  static const String writeReviewUrl =
      'https://apps.apple.com/jp/app/id$appStoreId?action=write-review';
}
