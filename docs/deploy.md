# 反映の手順（コンソール作業）

2026-09-26 のコード変更を本番に出すまでの手順。上から順に実行する。

## 1. Firestore のルールとインデックス

ルールに `chapters` `progress` `courseProgress` `events` `eventParticipations` の
定義が無く、これらの機能は全部 permission-denied で死んでいた。
複合インデックスも未登録だったため、条件付きの並べ替えクエリが失敗していた。

```sh
cd /Users/ichinomiya/private/try-roop
firebase login          # 個人アカウント (ichiryo108@gmail.com) で
firebase deploy --only firestore:rules,firestore:indexes --project try-roop
```

インデックスの作成には数分かかる。Firebase コンソールの
Firestore → インデックス が「有効」になるまで待つ。

## 2. レッスンの追加分を投入

空手のレッスンを3本→8本に増やした。`tool/seed.js` に定義済み。

```sh
cd tool
npm install            # 初回のみ
node seed.js
```

`tool/serviceAccountKey.json` が必要（gitignore 済み。無ければ Firebase コンソールの
プロジェクトの設定 → サービスアカウント から発行する）。

## 3. サイトの再デプロイ

App Store へのリンクを追加した。いままでサイトからアプリへ行く導線が無かった。

```sh
cd /Users/ichinomiya/private/try-roop
firebase deploy --only hosting --project try-roop
```

## 4. App Store Connect：課金アイテムの作成

**いま課金アイテムが1件も登録されていない。** 説明文では
「プレミアムプランでは、すべての動画・レッスンが見放題」と書いているのに、
課金画面は「現在利用可能なプランはありません」と表示される状態。

1. App Store Connect → try-roop-canpus → 収益化 → サブスクリプション
2. サブスクリプショングループを作成（例: `TryRoop Premium`）
3. 月額プランを追加。Product ID は RevenueCat と揃える
4. RevenueCat ダッシュボード → Products で同じ ID を登録
5. RevenueCat → Entitlements に `premium` を作り、上の商品を紐づける
   （アプリ側は `SubscriptionService.entitlementId = 'premium'` を見ている）
6. RevenueCat → Offerings の `current` にパッケージを入れる
   （`Purchases.getOfferings().current` を読んでいるので、ここが空だと何も出ない）

## 5. App Store Connect：掲載情報の差し替え

`docs/aso-and-growth-2026-09.md` の「3. 差し替える文言」をそのまま使う。

- アプリ名（いまは `try-roop-canpus`。campus の綴りが違う）
- サブタイトル（いま空欄）
- キーワード
- プロモーションテキスト（いま空欄）
- 説明文
- カテゴリ: ライフスタイル → 教育
- スクリーンショット（6.9インチが未登録。1枚目がダミー投稿になっている）

## 6. フォーム測定を入れたことによる変更

- **iOS の最低動作環境が 13.0 → 15.5 に上がった**（ML Kit の要求）。
  対応端末は減らないが、App Store Connect の対応バージョン表示が変わる。
- **アプリのサイズが増える**。提出前にダウンロードサイズを確認すること。
- Info.plist に `NSCameraUsageDescription` を追加済み。
- 映像は端末の外に出ないため、プライバシー表示に「写真・ビデオ」を
  追加する必要はない。保存しているのは回数と数値だけ。
- Firestore に `formSessions` を追加したので、1番のルールとインデックスの
  デプロイが必要。

## 7. ビルドと申請

```sh
cd /Users/ichinomiya/private/try-roop
flutter build ipa --dart-define=REVENUECAT_IOS_API_KEY=xxx
```

RevenueCat の API キーは `--dart-define` で渡す（リポジトリには置かない）。

## 8. 確認すること

出したあとに見る場所。

| 見るもの | 場所 |
| --- | --- |
| クラッシュ | Firebase Crashlytics（今回追加） |
| 測定の利用 | Firebase Analytics の `form_check_start` / `form_check_save` |
| 離脱箇所 | Firebase Analytics の `paywall_blocked` / `video_open` / `lesson_complete` |
| 検索順位 | `scripts/asc` の iTunes Search API 計測 |
| 評価 | App Store Connect → 評価とレビュー |
