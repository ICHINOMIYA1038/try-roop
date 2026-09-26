import type { Metadata } from "next";
import { LegalPage } from "../components/LegalPage";

export const metadata: Metadata = {
  title: "利用規約",
  description:
    "TryRoop Campus Live の利用規約。サービス内容、禁止事項、サブスクリプション、責任範囲について。",
};

export default function TermsOfService() {
  return (
    <LegalPage title="利用規約" effectiveDate="2026年4月30日">
      <p>
        本利用規約（以下「本規約」といいます）は、TryRoop（以下「運営者」といいます）が提供する TryRoop
        Campus Live モバイルアプリおよび関連する Web
        サービス（以下「本サービス」といいます）の利用条件を定めるものです。
        本サービスをご利用いただく前に、本規約をよくお読みください。
      </p>

      <h2 className="text-2xl font-bold mt-10">第 1 条（適用）</h2>
      <p>
        本規約は、ユーザーと運営者との間の、本サービスの利用に関わる一切の関係に適用されるものとします。本サービスを利用した時点で、ユーザーは本規約に同意したものとみなされます。
      </p>

      <h2 className="text-2xl font-bold mt-10">第 2 条（アカウント登録）</h2>
      <ol className="list-decimal pl-6 space-y-2">
        <li>
          本サービスの一部機能は、Google アカウントまたは Apple ID
          を用いた認証が必要です。
        </li>
        <li>
          ユーザーは、登録情報を最新かつ正確な内容に保つ責任を負います。
        </li>
        <li>
          ユーザーは、自身のアカウント情報を厳重に管理するものとし、第三者によるアカウントの不正利用について運営者は責任を負いません。
        </li>
      </ol>

      <h2 className="text-2xl font-bold mt-10">第 3 条（サブスクリプション）</h2>
      <ol className="list-decimal pl-6 space-y-2">
        <li>
          本サービスの一部コンテンツは、有料サブスクリプション（以下「プレミアムプラン」といいます）の登録ユーザーのみ閲覧可能です。
        </li>
        <li>
          プレミアムプランは、Apple App Store または Google Play
          を通じて購入され、それぞれのプラットフォームの定める課金条件に従います。
        </li>
        <li>
          サブスクリプションは、解約手続きが行われない限り自動的に更新されます。解約は各プラットフォームのアカウント設定から行ってください。
        </li>
        <li>
          支払い済みの料金は、各プラットフォームの返金ポリシーに従う場合を除き、原則として返金されません。
        </li>
      </ol>

      <h2 className="text-2xl font-bold mt-10">第 4 条（禁止事項）</h2>
      <p>ユーザーは、以下の行為をしてはなりません。</p>
      <ul className="list-disc pl-6 space-y-2">
        <li>法令または公序良俗に違反する行為</li>
        <li>犯罪行為に関連する行為</li>
        <li>運営者または第三者の知的財産権、肖像権、プライバシー、名誉、その他の権利または利益を侵害する行為</li>
        <li>本サービスのコンテンツを無断で複製、配信、改変、商用利用する行為</li>
        <li>本サービスのリバースエンジニアリング、自動化されたアクセス、過度な負荷をかける行為</li>
        <li>他のユーザーへの嫌がらせ、誹謗中傷、なりすまし</li>
        <li>運営者が不適切と判断するコンテンツの投稿</li>
        <li>その他、運営者が不適切と判断する行為</li>
      </ul>

      <h2 className="text-2xl font-bold mt-10">第 5 条（コンテンツの権利）</h2>
      <ol className="list-decimal pl-6 space-y-2">
        <li>
          本サービスで提供される動画、テキストレッスン、画像、ロゴ、その他一切のコンテンツに関する著作権およびその他の知的財産権は、運営者または正当な権利者に帰属します。
        </li>
        <li>
          ユーザーが本サービスに投稿した内容について、ユーザーは運営者に対し、本サービスの提供・改善・宣伝のために必要な範囲で、無償・非独占的に利用することを許諾するものとします。
        </li>
      </ol>

      <h2 className="text-2xl font-bold mt-10">
        第 6 条（サービスの変更・中断）
      </h2>
      <p>
        運営者は、ユーザーへの事前の通知なく、本サービスの内容を変更、追加、削除、または提供を一時的に中断することがあります。これによりユーザーに生じた損害について、運営者は責任を負いません。
      </p>

      <h2 className="text-2xl font-bold mt-10">第 7 条（免責事項）</h2>
      <ol className="list-decimal pl-6 space-y-2">
        <li>
          本サービスで提供される運動・健康に関するコンテンツは情報提供を目的とするものであり、医療・専門的助言の代替ではありません。実施はユーザー自身の判断と責任において行ってください。
        </li>
        <li>
          本サービスを利用したことによりユーザーに生じた一切の損害について、運営者の故意または重過失による場合を除き、運営者は責任を負いません。
        </li>
      </ol>

      <h2 className="text-2xl font-bold mt-10">第 8 条（アカウント停止）</h2>
      <p>
        ユーザーが本規約に違反した場合、運営者は事前の通知なくアカウントを停止または削除することがあります。
      </p>

      <h2 className="text-2xl font-bold mt-10">第 9 条（規約の変更）</h2>
      <p>
        運営者は、必要と判断した場合、ユーザーへの事前の通知なく本規約を変更することができます。変更後の規約は、本ページに掲載した時点から効力を生じます。
      </p>

      <h2 className="text-2xl font-bold mt-10">第 10 条（準拠法・管轄裁判所）</h2>
      <p>
        本規約の解釈および本サービスの利用に関する紛争については日本法を準拠法とし、運営者の所在地を管轄する地方裁判所を第一審の専属的合意管轄裁判所とします。
      </p>

      <h2 className="text-2xl font-bold mt-10">お問い合わせ</h2>
      <p>
        {/* TODO(release): 運営者情報を確定したら追記 */}
        TryRoop 運営チーム
        <br />
        メール:{" "}
        <a
          href="mailto:support@try-roop.com"
          className="text-[var(--color-brand)] underline"
        >
          support@try-roop.com
        </a>
      </p>
    </LegalPage>
  );
}
