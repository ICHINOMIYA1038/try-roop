"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { createContext, useContext, useEffect, useState, ReactNode } from "react";

type NavItem = {
  href: string;
  label: string;
  ready?: boolean;
};

const nav: { section: string; items: NavItem[] }[] = [
  {
    section: "ダッシュボード",
    items: [{ href: "/admin", label: "概要", ready: true }],
  },
  {
    section: "コンテンツ",
    items: [
      { href: "/admin/announcements", label: "お知らせ", ready: true },
      { href: "/admin/videos", label: "動画", ready: true },
      { href: "/admin/courses", label: "コース", ready: true },
      { href: "/admin/lessons", label: "テキストレッスン", ready: true },
      { href: "/admin/categories", label: "カテゴリ", ready: true },
      { href: "/admin/badges", label: "バッジ", ready: true },
      { href: "/admin/live-schedules", label: "ライブ予定", ready: true },
    ],
  },
  {
    section: "コミュニティ",
    items: [
      { href: "/admin/posts", label: "投稿モデレーション", ready: true },
      { href: "/admin/users", label: "ユーザー管理", ready: true },
    ],
  },
];

/**
 * モバイルメニューの開閉状態を共有する。Sidebar (本体) と TopBar (ハンバーガーボタン) で使う。
 */
type MobileMenuCtx = {
  open: boolean;
  setOpen: (v: boolean) => void;
};
const MobileMenuContext = createContext<MobileMenuCtx | null>(null);

export function MobileMenuProvider({ children }: { children: ReactNode }) {
  const [open, setOpen] = useState(false);
  const pathname = usePathname();
  // 画面遷移したらメニューを閉じる
  useEffect(() => {
    setOpen(false);
  }, [pathname]);
  return (
    <MobileMenuContext.Provider value={{ open, setOpen }}>
      {children}
    </MobileMenuContext.Provider>
  );
}

export function useMobileMenu(): MobileMenuCtx {
  const ctx = useContext(MobileMenuContext);
  if (!ctx) throw new Error("useMobileMenu must be used within MobileMenuProvider");
  return ctx;
}

function NavList() {
  const pathname = usePathname();
  const isActive = (href: string) =>
    href === "/admin" ? pathname === "/admin" : pathname?.startsWith(href);

  return (
    <nav className="space-y-6 text-sm">
      {nav.map((group) => (
        <div key={group.section}>
          <p className="px-2 mb-2 text-xs font-semibold text-[var(--color-text-muted)] uppercase tracking-wider">
            {group.section}
          </p>
          <ul className="space-y-1">
            {group.items.map((item) => (
              <li key={item.href}>
                <Link
                  href={item.href}
                  className={`flex items-center justify-between px-2 py-2 rounded-lg transition-colors ${
                    isActive(item.href)
                      ? "bg-[var(--color-brand)] text-white"
                      : "text-[var(--color-text)] hover:bg-[var(--color-bg)]"
                  }`}
                >
                  <span>{item.label}</span>
                  {!item.ready && (
                    <span className="text-[10px] px-1.5 py-0.5 rounded bg-[var(--color-bg)] text-[var(--color-text-muted)]">
                      準備中
                    </span>
                  )}
                </Link>
              </li>
            ))}
          </ul>
        </div>
      ))}
    </nav>
  );
}

function SidebarBrand() {
  return (
    <Link href="/admin" className="flex items-center gap-2 mb-6 px-2">
      <span
        aria-hidden
        className="inline-flex h-8 w-8 items-center justify-center rounded-lg bg-[var(--color-brand)] text-white font-bold"
      >
        T
      </span>
      <span className="font-bold">TryRoop Admin</span>
    </Link>
  );
}

export function Sidebar() {
  const { open, setOpen } = useMobileMenu();

  return (
    <>
      {/* デスクトップ常時表示 */}
      <aside className="hidden md:flex flex-col w-64 border-r border-[var(--color-border)] bg-[var(--color-card)] p-4 sticky top-0 self-start h-screen overflow-y-auto">
        <SidebarBrand />
        <NavList />
      </aside>

      {/* モバイル用ドロワー */}
      <div
        className={`md:hidden fixed inset-0 z-40 transition-opacity ${
          open ? "opacity-100 pointer-events-auto" : "opacity-0 pointer-events-none"
        }`}
        aria-hidden={!open}
      >
        <button
          type="button"
          aria-label="メニューを閉じる"
          onClick={() => setOpen(false)}
          className="absolute inset-0 bg-black/30"
        />
        <aside
          className={`absolute top-0 left-0 h-full w-72 max-w-[85%] bg-[var(--color-card)] border-r border-[var(--color-border)] p-4 overflow-y-auto transition-transform ${
            open ? "translate-x-0" : "-translate-x-full"
          }`}
        >
          <SidebarBrand />
          <NavList />
        </aside>
      </div>
    </>
  );
}
