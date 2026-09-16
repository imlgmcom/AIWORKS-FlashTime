import { getCurrentWindow } from '@tauri-apps/api/window';

/**
 * 自定义窗口控制：无边框模式下的拖动、最小化、关闭（隐藏到托盘）。
 * 经验教训：不要自维护"是否最小化/是否可见"的 ref，永远以真实窗口 API 为准。
 */
export function useWindowControl() {
  const win = (() => {
    try { return getCurrentWindow(); } catch { return null; }
  })();

  async function startDrag(e: MouseEvent) {
    if (!win) return;
    // 仅左键拖动
    if (e.button !== 0) return;
    try { await win.startDragging(); } catch {}
  }

  async function minimize() {
    if (!win) return;
    try { await win.minimize(); } catch {}
  }

  /** 关闭按钮：隐藏到托盘（Tauri 主进程 on_window_event 还会再兜底一次） */
  async function close() {
    if (!win) return;
    try {
      // 隐藏而不是真关闭（保持进程在，保持遮罩/快捷键继续工作）
      await win.hide();
    } catch {}
  }

  return { startDrag, minimize, close, hasWindow: !!win };
}
