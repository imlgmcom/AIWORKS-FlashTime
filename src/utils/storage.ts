/**
 * 本地持久化封装（绿色软件模式）：
 *  数据存 exe 同目录的 data/flashtime.store.json，而非 %APPDATA%。
 *  通过 Rust command data_store_path() 获取绝对路径。
 *  浏览器 dev 预览时 fallback 到 localStorage。
 */

import { Store } from '@tauri-apps/plugin-store';

type StoreValue = string | number | boolean | null | undefined | object;

let _tauriStore: Store | null = null;
let _tauriReady = false;
let _tauriInitPromise: Promise<Store | null> | null = null;

async function ensureTauri(): Promise<Store | null> {
  if (_tauriReady) return _tauriStore;
  if (_tauriInitPromise) return _tauriInitPromise;
  const hasTauri = typeof window !== 'undefined' && !!(window as any).__TAURI_INTERNALS__;
  if (!hasTauri) {
    _tauriReady = true;
    return null;
  }
  _tauriInitPromise = (async () => {
    try {
      const { invoke } = await import('@tauri-apps/api/core');
      // 绿色软件：拿到 exe 同目录的绝对路径
      const path = await invoke<string>('data_store_path');
      // tauri-plugin-store 2.x：Store.load 替代 new Store + load
      const s = await Store.load(path);
      _tauriStore = s;
      _tauriReady = true;
      _tauriInitPromise = null;
      return s;
    } catch {
      _tauriReady = true;
      _tauriInitPromise = null;
      return null;
    }
  })();
  return _tauriInitPromise;
}

export async function setJson<T extends StoreValue>(key: string, value: T): Promise<void> {
  const s = await ensureTauri();
  if (s) {
    await s.set(key, value as any);
    await s.save().catch(() => {});
  } else {
    try {
      localStorage.setItem(key, JSON.stringify(value));
    } catch {}
  }
}

export async function getJson<T extends StoreValue>(key: string, fallback: T): Promise<T> {
  const s = await ensureTauri();
  if (s) {
    try {
      const v = await s.get<any>(key);
      return (v === undefined || v === null) ? fallback : (v as T);
    } catch {
      return fallback;
    }
  }
  try {
    const raw = localStorage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : fallback;
  } catch {
    return fallback;
  }
}

export async function removeKey(key: string): Promise<void> {
  const s = await ensureTauri();
  if (s) {
    await s.delete(key);
    await s.save().catch(() => {});
  } else {
    try { localStorage.removeItem(key); } catch {}
  }
}
