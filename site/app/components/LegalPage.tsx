import { ReactNode } from "react";
import { Header } from "./Header";
import { Footer } from "./Footer";

export function LegalPage({
  title,
  effectiveDate,
  children,
}: {
  title: string;
  effectiveDate: string;
  children: ReactNode;
}) {
  return (
    <>
      <Header />
      <main className="flex-1">
        <article className="mx-auto max-w-3xl px-6 py-16">
          <header className="mb-10 pb-6 border-b border-[var(--color-border)]">
            <h1 className="text-4xl font-bold text-[var(--color-text)]">
              {title}
            </h1>
            <p className="mt-3 text-sm text-[var(--color-text-muted)]">
              制定日: {effectiveDate}
            </p>
          </header>
          <div className="prose-content space-y-6 text-[var(--color-text)] leading-relaxed">
            {children}
          </div>
        </article>
      </main>
      <Footer />
    </>
  );
}
