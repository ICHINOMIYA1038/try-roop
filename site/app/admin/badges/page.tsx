"use client";

import { useEffect, useState, useCallback } from "react";
import {
  collection,
  deleteDoc,
  doc,
  getDocs,
  setDoc,
  Timestamp,
} from "firebase/firestore";
import { getDb } from "@/lib/firebase";

const CONDITION_TYPES = [
  { value: "videosWatched", label: "動画視聴数" },
  { value: "coursesCompleted", label: "コース完了数" },
  { value: "specificCourse", label: "特定コース完了 (要 courseId)" },
  { value: "consecutiveDays", label: "連続利用日数" },
  { value: "postsCreated", label: "投稿数" },
] as const;

type ConditionType = (typeof CONDITION_TYPES)[number]["value"];

type Badge = {
  id: string;
  name: string;
  description: string;
  iconUrl: string;
  condition: { type: ConditionType; threshold: number; courseId: string | null };
  createdAt: string;
};

type FormState = {
  id: string | null;
  docId: string;
  name: string;
  description: string;
  iconUrl: string;
  conditionType: ConditionType;
  threshold: number;
  courseId: string;
};

const emptyForm: FormState = {
  id: null,
  docId: "",
  name: "",
  description: "",
  iconUrl: "",
  conditionType: "videosWatched",
  threshold: 1,
  courseId: "",
};

function isoFromAny(v: unknown): string {
  if (v instanceof Timestamp) return v.toDate().toISOString();
  if (typeof v === "string") return v;
  return new Date().toISOString();
}

export default function BadgesPage() {
  const [items, setItems] = useState<Badge[] | null>(null);
  const [form, setForm] = useState<FormState>(emptyForm);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    setError(null);
    try {
      const snap = await getDocs(collection(getDb(), "badges"));
      const list: Badge[] = snap.docs.map((d) => {
        const data = d.data();
        const cond = data.condition ?? {};
        return {
          id: d.id,
          name: data.name ?? "",
          description: data.description ?? "",
          iconUrl: data.iconUrl ?? "",
          condition: {
            type: (cond.type ?? "videosWatched") as ConditionType,
            threshold: cond.threshold ?? 0,
            courseId: cond.courseId ?? null,
          },
          createdAt: isoFromAny(data.createdAt),
        };
      });
      setItems(list.sort((a, b) => a.name.localeCompare(b.name)));
    } catch (e) {
      setError(e instanceof Error ? e.message : "読み込み失敗");
      setItems([]);
    }
  }, []);

  useEffect(() => {
    void reload();
  }, [reload]);

  const startEdit = (b: Badge) =>
    setForm({
      id: b.id,
      docId: b.id,
      name: b.name,
      description: b.description,
      iconUrl: b.iconUrl,
      conditionType: b.condition.type,
      threshold: b.condition.threshold,
      courseId: b.condition.courseId ?? "",
    });
  const reset = () => setForm(emptyForm);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const id =
        form.id ??
        (form.docId.trim() ||
          `badge_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`);
      const isCreate = form.id === null;
      let createdAt = new Date().toISOString();
      if (!isCreate) {
        const existing = items?.find((it) => it.id === id);
        if (existing) createdAt = existing.createdAt;
      }
      await setDoc(doc(getDb(), "badges", id), {
        name: form.name.trim(),
        description: form.description.trim(),
        iconUrl: form.iconUrl.trim(),
        condition: {
          type: form.conditionType,
          threshold: form.threshold,
          courseId:
            form.conditionType === "specificCourse"
              ? form.courseId.trim() || null
              : null,
        },
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
    if (!confirm(`バッジ "${id}" を削除しますか？`)) return;
    try {
      await deleteDoc(doc(getDb(), "badges", id));
      await reload();
    } catch (e) {
      setError(e instanceof Error ? e.message : "削除に失敗しました");
    }
  };

  return (
    <div className="grid gap-6 lg:grid-cols-[1fr_400px]">
      <section>
        <header className="flex items-end justify-between mb-4">
          <h1 className="text-2xl font-bold">バッジ</h1>
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
            まだバッジがありません。
          </p>
        ) : (
          <ul className="grid gap-3 sm:grid-cols-2">
            {items.map((b) => (
              <li
                key={b.id}
                className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] p-4"
              >
                <div className="flex items-start gap-3">
                  <div className="text-3xl">{b.iconUrl || "🏅"}</div>
                  <div className="flex-1 min-w-0">
                    <div className="font-bold">{b.name}</div>
                    <div className="text-xs text-[var(--color-text-muted)] font-mono">
                      {b.id}
                    </div>
                  </div>
                </div>
                <p className="mt-2 text-sm text-[var(--color-text-muted)]">
                  {b.description}
                </p>
                <p className="mt-2 text-xs text-[var(--color-text-muted)]">
                  条件:{" "}
                  {CONDITION_TYPES.find((t) => t.value === b.condition.type)
                    ?.label ?? b.condition.type}{" "}
                  ≥ {b.condition.threshold}
                  {b.condition.courseId && ` (${b.condition.courseId})`}
                </p>
                <div className="mt-3 flex gap-2">
                  <button
                    onClick={() => startEdit(b)}
                    className="px-3 py-1 rounded-lg text-sm border border-[var(--color-border)] hover:bg-[var(--color-bg)]"
                  >
                    編集
                  </button>
                  <button
                    onClick={() => remove(b.id)}
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
            {form.id ? "バッジを編集" : "バッジを追加"}
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
              placeholder="(空なら自動生成)"
              className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] font-mono focus:outline-none focus:border-[var(--color-brand)] disabled:opacity-50"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
              名前
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
              アイコン (絵文字 or URL)
            </label>
            <input
              type="text"
              value={form.iconUrl}
              onChange={(e) => setForm({ ...form, iconUrl: e.target.value })}
              placeholder="🏆"
              className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)]"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
              獲得条件
            </label>
            <select
              value={form.conditionType}
              onChange={(e) =>
                setForm({
                  ...form,
                  conditionType: e.target.value as ConditionType,
                })
              }
              className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)]"
            >
              {CONDITION_TYPES.map((t) => (
                <option key={t.value} value={t.value}>
                  {t.label}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
              閾値
            </label>
            <input
              type="number"
              required
              min={1}
              value={form.threshold}
              onChange={(e) =>
                setForm({ ...form, threshold: Number(e.target.value) })
              }
              className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)]"
            />
          </div>
          {form.conditionType === "specificCourse" && (
            <div>
              <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
                対象コース ID
              </label>
              <input
                type="text"
                value={form.courseId}
                onChange={(e) => setForm({ ...form, courseId: e.target.value })}
                className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] font-mono focus:outline-none focus:border-[var(--color-brand)]"
              />
            </div>
          )}
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
