<script setup lang="ts">
/**
 * 提醒计划：设定时刻 + 重复周期（每天/工作日/每周指定日/单次）。
 */
import { ref, computed } from 'vue';
import FButton from '../components/FButton.vue';
import { useReminderStore, type ReminderItem } from '../stores/reminder';
import type { RepeatMode } from '../utils/time';
import { formatHM, todayAt } from '../utils/time';

const store = useReminderStore();

const title = ref('');
const time = ref('09:00');
const repeat = ref<RepeatMode>('daily');
const weekDays = ref<number[]>([1, 2, 3, 4, 5]); // 周选择器
// 每小时模式的偏移：分:秒
const hourMin = ref(0);
const hourSec = ref(0);

const WK = [
  { d: 0, label: '日' }, { d: 1, label: '一' }, { d: 2, label: '二' },
  { d: 3, label: '三' }, { d: 4, label: '四' }, { d: 5, label: '五' }, { d: 6, label: '六' },
];

function toggleWeek(d: number) {
  const i = weekDays.value.indexOf(d);
  if (i >= 0) weekDays.value.splice(i, 1);
  else weekDays.value.push(d);
  weekDays.value.sort();
}

function add() {
  const t = title.value.trim() || '提醒';
  const rep: RepeatMode = repeat.value;
  let baseAt: number;
  if (rep === 'hourly') {
    // 每小时模式：用今天的日期 + 偏移分秒
    baseAt = todayAt(0, hourMin.value, hourSec.value);
  } else {
    const [hh, mm] = time.value.split(':').map(Number);
    baseAt = todayAt(hh, mm);
  }
  store.add({
    title: t,
    baseAt,
    repeat: rep,
    weekDays: rep === 'weekly' ? [...weekDays.value] : undefined,
  });
  title.value = '';
}

function repeatText(it: ReminderItem): string {
  switch (it.repeat) {
    case 'none': return '单次';
    case 'daily': return '每天';
    case 'weekdays': return '工作日';
    case 'hourly': {
      const d = new Date(it.baseAt);
      const m = d.getMinutes();
      const s = d.getSeconds();
      if (m === 0 && s === 0) return '每整点';
      if (s === 0) return `每小时 ${m}分`;
      return `每小时 ${m}分${s}秒`;
    }
    case 'weekly': {
      const wds = it.weekDays ?? [new Date(it.baseAt).getDay()];
      return '每 ' + wds.map(d => WK[d].label).join('·');
    }
  }
}

function nextText(ts: number): string {
  const diff = ts - Date.now();
  if (diff <= 0) return '即将触发';
  const d = Math.floor(diff / 86_400_000);
  const s = Math.floor(diff / 1000) % 86_400;
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  if (d >= 1) return `${d}天${h}小时后`;
  if (h >= 1) return `${h}小时${m}分后`;
  if (m >= 1) return `${m}分钟后`;
  return `${Math.floor(diff / 1000)}秒后`;
}

const sorted = computed(() =>
  [...store.items].sort((a, b) => (a.enabled === b.enabled ? a.nextAt - b.nextAt : a.enabled ? -1 : 1))
);

// 每分钟刷新一次 nextText 显示
const _t = ref(0);
setInterval(() => { _t.value++; }, 60_000);
const touch = () => _t.value;
</script>

<template>
  <section class="page">
    <div class="form">
      <input v-model="title" class="input" placeholder="提醒内容（如：喝水、吃水果）">
      <div class="row2">
        <input v-if="repeat !== 'hourly'" type="time" v-model="time" class="input">
        <div v-else class="hourly-input">
          <span class="hl-label">每小时</span>
          <select v-model.number="hourMin" class="input sm">
            <option v-for="m in 60" :key="m-1" :value="m-1">{{ m-1 }}分</option>
          </select>
          <select v-model.number="hourSec" class="input sm">
            <option v-for="s in 60" :key="s-1" :value="s-1">{{ s-1 }}秒</option>
          </select>
        </div>
        <select v-model="repeat" class="input">
          <option value="none">单次</option>
          <option value="daily">每天</option>
          <option value="weekdays">工作日</option>
          <option value="weekly">每周</option>
          <option value="hourly">每小时</option>
        </select>
      </div>
      <div v-if="repeat === 'weekly'" class="weeks">
        <button
          v-for="w in WK" :key="w.d"
          class="wk"
          :class="{ on: weekDays.includes(w.d) }"
          type="button"
          @click="toggleWeek(w.d)"
        >{{ w.label }}</button>
      </div>
      <FButton tone="primary" block size="md" @click="add()">➕ 添加提醒</FButton>
    </div>

    <div class="list" v-if="sorted.length">
      <div class="item" v-for="it in sorted" :key="it.id" :class="{ off: !it.enabled }">
        <label class="sw" @click.stop>
          <input type="checkbox" :checked="it.enabled" @change="store.toggle(it.id)">
          <span class="slider"></span>
        </label>
        <div class="main" style="flex:1; min-width:0">
          <div class="t">{{ it.title }}</div>
          <div class="sub">
            <span v-if="it.repeat === 'hourly'">🔁 {{ repeatText(it) }}</span>
            <template v-else>
              <span>⏰ {{ formatHM(new Date(it.baseAt)) }}</span>
              <span class="dot">·</span>
              <span>🔁 {{ repeatText(it) }}</span>
            </template>
          </div>
        </div>
        <div class="right">
          <span class="next" v-if="it.enabled">
            {{ (touch(), nextText(it.nextAt)) }}
          </span>
          <button class="x" @click="store.remove(it.id)">✕</button>
        </div>
      </div>
    </div>
    <div v-else class="empty">还没有提醒计划</div>
  </section>
</template>

<style scoped>
.page { padding: 4px 16px 16px; display: flex; flex-direction: column; gap: 12px; }
.form {
  padding: 12px; border-radius: 14px;
  background: var(--ft-surface-2);
  display: flex; flex-direction: column; gap: 8px;
}
.input {
  height: 36px; padding: 0 10px;
  border-radius: 8px; border: 1px solid var(--ft-border);
  background: var(--ft-surface-1); color: var(--ft-text-1);
  font-size: 13px;
}
.input:focus { outline: 2px solid var(--ft-accent); outline-offset: 0; border-color: var(--ft-accent); }
.row2 { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
.hourly-input { display: flex; align-items: center; gap: 4px; }
.hl-label { font-size: 12px; color: var(--ft-text-2); white-space: nowrap; }
.input.sm { width: auto; flex: 1; min-width: 0; padding: 0 4px; }
.weeks { display: flex; gap: 4px; flex-wrap: wrap; }
.wk {
  width: 34px; height: 28px; border-radius: 8px;
  border: 1px solid var(--ft-border); background: var(--ft-surface-1);
  color: var(--ft-text-2); cursor: pointer; font-size: 12px;
}
.wk.on { background: var(--ft-accent); border-color: var(--ft-accent); color: #fff; }

.list { display: flex; flex-direction: column; gap: 6px; }
.item {
  display: flex; align-items: center; gap: 10px;
  padding: 10px 12px;
  background: var(--ft-surface-2);
  border-radius: 12px;
}
.item.off .t, .item.off .sub { color: var(--ft-text-3) !important; }
.t { font-size: 13.5px; font-weight: 600; color: var(--ft-text-1); }
.sub { font-size: 11.5px; color: var(--ft-text-3); margin-top: 2px; display: inline-flex; gap: 4px; }
.right { display: flex; align-items: center; gap: 10px; }
.next { font-size: 12px; color: var(--ft-accent); font-weight: 600; }
.x { width: 24px; height: 24px; border: 0; background: transparent; border-radius: 6px; color: var(--ft-text-3); cursor: pointer; }
.x:hover { background: var(--ft-surface-3); color: #d13438; }

/* toggle switch */
.sw {
  position: relative; display: inline-block; width: 34px; height: 20px; flex-shrink: 0;
}
.sw input { opacity: 0; width: 0; height: 0; }
.slider {
  position: absolute; inset: 0; cursor: pointer;
  background: var(--ft-surface-3); border-radius: 20px; transition: .2s;
}
.slider::before {
  position: absolute; content: "";
  width: 14px; height: 14px; left: 3px; top: 3px;
  background: #fff; border-radius: 50%; transition: .2s;
  box-shadow: 0 1px 3px rgba(0,0,0,.25);
}
.sw input:checked + .slider { background: var(--ft-accent); }
.sw input:checked + .slider::before { transform: translateX(14px); }

.empty {
  padding: 20px; text-align: center; color: var(--ft-text-3); font-size: 12.5px;
  background: var(--ft-surface-2); border-radius: 12px;
}
</style>
