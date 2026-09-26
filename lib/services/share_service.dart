import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_links.dart';
import '../features/form_check/form_session.dart';
import '../features/form_check/pose_metrics.dart';
import 'analytics_service.dart';

/// 学んだ内容を外に持ち出せるようにする。
///
/// 口コミで広がる余地を作るのが目的なので、共有文には必ずアプリへの
/// 行き先を付ける。
class ShareService {
  static Future<void> shareVideo(String title) =>
      _share('video', title, '「$title」を try-roop で見ています。');

  static Future<void> shareLesson(String title) =>
      _share('lesson', title, '「$title」を try-roop で読みました。');

  /// 測定の結果。数字が出るので人に見せたくなる。口コミの起点として、
  /// アプリの行き先を必ず付ける。
  static Future<void> shareFormResult(FormSession session) {
    final buffer = StringBuffer('${session.kind.label}を測りました。');
    buffer.write('${session.reps}回');

    final best = session.bestValue;
    if (best != null) {
      buffer.write(switch (session.kind) {
        ExerciseKind.squat => '、いちばん深いところで${best.round()}度',
        ExerciseKind.kick =>
          '、いちばん高いところで${classifyKickHeight(best).label}',
      });
    }
    buffer.write('。');

    return _share('form_result', session.kind.name, buffer.toString());
  }

  static Future<void> shareApp() =>
      _share('app', 'app', '空手の基本を動画とテキストで学べるアプリです。');

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
