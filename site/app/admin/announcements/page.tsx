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
  Timestamp,
} from "firebase/firestore";
import { getDb } from "@/lib/firebase";

type Announcement = {
  id: string;
  title: string;
  content: string;
  imageUrl: string | null;
  isPublished: boolean;
  createdAt: string; // ISO 8601 (モバイルアプリの Announcement.fromMap 互換)
};

type FormState = {
  id: string | null;
  title: string;
  content: string;
  imageUrl: string;
  isPublished: boolean;
};

const emptyForm: FormState = {
  id: null,
  title: "",
  content: "",
  imageUrl: "",
  isPublished: false,
};

export default function AnnouncementsPage() {
  const [items, setItems] = useState<Announcement[] | null>(null);
  const [form, setForm] = useState<FormState>(emptyForm);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    setError(null);
    try {
      const snap = await getDocs(
        query(collection(getDb(), "announcements"), orderBy("createdAt", "desc")),
      );
      const list: Announcement[] = snap.docs.map((d) => {
        const data = d.data();
        const created = data.createdAt;
        const createdIso =
          created instanceof Timestamp
            ? created.toDate().toISOString()
            : typeof created === "string"
              ? created
              : new Date().toISOString();
        return {
          id: d.id,
          title: data.title ?? "",
          content: data.content ?? "",
          imageUrl: data.imageUrl ?? null,
          isPublished: data.isPublished === true,
          createdAt: createdIso,
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

  const startEdit = (a: Announcement) => {
    setForm({
      id: a.id,
      title: a.title,
      content: a.content,
      imageUrl: a.imageUrl ?? "",
      isPublished: a.isPublished,
    });
  };

  const reset = () => setForm(emptyForm);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const id =
        form.id ??
        `announcement_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
      const isCreate = form.id === null;
      const docRef = doc(getDb(), "announcements", id);
      // 既存ドキュメントを更新する場合は createdAt を保持する
      let createdAt = new Date().toISOString();
      if (!isCreate) {
        const existing = items?.find((it) => it.id === id);
        if (existing) createdAt = existing.createdAt;
      }
      await setDoc(docRef, {
        title: form.title.trim(),
        content: form.content,
        imageUrl: form.imageUrl.trim() || null,
        isPublished: form.isPublished,
        createdAt,
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
    if (!confirm("この告知を削除しますか？")) return;
    try {
      await deleteDoc(doc(getDb(), "announcements", id));
      await reload();
    } catch (e) {
      setError(e instanceof Error ? e.message : "削除に失敗しました");
    }
  };

  return (
    <div className="grid gap-6 lg:grid-cols-[1fr_360px]">
      <section>
        <header className="flex items-end justify-between mb-4">
          <h1 className="text-2xl font-bold">お知らせ</h1>
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
            まだ告知がありません。右のフォームから追加できます。
          </p>
        ) : (
          <ul className="space-y-3">
            {items.map((a) => (
              <li
                key={a.id}
                className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] p-4"
              >
                <div className="flex items-center gap-2 text-xs text-[var(--color-text-muted)] mb-1">
                  <span
                    className={`px-1.5 py-0.5 rounded ${
                      a.isPublished
                        ? "bg-green-100 text-green-700"
                        : "bg-gray-100 text-gray-600"
                    }`}
                  >
                    {a.isPublished ? "公開中" : "非公開"}
                  </span>
                  <span>{new Date(a.createdAt).toLocaleString("ja-JP")}</span>
                </div>
                <h2 className="font-bold">{a.title}</h2>
                <p className="mt-1 text-sm whitespace-pre-line text-[var(--color-text-muted)] line-clamp-3">
                  {a.content}
                </p>
                <div className="mt-3 flex gap-2">
                  <button
                    onClick={() => startEdit(a)}
                    className="px-3 py-1 rounded-lg text-sm border border-[var(--color-border)] hover:bg-[var(--color-bg)]"
                  >
                    編集
                  </button>
                  <button
                    onClick={() => remove(a.id)}
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
            {form.id ? "告知を編集" : "新しい告知を追加"}
          </h2>
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
              本文
            </label>
            <textarea
              required
              rows={6}
              value={form.content}
              onChange={(e) => setForm({ ...form, content: e.target.value })}
              className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)] resize-y"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
              画像 URL (任意)
            </label>
            <input
              type="url"
              value={form.imageUrl}
              onChange={(e) => setForm({ ...form, imageUrl: e.target.value })}
              className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)]"
            />
          </div>
          <label className="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={form.isPublished}
              onChange={(e) =>
                setForm({ ...form, isPublished: e.target.checked })
              }
              className="accent-[var(--color-brand)]"
            />
            公開する
          </label>
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
