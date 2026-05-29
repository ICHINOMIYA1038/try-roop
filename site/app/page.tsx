import Link from "next/link";
import { Header } from "./components/Header";
import { Footer } from "./components/Footer";

const features = [
  {
    icon: "▶",
    title: "動画レッスン",
    description:
      "プロ監修の動画で、空手や筋トレのフォームを正しく学ぶ。隙間時間にも繰り返し見返せます。",
  },
  {
    icon: "📖",
    title: "テキストレッスン",
    description:
      "Markdown 形式の解説で、深く理解したいトピックをじっくり学習。",
  },
  {
    icon: "💬",
    title: "コミュニティ",
    description:
      "学んだことを投稿して仲間と共有。質問や励ましを通じて学習を続けやすく。",
  },
  {
    icon: "🏆",
    title: "バッジ",
    description: "視聴・継続・コース完了に応じてバッジを獲得。学習が習慣に。",
  },
];

const categories = [
  { name: "空手", emoji: "🥋", description: "基本姿勢から技まで" },
  { name: "筋トレ", emoji: "💪", description: "自重・部位別トレーニング" },
  { name: "健康", emoji: "🌿", description: "睡眠・ストレス管理" },
  { name: "AI", emoji: "🤖", description: "ChatGPT・プロンプト活用" },
];

export default function Home() {
  return (
    <>
      <Header />
      <main className="flex-1">
        <section className="mx-auto max-w-5xl px-6 py-20 md:py-28">
          <div className="flex flex-col items-center text-center">
            <span className="inline-flex h-20 w-20 items-center justify-center rounded-3xl bg-[var(--color-brand)] text-white text-4xl font-bold shadow-lg shadow-[var(--color-brand)]/20">
              T
            </span>
            <h1 className="mt-6 text-4xl md:text-6xl font-bold tracking-tight text-[var(--color-text)]">
              学びを、自分のペースで。
            </h1>
            <p className="mt-6 max-w-2xl text-lg text-[var(--color-text-muted)] leading-relaxed">
              TryRoop Campus Live は、空手・筋トレ・健康・AI を、
              動画とテキストで自分のペースで学べるモバイル学習アプリです。
            </p>
            <div className="mt-10 flex flex-col sm:flex-row gap-3">
              {/* TODO(release): App Store / Google Play のリンクが揃ったら有効化 */}
              <button
                disabled
                className="px-6 py-3 rounded-full bg-[var(--color-text)] text-white font-semibold opacity-50 cursor-not-allowed"
              >
                App Store (準備中)
              </button>
              <button
                disabled
                className="px-6 py-3 rounded-full bg-[var(--color-text)] text-white font-semibold opacity-50 cursor-not-allowed"
              >
                Google Play (準備中)
              </button>
            </div>
          </div>
        </section>

        <section className="bg-[var(--color-card)] border-y border-[var(--color-border)]">
          <div className="mx-auto max-w-5xl px-6 py-20">
            <h2 className="text-3xl font-bold text-center text-[var(--color-text)]">
              できること
            </h2>
            <div className="mt-12 grid gap-6 md:grid-cols-2 lg:grid-cols-4">
              {features.map((f) => (
                <div
                  key={f.title}
                  className="rounded-2xl border border-[var(--color-border)] p-6 bg-[var(--color-bg)]"
                >
                  <div className="text-3xl">{f.icon}</div>
                  <h3 className="mt-4 font-bold text-[var(--color-text)]">
                    {f.title}
                  </h3>
                  <p className="mt-2 text-sm text-[var(--color-text-muted)] leading-relaxed">
                    {f.description}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className="mx-auto max-w-5xl px-6 py-20">
          <h2 className="text-3xl font-bold text-center text-[var(--color-text)]">
            学べるカテゴリ
          </h2>
          <div className="mt-12 grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            {categories.map((c) => (
              <div
                key={c.name}
                className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] p-6 text-center"
              >
                <div className="text-4xl">{c.emoji}</div>
                <h3 className="mt-3 font-bold text-[var(--color-text)]">
                  {c.name}
                </h3>
                <p className="mt-1 text-xs text-[var(--color-text-muted)]">
                  {c.description}
                </p>
              </div>
            ))}
          </div>
        </section>

        <section className="bg-[var(--color-card)] border-t border-[var(--color-border)]">
          <div className="mx-auto max-w-5xl px-6 py-20">
            <h2 className="text-3xl font-bold text-center text-[var(--color-text)]">
              プラン
            </h2>
            <div className="mt-12 grid gap-6 md:grid-cols-2 max-w-3xl mx-auto">
              <div className="rounded-2xl border border-[var(--color-border)] p-8 bg-[var(--color-bg)]">
                <h3 className="font-bold text-xl text-[var(--color-text)]">
                  無料プラン
                </h3>
                <p className="mt-2 text-sm text-[var(--color-text-muted)]">
                  まずはお試し
                </p>
                <ul className="mt-6 space-y-2 text-sm text-[var(--color-text-muted)]">
                  <li>✓ 一部の動画とテキストレッスン</li>
                  <li>✓ コミュニティ閲覧・投稿</li>
                  <li>✓ バッジ獲得</li>
                </ul>
              </div>
              <div className="rounded-2xl border-2 border-[var(--color-brand)] p-8 bg-[var(--color-bg)] relative">
                <span className="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-1 rounded-full bg-[var(--color-brand)] text-white text-xs font-bold">
                  おすすめ
                </span>
                <h3 className="font-bold text-xl text-[var(--color-text)]">
                  プレミアムプラン
                </h3>
                <p className="mt-2 text-sm text-[var(--color-text-muted)]">
                  すべてのコンテンツへ
                </p>
                <ul className="mt-6 space-y-2 text-sm text-[var(--color-text-muted)]">
                  <li>✓ プレミアム動画・レッスンが見放題</li>
                  <li>✓ 限定ライブ配信</li>
                  <li>✓ 無料プランの全機能</li>
                </ul>
                <p className="mt-4 text-xs text-[var(--color-text-muted)]">
                  料金とお試し期間はアプリ内サブスクリプション画面でご確認ください
                </p>
              </div>
            </div>
          </div>
        </section>

        <section className="mx-auto max-w-3xl px-6 py-20 text-center">
          <h2 className="text-3xl font-bold text-[var(--color-text)]">
            お問い合わせ
          </h2>
          <p className="mt-6 text-[var(--color-text-muted)] leading-relaxed">
            ご質問・ご要望・不具合のご報告は、メールまたはアプリ内
            「ヘルプ・お問い合わせ」からお寄せください。
          </p>
          <a
            href="mailto:support@try-roop.com"
            className="mt-6 inline-block px-6 py-3 rounded-full bg-[var(--color-brand)] text-white font-semibold hover:bg-[var(--color-brand-dark)] transition-colors"
          >
            support@try-roop.com
          </a>
          <p className="mt-8 text-sm text-[var(--color-text-muted)]">
            <Link href="/privacy/" className="underline">
              プライバシーポリシー
            </Link>
            <span className="mx-2">·</span>
            <Link href="/terms/" className="underline">
              利用規約
            </Link>
          </p>
        </section>
      </main>
      <Footer />
    </>
  );
}
