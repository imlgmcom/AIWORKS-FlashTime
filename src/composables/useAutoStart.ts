import { ref, onMounted } from 'vue';

/**
 * 开机自启开关（Tauri 插件包装）。
 * 非 Tauri 环境下默认 false 且操作无副作用。
 */
export function useAutoStart() {
  const enabled = ref(false);
  const loading = ref(false);
  const available = ref(true);

  async function loadPlugin() {
    try {
      if (typeof window !== 'undefined' && !(window as any).__TAURI_INTERNALS__) {
        return null;
      }
      return await import('@tauri-apps/plugin-autostart');
    } catch {
      return null;
    }
  }

  async function check() {
    const mod = await loadPlugin();
    if (!mod) { available.value = false; enabled.value = false; return; }
    try {
      enabled.value = await mod.isEnabled();
    } catch { enabled.value = false; }
  }

  async function setOn(v: boolean) {
    loading.value = true;
    try {
      const mod = await loadPlugin();
      if (!mod) { available.value = false; return; }
      if (v) await mod.enable(); else await mod.disable();
      enabled.value = await mod.isEnabled().catch(() => v);
    } finally {
      loading.value = false;
    }
  }

  async function toggle() {
    await setOn(!enabled.value);
  }

  onMounted(check);

  return { enabled, loading, available, check, setOn, toggle };
}
