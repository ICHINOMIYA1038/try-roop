import Link from "next/link";

export function Footer() {
  const year = new Date().getFullYear();
  return (
    <footer className="mt-auto border-t border-[var(--color-border)] bg-[var(--color-card)]">
      <div className="mx-auto max-w-5xl px-6 py-10 grid gap-8 md:grid-cols-3 text-sm">
        <div>
          <div className="flex items-center gap-2 font-bold text-base text-[var(--color-text)]">
            <span
              aria-hidden
              className="inline-flex h-7 w-7 items-center justify-center rounded-lg bg-[var(--color-brand)] text-white text-sm font-bold"
            >
              T
            </span>
            TryRoop Campus Live
          </div>
          <p className="mt-3 text-[var(--color-text-muted)] leading-relaxed">
            空手・筋トレ・健康・AI を、動画とテキストで自分のペースで学べる学習アプリ。
          </p>
        </div>
        <div>
          <h3 className="font-semibold text-[var(--color-text)] mb-3">
            リンク
          </h3>
          <ul className="space-y-2 text-[var(--color-text-muted)]">
            <li>
              <Link
                href="/privacy/"
                className="hover:text-[var(--color-text)] transition-colors"
              >
                プライバシーポリシー
              </Link>
            </li>
            <li>
              <Link
                href="/terms/"
                className="hover:text-[var(--color-text)] transition-colors"
              >
                利用規約
              </Link>
            </li>
            <li>
              <a
                href="mailto:support@try-roop.com"
                className="hover:text-[var(--color-text)] transition-colors"
              >
                お問い合わせ
              </a>
            </li>
          </ul>
        </div>
        <div>
          <h3 className="font-semibold text-[var(--color-text)] mb-3">
            運営
          </h3>
          <p className="text-[var(--color-text-muted)] leading-relaxed">
            {/* TODO(release): 運営者情報 (会社名 / 代表者 / 住所) を追記 */}
            TryRoop 運営チーム
          </p>
        </div>
      </div>
      <div className="border-t border-[var(--color-border)] py-4">
        <p className="text-center text-xs text-[var(--color-text-muted)]">
          © {year} TryRoop Campus Live. All rights reserved.
        </p>
      </div>
    </footer>
  );
}
