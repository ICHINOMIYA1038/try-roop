"use client";

import { initializeApp, getApps, FirebaseApp } from "firebase/app";
import { getAuth, Auth } from "firebase/auth";
import { getFirestore, Firestore } from "firebase/firestore";
import { getStorage, FirebaseStorage } from "firebase/storage";

// Web SDK config (matches lib/firebase_options.dart の web 設定).
// API key は公開してよい識別子で、機密情報ではない (実際の保護は Firestore rules で行う)。
const firebaseConfig = {
  apiKey: "AIzaSyC5gazrh4zGA-929so2PhGTxFB6fi8Ah9k",
  authDomain: "try-roop.firebaseapp.com",
  projectId: "try-roop",
  storageBucket: "try-roop.firebasestorage.app",
  messagingSenderId: "831378661778",
  appId: "1:831378661778:web:bdbbaae510e15b474fa14b",
};

let app: FirebaseApp;
let _auth: Auth | null = null;
let _db: Firestore | null = null;
let _storage: FirebaseStorage | null = null;

function getApp(): FirebaseApp {
  if (getApps().length) return getApps()[0]!;
  app = initializeApp(firebaseConfig);
  return app;
}

export function getFirebaseAuth(): Auth {
  if (_auth) return _auth;
  _auth = getAuth(getApp());
  return _auth;
}

export function getDb(): Firestore {
  if (_db) return _db;
  _db = getFirestore(getApp());
  return _db;
}

export function getFirebaseStorage(): FirebaseStorage {
  if (_storage) return _storage;
  _storage = getStorage(getApp());
  return _storage;
}
