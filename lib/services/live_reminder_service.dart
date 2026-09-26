import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/live_schedule.dart';

/// LIVE が始まる前に知らせる。
///
/// サーバーも APNs の鍵も要らないよう、端末内の通知だけで作ってある。
/// LIVE は1回15分なので、始まってから気づいても間に合わない。
class LiveReminderService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// 何分前に知らせるか。
  static const reminderMinutes = 15;

  static const _channelId = 'live_reminder';
  static const _prefsKey = 'live_reminder_enabled';

  static bool _ready = false;

  static Future<void> _ensureReady() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    // 端末の地域に依存しないよう、サービスの基準時刻に合わせる。
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    await _plugin.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _ready = true;
  }

  /// 利用者が通知を受け取る設定にしているか。
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  /// 通知を有効にする。許可されなければ false を返す。
  static Future<bool> enable() async {
    await _ensureReady();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await ios?.requestPermissions(alert: true, sound: true) ??
        true;

    if (!granted) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    return true;
  }

  static Future<void> disable() async {
    await _ensureReady();
    await _plugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, false);
  }

  /// 予定の一覧から、通知をまとめて入れ直す。
  ///
  /// 予定は管理画面で変わるので、消してから入れ直すのが確実。
  static Future<void> sync(List<LiveSchedule> schedules) async {
    if (!await isEnabled()) return;
    await _ensureReady();
    await _plugin.cancelAll();

    final now = DateTime.now();

    for (final s in schedules) {
      if (s.isEnded) continue;

      final at = s.scheduledAt.subtract(
        const Duration(minutes: reminderMinutes),
      );
      // すでに過ぎているものは入れない。
      if (!at.isAfter(now)) continue;

      try {
        await _plugin.zonedSchedule(
          id: s.id.hashCode & 0x7fffffff,
          title: 'まもなくLIVEが始まります',
          body: '${s.formattedTime}から「${s.title}」（${s.duration}分）',
          scheduledDate: tz.TZDateTime.from(at, tz.local),
          notificationDetails: const NotificationDetails(
            iOS: DarwinNotificationDetails(),
            android: AndroidNotificationDetails(
              _channelId,
              'LIVEのお知らせ',
              channelDescription: 'LIVEが始まる前にお知らせします',
              importance: Importance.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (e) {
        debugPrint('failed to schedule reminder for ${s.id}: $e');
      }
    }
  }
}
