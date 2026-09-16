import { defineStore } from 'pinia';
import { ref, computed, onMounted } from 'vue';
import { getJson, setJson } from '../utils/storage';

/**
 * 倒计时：
 *  - 保存用户常用 preset（如 1/5/10/25 分钟）
 *  - 运行中每秒自减，到 0 触发：
 *      1) emit 事件，外层播放提示音
 *      2) 推送 Windows 通知
 *      3) 本地记一次结束
 *  - 配置：presetMs 数组
 */

export const useCountdownStore = defineStore('countdown', () => {
  const presetMs = ref<number[]>([60_000, 300_000, 600_000, 1_500_000, 3_600_000]);
  const totalMs = ref(600_000);      // 设定值
  const remainMs = ref(600_000);     // 剩余（运行中）
  const running = ref(false);
  const paused = ref(false);
  const endEpoch = ref(0);           // 预期结束 Date.now()（用于后台/切页后仍准确）

  const progress = computed(() => {
    if (totalMs.value <= 0) return 0;
    return Math.max(0, Math.min(1, remainMs.value / totalMs.value));
  });

  let timerId: number | null = null;

  function tick() {
    if (!running.value || paused.value) return;
    const now = Date.now();
    remainMs.value = Math.max(0, endEpoch.value - now);
    if (remainMs.value <= 0) {
      stop();
      // 触发结束：由外层 listen('countdown-finish') 处理通知/声音
      const ev = new CustomEvent('countdown-finish', { detail: { totalMs: totalMs.value } });
      window.dispatchEvent(ev);
    }
  }

  function start() {
    if (remainMs.value <= 0) remainMs.value = totalMs.value;
    if (running.value && !paused.value) return;
    endEpoch.value = Date.now() + remainMs.value;
    running.value = true;
    paused.value = false;
    if (timerId) window.clearInterval(timerId);
    timerId = window.setInterval(tick, 200);
    tick();
  }

  function pauseAction() {
    if (!running.value) return;
    paused.value = !paused.value;
  }

  function stop() {
    running.value = false;
    paused.value = false;
    if (timerId) {
      window.clearInterval(timerId);
      timerId = null;
    }
  }

  function reset() {
    stop();
    remainMs.value = totalMs.value;
  }

  function setTotal(ms: number) {
    totalMs.value = Math.max(0, ms);
    if (!running.value) remainMs.value = totalMs.value;
  }

  async function loadPersisted() {
    const saved = await getJson<number[]>('countdown_presets', presetMs.value);
    presetMs.value = saved;
    const last = await getJson<number>('countdown_last_total', totalMs.value);
    setTotal(last);
  }

  async function savePreset() {
    await setJson('countdown_presets', presetMs.value);
    await setJson('countdown_last_total', totalMs.value);
  }

  function addPreset(ms: number) {
    if (ms <= 0) return;
    if (!presetMs.value.includes(ms)) {
      presetMs.value.push(ms);
      presetMs.value.sort((a, b) => a - b);
      savePreset();
    }
  }

  function removePreset(ms: number) {
    const i = presetMs.value.indexOf(ms);
    if (i >= 0) {
      presetMs.value.splice(i, 1);
      savePreset();
    }
  }

  // 初始化时加载持久化数据
  onMounted(loadPersisted);

  return {
    presetMs, totalMs, remainMs, running, paused, progress,
    start, pauseAction, stop, reset, setTotal,
    loadPersisted, savePreset, addPreset, removePreset,
  };
});
