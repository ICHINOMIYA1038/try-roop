# 反映の手順（コンソール作業）

2026-09-26 のコード変更を本番に出すまでの手順。上から順に実行する。

**最優先**: 今回の修正には「公開以来どの利用者もコンテンツを1件も見られて
いなかった」問題の修正が含まれている（日時が Timestamp で保存されているのに
文字列として読んでいた）。これはアプリ側の修正なので、ストアに出さないと
直らない。ルールのデプロイよりも新しいビルドの提出が効く。

あわせて iOS の最低動作環境を 13.0 から 15.0 に上げてある。
`ITMS-90068 Deployment target too low` で 2026-09-24 に他のアプリを
全部 15.0 にしたが、try-roop だけ 13.0 のまま残っていた。

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

`docs/store-listing.md` の文言をそのまま使う。

- アプリ名（いまは `try-roop-canpus`。campus の綴りが違う）
- サブタイトル（いま空欄）
- キーワード
- プロモーションテキスト（いま空欄）
- 説明文
- カテゴリ: ライフスタイル → 教育
- スクリーンショット（6.9インチが未登録。1枚目がダミー投稿になっている）

## 6. ビルドと申請

```sh
cd /Users/ichinomiya/private/try-roop
flutter build ipa --dart-define=REVENUECAT_IOS_API_KEY=xxx
```

RevenueCat の API キーは `--dart-define` で渡す（リポジトリには置かない）。

## 7. 確認すること

出したあとに見る場所。

| 見るもの | 場所 |
| --- | --- |
| クラッシュ | Firebase Crashlytics（今回追加） |
| 離脱箇所 | Firebase Analytics の `paywall_blocked` / `video_open` / `lesson_complete` |
| 検索順位 | `scripts/asc` の iTunes Search API 計測 |
| 評価 | App Store Connect → 評価とレビュー |


## 運営の手順（管理画面）

管理画面は https://try-roop.com/admin/ 。Firestore に直接書き込むので、
アプリ側の再ビルドは不要。

### LIVE を1本追加する

1. `/admin/live-schedules`
2. タイトル・日時・長さ（15分）・配信URL（YouTube 限定配信のURL）を入れる
3. 状態は「予定」
4. アプリのホームに「本日のLIVE」として出る。当日以外は日付で判定して出ない

配信が始まったら状態を「配信中」にすると、バナーが赤になり
「いま参加する」に変わる。

### 見逃し配信にする

1. 配信が終わったら `/admin/videos` でアーカイブ動画を登録する
2. `/admin/live-schedules` で該当のLIVEを開き、状態を「終了」に
3. 「見逃し配信の動画ID」に、1で作った動画のドキュメントIDを入れる
4. アプリの LIVE → 見逃し配信タブに出る

### 講座を作る（第1回・第2回…）

1. `/admin/videos` で各回の動画を登録する
2. `/admin/courses` で講座を作り、含める動画にチェックを入れる
3. 「回の順番」で ↑ ↓ を押して並べ替える
4. **先頭が第1回になり、無料で公開される**（各講座の第1回のみ無料）

並び順がそのまま受講順になるので、必ず確認すること。
