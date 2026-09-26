import { ReactNode } from "react";
import { AuthProvider } from "@/lib/auth-context";
import { AuthGuard } from "./_components/AuthGuard";
import { Sidebar, MobileMenuProvider } from "./_components/Sidebar";
import { TopBar } from "./_components/TopBar";

// /admin/ は静的エクスポートでも動的フェッチを行う SPA。
// データ取得は Firebase JS SDK 経由で行うため、ビルド時には認証情報を必要としない。
export const dynamic = "force-static";

export default function AdminLayout({ children }: { children: ReactNode }) {
  return (
    <AuthProvider>
      <AuthGuard>
        <MobileMenuProvider>
          <div className="min-h-screen flex bg-[var(--color-bg)]">
            <Sidebar />
            <div className="flex-1 flex flex-col min-w-0">
              <TopBar />
              <main className="flex-1 p-4 md:p-8">{children}</main>
            </div>
          </div>
        </MobileMenuProvider>
      </AuthGuard>
    </AuthProvider>
  );
}
