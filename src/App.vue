<script setup lang="ts">
/**
 * 根组件：
 *  - 自定义标题栏（拖动/最小化/隐藏到托盘/开机自启开关）
 *  - Tab 导航
 *  - 五个功能视图
 *  - 全局监听到点事件（countdown-finish / schedule-fire / reminder-fire）
 *    无论当前在哪个 tab 都能收到通知 + 提示音 + 系统弹窗，且窗口隐藏时自动唤出
 */
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import TitleBar from './components/TitleBar.vue';
import TabNav, { type TabKey } from './components/TabNav.vue';
import Timer from './views/Timer.vue';
import Countdown from './views/Countdown.vue';
import Schedule from './views/Schedule.vue';
import Reminder from './views/Reminder.vue';
import Todo from './views/Todo.vue';
import { useNotification } from './composables/useNotification';
import { useReminderStore } from './stores/reminder';
import { useScheduleStore } from './stores/schedule';

const tab = ref<TabKey>('countdown');  // 默认打开倒计时（最常用）

// —— 通知权限：首次加载请求一下 ——
const { ensurePermission, flash } = useNotification();
ensurePermission().catch(() => {});

// —— 启动时预加载提醒/定时任务数据（不等 tab 切换） ——
const reminderStore = useReminderStore();
const scheduleStore = useScheduleStore();
let unlistenScheduler: (() => void) | null = null;

/** 到点时唤出窗口（如果隐藏在托盘） */
async function bringWindowToFront() {
  try {
    if (typeof window !== 'undefined' && (window as any).__TAURI_INTERNALS__) {
      const { getCurrentWindow } = await import('@tauri-apps/api/window');
      const win = getCurrentWindow();
      if (!(await win.isVisible())) {
        await win.show();
      }
      await win.unminimize();
      await win.setAlwaysOnTop(true);
      await win.setFocus();
      // 短暂置顶后恢复，确保弹出窗口能被看到但不强制长期置顶
      setTimeout(() => win.setAlwaysOnTop(false), 2000);
    }
  } catch {}
}

/** 调用 Rust 端弹出 Windows 原生系统弹窗（屏幕正中心、置顶、带系统提示音） */
async function showSystemAlarm(title: string, body: string) {
  try {
    if (typeof window !== 'undefined' && (window as any).__TAURI_INTERNALS__) {
      const { invoke } = await import('@tauri-apps/api/core');
      await invoke('show_alarm', { title, body });
    }
  } catch {}
}

/** 倒计时结束 */
function onCountdownFinish(e: Event) {
  const d = (e as CustomEvent).detail as { totalMs?: number };
  const label = d.totalMs ? formatMsLabel(d.totalMs) : '';
  const body = label ? `已完成 ${label} 倒计时` : '倒计时已结束';
  flash('倒计时结束', body, { beep: true, alarm: true });
  showSystemAlarm('倒计时结束', body);
  bringWindowToFront();
}

/** 定时任务到点 */
function onScheduleFire(e: Event) {
  const d = (e as CustomEvent).detail as { title: string };
  flash('定时到点', d.title || '定时任务已到点', { beep: true, alarm: true });
  showSystemAlarm('定时提醒', d.title || '定时任务已到点');
  bringWindowToFront();
}

/** 提醒计划触发 */
function onReminderFire(e: Event) {
  const d = (e as CustomEvent).detail as { title: string };
  flash('闪时提醒', d.title || '提醒时间到', { beep: true, alarm: true });
  showSystemAlarm('闪时提醒', d.title || '提醒时间到了');
  bringWindowToFront();
}

function formatMsLabel(ms: number): string {
  const total = Math.floor(ms / 1000);
  const h = Math.floor(total / 3600);
  const m = Math.floor((total % 3600) / 60);
  const s = total % 60;
  if (h) return `${h}时${m ? m + '分' : ''}`;
  if (m) return `${m}分${s ? s + '秒' : ''}`;
  return `${s}秒`;
}

onMounted(async () => {
  window.addEventListener('countdown-finish', onCountdownFinish);
  window.addEventListener('schedule-fire', onScheduleFire);
  window.addEventListener('reminder-fire', onReminderFire);

  // 预加载提醒/定时任务数据
  await Promise.all([reminderStore.load(), scheduleStore.load()]);

  // 监听 Rust 后端调度器事件（窗口隐藏时也能收到）
  try {
    if (typeof window !== 'undefined' && (window as any).__TAURI_INTERNALS__) {
      const { listen } = await import('@tauri-apps/api/event');
      unlistenScheduler = await listen('scheduler-fired', (event) => {
        const { type, id, title } = event.payload as { type: string; id: string; title: string };
        if (type === 'reminder') {
          reminderStore.handleFired(id);
          flash('闪时提醒', title || '提醒时间到', { beep: true, alarm: true });
          bringWindowToFront();
        } else if (type === 'schedule') {
          scheduleStore.handleFired(id);
          flash('定时到点', title || '定时任务已到点', { beep: true, alarm: true });
          bringWindowToFront();
        }
      });
    }
  } catch {}
});

onBeforeUnmount(() => {
  window.removeEventListener('countdown-finish', onCountdownFinish);
  window.removeEventListener('schedule-fire', onScheduleFire);
  window.removeEventListener('reminder-fire', onReminderFire);
  unlistenScheduler?.();
});

const view = computed(() => {
  switch (tab.value) {
    case 'timer':     return Timer;
    case 'countdown': return Countdown;
    case 'schedule':  return Schedule;
    case 'reminder':  return Reminder;
    case 'todo':      return Todo;
  }
});
</script>

<template>
  <div class="app-root" :key="tab">
    <div class="shell">
      <TitleBar />
      <TabNav v-model="tab" />
      <main class="content" :class="`view-${tab}`">
        <transition name="fade">
          <component :is="view" />
        </transition>
      </main>
      <footer class="foot">
        <span class="tip">点击托盘图标唤出</span>
      </footer>
    </div>
  </div>
</template>

<style scoped>
.app-root {
  position: absolute; inset: 0;
  display: flex; justify-content: center; align-items: stretch;
  padding: 0;
}
.shell {
  display: flex; flex-direction: column;
  flex: 1;
  max-width: 100%;
  width: 100%;
  border-radius: 0;
  background: var(--ft-shell-bg);
  backdrop-filter: blur(18px) saturate(140%);
  -webkit-backdrop-filter: blur(18px) saturate(140%);
  border: none;
  overflow: hidden;
}
.content { flex: 1; min-height: 0; overflow-y: auto; }
.content::-webkit-scrollbar { width: 6px; }
.content::-webkit-scrollbar-thumb { background: var(--ft-scrollbar); border-radius: 6px; }
.foot {
  padding: 6px 14px 10px;
  text-align: center;
  font-size: 10.5px;
  color: var(--ft-text-3);
  letter-spacing: .3px;
}

.fade-enter-active, .fade-leave-active {
  transition: opacity .22s ease, transform .22s ease;
}
.fade-enter-from { opacity: 0; transform: translateY(6px); }
.fade-leave-to   { opacity: 0; transform: translateY(-6px); }
</style>
