"use client";

import { useEffect, useState, useCallback } from "react";
import {
  collection,
  deleteDoc,
  doc,
  getDocs,
  orderBy,
  query,
  updateDoc,
} from "firebase/firestore";
import { getDb } from "@/lib/firebase";
import { isoFromAny } from "@/lib/admin-helpers";

type Post = {
  id: string;
  authorId: string;
  authorName: string;
  authorPhotoUrl: string | null;
  content: string;
  imageUrls: string[];
  likeCount: number;
  commentCount: number;
  isPinned: boolean;
  createdAt: string;
  updatedAt: string;
};

export default function PostsPage() {
  const [items, setItems] = useState<Post[] | null>(null);
  const [filter, setFilter] = useState<"all" | "pinned">("all");
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    setError(null);
    try {
      const snap = await getDocs(
        query(collection(getDb(), "posts"), orderBy("createdAt", "desc")),
      );
      const list: Post[] = snap.docs.map((d) => {
        const data = d.data();
        return {
          id: d.id,
          authorId: data.authorId ?? "",
          authorName: data.authorName ?? "",
          authorPhotoUrl: data.authorPhotoUrl ?? null,
          content: data.content ?? "",
          imageUrls: Array.isArray(data.imageUrls) ? data.imageUrls : [],
          likeCount: data.likeCount ?? 0,
          commentCount: data.commentCount ?? 0,
          isPinned: data.isPinned === true,
          createdAt: isoFromAny(data.createdAt),
          updatedAt: isoFromAny(data.updatedAt),
        };
      });
      setItems(list);
    } catch (e) {
      setError(e instanceof Error ? e.message : "読み込み失敗");
      setItems([]);
    }
  }, []);

  useEffect(() => {
    void reload();
  }, [reload]);

  const togglePinned = async (post: Post) => {
    try {
      await updateDoc(doc(getDb(), "posts", post.id), {
        isPinned: !post.isPinned,
        updatedAt: new Date().toISOString(),
      });
      await reload();
    } catch (e) {
      setError(e instanceof Error ? e.message : "更新に失敗しました");
    }
  };

  const remove = async (post: Post) => {
    if (
      !confirm(
        `この投稿を削除しますか？\n\n投稿者: ${post.authorName}\n本文: ${post.content.slice(0, 50)}…`,
      )
    )
      return;
    try {
      await deleteDoc(doc(getDb(), "posts", post.id));
      await reload();
    } catch (e) {
      setError(e instanceof Error ? e.message : "削除に失敗しました");
    }
  };

  const visible =
    items === null
      ? null
      : filter === "pinned"
        ? items.filter((p) => p.isPinned)
        : items;

  return (
    <div>
      <header className="flex items-end justify-between mb-4">
        <div>
          <h1 className="text-2xl font-bold">投稿モデレーション</h1>
          <p className="mt-1 text-sm text-[var(--color-text-muted)]">
            ピン留めの切り替え・不適切投稿の削除を行えます。
          </p>
        </div>
        <span className="text-sm text-[var(--color-text-muted)]">
          {visible === null ? "" : `${visible.length} 件`}
        </span>
      </header>

      <div className="mb-4 flex gap-2 text-sm">
        <button
          onClick={() => setFilter("all")}
          className={`px-3 py-1 rounded-full ${
            filter === "all"
              ? "bg-[var(--color-text)] text-white"
              : "border border-[var(--color-border)] hover:bg-[var(--color-card)]"
          }`}
        >
          すべて
        </button>
        <button
          onClick={() => setFilter("pinned")}
          className={`px-3 py-1 rounded-full ${
            filter === "pinned"
              ? "bg-[var(--color-text)] text-white"
              : "border border-[var(--color-border)] hover:bg-[var(--color-card)]"
          }`}
        >
          ピン留めのみ
        </button>
      </div>

      {error && (
        <p className="mb-4 px-3 py-2 rounded-lg bg-red-50 text-red-700 text-sm">
          {error}
        </p>
      )}

      {visible === null ? (
        <p className="text-[var(--color-text-muted)]">読み込み中…</p>
      ) : visible.length === 0 ? (
        <p className="text-[var(--color-text-muted)]">投稿がありません。</p>
      ) : (
        <ul className="space-y-3">
          {visible.map((p) => (
            <li
              key={p.id}
              className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] p-4"
            >
              <div className="flex items-center gap-2 text-xs text-[var(--color-text-muted)] mb-2">
                {p.isPinned && (
                  <span className="px-1.5 py-0.5 rounded bg-orange-100 text-orange-700">
                    📌 ピン
                  </span>
                )}
                <span className="font-bold text-[var(--color-text)]">
                  {p.authorName || "(無名)"}
                </span>
                <span className="font-mono">{p.authorId}</span>
                <span>{new Date(p.createdAt).toLocaleString("ja-JP")}</span>
              </div>
              <p className="text-sm whitespace-pre-line">{p.content}</p>
              {p.imageUrls.length > 0 && (
                <p className="mt-2 text-xs text-[var(--color-text-muted)]">
                  画像 {p.imageUrls.length} 枚
                </p>
              )}
              <div className="mt-3 flex items-center gap-3 text-xs text-[var(--color-text-muted)]">
                <span>いいね {p.likeCount}</span>
                <span>コメント {p.commentCount}</span>
              </div>
              <div className="mt-3 flex gap-2">
                <button
                  onClick={() => togglePinned(p)}
                  className="px-3 py-1 rounded-lg text-sm border border-[var(--color-border)] hover:bg-[var(--color-bg)]"
                >
                  {p.isPinned ? "ピン解除" : "ピン留め"}
                </button>
                <button
                  onClick={() => remove(p)}
                  className="px-3 py-1 rounded-lg text-sm border border-red-200 text-red-700 hover:bg-red-50"
                >
                  削除
                </button>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
