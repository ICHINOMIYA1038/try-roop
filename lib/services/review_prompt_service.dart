import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 評価をお願いするタイミングを決める。
///
/// 起動直後に出すと嫌われるだけなので、学習を終えた直後にだけ声をかける。
/// 一度でも表示したら、そのあとは出さない。
class ReviewPromptService {
  static const _keyCompletions = 'review_prompt_completions';
  static const _keyAsked = 'review_prompt_asked';

  /// これだけ学習を終えたら声をかける。
  static const _threshold = 3;

  /// 学習をひとつ終えたときに呼ぶ。条件を満たしていれば評価依頼を出す。
  static Future<void> recordCompletion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_keyAsked) ?? false) return;

      final count = (prefs.getInt(_keyCompletions) ?? 0) + 1;
      await prefs.setInt(_keyCompletions, count);
      if (count < _threshold) return;

      final inAppReview = InAppReview.instance;
      if (!await inAppReview.isAvailable()) return;

      await prefs.setBool(_keyAsked, true);
      await inAppReview.requestReview();
    } catch (e) {
      debugPrint('review prompt failed: $e');
    }
  }

  /// 設定画面などから、利用者が自分でレビューを書きにいくとき。
  static Future<void> openStoreListing(String appStoreId) async {
    try {
      await InAppReview.instance.openStoreListing(appStoreId: appStoreId);
    } catch (e) {
      debugPrint('failed to open store listing: $e');
    }
  }
}
