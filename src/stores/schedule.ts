import { defineStore } from 'pinia';
import { ref, onMounted } from 'vue';
import { getJson, setJson } from '../utils/storage';
import { uid } from '../utils/time';

export interface ScheduleItem {
  id: string;
  title: string;
  /** 触发时刻（时间戳 ms） */
  at: number;
  fired: boolean;
  createdAt: number;
}

/**
 * 定时任务：到点触发一次，之后标记 fired，保留历史。
 */
export const useScheduleStore = defineStore('schedule', () => {
  const items = ref<ScheduleItem[]>([]);
  let ticker: number | null = null;

  async function load() {
    items.value = await getJson<ScheduleItem[]>('schedule_items', []);
    startTick();
  }

  async function save() {
    await setJson('schedule_items', items.value);
  }

  function startTick() {
    if (ticker) return;
    ticker = window.setInterval(tick, 1000);
  }

  function tick() {
    const now = Date.now();
    let changed = false;
    for (const it of items.value) {
      if (!it.fired && it.at <= now) {
        it.fired = true;
        changed = true;
        const ev = new CustomEvent('schedule-fire', {
          detail: { id: it.id, title: it.title },
        });
        window.dispatchEvent(ev);
      }
    }
    if (changed) save();
  }

  function add(title: string, at: number) {
    const t = title.trim();
    if (!t || at <= Date.now()) return;
    items.value.push({
      id: uid(),
      title: t,
      at,
      fired: false,
      createdAt: Date.now(),
    });
    save();
    startTick();
  }

  function remove(id: string) {
    const i = items.value.findIndex(x => x.id === id);
    if (i >= 0) {
      items.value.splice(i, 1);
      save();
    }
  }

  function clearFired() {
    items.value = items.value.filter(x => !x.fired);
    save();
  }

  /** Rust scheduler 触发后，前端更新 store 状态 */
  function handleFired(id: string) {
    const it = items.value.find(x => x.id === id);
    if (!it) return;
    it.fired = true;
    save();
  }

  onMounted(load);

  return { items, load, add, remove, clearFired, handleFired };
});
