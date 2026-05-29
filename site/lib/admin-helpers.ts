"use client";

import { useEffect, useState } from "react";
import {
  collection,
  getDocs,
  orderBy,
  query,
  Timestamp,
} from "firebase/firestore";
import { getDb } from "./firebase";

export type CategoryOption = { id: string; name: string };

/** カテゴリ選択用の軽量取得 (admin の各 form 共通)。 */
export function useCategories(): { options: CategoryOption[]; error: string | null } {
  const [options, setOptions] = useState<CategoryOption[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        const snap = await getDocs(
          query(collection(getDb(), "categories"), orderBy("order", "asc")),
        );
        if (!alive) return;
        setOptions(
          snap.docs.map((d) => ({
            id: d.id,
            name: d.data().name ?? d.id,
          })),
        );
      } catch (e) {
        if (alive) setError(e instanceof Error ? e.message : "categories の読み込みに失敗");
      }
    })();
    return () => {
      alive = false;
    };
  }, []);

  return { options, error };
}

/** Firestore のフィールド (Timestamp / string) を ISO 8601 文字列に正規化。 */
export function isoFromAny(v: unknown): string {
  if (v instanceof Timestamp) return v.toDate().toISOString();
  if (typeof v === "string") return v;
  return new Date().toISOString();
}

/** 衝突しにくい id を生成。 */
export function genId(prefix: string): string {
  return `${prefix}_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`;
}
