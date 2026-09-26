"use client";

import Link from "next/link";

export function ComingSoon({
  title,
  collectionName,
}: {
  title: string;
  collectionName: string;
}) {
  return (
    <div>
      <h1 className="text-2xl font-bold">{title}</h1>
      <div className="mt-6 rounded-2xl border border-dashed border-[var(--color-border)] bg-[var(--color-card)] p-8 text-center">
        <p className="text-[var(--color-text-muted)]">
          この管理画面は準備中です。
        </p>
        <p className="mt-2 text-xs text-[var(--color-text-muted)]">
          Firestore コレクション{" "}
          <code className="px-1.5 py-0.5 rounded bg-[var(--color-bg)] text-xs">
            {collectionName}
          </code>{" "}
          を直接管理する場合は Firebase Console、または{" "}
          <code className="px-1.5 py-0.5 rounded bg-[var(--color-bg)] text-xs">
            tool/seed.js
          </code>{" "}
          をご利用ください。
        </p>
        <p className="mt-4 text-xs text-[var(--color-text-muted)]">
          実装の参考は{" "}
          <Link
            href="/admin/announcements"
            className="text-[var(--color-brand)] underline"
          >
            お知らせ管理
          </Link>{" "}
          をご覧ください。同じパターンで CRUD を構築できます。
        </p>
      </div>
    </div>
  );
}
