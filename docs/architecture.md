# tryroop campus live - システム設計書

## 概要

オンラインサロン会員向けの動画配信アプリ。
YouTube埋め込みによる動画再生、チャプター機能、会員認証を提供。

---

## アーキテクチャ全体図

```
┌─────────────────────────────────────────────────────────────────┐
│                        クライアント                              │
│                   Flutter App (iOS/Android)                     │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                         認証レイヤー                             │
│                      Firebase Auth                              │
│            (Email/Password, Google, Apple Sign-In)              │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                        データベース                              │
│                    Cloud Firestore                              │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   users     │  │   videos    │  │  chapters   │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│  ┌─────────────┐  ┌─────────────┐                              │
│  │  progress   │  │ categories  │                              │
│  └─────────────┘  └─────────────┘                              │
└─────────────────────────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                     動画ストリーミング                           │
│                        YouTube                                  │
│                   (限定公開 / 公開)                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## 技術スタック

| レイヤー | 技術 | 理由 |
|---------|------|------|
| フロントエンド | Flutter 3.38 | クロスプラットフォーム、高パフォーマンス |
| 認証 | Firebase Auth | 無料枠大、実装が簡単、セキュア |
| データベース | Cloud Firestore | リアルタイム同期、スケーラブル |
| 動画配信 | YouTube (埋め込み) | インフラ不要、CDN完備、コスト0 |
| 状態管理 | Riverpod | 型安全、テスト容易 |

---

## データモデル

### users（ユーザー）
```json
{
  "uid": "string (Firebase Auth UID)",
  "email": "string",
  "displayName": "string",
  "membershipType": "free | premium",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### videos（動画）
```json
{
  "id": "string",
  "title": "string",
  "description": "string",
  "youtubeVideoId": "string (例: dQw4w9WgXcQ)",
  "thumbnailUrl": "string",
  "duration": "number (秒)",
  "accessLevel": "free | premium",
  "categoryId": "string",
  "order": "number",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### chapters（チャプター）
```json
{
  "id": "string",
  "videoId": "string (videos.id)",
  "title": "string",
  "startTime": "number (秒)",
  "order": "number"
}
```

### progress（視聴進捗）
```json
{
  "id": "string",
  "uid": "string (users.uid)",
  "videoId": "string (videos.id)",
  "currentTime": "number (秒)",
  "completed": "boolean",
  "updatedAt": "timestamp"
}
```

### categories（カテゴリ）
```json
{
  "id": "string",
  "name": "string",
  "order": "number"
}
```

---

## 動画ストリーミング設計

### なぜYouTubeを使うのか

| 観点 | YouTube | 自前ホスティング (S3+CloudFront等) |
|------|---------|-----------------------------------|
| コスト | 無料 | 高い（転送量課金） |
| CDN | Google CDN自動 | 自分で設定必要 |
| トランスコード | 自動（複数画質） | 自分で実装必要 |
| 帯域 | 無制限 | 従量課金 |
| 実装工数 | 低 | 高 |

### アクセス制御

```
┌────────────────────────────────────────────────────┐
│                   アクセスフロー                    │
└────────────────────────────────────────────────────┘

1. ユーザーがアプリにログイン
   └─> Firebase Auth で認証

2. 動画一覧を取得
   └─> Firestore から videos を取得
   └─> accessLevel でフィルタリング
       - free: 全ユーザーに表示
       - premium: membershipType=premium のみ

3. 動画再生リクエスト
   └─> アプリ内でアクセス権チェック
   └─> OK なら YouTube Player で再生

※ YouTube動画は「限定公開」に設定
  → URLを知っていれば見られるが、検索には出ない
  → アプリ経由でのみURLを取得可能
```

### セキュリティ考慮

1. **YouTube限定公開の限界**
   - URLが漏れると誰でも視聴可能
   - 対策: 定期的にURL更新、重要コンテンツは別手段検討

2. **将来的な強化オプション**
   - Vimeo OTT（有料、より強固なDRM）
   - AWS MediaConvert + CloudFront Signed URLs
   - mux.com（動画APIサービス）

---

## 画面構成（実装済み）

```
lib/
├── main.dart                          # アプリエントリポイント
├── router.dart                        # GoRouter ルーティング設定
├── models/
│   ├── app_user.dart                  # ユーザーモデル
│   ├── video.dart                     # 動画モデル
│   ├── chapter.dart                   # チャプターモデル
│   ├── video_progress.dart            # 視聴進捗モデル
│   └── category.dart                  # カテゴリモデル
├── services/
│   ├── auth_service.dart              # Firebase Auth サービス
│   ├── firestore_service.dart         # Firestore CRUD
│   └── subscription_service.dart      # RevenueCat サブスク
├── providers/
│   └── providers.dart                 # Riverpod プロバイダー
├── screens/
│   ├── auth/
│   │   └── login_screen.dart          # ログイン/サインアップ
│   ├── home/
│   │   └── home_screen.dart           # ホーム（動画一覧）
│   ├── video/
│   │   └── video_player_screen.dart   # YouTube + チャプター
│   └── profile/
│       ├── profile_screen.dart        # プロフィール/設定
│       └── subscription_screen.dart   # サブスク購入画面
└── widgets/
    ├── video_card.dart                # 動画カードUI
    └── chapter_list.dart              # チャプターリストUI
```

---

## チャプター機能の実装

### UI設計

```
┌─────────────────────────────────────────┐
│         YouTube Player                  │
│    ┌─────────────────────────────┐      │
│    │                             │      │
│    │         動画表示             │      │
│    │                             │      │
│    └─────────────────────────────┘      │
│    ▶ ──●─────────────────── 12:34      │
├─────────────────────────────────────────┤
│  チャプター                              │
├─────────────────────────────────────────┤
│  ▶ 00:00  イントロダクション             │
│    02:30  基本概念の説明                 │
│    08:15  実践デモ                       │
│    15:00  まとめ                         │
└─────────────────────────────────────────┘
```

### 機能
- チャプタータップで該当時間にシーク
- 現在再生中のチャプターをハイライト
- チャプター間のスキップボタン

---

## Firebase設定手順

1. Firebase Console でプロジェクト作成
2. Authentication 有効化（Email/Password, Google）
3. Firestore Database 作成
4. Flutter に firebase_core, firebase_auth, cloud_firestore 追加
5. flutterfire configure でセットアップ

---

## 今後の拡張案

- [ ] プッシュ通知（新動画アップロード時）
- [ ] オフライン視聴（ダウンロード機能）
- [ ] コメント・Q&A機能
- [ ] ライブ配信対応
- [ ] 決済連携（Stripe, RevenueCat）

---

## 開発フェーズ

### Phase 1（MVP）✅ 完了
- [x] プロジェクトセットアップ
- [x] Firebase Auth 認証（Email/Google/Apple）
- [x] YouTube Player 実装
- [x] チャプター機能
- [x] 基本的な動画一覧（無料/有料分類）
- [x] RevenueCat サブスク連携
- [x] プロフィール画面

### Phase 2（次のステップ）
- [ ] Firebaseプロジェクト作成・連携
- [ ] RevenueCat設定（APIキー設定）
- [ ] Firestoreにテストデータ投入
- [ ] 視聴進捗の保存機能
- [ ] 検索機能

### Phase 3
- [ ] プッシュ通知
- [ ] オフライン視聴
- [ ] ライブ配信対応

---

## セットアップ手順

### 1. Firebaseセットアップ
```bash
# Firebase CLI インストール
npm install -g firebase-tools

# FlutterFire CLI インストール
dart pub global activate flutterfire_cli

# Firebase プロジェクトに接続
flutterfire configure
```

### 2. RevenueCatセットアップ
1. https://app.revenuecat.com でアカウント作成
2. プロジェクト作成
3. iOS/Android アプリ追加
4. `lib/services/subscription_service.dart` の APIキーを更新

### 3. Firestoreデータ構造
Firebase Console で以下のコレクションを作成:
- `users` - ユーザー情報
- `videos` - 動画メタデータ
- `chapters` - チャプター情報
- `progress` - 視聴進捗
- `categories` - カテゴリ
