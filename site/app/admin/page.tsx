"use client";

import Link from "next/link";

const sections = [
  {
    href: "/admin/announcements",
    label: "お知らせ",
    description: "ユーザーへの全体告知の作成・編集・公開管理",
    ready: true,
  },
  {
    href: "/admin/videos",
    label: "動画",
    description: "YouTube 動画の登録、カテゴリ・公開状態の管理",
    ready: true,
  },
  {
    href: "/admin/courses",
    label: "コース",
    description: "動画をまとめたコースの編集",
    ready: true,
  },
  {
    href: "/admin/lessons",
    label: "テキストレッスン",
    description: "Markdown レッスンの管理",
    ready: true,
  },
  {
    href: "/admin/categories",
    label: "カテゴリ",
    description: "カテゴリの追加・並び替え",
    ready: true,
  },
  {
    href: "/admin/badges",
    label: "バッジ",
    description: "獲得バッジの定義",
    ready: true,
  },
  {
    href: "/admin/live-schedules",
    label: "ライブ予定",
    description: "ライブ配信のスケジュール管理",
    ready: true,
  },
  {
    href: "/admin/posts",
    label: "投稿モデレーション",
    description: "コミュニティ投稿の確認・削除",
    ready: true,
  },
  {
    href: "/admin/users",
    label: "ユーザー管理",
    description: "プレミアム手動付与・ユーザー検索",
    ready: true,
  },
];

export default function AdminDashboard() {
  return (
    <div>
      <h1 className="text-2xl font-bold text-[var(--color-text)]">ダッシュボード</h1>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        管理したい項目を選んでください。
      </p>
      <div className="mt-8 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {sections.map((s) => (
          <Link
            key={s.href}
            href={s.href}
            className="block rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] p-5 hover:border-[var(--color-brand)] transition-colors"
          >
            <div className="flex items-center justify-between">
              <h2 className="font-bold text-[var(--color-text)]">{s.label}</h2>
              {!s.ready && (
                <span className="text-[10px] px-1.5 py-0.5 rounded bg-[var(--color-bg)] text-[var(--color-text-muted)]">
                  準備中
                </span>
              )}
            </div>
            <p className="mt-2 text-sm text-[var(--color-text-muted)] leading-relaxed">
              {s.description}
            </p>
          </Link>
        ))}
      </div>
    </div>
  );
}
