"use client";

import { useEffect, useState, useCallback } from "react";
import {
  collection,
  deleteDoc,
  doc,
  getDocs,
  orderBy,
  query,
  setDoc,
} from "firebase/firestore";
import { getDb } from "@/lib/firebase";
import { useCategories, isoFromAny, genId } from "@/lib/admin-helpers";

const ACCESS_LEVELS = [
  { value: "free", label: "無料" },
  { value: "premium", label: "プレミアム" },
] as const;

type AccessLevel = (typeof ACCESS_LEVELS)[number]["value"];

type Video = {
  id: string;
  title: string;
  description: string;
  youtubeVideoId: string;
  thumbnailUrl: string | null;
  duration: number;
  accessLevel: AccessLevel;
  categoryId: string | null;
  order: number;
  createdAt: string;
  updatedAt: string;
};

type FormState = {
  id: string | null;
  title: string;
  description: string;
  youtubeVideoId: string;
  thumbnailUrl: string;
  duration: number;
  accessLevel: AccessLevel;
  categoryId: string;
  order: number;
};

const emptyForm: FormState = {
  id: null,
  title: "",
  description: "",
  youtubeVideoId: "",
  thumbnailUrl: "",
  duration: 0,
  accessLevel: "free",
  categoryId: "",
  order: 0,
};

export default function VideosPage() {
  const [items, setItems] = useState<Video[] | null>(null);
  const [form, setForm] = useState<FormState>(emptyForm);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { options: categoryOptions } = useCategories();

  const reload = useCallback(async () => {
    setError(null);
    try {
      const snap = await getDocs(
        query(collection(getDb(), "videos"), orderBy("order", "asc")),
      );
      const list: Video[] = snap.docs.map((d) => {
        const data = d.data();
        return {
          id: d.id,
          title: data.title ?? "",
          description: data.description ?? "",
          youtubeVideoId: data.youtubeVideoId ?? "",
          thumbnailUrl: data.thumbnailUrl ?? null,
          duration: data.duration ?? 0,
          accessLevel: (data.accessLevel ?? "free") as AccessLevel,
          categoryId: data.categoryId ?? null,
          order: data.order ?? 0,
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

  const startEdit = (v: Video) =>
    setForm({
      id: v.id,
      title: v.title,
      description: v.description,
      youtubeVideoId: v.youtubeVideoId,
      thumbnailUrl: v.thumbnailUrl ?? "",
      duration: v.duration,
      accessLevel: v.accessLevel,
      categoryId: v.categoryId ?? "",
      order: v.order,
    });
  const reset = () => setForm(emptyForm);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const id =
        form.id ?? `video_${form.youtubeVideoId.trim() || genId("untitled")}`;
      const isCreate = form.id === null;
      let createdAt = new Date().toISOString();
      if (!isCreate) {
        const existing = items?.find((it) => it.id === id);
        if (existing) createdAt = existing.createdAt;
      }
      const ytId = form.youtubeVideoId.trim();
      await setDoc(doc(getDb(), "videos", id), {
        title: form.title.trim(),
        description: form.description.trim(),
        youtubeVideoId: ytId,
        thumbnailUrl:
          form.thumbnailUrl.trim() ||
          (ytId ? `https://img.youtube.com/vi/${ytId}/0.jpg` : null),
        duration: form.duration,
        accessLevel: form.accessLevel,
        categoryId: form.categoryId || null,
        order: form.order,
        createdAt,
        updatedAt: new Date().toISOString(),
      });
      await reload();
      reset();
    } catch (e) {
      setError(e instanceof Error ? e.message : "保存に失敗しました");
    } finally {
      setSubmitting(false);
    }
  };

  const remove = async (id: string) => {
    if (!confirm(`動画 "${id}" を削除しますか？`)) return;
    try {
      await deleteDoc(doc(getDb(), "videos", id));
      await reload();
    } catch (e) {
      setError(e instanceof Error ? e.message : "削除に失敗しました");
    }
  };

  return (
    <div className="grid gap-6 lg:grid-cols-[1fr_400px]">
      <section>
        <header className="flex items-end justify-between mb-4">
          <h1 className="text-2xl font-bold">動画</h1>
          <span className="text-sm text-[var(--color-text-muted)]">
            {items === null ? "" : `${items.length} 件`}
          </span>
        </header>

        {error && (
          <p className="mb-4 px-3 py-2 rounded-lg bg-red-50 text-red-700 text-sm">
            {error}
          </p>
        )}

        {items === null ? (
          <p className="text-[var(--color-text-muted)]">読み込み中…</p>
        ) : items.length === 0 ? (
          <p className="text-[var(--color-text-muted)]">
            まだ動画がありません。
          </p>
        ) : (
          <ul className="space-y-3">
            {items.map((v) => (
              <li
                key={v.id}
                className="flex gap-4 rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] p-4"
              >
                {v.thumbnailUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={v.thumbnailUrl}
                    alt=""
                    className="w-32 h-20 rounded-lg object-cover bg-[var(--color-bg)]"
                  />
                ) : (
                  <div className="w-32 h-20 rounded-lg bg-[var(--color-bg)]" />
                )}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 text-xs">
                    <span
                      className={`px-1.5 py-0.5 rounded ${
                        v.accessLevel === "premium"
                          ? "bg-orange-100 text-orange-700"
                          : "bg-green-100 text-green-700"
                      }`}
                    >
                      {v.accessLevel === "premium" ? "プレミアム" : "無料"}
                    </span>
                    {v.categoryId && (
                      <span className="text-[var(--color-text-muted)]">
                        {categoryOptions.find((c) => c.id === v.categoryId)
                          ?.name ?? v.categoryId}
                      </span>
                    )}
                    <span className="text-[var(--color-text-muted)]">
                      #{v.order}
                    </span>
                  </div>
                  <h2 className="font-bold mt-1 truncate">{v.title}</h2>
                  <p className="text-xs text-[var(--color-text-muted)] font-mono truncate">
                    {v.youtubeVideoId}
                  </p>
                  <div className="mt-2 flex gap-2">
                    <button
                      onClick={() => startEdit(v)}
                      className="px-3 py-1 rounded-lg text-sm border border-[var(--color-border)] hover:bg-[var(--color-bg)]"
                    >
                      編集
                    </button>
                    <button
                      onClick={() => remove(v.id)}
                      className="px-3 py-1 rounded-lg text-sm border border-red-200 text-red-700 hover:bg-red-50"
                    >
                      削除
                    </button>
                  </div>
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>

      <aside>
        <form
          onSubmit={submit}
          className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] p-5 space-y-3 sticky top-24"
        >
          <h2 className="font-bold">
            {form.id ? "動画を編集" : "動画を追加"}
          </h2>
          <div>
            <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
              YouTube Video ID
            </label>
            <input
              type="text"
              required
              value={form.youtubeVideoId}
              onChange={(e) =>
                setForm({ ...form, youtubeVideoId: e.target.value })
              }
              placeholder="例: dQw4w9WgXcQ"
              className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] font-mono focus:outline-none focus:border-[var(--color-brand)]"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
              タイトル
            </label>
            <input
              type="text"
              required
              value={form.title}
              onChange={(e) => setForm({ ...form, title: e.target.value })}
              className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)]"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
              説明
            </label>
            <textarea
              rows={3}
              value={form.description}
              onChange={(e) =>
                setForm({ ...form, description: e.target.value })
              }
              className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)] resize-y"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
              サムネイル URL (任意。空なら YouTube の自動生成)
            </label>
            <input
              type="url"
              value={form.thumbnailUrl}
              onChange={(e) =>
                setForm({ ...form, thumbnailUrl: e.target.value })
              }
              className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)]"
            />
          </div>
          <div className="grid grid-cols-2 gap-2">
            <div>
              <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
                秒数
              </label>
              <input
                type="number"
                min={0}
                value={form.duration}
                onChange={(e) =>
                  setForm({ ...form, duration: Number(e.target.value) })
                }
                className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)]"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
                並び順
              </label>
              <input
                type="number"
                value={form.order}
                onChange={(e) =>
                  setForm({ ...form, order: Number(e.target.value) })
                }
                className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)]"
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-2">
            <div>
              <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
                アクセス
              </label>
              <select
                value={form.accessLevel}
                onChange={(e) =>
                  setForm({
                    ...form,
                    accessLevel: e.target.value as AccessLevel,
                  })
                }
                className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)]"
              >
                {ACCESS_LEVELS.map((a) => (
                  <option key={a.value} value={a.value}>
                    {a.label}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
                カテゴリ
              </label>
              <select
                value={form.categoryId}
                onChange={(e) =>
                  setForm({ ...form, categoryId: e.target.value })
                }
                className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)]"
              >
                <option value="">(なし)</option>
                {categoryOptions.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </div>
          </div>
          <div className="flex gap-2 pt-2">
            <button
              type="submit"
              disabled={submitting}
              className="flex-1 py-2 rounded-full bg-[var(--color-brand)] hover:bg-[var(--color-brand-dark)] text-white font-semibold disabled:opacity-50"
            >
              {submitting ? "保存中…" : form.id ? "更新" : "追加"}
            </button>
            {form.id && (
              <button
                type="button"
                onClick={reset}
                className="px-4 py-2 rounded-full border border-[var(--color-border)] hover:bg-[var(--color-bg)]"
              >
                キャンセル
              </button>
            )}
          </div>
        </form>
      </aside>
    </div>
  );
}
