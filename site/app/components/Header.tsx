import Link from "next/link";

export function Header() {
  return (
    <header className="border-b border-[var(--color-border)] bg-[var(--color-bg)]/80 backdrop-blur sticky top-0 z-10">
      <div className="mx-auto max-w-5xl px-6 py-4 flex items-center justify-between">
        <Link
          href="/"
          className="flex items-center gap-3 font-bold text-lg text-[var(--color-text)]"
        >
          <span
            aria-hidden
            className="inline-flex h-9 w-9 items-center justify-center rounded-xl bg-[var(--color-brand)] text-white text-xl font-bold"
          >
            T
          </span>
          TryRoop Campus Live
        </Link>
        <nav className="flex items-center gap-6 text-sm">
          <Link
            href="/privacy/"
            className="text-[var(--color-text-muted)] hover:text-[var(--color-text)] transition-colors"
          >
            プライバシー
          </Link>
          <Link
            href="/terms/"
            className="text-[var(--color-text-muted)] hover:text-[var(--color-text)] transition-colors"
          >
            利用規約
          </Link>
        </nav>
      </div>
    </header>
  );
}
