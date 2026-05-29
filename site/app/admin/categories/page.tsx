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

type Category = {
  id: string;
  name: string;
  order: number;
};

type FormState = {
  id: string | null;
  docId: string;
  name: string;
  order: number;
};

const emptyForm: FormState = { id: null, docId: "", name: "", order: 0 };

export default function CategoriesPage() {
  const [items, setItems] = useState<Category[] | null>(null);
  const [form, setForm] = useState<FormState>(emptyForm);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    setError(null);
    try {
      const snap = await getDocs(
        query(collection(getDb(), "categories"), orderBy("order", "asc")),
      );
      setItems(
        snap.docs.map((d) => ({
          id: d.id,
          name: d.data().name ?? "",
          order: d.data().order ?? 0,
        })),
      );
    } catch (e) {
      setError(e instanceof Error ? e.message : "読み込み失敗");
      setItems([]);
    }
  }, []);

  useEffect(() => {
    void reload();
  }, [reload]);

  const startEdit = (c: Category) =>
    setForm({ id: c.id, docId: c.id, name: c.name, order: c.order });
  const reset = () => setForm(emptyForm);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const id =
        form.id ??
        (form.docId.trim() ||
          form.name.trim().toLowerCase().replace(/\s+/g, "_"));
      if (!id) throw new Error("ドキュメント ID または名前が必要です");
      await setDoc(doc(getDb(), "categories", id), {
        name: form.name.trim(),
        order: form.order,
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
    if (
      !confirm(
        `カテゴリ "${id}" を削除しますか？このカテゴリを参照する動画/レッスン/コースが孤立する可能性があります。`,
      )
    )
      return;
    try {
      await deleteDoc(doc(getDb(), "categories", id));
      await reload();
    } catch (e) {
      setError(e instanceof Error ? e.message : "削除に失敗しました");
    }
  };

  return (
    <div className="grid gap-6 lg:grid-cols-[1fr_360px]">
      <section>
        <header className="flex items-end justify-between mb-4">
          <h1 className="text-2xl font-bold">カテゴリ</h1>
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
            まだカテゴリがありません。
          </p>
        ) : (
          <ul className="space-y-2">
            {items.map((c) => (
              <li
                key={c.id}
                className="flex items-center gap-4 rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] p-4"
              >
                <div className="w-12 text-sm text-[var(--color-text-muted)]">
                  #{c.order}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="font-bold">{c.name}</div>
                  <div className="text-xs text-[var(--color-text-muted)] font-mono">
                    {c.id}
                  </div>
                </div>
                <button
                  onClick={() => startEdit(c)}
                  className="px-3 py-1 rounded-lg text-sm border border-[var(--color-border)] hover:bg-[var(--color-bg)]"
                >
                  編集
                </button>
                <button
                  onClick={() => remove(c.id)}
                  className="px-3 py-1 rounded-lg text-sm border border-red-200 text-red-700 hover:bg-red-50"
                >
                  削除
                </button>
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
            {form.id ? "カテゴリを編集" : "カテゴリを追加"}
          </h2>
          <div>
            <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
              ドキュメント ID{" "}
              {!form.id && <span className="text-red-600">*</span>}
            </label>
            <input
              type="text"
              required={!form.id}
              disabled={!!form.id}
              value={form.docId}
              onChange={(e) => setForm({ ...form, docId: e.target.value })}
              placeholder="例: karate"
              className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)] font-mono disabled:opacity-50"
            />
            <p className="mt-1 text-[11px] text-[var(--color-text-muted)]">
              モバイルアプリと seed.js が参照する識別子。半角英数字推奨。
            </p>
          </div>
          <div>
            <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
              表示名
            </label>
            <input
              type="text"
              required
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)]"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
              並び順
            </label>
            <input
              type="number"
              required
              value={form.order}
              onChange={(e) =>
                setForm({ ...form, order: Number(e.target.value) })
              }
              className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)]"
            />
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
