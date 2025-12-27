# TryRoop Campus Live Flutter

オンライン教育コミュニティアプリ

## 必要な環境

- Flutter SDK
- Xcode (iOS開発用)
- iOS シミュレータ または 実機

## セットアップ

```bash
# 依存パッケージをインストール
task deps
```

## Taskfile コマンド

[Task](https://taskfile.dev/) を使用して開発タスクを実行します。

| コマンド | 説明 |
|----------|------|
| `task run` | アプリを起動 |
| `task stop` | アプリを停止 |
| `task restart` | アプリを再起動 |
| `task devices` | デバイス一覧 |
| `task clean` | キャッシュクリア |
| `task analyze` | 静的解析 |
| `task test` | テスト実行 |
| `task deps` | 依存パッケージ更新 |

### ホットリロード

アプリ起動後、以下のキーが使用可能:

| キー | 動作 |
|------|------|
| `r` | ホットリロード |
| `R` | ホットリスタート |
| `q` | アプリ終了 |

## プロジェクト構成

```
lib/
├── main.dart              # アプリのエントリポイント
├── router.dart            # ルーティング設定
├── models/                # データモデル
├── providers/             # Riverpod プロバイダー
├── screens/               # 画面
├── services/              # Firebase等のサービス
└── widgets/               # 共通ウィジェット
```

## 主な機能

- 動画コース
- テキストレッスン
- コミュニティ投稿
- イベントカレンダー
- お知らせ
- メンバー一覧
- バッジ・ダッシュボード
