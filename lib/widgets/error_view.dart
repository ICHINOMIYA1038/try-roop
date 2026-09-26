import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 読み込みに失敗したときに出す画面。
///
/// これまでは `Text('エラー: $error')` で例外をそのまま表示していたため、
/// `[cloud_firestore/permission-denied]` のような内部の文字列が利用者に
/// 見えていた。原因はログに残し、画面には何をすればよいかだけを出す。
class ErrorView extends StatelessWidget {
  final Object? error;
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    this.error,
    this.message = '読み込みに失敗しました',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      debugPrint('ErrorView: $error');
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '通信環境をご確認のうえ、もう一度お試しください。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('再試行'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
