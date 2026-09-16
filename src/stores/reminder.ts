import { defineStore } from 'pinia';
import { ref, onMounted } from 'vue';
import { getJson, setJson } from '../utils/storage';
import { uid, nextTriggerAt, RepeatMode } from '../utils/time';

export interface ReminderItem {
  id: string;
  title: string;
  /** 下一次触发时间戳（ms） */
  nextAt: number;
  /** 原始基准时刻（用于计算 repeat） */
  baseAt: number;
  repeat: RepeatMode;
  weekDays?: number[];  // 当 repeat = 'weekly' 时有效，0=Sun..6=Sat
  enabled: boolean;
  firedCount: number;
}

/**
 * 提醒计划：每个提醒有下次触发时间，每秒 tick 检查是否到期。
 * 到期后：
 *  - 发 Windows 通知 + 声音（外层监听 reminder-fire）
 *  - 按 RepeatMode 计算下一次 nextAt
 */
export const useReminderStore = defineStore('reminder', () => {
  const items = ref<ReminderItem[]>([]);
  let ticker: number | null = null;

  async function load() {
    items.value = await getJson<ReminderItem[]>('reminder_items', []);
    // 修正 nextAt（可能都过期了，重算一下 daily/weekly 的）
    for (const it of items.value) {
      if (it.enabled && it.nextAt <= Date.now() && it.repeat !== 'none') {
        it.nextAt = nextTriggerAt(it.baseAt, it.repeat, it.weekDays);
      }
    }
    save();
    startTick();
  }

  async function save() {
    await setJson('reminder_items', items.value);
  }

  function startTick() {
    if (ticker) return;
    ticker = window.setInterval(tick, 1000);
  }

  function tick() {
    const now = Date.now();
    let changed = false;
    for (const it of items.value) {
      if (!it.enabled) continue;
      if (it.nextAt > 0 && it.nextAt <= now) {
        // 触发
        const ev = new CustomEvent('reminder-fire', {
          detail: { id: it.id, title: it.title },
        });
        window.dispatchEvent(ev);

        it.firedCount += 1;
        changed = true;

        if (it.repeat === 'none') {
          it.enabled = false;
        } else {
          it.nextAt = nextTriggerAt(it.baseAt, it.repeat, it.weekDays);
        }
      }
    }
    if (changed) save();
  }

  function add(data: Omit<ReminderItem, 'id' | 'firedCount' | 'nextAt' | 'enabled'> & { enabled?: boolean }) {
    const nextAt = nextTriggerAt(data.baseAt, data.repeat, data.weekDays);
    items.value.push({
      id: uid(),
      title: data.title,
      baseAt: data.baseAt,
      repeat: data.repeat,
      weekDays: data.weekDays,
      nextAt,
      firedCount: 0,
      enabled: data.enabled ?? true,
    });
    save();
    startTick();
  }

  function toggle(id: string) {
    const it = items.value.find(x => x.id === id);
    if (!it) return;
    it.enabled = !it.enabled;
    if (it.enabled && it.nextAt <= Date.now()) {
      it.nextAt = nextTriggerAt(it.baseAt, it.repeat, it.weekDays);
    }
    save();
  }

  function remove(id: string) {
    const i = items.value.findIndex(x => x.id === id);
    if (i >= 0) {
      items.value.splice(i, 1);
      save();
    }
  }

  /** Rust scheduler 触发后，前端更新 store 状态 */
  function handleFired(id: string) {
    const it = items.value.find(x => x.id === id);
    if (!it) return;
    it.firedCount += 1;
    if (it.repeat === 'none') {
      it.enabled = false;
    } else {
      it.nextAt = nextTriggerAt(it.baseAt, it.repeat, it.weekDays);
    }
    save();
  }

  onMounted(load);

  return { items, load, add, toggle, remove, handleFired };
});
