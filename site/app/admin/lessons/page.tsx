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

type Lesson = {
  id: string;
  title: string;
  description: string;
  content: string | null;
  assetPath: string | null;
  thumbnailUrl: string | null;
  categoryId: string;
  order: number;
  estimatedReadingMinutes: number;
  accessLevel: AccessLevel;
  createdAt: string;
  updatedAt: string;
};

type FormState = {
  id: string | null;
  docId: string;
  title: string;
  description: string;
  content: string;
  thumbnailUrl: string;
  categoryId: string;
  order: number;
  estimatedReadingMinutes: number;
  accessLevel: AccessLevel;
};

const emptyForm: FormState = {
  id: null,
  docId: "",
  title: "",
  description: "",
  content: "",
  thumbnailUrl: "",
  categoryId: "",
  order: 0,
  estimatedReadingMinutes: 5,
  accessLevel: "free",
};

export default function LessonsPage() {
  const [items, setItems] = useState<Lesson[] | null>(null);
  const [form, setForm] = useState<FormState>(emptyForm);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { options: categoryOptions } = useCategories();

  const reload = useCallback(async () => {
    setError(null);
    try {
      const snap = await getDocs(
        query(collection(getDb(), "textLessons"), orderBy("order", "asc")),
      );
      const list: Lesson[] = snap.docs.map((d) => {
        const data = d.data();
        return {
          id: d.id,
          title: data.title ?? "",
          description: data.description ?? "",
          content: data.content ?? null,
          assetPath: data.assetPath ?? null,
          thumbnailUrl: data.thumbnailUrl ?? null,
          categoryId: data.categoryId ?? "",
          order: data.order ?? 0,
          estimatedReadingMinutes: data.estimatedReadingMinutes ?? 5,
          accessLevel: (data.accessLevel ?? "free") as AccessLevel,
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

  const startEdit = (l: Lesson) =>
    setForm({
      id: l.id,
      docId: l.id,
      title: l.title,
      description: l.description,
      content: l.content ?? "",
      thumbnailUrl: l.thumbnailUrl ?? "",
      categoryId: l.categoryId,
      order: l.order,
      estimatedReadingMinutes: l.estimatedReadingMinutes,
      accessLevel: l.accessLevel,
    });
  const reset = () => setForm(emptyForm);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const id = form.id ?? (form.docId.trim() || genId("lesson"));
      const isCreate = form.id === null;
      let createdAt = new Date().toISOString();
      let assetPath: string | null = null;
      if (!isCreate) {
        const existing = items?.find((it) => it.id === id);
        if (existing) {
          createdAt = existing.createdAt;
          assetPath = existing.assetPath; // 既存の assetPath は維持 (旧ローカルアセット参照)
        }
      }
      await setDoc(doc(getDb(), "textLessons", id), {
        title: form.title.trim(),
        description: form.description.trim(),
        content: form.content || null,
        assetPath,
        thumbnailUrl: form.thumbnailUrl.trim() || null,
        categoryId: form.categoryId,
        order: form.order,
        estimatedReadingMinutes: form.estimatedReadingMinutes,
        accessLevel: form.accessLevel,
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
    if (!confirm(`レッスン "${id}" を削除しますか？`)) return;
    try {
      await deleteDoc(doc(getDb(), "textLessons", id));
      await reload();
    } catch (e) {
      setError(e instanceof Error ? e.message : "削除に失敗しました");
    }
  };

  return (
    <div className="grid gap-6 xl:grid-cols-[1fr_480px]">
      <section>
        <header className="flex items-end justify-between mb-4">
          <h1 className="text-2xl font-bold">テキストレッスン</h1>
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
            まだレッスンがありません。
          </p>
        ) : (
          <ul className="space-y-3">
            {items.map((l) => (
              <li
                key={l.id}
                className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] p-4"
              >
                <div className="flex items-center gap-2 text-xs mb-1">
                  <span
                    className={`px-1.5 py-0.5 rounded ${
                      l.accessLevel === "premium"
                        ? "bg-orange-100 text-orange-700"
                        : "bg-green-100 text-green-700"
                    }`}
                  >
                    {l.accessLevel === "premium" ? "プレミアム" : "無料"}
                  </span>
                  <span className="text-[var(--color-text-muted)]">
                    {categoryOptions.find((c) => c.id === l.categoryId)?.name ??
                      l.categoryId}
                  </span>
                  <span className="text-[var(--color-text-muted)]">
                    #{l.order} · {l.estimatedReadingMinutes} 分
                  </span>
                  {l.assetPath && (
                    <span
                      title={l.assetPath}
                      className="px-1.5 py-0.5 rounded bg-yellow-50 text-yellow-700"
                    >
                      アセット参照
                    </span>
                  )}
                </div>
                <h2 className="font-bold">{l.title}</h2>
                <p className="text-xs text-[var(--color-text-muted)] font-mono">
                  {l.id}
                </p>
                <p className="mt-1 text-sm text-[var(--color-text-muted)] line-clamp-2">
                  {l.description}
                </p>
                <div className="mt-3 flex gap-2">
                  <button
                    onClick={() => startEdit(l)}
                    className="px-3 py-1 rounded-lg text-sm border border-[var(--color-border)] hover:bg-[var(--color-bg)]"
                  >
                    編集
                  </button>
                  <button
                    onClick={() => remove(l.id)}
                    className="px-3 py-1 rounded-lg text-sm border border-red-200 text-red-700 hover:bg-red-50"
                  >
                    削除
                  </button>
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
            {form.id ? "レッスンを編集" : "レッスンを追加"}
          </h2>
          <div>
            <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
              ドキュメント ID
            </label>
            <input
              type="text"
              disabled={!!form.id}
              value={form.docId}
              onChange={(e) => setForm({ ...form, docId: e.target.value })}
              placeholder="例: lesson_karate_1 (空なら自動生成)"
              className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] font-mono focus:outline-none focus:border-[var(--color-brand)] disabled:opacity-50"
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
              required
              rows={2}
              value={form.description}
              onChange={(e) =>
                setForm({ ...form, description: e.target.value })
              }
              className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)] resize-y"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
              本文 (Markdown)
            </label>
            <textarea
              rows={10}
              value={form.content}
              onChange={(e) => setForm({ ...form, content: e.target.value })}
              placeholder="# タイトル&#10;&#10;空ならアプリ側のローカル assetPath にフォールバック"
              className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] font-mono text-xs focus:outline-none focus:border-[var(--color-brand)] resize-y"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
              サムネイル URL (任意)
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
                カテゴリ
              </label>
              <select
                required
                value={form.categoryId}
                onChange={(e) =>
                  setForm({ ...form, categoryId: e.target.value })
                }
                className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)]"
              >
                <option value="">(選択してください)</option>
                {categoryOptions.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </div>
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
          </div>
          <div className="grid grid-cols-2 gap-2">
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
            <div>
              <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
                想定読書時間 (分)
              </label>
              <input
                type="number"
                min={1}
                value={form.estimatedReadingMinutes}
                onChange={(e) =>
                  setForm({
                    ...form,
                    estimatedReadingMinutes: Number(e.target.value),
                  })
                }
                className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)]"
              />
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
