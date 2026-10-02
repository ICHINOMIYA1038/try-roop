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
cd site && wrangler deploy   # try-roop.com（Cloudflare Workers）にも同じ内容を出す
```

サイトは2か所から配信している。`try-roop.web.app` は Firebase Hosting、
`try-roop.com` は Cloudflare Workers（`site/wrangler.jsonc`）。片方だけ
出すと、もう片方が古いまま残る。`wrangler` は try-roop.com を持っている
個人の Cloudflare アカウントでログインしておくこと。

管理画面の Google ログインは `try-roop.web.app/admin/` でしか通らない。
Firebase Authentication の承認済みドメインに `try-roop.com` が無いため。

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

**状態を手で切り替える必要はない。** 開始5分前から終了予定までは、
時刻から自動で「配信中」として扱う。予定より延びたときだけ、状態を
「配信中」にしておくと終了予定を過ぎても赤いままになる。

**既定では有料会員だけが参加できる。** 集客のために開放したい回は
「この回は無料で参加できるようにする」にチェックを入れる。

### 注意: URL が外に出ると防げない

YouTube の限定公開は、URL を知っていれば誰でも見られる。アプリ側で
有料会員だけに参加ボタンを出しても、URL が共有されたら止められない。

対策として考えられるのは次のとおり。
- 配信ごとに URL を変える（毎回新しい限定公開を立てる）
- YouTube のメンバーシップ限定配信にする（YouTube 側で課金者を判定）
- 配信中に画面へ会員名を出す（共有の抑止）

いまの作りは1つ目を前提にしている。使い回さないこと。

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


## UGC（利用者の投稿）の審査要件

App Store ガイドライン 1.2 は、利用者が内容を投稿できるアプリに
次の4つを求めている。2026-09-26 時点で4つとも揃えた。

| 要件 | 実装 |
| --- | --- |
| 不適切な内容を報告する手段 | 投稿・コメントの「…」から報告。理由は選択式 |
| 迷惑な利用者をブロックする手段 | 同じ「…」からブロック。プロフィール →「ブロックしたユーザー」で解除 |
| 不適切な内容を取り除く手段 | 管理画面 `/admin/reports` から内容を削除 |
| 規約で迷惑行為を禁止していること | 利用規約 第4条（禁止事項） |

通報は `reports` コレクションに入る。通報した本人にも読めない設定に
してある（取り下げや改変をさせないため）。確認と対応は管理画面から行う。

**運営でやること**: 通報が届いたら `/admin/reports` の「未対応」を見る。
内容を表示して判断し、「内容を削除」か「問題なし」を選ぶ。
審査でここを聞かれることがあるので、対応できる状態を保つこと。


## 数字の見かた（管理画面 /admin/stats）

アプリが書いた記録から集計している。Firebase Analytics とは別で、
こちらは運営がすぐ見られるようにしたもの。

| 数字 | 出どころ |
| --- | --- |
| 登録者数 | `users` の件数 |
| 有料会員 | `users.hasActiveSubscription` が true の件数 |
| 7日/30日以内に利用 | 視聴位置とTRYの記録から、期間内に動きがあった人 |
| 今月のTRY | `tryRecords` の今月ぶん |
| 動画別の視聴数 | `progress`（視聴位置）から。1人1動画で1 |
| 講座別 | `courseProgress` から、始めた人と終えた人 |

**有料会員の数え方に注意。** RevenueCat の課金状態を、アプリが起動時に
`users` へ写している。一度もアプリを開いていない人は反映されないので、
請求上の正確な数字は RevenueCat の管理画面で確認すること。

この写しは**権限の判定には使っていない**。使うと、解約した人が
ずっとプレミアムのままになるため。権限は必ず RevenueCat を見ている。

Firebase Analytics の方には、より細かい行動が入っている
（`live_join` / `video_open` / `lesson_complete` / `paywall_blocked` /
`purchase_complete`）。どこで離脱しているかはそちらで見る。
