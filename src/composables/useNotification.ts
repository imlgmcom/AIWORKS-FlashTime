import { ref } from 'vue';
import { isPermissionGranted, requestPermission, sendNotification } from '@tauri-apps/plugin-notification';

/**
 * 统一的通知 + 提示音封装。
 *  - Tauri 环境：走 Windows 原生 Toast 通知（tauri-plugin-notification）
 *  - 浏览器环境：走 Web Notification API
 *  - 到点都会额外播放一个简短提示音（Web Audio API 生成，无外部文件依赖）
 */

const permissionRequestedRef = ref(false);

export function useNotification() {
  async function ensurePermission(): Promise<boolean> {
    try {
      if (await isPermissionGranted()) return true;
      if (permissionRequestedRef.value) return false;
      permissionRequestedRef.value = true;
      const r = await requestPermission();
      return r === 'granted';
    } catch {
      // 非 Tauri 环境：fallback Web Notification
      if (typeof Notification !== 'undefined') {
        if (Notification.permission === 'granted') return true;
        if (Notification.permission === 'denied') return false;
        const r = await Notification.requestPermission();
        return r === 'granted';
      }
      return false;
    }
  }

  // 复用同一个 AudioContext，避免每次播放都创建新实例
  let _audioCtx: AudioContext | null = null;
  function getAudioContext(): AudioContext | null {
    try {
      if (_audioCtx) return _audioCtx;
      const AC = (window.AudioContext || (window as any).webkitAudioContext);
      if (!AC) return null;
      _audioCtx = new AC();
      return _audioCtx;
    } catch { return null; }
  }

  function playBeep(freq = 880, durationMs = 220, type: OscillatorType = 'sine') {
    try {
      const ctx = getAudioContext();
      if (!ctx) return;
      // 窗口隐藏/未交互时 AudioContext 可能处于 suspended，先恢复
      if (ctx.state === 'suspended') {
        ctx.resume().catch(() => {});
      }
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = type;
      osc.frequency.value = freq;
      gain.gain.value = 0.22;
      osc.connect(gain).connect(ctx.destination);
      osc.start();
      gain.gain.setValueAtTime(0.22, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + durationMs / 1000);
      osc.stop(ctx.currentTime + durationMs / 1000 + 0.02);
    } catch {}
  }

  /** 到点提醒：三声递进蜂鸣，比单声更醒目 */
  function playAlarm() {
    playBeep(880, 200, 'sine');
    setTimeout(() => playBeep(1175, 200, 'sine'), 230);
    setTimeout(() => playBeep(1568, 320, 'triangle'), 460);
  }

  async function flash(title: string, body = '', options?: { beep?: boolean; body2?: string; alarm?: boolean }) {
    const beep = options?.beep ?? true;
    if (beep) {
      if (options?.alarm) {
        playAlarm();
      } else {
        playBeep(880, 180, 'sine');
        setTimeout(() => playBeep(1200, 220, 'triangle'), 170);
      }
    }
    try {
      // Tauri 原生通知
      const granted = await ensurePermission();
      if (granted) {
        try {
          sendNotification({ title, body: body || (options?.body2 ?? '') });
          return;
        } catch {}
      }
      // 兜底 Web Notification
      if (typeof Notification !== 'undefined') {
        new Notification(title, { body });
      }
    } catch {}
  }

  return { ensurePermission, flash, playBeep, playAlarm };
}
