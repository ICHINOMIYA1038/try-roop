import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalUrls {
  // ホームページ (Firebase Hosting / try-roop.com) で公開している法務ページ。
  // ホームページ実装は site/app/{privacy,terms}/page.tsx を参照。
  static const String privacyPolicy = 'https://try-roop.com/privacy';
  static const String termsOfService = 'https://try-roop.com/terms';
  static const String supportContact =
      'mailto:support@try-roop.com?subject=TryRoop%20Campus%20Live%20%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6';
}

Future<void> openExternalUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('リンクを開けませんでした')),
    );
  }
}
