"use client";

import { useEffect, useState, useCallback, useMemo } from "react";
import {
  collection,
  doc,
  getDocs,
  orderBy,
  query,
  updateDoc,
} from "firebase/firestore";
import { getDb } from "@/lib/firebase";
import { isoFromAny } from "@/lib/admin-helpers";

const MEMBERSHIPS = [
  { value: "free", label: "無料" },
  { value: "premium", label: "プレミアム" },
] as const;

type Membership = (typeof MEMBERSHIPS)[number]["value"];

type AppUser = {
  uid: string;
  email: string;
  displayName: string | null;
  photoUrl: string | null;
  membershipType: Membership;
  createdAt: string;
  updatedAt: string;
};

export default function UsersPage() {
  const [items, setItems] = useState<AppUser[] | null>(null);
  const [search, setSearch] = useState("");
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    setError(null);
    try {
      const snap = await getDocs(
        query(collection(getDb(), "users"), orderBy("createdAt", "desc")),
      );
      const list: AppUser[] = snap.docs.map((d) => {
        const data = d.data();
        return {
          uid: d.id,
          email: data.email ?? "",
          displayName: data.displayName ?? null,
          photoUrl: data.photoUrl ?? null,
          membershipType: (data.membershipType ?? "free") as Membership,
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

  const setMembership = async (user: AppUser, next: Membership) => {
    if (
      !confirm(
        `${user.email || user.uid} の membershipType を "${next}" に変更しますか？\n\n注意: RevenueCat 経由のサブスクリプションとは独立した手動上書きです。`,
      )
    )
      return;
    try {
      await updateDoc(doc(getDb(), "users", user.uid), {
        membershipType: next,
        updatedAt: new Date().toISOString(),
      });
      await reload();
    } catch (e) {
      setError(e instanceof Error ? e.message : "更新に失敗しました");
    }
  };

  const filtered = useMemo(() => {
    if (items === null) return null;
    const q = search.trim().toLowerCase();
    if (!q) return items;
    return items.filter(
      (u) =>
        u.email.toLowerCase().includes(q) ||
        (u.displayName ?? "").toLowerCase().includes(q) ||
        u.uid.toLowerCase().includes(q),
    );
  }, [items, search]);

  return (
    <div>
      <header className="flex items-end justify-between mb-4">
        <div>
          <h1 className="text-2xl font-bold">ユーザー管理</h1>
          <p className="mt-1 text-sm text-[var(--color-text-muted)]">
            プレミアム手動付与・ユーザー検索ができます。アカウントの BAN や削除は{" "}
            <code className="px-1 rounded bg-[var(--color-card)] text-xs">
              setAdminClaim.js
            </code>{" "}
            と同様に Firebase Auth Admin SDK 経由で行う必要があります。
          </p>
        </div>
        <span className="text-sm text-[var(--color-text-muted)]">
          {filtered === null ? "" : `${filtered.length} / ${items?.length ?? 0} 件`}
        </span>
      </header>

      <div className="mb-4">
        <input
          type="search"
          placeholder="email / 表示名 / uid で検索"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full md:w-80 px-3 py-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-card)] focus:outline-none focus:border-[var(--color-brand)]"
        />
      </div>

      {error && (
        <p className="mb-4 px-3 py-2 rounded-lg bg-red-50 text-red-700 text-sm">
          {error}
        </p>
      )}

      {filtered === null ? (
        <p className="text-[var(--color-text-muted)]">読み込み中…</p>
      ) : filtered.length === 0 ? (
        <p className="text-[var(--color-text-muted)]">該当ユーザーなし。</p>
      ) : (
        <div className="overflow-x-auto rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)]">
          <table className="w-full text-sm">
            <thead className="text-xs uppercase tracking-wider text-[var(--color-text-muted)]">
              <tr className="border-b border-[var(--color-border)]">
                <th className="text-left px-4 py-3">ユーザー</th>
                <th className="text-left px-4 py-3">UID</th>
                <th className="text-left px-4 py-3">プラン</th>
                <th className="text-left px-4 py-3">登録日</th>
                <th className="text-right px-4 py-3">操作</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((u) => (
                <tr
                  key={u.uid}
                  className="border-b border-[var(--color-border)] last:border-0"
                >
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-[var(--color-bg)] flex items-center justify-center overflow-hidden">
                        {u.photoUrl ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img
                            src={u.photoUrl}
                            alt=""
                            className="w-full h-full object-cover"
                          />
                        ) : (
                          <span className="text-xs">
                            {u.displayName?.[0] ?? u.email[0] ?? "?"}
                          </span>
                        )}
                      </div>
                      <div className="min-w-0">
                        <div className="font-bold truncate">
                          {u.displayName || "(表示名なし)"}
                        </div>
                        <div className="text-xs text-[var(--color-text-muted)] truncate">
                          {u.email}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3 font-mono text-xs text-[var(--color-text-muted)]">
                    {u.uid}
                  </td>
                  <td className="px-4 py-3">
                    <span
                      className={`px-1.5 py-0.5 rounded text-xs ${
                        u.membershipType === "premium"
                          ? "bg-orange-100 text-orange-700"
                          : "bg-gray-100 text-gray-600"
                      }`}
                    >
                      {u.membershipType === "premium" ? "プレミアム" : "無料"}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-xs text-[var(--color-text-muted)]">
                    {new Date(u.createdAt).toLocaleDateString("ja-JP")}
                  </td>
                  <td className="px-4 py-3 text-right">
                    <button
                      onClick={() =>
                        setMembership(
                          u,
                          u.membershipType === "premium" ? "free" : "premium",
                        )
                      }
                      className="px-3 py-1 rounded-lg text-xs border border-[var(--color-border)] hover:bg-[var(--color-bg)]"
                    >
                      {u.membershipType === "premium"
                        ? "無料に戻す"
                        : "プレミアム付与"}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
