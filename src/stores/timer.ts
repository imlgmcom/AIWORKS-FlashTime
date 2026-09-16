import { defineStore } from 'pinia';
import { ref } from 'vue';
import { formatHMSMs } from '../utils/time';

/**
 * 正计时（Stopwatch）：支持开始/暂停/重置、计次 Lap。
 * 数据不做本地持久化（只是运行中状态）。
 */
export const useTimerStore = defineStore('timer', () => {
  const elapsedMs = ref(0);        // 已累计毫秒数（暂停时保留）
  const running = ref(false);
  const startEpochMs = ref(0);    // 本轮开始的 Date.now() 基准
  const laps = ref<{ index: number; lap: string; total: string; diffMs: number }[]>([]);

  let raf = 0;

  function tick() {
    if (!running.value) return;
    elapsedMs.value = Date.now() - startEpochMs.value;
    raf = requestAnimationFrame(tick);
  }

  function start() {
    if (running.value) return;
    running.value = true;
    startEpochMs.value = Date.now() - elapsedMs.value;
    tick();
  }

  function pause() {
    if (!running.value) return;
    running.value = false;
    cancelAnimationFrame(raf);
  }

  function reset() {
    pause();
    elapsedMs.value = 0;
    laps.value = [];
  }

  function lap() {
    // 只有运行中才计次
    const ms = elapsedMs.value;
    const prevMs = laps.value.length ? laps.value[0].diffMs : 0;
    const diff = laps.value.length ? ms - laps.value[0].diffMs : ms;
    laps.value.unshift({
      index: laps.value.length + 1,
      lap: formatHMSMs(diff),
      total: formatHMSMs(ms),
      diffMs: ms,
    });
    // 保留最近 50 次
    if (laps.value.length > 50) laps.value.length = 50;
    void prevMs;
  }

  return { elapsedMs, running, laps, start, pause, reset, lap };
});
