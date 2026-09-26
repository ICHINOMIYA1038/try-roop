"use client";

import { useState } from "react";
import { useAuth } from "@/lib/auth-context";

export function AuthGuard({ children }: { children: React.ReactNode }) {
  const { status, signInWithGoogle, signOut, refreshClaims } = useAuth();

  if (status === "loading") {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <span className="text-[var(--color-text-muted)]">読み込み中…</span>
      </div>
    );
  }

  if (status === "signed-out") {
    return <SignInForm onSignInWithGoogle={signInWithGoogle} />;
  }

  if (status === "no-claim") {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[var(--color-bg)]">
        <div className="max-w-md w-full mx-6 rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] p-8 text-center">
          <h1 className="text-xl font-bold text-[var(--color-text)]">
            管理者権限がありません
          </h1>
          <p className="mt-3 text-sm text-[var(--color-text-muted)] leading-relaxed">
            このアカウントには admin ロールが付与されていません。
            管理者から権限を付与してもらうか、別のアカウントでログインしてください。
          </p>
          <div className="mt-6 flex gap-3 justify-center">
            <button
              onClick={refreshClaims}
              className="px-4 py-2 rounded-full border border-[var(--color-border)] text-sm hover:bg-[var(--color-bg)]"
            >
              再読込
            </button>
            <button
              onClick={signOut}
              className="px-4 py-2 rounded-full bg-[var(--color-text)] text-white text-sm"
            >
              ログアウト
            </button>
          </div>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}

function SignInForm({
  onSignInWithGoogle,
}: {
  onSignInWithGoogle: () => Promise<void>;
}) {
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleGoogle = async () => {
    setSubmitting(true);
    setError(null);
    try {
      await onSignInWithGoogle();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Google ログイン失敗");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[var(--color-bg)]">
      <div className="max-w-sm w-full mx-6 rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] p-8 space-y-5">
        <div className="text-center">
          <span
            aria-hidden
            className="inline-flex h-12 w-12 items-center justify-center rounded-2xl bg-[var(--color-brand)] text-white text-xl font-bold"
          >
            T
          </span>
          <h1 className="mt-4 text-xl font-bold text-[var(--color-text)]">
            管理画面ログイン
          </h1>
          <p className="mt-1 text-xs text-[var(--color-text-muted)]">
            管理者権限を持つ Google アカウントでログインしてください
          </p>
        </div>

        <button
          type="button"
          onClick={handleGoogle}
          disabled={submitting}
          className="w-full py-2.5 rounded-full border border-[var(--color-border)] bg-[var(--color-card)] hover:bg-[var(--color-bg)] font-semibold disabled:opacity-50 flex items-center justify-center gap-2"
        >
          <svg width="18" height="18" viewBox="0 0 18 18" aria-hidden>
            <path
              fill="#4285F4"
              d="M17.64 9.2c0-.64-.06-1.25-.16-1.84H9v3.48h4.84a4.14 4.14 0 0 1-1.8 2.71v2.26h2.92c1.7-1.57 2.68-3.88 2.68-6.61z"
            />
            <path
              fill="#34A853"
              d="M9 18c2.43 0 4.47-.81 5.96-2.18l-2.92-2.27c-.81.54-1.85.86-3.04.86-2.34 0-4.32-1.58-5.03-3.7H.96v2.33A9 9 0 0 0 9 18z"
            />
            <path
              fill="#FBBC05"
              d="M3.97 10.71A5.41 5.41 0 0 1 3.68 9c0-.59.1-1.17.29-1.71V4.96H.96A9 9 0 0 0 0 9c0 1.45.35 2.83.96 4.04l3.01-2.33z"
            />
            <path
              fill="#EA4335"
              d="M9 3.58c1.32 0 2.5.45 3.44 1.35l2.58-2.58A9 9 0 0 0 9 0 9 9 0 0 0 .96 4.96l3.01 2.33C4.68 5.16 6.66 3.58 9 3.58z"
            />
          </svg>
          {submitting ? "ログイン中…" : "Google でログイン"}
        </button>

        {error && <p className="text-sm text-red-600 break-all">{error}</p>}
      </div>
    </div>
  );
}
