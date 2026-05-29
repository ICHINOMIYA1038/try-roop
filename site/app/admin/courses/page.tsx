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

const DIFFICULTIES = [
  { value: "beginner", label: "初級" },
  { value: "intermediate", label: "中級" },
  { value: "advanced", label: "上級" },
] as const;

type Difficulty = (typeof DIFFICULTIES)[number]["value"];

type VideoOption = { id: string; title: string };

type Course = {
  id: string;
  title: string;
  description: string;
  thumbnailUrl: string | null;
  categoryId: string | null;
  videoIds: string[];
  totalDuration: number;
  difficulty: Difficulty;
  isPublished: boolean;
  createdAt: string;
  updatedAt: string;
};

type FormState = {
  id: string | null;
  title: string;
  description: string;
  thumbnailUrl: string;
  categoryId: string;
  videoIds: string[];
  totalDuration: number;
  difficulty: Difficulty;
  isPublished: boolean;
};

const emptyForm: FormState = {
  id: null,
  title: "",
  description: "",
  thumbnailUrl: "",
  categoryId: "",
  videoIds: [],
  totalDuration: 0,
  difficulty: "beginner",
  isPublished: false,
};

export default function CoursesPage() {
  const [items, setItems] = useState<Course[] | null>(null);
  const [videoOptions, setVideoOptions] = useState<VideoOption[]>([]);
  const [form, setForm] = useState<FormState>(emptyForm);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { options: categoryOptions } = useCategories();

  const reload = useCallback(async () => {
    setError(null);
    try {
      const [coursesSnap, videosSnap] = await Promise.all([
        getDocs(collection(getDb(), "courses")),
        getDocs(query(collection(getDb(), "videos"), orderBy("order", "asc"))),
      ]);
      const list: Course[] = coursesSnap.docs.map((d) => {
        const data = d.data();
        return {
          id: d.id,
          title: data.title ?? "",
          description: data.description ?? "",
          thumbnailUrl: data.thumbnailUrl ?? null,
          categoryId: data.categoryId ?? null,
          videoIds: Array.isArray(data.videoIds) ? data.videoIds : [],
          totalDuration: data.totalDuration ?? 0,
          difficulty: (data.difficulty ?? "beginner") as Difficulty,
          isPublished: data.isPublished === true,
          createdAt: isoFromAny(data.createdAt),
          updatedAt: isoFromAny(data.updatedAt),
        };
      });
      setItems(list.sort((a, b) => a.title.localeCompare(b.title)));
      setVideoOptions(
        videosSnap.docs.map((d) => ({
          id: d.id,
          title: d.data().title ?? d.id,
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

  const startEdit = (c: Course) =>
    setForm({
      id: c.id,
      title: c.title,
      description: c.description,
      thumbnailUrl: c.thumbnailUrl ?? "",
      categoryId: c.categoryId ?? "",
      videoIds: c.videoIds,
      totalDuration: c.totalDuration,
      difficulty: c.difficulty,
      isPublished: c.isPublished,
    });
  const reset = () => setForm(emptyForm);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const id = form.id ?? genId("course");
      const isCreate = form.id === null;
      let createdAt = new Date().toISOString();
      if (!isCreate) {
        const existing = items?.find((it) => it.id === id);
        if (existing) createdAt = existing.createdAt;
      }
      await setDoc(doc(getDb(), "courses", id), {
        title: form.title.trim(),
        description: form.description.trim(),
        thumbnailUrl: form.thumbnailUrl.trim() || null,
        instructorId: null,
        categoryId: form.categoryId || null,
        videoIds: form.videoIds,
        totalDuration: form.totalDuration,
        difficulty: form.difficulty,
        isPublished: form.isPublished,
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
    if (!confirm(`コース "${id}" を削除しますか？`)) return;
    try {
      await deleteDoc(doc(getDb(), "courses", id));
      await reload();
    } catch (e) {
      setError(e instanceof Error ? e.message : "削除に失敗しました");
    }
  };

  const toggleVideo = (videoId: string) => {
    setForm((f) =>
      f.videoIds.includes(videoId)
        ? { ...f, videoIds: f.videoIds.filter((v) => v !== videoId) }
        : { ...f, videoIds: [...f.videoIds, videoId] },
    );
  };

  return (
    <div className="grid gap-6 lg:grid-cols-[1fr_420px]">
      <section>
        <header className="flex items-end justify-between mb-4">
          <h1 className="text-2xl font-bold">コース</h1>
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
            まだコースがありません。
          </p>
        ) : (
          <ul className="space-y-3">
            {items.map((c) => (
              <li
                key={c.id}
                className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] p-4"
              >
                <div className="flex items-center gap-2 text-xs mb-1">
                  <span
                    className={`px-1.5 py-0.5 rounded ${
                      c.isPublished
                        ? "bg-green-100 text-green-700"
                        : "bg-gray-100 text-gray-600"
                    }`}
                  >
                    {c.isPublished ? "公開中" : "非公開"}
                  </span>
                  <span className="px-1.5 py-0.5 rounded bg-[var(--color-bg)] text-[var(--color-text-muted)]">
                    {DIFFICULTIES.find((d) => d.value === c.difficulty)?.label}
                  </span>
                  {c.categoryId && (
                    <span className="text-[var(--color-text-muted)]">
                      {categoryOptions.find((cat) => cat.id === c.categoryId)
                        ?.name ?? c.categoryId}
                    </span>
                  )}
                </div>
                <h2 className="font-bold">{c.title}</h2>
                <p className="mt-1 text-sm text-[var(--color-text-muted)] line-clamp-2">
                  {c.description}
                </p>
                <p className="mt-2 text-xs text-[var(--color-text-muted)]">
                  動画 {c.videoIds.length} 本 / {c.totalDuration} 分
                </p>
                <div className="mt-3 flex gap-2">
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
            {form.id ? "コースを編集" : "コースを追加"}
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
            <div>
              <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
                難易度
              </label>
              <select
                value={form.difficulty}
                onChange={(e) =>
                  setForm({
                    ...form,
                    difficulty: e.target.value as Difficulty,
                  })
                }
                className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)]"
              >
                {DIFFICULTIES.map((d) => (
                  <option key={d.value} value={d.value}>
                    {d.label}
                  </option>
                ))}
              </select>
            </div>
          </div>
          <div>
            <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
              合計時間 (分)
            </label>
            <input
              type="number"
              min={0}
              value={form.totalDuration}
              onChange={(e) =>
                setForm({ ...form, totalDuration: Number(e.target.value) })
              }
              className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)]"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
              含める動画 ({form.videoIds.length} 件)
            </label>
            <div className="max-h-40 overflow-y-auto border border-[var(--color-border)] rounded-lg p-2 space-y-1 bg-[var(--color-bg)]">
              {videoOptions.length === 0 ? (
                <p className="text-xs text-[var(--color-text-muted)]">
                  動画がまだありません
                </p>
              ) : (
                videoOptions.map((v) => (
                  <label
                    key={v.id}
                    className="flex items-center gap-2 text-sm cursor-pointer"
                  >
                    <input
                      type="checkbox"
                      checked={form.videoIds.includes(v.id)}
                      onChange={() => toggleVideo(v.id)}
                      className="accent-[var(--color-brand)]"
                    />
                    <span className="truncate">{v.title}</span>
                  </label>
                ))
              )}
            </div>
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
