"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "@/lib/auth-context";
import { useMobileMenu } from "./Sidebar";

const TITLES: Record<string, string> = {
  "/admin": "ダッシュボード",
  "/admin/announcements": "お知らせ",
  "/admin/videos": "動画",
  "/admin/courses": "コース",
  "/admin/lessons": "テキストレッスン",
  "/admin/categories": "カテゴリ",
  "/admin/badges": "バッジ",
  "/admin/live-schedules": "ライブ予定",
  "/admin/posts": "投稿モデレーション",
  "/admin/users": "ユーザー管理",
};

function currentTitle(pathname: string | null): string {
  if (!pathname) return "管理画面";
  // 末尾スラッシュ正規化
  const p = pathname.replace(/\/$/, "") || "/admin";
  return TITLES[p] ?? "管理画面";
}

export function TopBar() {
  const pathname = usePathname();
  const { user, signOut } = useAuth();
  const { setOpen } = useMobileMenu();
  const onDashboard = (pathname?.replace(/\/$/, "") || "/admin") === "/admin";

  return (
    <header className="sticky top-0 z-20 border-b border-[var(--color-border)] bg-[var(--color-card)]/95 backdrop-blur px-4 md:px-6 py-3 flex items-center gap-3">
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="md:hidden inline-flex h-9 w-9 items-center justify-center rounded-lg border border-[var(--color-border)] hover:bg-[var(--color-bg)]"
        aria-label="メニューを開く"
      >
        <svg width="20" height="20" viewBox="0 0 20 20" aria-hidden>
          <path
            d="M3 5h14M3 10h14M3 15h14"
            stroke="currentColor"
            strokeWidth="1.8"
            strokeLinecap="round"
          />
        </svg>
      </button>

      <nav className="flex items-center gap-2 text-sm min-w-0 flex-1" aria-label="breadcrumb">
        {onDashboard ? (
          <span className="font-bold text-[var(--color-text)] truncate">
            ダッシュボード
          </span>
        ) : (
          <>
            <Link
              href="/admin"
              className="text-[var(--color-text-muted)] hover:text-[var(--color-text)] whitespace-nowrap"
            >
              ダッシュボード
            </Link>
            <span className="text-[var(--color-text-muted)]">›</span>
            <span className="font-bold text-[var(--color-text)] truncate">
              {currentTitle(pathname)}
            </span>
          </>
        )}
      </nav>

      <div className="hidden sm:block text-xs text-[var(--color-text-muted)] truncate max-w-[180px]">
        {user?.email ?? ""}
      </div>
      <button
        onClick={signOut}
        className="px-3 py-1.5 rounded-lg text-sm border border-[var(--color-border)] hover:bg-[var(--color-bg)] whitespace-nowrap"
      >
        ログアウト
      </button>
    </header>
  );
}
