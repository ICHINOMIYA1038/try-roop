import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_links.dart';
import 'analytics_service.dart';

/// 学んだ内容を外に持ち出せるようにする。
///
/// 口コミで広がる余地を作るのが目的なので、共有文には必ずアプリへの
/// 行き先を付ける。
class ShareService {
  static Future<void> shareVideo(String title) =>
      _share('video', title, '「$title」を Try Loop で見ています。');

  static Future<void> shareLesson(String title) =>
      _share('lesson', title, '「$title」を Try Loop で読みました。');

  static Future<void> shareApp() =>
      _share('app', 'app', '筋トレ・ボクササイズ・韓国語を15分のLIVEで学べるアプリです。');

  static Future<void> _share(
    String type,
    String id,
    String message,
  ) async {
    try {
      await Share.share('$message\n${AppLinks.appStoreUrl}');
      await AnalyticsService.shared(type, id);
    } catch (e) {
      debugPrint('share failed: $e');
    }
  }
}
