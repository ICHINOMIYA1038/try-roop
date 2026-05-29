"use client";

import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  ReactNode,
} from "react";
import {
  GoogleAuthProvider,
  onAuthStateChanged,
  signInWithPopup,
  signOut as firebaseSignOut,
  User,
} from "firebase/auth";
import { getFirebaseAuth } from "./firebase";

type Status = "loading" | "signed-out" | "no-claim" | "admin";

type AuthContextValue = {
  status: Status;
  user: User | null;
  signInWithGoogle: () => Promise<void>;
  signOut: () => Promise<void>;
  refreshClaims: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [status, setStatus] = useState<Status>("loading");
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    const auth = getFirebaseAuth();
    return onAuthStateChanged(auth, async (next) => {
      if (!next) {
        setUser(null);
        setStatus("signed-out");
        return;
      }
      const token = await next.getIdTokenResult();
      setUser(next);
      setStatus(token.claims.admin === true ? "admin" : "no-claim");
    });
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      status,
      user,
      signInWithGoogle: async () => {
        const auth = getFirebaseAuth();
        const provider = new GoogleAuthProvider();
        await signInWithPopup(auth, provider);
      },
      signOut: async () => {
        const auth = getFirebaseAuth();
        await firebaseSignOut(auth);
      },
      refreshClaims: async () => {
        const current = getFirebaseAuth().currentUser;
        if (!current) return;
        const token = await current.getIdTokenResult(true);
        setStatus(token.claims.admin === true ? "admin" : "no-claim");
      },
    }),
    [status, user],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
