import 'package:flutter/material.dart';

/// 書き込みが失敗したときに、利用者に伝える。
///
/// いいねやブックマークは投げっぱなしで呼ばれていて、権限や通信で
/// 失敗しても画面上は何も起きないように見えていた。
Future<void> runWithFeedback(
  BuildContext context,
  Future<void> Function() action, {
  required String onFailure,
}) async {
  try {
    await action();
  } catch (e) {
    debugPrint('action failed: $e');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(onFailure)),
    );
  }
}

/// ログインしていないと使えない操作の入口。
void requireSignIn(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
