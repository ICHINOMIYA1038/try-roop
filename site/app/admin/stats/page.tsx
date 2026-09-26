"use client";

import { useCallback, useEffect, useState } from "react";
import { collection, getDocs } from "firebase/firestore";
import { getDb } from "@/lib/firebase";
import { isoFromAny } from "@/lib/admin-helpers";

type Row = { id: string; title: string; a: number; b: number };

type Stats = {
  users: number;
  paying: number;
  activeWeek: number;
  activeMonth: number;
  tryThisMonth: number;
  videos: Row[];
  courses: Row[];
};

function daysAgo(n: number) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d;
}

export default function StatsPage() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    setError(null);
    try {
      const db = getDb();
      const [users, progress, tries, videos, courses, courseProgress] =
        await Promise.all([
          getDocs(collection(db, "users")),
          getDocs(collection(db, "progress")),
          getDocs(collection(db, "tryRecords")),
          getDocs(collection(db, "videos")),
          getDocs(collection(db, "courses")),
          getDocs(collection(db, "courseProgress")),
        ]);

      const week = daysAgo(7);
      const month = daysAgo(30);
      const monthStart = new Date();
      monthStart.setDate(1);
      monthStart.setHours(0, 0, 0, 0);

      // 視聴数は progress（視聴位置の記録）から数える。1人1動画で1。
      const views = new Map<string, { views: number; completed: number }>();
      const activeWeek = new Set<string>();
      const activeMonth = new Set<string>();

      progress.forEach((d) => {
        const p = d.data();
        const v = views.get(p.videoId) ?? { views: 0, completed: 0 };
        v.views += 1;
        if (p.completed) v.completed += 1;
        views.set(p.videoId, v);

        const at = new Date(isoFromAny(p.updatedAt));
        if (at >= week) activeWeek.add(p.uid);
        if (at >= month) activeMonth.add(p.uid);
      });

      let tryThisMonth = 0;
      tries.forEach((d) => {
        const t = d.data();
        const at = new Date(isoFromAny(t.completedAt));
        if (at >= monthStart) tryThisMonth += 1;
        if (at >= week) activeWeek.add(t.userId);
        if (at >= month) activeMonth.add(t.userId);
      });

      const courseStats = new Map<string, { s: number; f: number }>();
      courseProgress.forEach((d) => {
        const c = d.data();
        const cur = courseStats.get(c.courseId) ?? { s: 0, f: 0 };
        cur.s += 1;
        if (c.isCompleted) cur.f += 1;
        courseStats.set(c.courseId, cur);
      });

      let paying = 0;
      users.forEach((d) => {
        if (d.data().hasActiveSubscription === true) paying += 1;
      });

      setStats({
        users: users.size,
        paying,
        activeWeek: activeWeek.size,
        activeMonth: activeMonth.size,
        tryThisMonth,
        videos: videos.docs
          .map((d) => ({
            id: d.id,
            title: d.data().title ?? d.id,
            a: views.get(d.id)?.views ?? 0,
            b: views.get(d.id)?.completed ?? 0,
          }))
          .sort((x, y) => y.a - x.a),
        courses: courses.docs
          .map((d) => ({
            id: d.id,
            title: d.data().title ?? d.id,
            a: courseStats.get(d.id)?.s ?? 0,
            b: courseStats.get(d.id)?.f ?? 0,
          }))
          .sort((x, y) => y.a - x.a),
      });
    } catch (e) {
      setError(e instanceof Error ? e.message : "読み込みに失敗しました");
    }
  }, []);

  useEffect(() => {
    reload();
  }, [reload]);

  return (
    <section>
      <header className="mb-4">
        <h1 className="text-2xl font-bold">数字</h1>
        <p className="mt-1 text-sm text-[var(--color-text-muted)]">
          アプリが書いた記録から集計しています。
        </p>
      </header>

      {error && (
        <p className="mb-4 px-3 py-2 rounded-lg bg-red-50 text-red-700 text-sm">
          {error}
        </p>
      )}

      {stats === null ? (
        <p className="text-[var(--color-text-muted)]">読み込み中…</p>
      ) : (
        <>
          <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
            <Stat label="登録者数" value={stats.users} />
            <Stat label="有料会員" value={stats.paying} />
            <Stat label="7日以内に利用" value={stats.activeWeek} />
            <Stat label="30日以内に利用" value={stats.activeMonth} />
            <Stat label="今月のTRY" value={stats.tryThisMonth} />
          </div>

          <p className="mt-3 text-xs text-[var(--color-text-muted)]">
            有料会員は、アプリが起動時に書き込む課金状態の写しを数えています。
            一度もアプリを開いていない人は反映されません。請求上の正確な数字は
            RevenueCat の管理画面で確認してください。
          </p>

          <h2 className="mt-8 mb-3 text-lg font-bold">動画別</h2>
          <Table
            head={["動画", "視聴した人", "最後まで見た人"]}
            rows={stats.videos}
            empty="動画がまだありません。"
          />

          <h2 className="mt-8 mb-3 text-lg font-bold">講座別</h2>
          <Table
            head={["講座", "始めた人", "終えた人"]}
            rows={stats.courses}
            empty="講座がまだありません。"
          />
        </>
      )}
    </section>
  );
}

function Stat({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-xl border border-[var(--color-border)] bg-[var(--color-card)] p-4">
      <div className="text-2xl font-bold text-[var(--color-brand)]">
        {value}
      </div>
      <div className="mt-1 text-xs text-[var(--color-text-muted)]">{label}</div>
    </div>
  );
}

function Table({
  head,
  rows,
  empty,
}: {
  head: string[];
  rows: Row[];
  empty: string;
}) {
  if (rows.length === 0) {
    return <p className="text-sm text-[var(--color-text-muted)]">{empty}</p>;
  }
  return (
    <div className="overflow-x-auto rounded-xl border border-[var(--color-border)]">
      <table className="w-full text-sm">
        <thead className="bg-[var(--color-card)]">
          <tr>
            {head.map((h, i) => (
              <th
                key={h}
                className={`px-4 py-2 font-semibold ${
                  i === 0 ? "text-left" : "text-right"
                }`}
              >
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <tr key={r.id} className="border-t border-[var(--color-border)]">
              <td className="px-4 py-2">{r.title}</td>
              <td className="px-4 py-2 text-right tabular-nums">{r.a}</td>
              <td className="px-4 py-2 text-right tabular-nums">{r.b}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
