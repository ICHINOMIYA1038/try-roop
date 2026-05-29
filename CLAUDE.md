# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TryRoop Campus Live — オンライン教育コミュニティ（空手・筋トレ・健康・AI）向け Flutter モバイルアプリ。
動画コース、テキストレッスン、コミュニティ投稿、イベント、バッジなどの機能を持つ。対象は iOS / Android。

## Commands

開発タスクは [Taskfile](https://taskfile.dev/) で管理。`.env` から RevenueCat キーを読み込む。

```bash
task run              # デモモード ON で iOS シミュレータ起動
task run:prod         # Firebase 接続モードで起動（要 .env 設定）
task stop             # Flutter プロセス停止
task restart          # stop + run
task analyze          # flutter analyze（静的解析）
task test             # flutter test
task clean            # flutter clean && flutter pub get
task deps             # flutter pub get
task build:ios        # iOS リリースビルド（IPA）
task build:android    # Android リリースビルド（App Bundle）

# LP (site/ ディレクトリ — Next.js)
task web:dev          # http://localhost:3000
task web:build        # 静的ビルド → site/out
task web:deploy       # firebase deploy --only hosting
```

## Architecture

### State Management — Riverpod

`lib/providers/providers.dart` に全プロバイダーを集約（1000行超）。デモモード時はモックデータを返す。

主要プロバイダー:
- **Auth**: `authStateProvider`, `currentUserProvider`, `appUserProvider`
- **Content**: `videosProvider`, `coursesProvider`, `textLessonsProvider`
- **Commerce**: `isPremiumProvider` (RevenueCat 経由のサブスクリプション判定)
- **Community**: `postsProvider`, `commentsProvider`, `hasLikedProvider`

### Routing — GoRouter

`lib/router.dart` で定義。`MainShell` ウィジェットで BottomNavigationBar を持つタブ構造。
認証必須ルートは `redirect` でガード。デモモード時はログインをバイパス。

### Service Layer

| Service | 役割 |
|---------|------|
| `AuthService` | Firebase Auth + Google/Apple OAuth |
| `FirestoreService` | Firestore CRUD（全コレクション） |
| `SubscriptionService` | RevenueCat (purchases_flutter) ラッパー |

### Demo Mode

`--dart-define=DEMO_MODE=true` で有効化（`task run` がデフォルトで ON）。
Firebase 初期化失敗時にもデバッグビルドで自動フォールバック。
全画面にリアルなモックデータを提供し、Firebase 不要で開発可能。

### Membership & Access Control

- `MembershipType`: free / premium
- `AccessLevel`: free / premium（コンテンツ単位）
- Premium 判定は `isPremiumProvider` → RevenueCat entitlement "premium"
- Admin は `lib/config/admin_config.dart` のメール白名単 + Firestore custom claim

## Firebase

**Project ID**: `try-roop`

使用サービス: Authentication, Firestore, Hosting

主要コレクション: `users`, `videos`, `courses`, `textLessons`, `posts`, `comments`, `likes`, `bookmarks`, `notifications`, `badges`, `events`, `eventParticipations`, `announcements`, `liveSchedules`

セキュリティルール: `firestore.rules` — admin custom claim ベース。ユーザーデータは自分+admin、コンテンツは read-only、コミュニティは自分の投稿のみ編集/削除可。

## Key Design Decisions

- 動画は YouTube ID ベース（`youtube_player_flutter`）。自前ホスティングなし
- テキストレッスンは `assets/lessons/{category}/` の Markdown ファイル
- UI は Material Design 3、プライマリカラー: オレンジ (#FF8A3D)
- 全 UI テキストは日本語
- Apple Sign-In は App Store ガイドライン 4.8 により必須
- `lib/config/feature_flags.dart` でフィーチャーフラグ管理

## Web LP (site/)

Next.js 製のランディングページ。Firebase Hosting にデプロイ。
詳細は `site/CLAUDE.md` を参照。
