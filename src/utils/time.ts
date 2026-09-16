/**
 * 时间格式化与通用工具
 */

/** 把毫秒数格式化为 "HH:MM:SS" */
export function formatHMS(totalMs: number): string {
  if (totalMs < 0) totalMs = 0;
  const s = Math.floor(totalMs / 1000);
  const hh = Math.floor(s / 3600);
  const mm = Math.floor((s % 3600) / 60);
  const ss = s % 60;
  return `${pad(hh)}:${pad(mm)}:${pad(ss)}`;
}

/** 把毫秒数格式化为 "HH:MM:SS.mmm" */
export function formatHMSMs(totalMs: number): string {
  if (totalMs < 0) totalMs = 0;
  const base = formatHMS(totalMs);
  const ms = Math.floor(totalMs % 1000);
  return `${base}.${pad3(ms)}`;
}

/** 把 Date 转为 "YYYY-MM-DD" */
export function formatDate(d: Date): string {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

/** 把 Date 转为 "HH:MM"（24h） */
export function formatHM(d: Date): string {
  return `${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

/** 把 Date 转为 "YYYY-MM-DD HH:MM" */
export function formatDateTime(d: Date): string {
  return `${formatDate(d)} ${formatHM(d)}`;
}

export function pad(n: number, w = 2): string {
  return n.toString().padStart(w, '0');
}
export function pad3(n: number): string {
  return n.toString().padStart(3, '0');
}

/** 给今天的日期设定一个 HH:MM，返回时间戳 */
export function todayAt(hh: number, mm: number, ss = 0): number {
  const d = new Date();
  d.setHours(hh, mm, ss, 0);
  return d.getTime();
}

/** 计算下次重复触发时间戳（基于 RepeatMode） */
export type RepeatMode = 'none' | 'daily' | 'weekly' | 'weekdays' | 'hourly';

export function nextTriggerAt(base: number, mode: RepeatMode, weekDays?: number[]): number {
  // base: 基准时刻的时间戳（ms），可能已过期
  const now = Date.now();
  let t = base;
  if (t <= now) {
    const bd = new Date(base);
    const hh = bd.getHours();
    const mm = bd.getMinutes();
    const ss = bd.getSeconds();
    // 先从明天开始找
    switch (mode) {
      case 'none':
        return base; // 已过期，单次不再触发
      case 'daily': {
        const d = new Date(now);
        d.setDate(d.getDate() + 1);
        d.setHours(hh, mm, ss, 0);
        return d.getTime();
      }
      case 'weekdays': {
        for (let i = 1; i <= 7; i++) {
          const d = new Date(now);
          d.setDate(d.getDate() + i);
          const w = d.getDay();
          if (w >= 1 && w <= 5) {
            d.setHours(hh, mm, ss, 0);
            return d.getTime();
          }
        }
        return t;
      }
      case 'weekly': {
        const days = (weekDays && weekDays.length) ? weekDays : [bd.getDay()];
        for (let i = 1; i <= 14; i++) {
          const d = new Date(now);
          d.setDate(d.getDate() + i);
          if (days.includes(d.getDay())) {
            d.setHours(hh, mm, ss, 0);
            return d.getTime();
          }
        }
        return t;
      }
      case 'hourly': {
        // 每小时的 mm:ss 触发，先尝试当前小时
        const d = new Date(now);
        d.setMinutes(mm, ss, 0);
        if (d.getTime() > now) return d.getTime();
        // 下一个小时
        d.setHours(d.getHours() + 1, mm, ss, 0);
        return d.getTime();
      }
    }
  }
  return t;
}

/** 唯一 ID（本地够用即可） */
export function uid(): string {
  return Math.random().toString(36).slice(2, 10) + Date.now().toString(36).slice(-4);
}
