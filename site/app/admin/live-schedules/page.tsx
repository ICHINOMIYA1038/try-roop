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

const STATUSES = [
  { value: "scheduled", label: "予定" },
  { value: "live", label: "配信中" },
  { value: "ended", label: "終了" },
] as const;

type Status = (typeof STATUSES)[number]["value"];

type LiveSchedule = {
  id: string;
  title: string;
  description: string;
  scheduledAt: string;
  duration: number;
  thumbnailUrl: string | null;
  streamUrl: string | null;
  status: Status;
  createdAt: string;
};

type FormState = {
  id: string | null;
  title: string;
  description: string;
  scheduledAtLocal: string; // datetime-local 形式
  duration: number;
  thumbnailUrl: string;
  streamUrl: string;
  status: Status;
};

const emptyForm: FormState = {
  id: null,
  title: "",
  description: "",
  scheduledAtLocal: toLocalInput(new Date()),
  duration: 60,
  thumbnailUrl: "",
  streamUrl: "",
  status: "scheduled",
};

function toLocalInput(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}
function fromLocalInput(s: string): Date {
  return new Date(s);
}
function isoFromAny(v: unknown): string {
  if (v instanceof Timestamp) return v.toDate().toISOString();
  if (typeof v === "string") return v;
  return new Date().toISOString();
}

export default function LiveSchedulesPage() {
  const [items, setItems] = useState<LiveSchedule[] | null>(null);
  const [form, setForm] = useState<FormState>(emptyForm);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    setError(null);
    try {
      const snap = await getDocs(
        query(collection(getDb(), "liveSchedules"), orderBy("scheduledAt", "desc")),
      );
      const list: LiveSchedule[] = snap.docs.map((d) => {
        const data = d.data();
        return {
          id: d.id,
          title: data.title ?? "",
          description: data.description ?? "",
          scheduledAt: isoFromAny(data.scheduledAt),
          duration: data.duration ?? 60,
          thumbnailUrl: data.thumbnailUrl ?? null,
          streamUrl: data.streamUrl ?? null,
          status: (data.status ?? "scheduled") as Status,
          createdAt: isoFromAny(data.createdAt),
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

  const startEdit = (s: LiveSchedule) =>
    setForm({
      id: s.id,
      title: s.title,
      description: s.description,
      scheduledAtLocal: toLocalInput(new Date(s.scheduledAt)),
      duration: s.duration,
      thumbnailUrl: s.thumbnailUrl ?? "",
      streamUrl: s.streamUrl ?? "",
      status: s.status,
    });
  const reset = () => setForm({ ...emptyForm, scheduledAtLocal: toLocalInput(new Date()) });

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const id =
        form.id ??
        `live_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`;
      const isCreate = form.id === null;
      let createdAt = new Date().toISOString();
      if (!isCreate) {
        const existing = items?.find((it) => it.id === id);
        if (existing) createdAt = existing.createdAt;
      }
      await setDoc(doc(getDb(), "liveSchedules", id), {
        title: form.title.trim(),
        description: form.description.trim(),
        scheduledAt: fromLocalInput(form.scheduledAtLocal).toISOString(),
        duration: form.duration,
        thumbnailUrl: form.thumbnailUrl.trim() || null,
        streamUrl: form.streamUrl.trim() || null,
        status: form.status,
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
    if (!confirm("このライブ予定を削除しますか？")) return;
    try {
      await deleteDoc(doc(getDb(), "liveSchedules", id));
      await reload();
    } catch (e) {
      setError(e instanceof Error ? e.message : "削除に失敗しました");
    }
  };

  return (
    <div className="grid gap-6 lg:grid-cols-[1fr_400px]">
      <section>
        <header className="flex items-end justify-between mb-4">
          <h1 className="text-2xl font-bold">ライブ予定</h1>
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
            まだライブ予定はありません。
          </p>
        ) : (
          <ul className="space-y-3">
            {items.map((s) => {
              const sched = new Date(s.scheduledAt);
              return (
                <li
                  key={s.id}
                  className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] p-4"
                >
                  <div className="flex items-center gap-2 text-xs mb-1">
                    <span
                      className={`px-1.5 py-0.5 rounded ${
                        s.status === "live"
                          ? "bg-red-100 text-red-700"
                          : s.status === "scheduled"
                            ? "bg-blue-100 text-blue-700"
                            : "bg-gray-100 text-gray-600"
                      }`}
                    >
                      {STATUSES.find((t) => t.value === s.status)?.label}
                    </span>
                    <span className="text-[var(--color-text-muted)]">
                      {sched.toLocaleString("ja-JP")} ({s.duration} 分)
                    </span>
                  </div>
                  <h2 className="font-bold">{s.title}</h2>
                  <p className="mt-1 text-sm text-[var(--color-text-muted)] line-clamp-2">
                    {s.description}
                  </p>
                  {s.streamUrl && (
                    <p className="mt-1 text-xs text-[var(--color-text-muted)] truncate">
                      Stream: {s.streamUrl}
                    </p>
                  )}
                  <div className="mt-3 flex gap-2">
                    <button
                      onClick={() => startEdit(s)}
                      className="px-3 py-1 rounded-lg text-sm border border-[var(--color-border)] hover:bg-[var(--color-bg)]"
                    >
                      編集
                    </button>
                    <button
                      onClick={() => remove(s.id)}
                      className="px-3 py-1 rounded-lg text-sm border border-red-200 text-red-700 hover:bg-red-50"
                    >
                      削除
                    </button>
                  </div>
                </li>
              );
            })}
          </ul>
        )}
      </section>

      <aside>
        <form
          onSubmit={submit}
          className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] p-5 space-y-3 sticky top-24"
        >
          <h2 className="font-bold">
            {form.id ? "ライブ予定を編集" : "ライブ予定を追加"}
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
              required
              rows={3}
              value={form.description}
              onChange={(e) =>
                setForm({ ...form, description: e.target.value })
              }
              className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)] resize-y"
            />
          </div>
          <div className="grid grid-cols-2 gap-2">
            <div>
              <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
                配信日時
              </label>
              <input
                type="datetime-local"
                required
                value={form.scheduledAtLocal}
                onChange={(e) =>
                  setForm({ ...form, scheduledAtLocal: e.target.value })
                }
                className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)]"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
                時間 (分)
              </label>
              <input
                type="number"
                required
                min={1}
                value={form.duration}
                onChange={(e) =>
                  setForm({ ...form, duration: Number(e.target.value) })
                }
                className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)]"
              />
            </div>
          </div>
          <div>
            <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
              ステータス
            </label>
            <select
              value={form.status}
              onChange={(e) =>
                setForm({ ...form, status: e.target.value as Status })
              }
              className="w-full px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg)] focus:outline-none focus:border-[var(--color-brand)]"
            >
              {STATUSES.map((s) => (
                <option key={s.value} value={s.value}>
                  {s.label}
                </option>
              ))}
            </select>
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
          <div>
            <label className="block text-xs font-semibold text-[var(--color-text-muted)] mb-1">
              配信 URL (任意)
            </label>
            <input
              type="url"
              value={form.streamUrl}
              onChange={(e) => setForm({ ...form, streamUrl: e.target.value })}
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
