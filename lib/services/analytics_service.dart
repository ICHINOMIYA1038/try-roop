import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// アプリ内の行動を記録する。
///
/// 流入がどこで止まっているか (インストール → 視聴 → 課金) が見えないと、
/// 施策の良し悪しを判断できないため、節目だけを絞って送る。
class AnalyticsService {
  static final FirebaseAnalytics instance = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: instance);

  static Future<void> _log(
    String name, [
    Map<String, Object>? parameters,
  ]) async {
    try {
      await instance.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('analytics: failed to log $name: $e');
    }
  }

  static Future<void> setUser(String? uid) async {
    try {
      await instance.setUserId(id: uid);
    } catch (e) {
      debugPrint('analytics: failed to set user: $e');
    }
  }

  static Future<void> signedIn(String method) =>
      _log('login', {'method': method});

  static Future<void> videoOpened(String videoId, {required bool premium}) =>
      _log('video_open', {'video_id': videoId, 'premium': premium});

  static Future<void> videoCompleted(String videoId) =>
      _log('video_complete', {'video_id': videoId});

  static Future<void> lessonOpened(String lessonId, {required bool premium}) =>
      _log('lesson_open', {'lesson_id': lessonId, 'premium': premium});

  static Future<void> lessonCompleted(String lessonId) =>
      _log('lesson_complete', {'lesson_id': lessonId});

  /// プレミアム限定の壁に当たった回数。どのコンテンツが課金の動機になって
  /// いるかを見るために、どこで当たったかも一緒に送る。
  static Future<void> paywallBlocked(String contentType, String contentId) =>
      _log('paywall_blocked', {
        'content_type': contentType,
        'content_id': contentId,
      });

  static Future<void> paywallViewed(String source) =>
      _log('paywall_view', {'source': source});

  static Future<void> purchaseStarted(String productId) =>
      _log('purchase_start', {'product_id': productId});

  static Future<void> purchaseCompleted(String productId) =>
      _log('purchase_complete', {'product_id': productId});

  static Future<void> shared(String contentType, String contentId) =>
      _log('share', {'content_type': contentType, 'item_id': contentId});

  /// LIVE への参加。Try Loop の中心機能なので、配信中と予定で分けて見る。
  static Future<void> liveJoined(String scheduleId, {required bool live}) =>
      _log('live_join', {'schedule_id': scheduleId, 'is_live': live});

  static Future<void> searched(String query) =>
      _log('search', {'search_term': query});
}
