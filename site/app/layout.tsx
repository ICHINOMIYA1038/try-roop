import type { Metadata } from "next";
import { Noto_Sans_JP } from "next/font/google";
import "./globals.css";

const notoSansJP = Noto_Sans_JP({
  variable: "--font-noto-sans-jp",
  subsets: ["latin"],
  weight: ["400", "500", "700"],
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL("https://try-roop.com"),
  title: {
    default: "TryRoop Campus Live",
    template: "%s | TryRoop Campus Live",
  },
  description:
    "TryRoop Campus Live は、空手・筋トレ・健康・AI など暮らしに役立つ学習コンテンツを動画とテキストで届けるモバイル学習アプリです。",
  keywords: [
    "学習アプリ",
    "オンライン学習",
    "空手",
    "筋トレ",
    "健康",
    "AI",
    "TryRoop",
  ],
  openGraph: {
    type: "website",
    locale: "ja_JP",
    siteName: "TryRoop Campus Live",
    title: "TryRoop Campus Live",
    description:
      "空手・筋トレ・健康・AI を、動画とテキストで自分のペースで学べるモバイルアプリ",
    images: [{ url: "/og-image.png", width: 1200, height: 630 }],
  },
  icons: {
    icon: [{ url: "/icon-32.png", sizes: "32x32" }],
    apple: "/apple-icon.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="ja"
      className={`${notoSansJP.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col bg-[#F9F7F4] text-[#433D39]">
        {children}
      </body>
    </html>
  );
}
