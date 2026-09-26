"use client";

import { useCallback, useEffect, useState } from "react";
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  updateDoc,
} from "firebase/firestore";
import { getDb } from "@/lib/firebase";
import { isoFromAny } from "@/lib/admin-helpers";

const REASONS: Record<string, string> = {
  spam: "迷惑・宣伝",
  harassment: "誹謗中傷・嫌がらせ",
  sexual: "性的な内容",
  violence: "暴力的な内容",
  misinformation: "誤った情報",
  other: "その他",
};

const TARGETS: Record<string, string> = {
  post: "投稿",
  comment: "コメント",
  user: "ユーザー",
};

type Report = {
  id: string;
  reporterId: string;
  targetType: string;
  targetId: string;
  targetAuthorId: string | null;
  reason: string;
  note: string | null;
  status: "open" | "resolved" | "dismissed";
  createdAt: string;
};

export default function ReportsPage() {
  const [items, setItems] = useState<Report[] | null>(null);
  const [filter, setFilter] = useState<"open" | "all">("open");
  const [error, setError] = useState<string | null>(null);
  const [preview, setPreview] = useState<Record<string, string>>({});

  const reload = useCallback(async () => {
    setError(null);
    try {
      const snap = await getDocs(
        query(collection(getDb(), "reports"), orderBy("createdAt", "desc")),
      );
      setItems(
        snap.docs.map((d) => {
          const data = d.data();
          return {
            id: d.id,
            reporterId: data.reporterId ?? "",
            targetType: data.targetType ?? "post",
            targetId: data.targetId ?? "",
            targetAuthorId: data.targetAuthorId ?? null,
            reason: data.reason ?? "other",
            note: data.note ?? null,
            status: data.status ?? "open",
            createdAt: isoFromAny(data.createdAt),
          };
        }),
      );
    } catch (e) {
      setError(e instanceof Error ? e.message : "読み込みに失敗しました");
    }
  }, []);

  useEffect(() => {
    reload();
  }, [reload]);

  /** 通報された投稿・コメントの本文を取りにいく。判断できないと対応できない。 */
  const loadPreview = async (r: Report) => {
    const key = `${r.targetType}/${r.targetId}`;
    if (preview[key]) return;
    try {
      const col = r.targetType === "comment" ? "comments" : "posts";
      const snap = await getDoc(doc(getDb(), col, r.targetId));
      setPreview((p) => ({
        ...p,
        [key]: snap.exists()
          ? (snap.data().content ?? "(本文なし)")
          : "(削除済み)",
      }));
    } catch {
      setPreview((p) => ({ ...p, [key]: "(取得できませんでした)" }));
    }
  };

  const setStatus = async (r: Report, status: Report["status"]) => {
    try {
      await updateDoc(doc(getDb(), "reports", r.id), { status });
      await reload();
    } catch (e) {
      setError(e instanceof Error ? e.message : "更新に失敗しました");
    }
  };

  /** 通報された投稿・コメントそのものを消す。 */
  const removeTarget = async (r: Report) => {
    if (!confirm(`${TARGETS[r.targetType]}を削除しますか？この操作は戻せません。`))
      return;
    try {
      const col = r.targetType === "comment" ? "comments" : "posts";
      await deleteDoc(doc(getDb(), col, r.targetId));
      await updateDoc(doc(getDb(), "reports", r.id), { status: "resolved" });
      await reload();
    } catch (e) {
      setError(e instanceof Error ? e.message : "削除に失敗しました");
    }
  };

  const visible =
    items === null
      ? null
      : filter === "open"
        ? items.filter((r) => r.status === "open")
        : items;

  return (
    <section>
      <header className="flex items-end justify-between mb-4">
        <div>
          <h1 className="text-2xl font-bold">通報</h1>
          <p className="mt-1 text-sm text-[var(--color-text-muted)]">
            利用者から届いた報告です。App Store
            の審査要件として、不適切な内容を取り除ける状態にしておく必要があります。
          </p>
        </div>
        <div className="flex gap-2">
          {(["open", "all"] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-3 py-1 rounded-full text-sm ${
                filter === f
                  ? "bg-[var(--color-brand)] text-white"
                  : "bg-[var(--color-card)] text-[var(--color-text-muted)]"
              }`}
            >
              {f === "open" ? "未対応" : "すべて"}
            </button>
          ))}
        </div>
      </header>

      {error && (
        <p className="mb-4 px-3 py-2 rounded-lg bg-red-50 text-red-700 text-sm">
          {error}
        </p>
      )}

      {visible === null ? (
        <p className="text-[var(--color-text-muted)]">読み込み中…</p>
      ) : visible.length === 0 ? (
        <p className="text-[var(--color-text-muted)]">
          {filter === "open" ? "未対応の通報はありません。" : "通報はありません。"}
        </p>
      ) : (
        <ul className="space-y-3">
          {visible.map((r) => {
            const key = `${r.targetType}/${r.targetId}`;
            return (
              <li
                key={r.id}
                className="rounded-xl border border-[var(--color-border)] bg-[var(--color-card)] p-4"
              >
                <div className="flex items-center gap-2 text-sm">
                  <span className="px-2 py-0.5 rounded bg-red-50 text-red-700 font-semibold">
                    {REASONS[r.reason] ?? r.reason}
                  </span>
                  <span className="text-[var(--color-text-muted)]">
                    {TARGETS[r.targetType] ?? r.targetType}
                  </span>
                  <span className="text-[var(--color-text-muted)] text-xs">
                    {r.createdAt.slice(0, 16).replace("T", " ")}
                  </span>
                  {r.status !== "open" && (
                    <span className="ml-auto text-xs text-[var(--color-text-muted)]">
                      {r.status === "resolved" ? "対応済み" : "問題なし"}
                    </span>
                  )}
                </div>

                {r.note && <p className="mt-2 text-sm">{r.note}</p>}

                <div className="mt-3">
                  {preview[key] ? (
                    <pre className="whitespace-pre-wrap text-sm p-3 rounded-lg bg-[var(--color-bg)] border border-[var(--color-border)]">
                      {preview[key]}
                    </pre>
                  ) : (
                    <button
                      onClick={() => loadPreview(r)}
                      className="text-sm underline text-[var(--color-text-muted)]"
                    >
                      通報された内容を表示
                    </button>
                  )}
                </div>

                <div className="mt-3 flex flex-wrap gap-2">
                  <button
                    onClick={() => removeTarget(r)}
                    className="px-3 py-1.5 rounded-full bg-red-600 hover:bg-red-700 text-white text-sm font-semibold"
                  >
                    内容を削除
                  </button>
                  {r.status === "open" && (
                    <>
                      <button
                        onClick={() => setStatus(r, "resolved")}
                        className="px-3 py-1.5 rounded-full bg-[var(--color-card)] border border-[var(--color-border)] text-sm"
                      >
                        対応済みにする
                      </button>
                      <button
                        onClick={() => setStatus(r, "dismissed")}
                        className="px-3 py-1.5 rounded-full bg-[var(--color-card)] border border-[var(--color-border)] text-sm"
                      >
                        問題なし
                      </button>
                    </>
                  )}
                </div>
              </li>
            );
          })}
        </ul>
      )}
    </section>
  );
}
