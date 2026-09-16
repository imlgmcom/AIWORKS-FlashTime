<script setup lang="ts">
/**
 * 定时任务：设定目标时间点，到时触发一次通知。
 */
import { computed, ref } from 'vue';
import FButton from '../components/FButton.vue';
import { useScheduleStore } from '../stores/schedule';
import { formatDate, formatDateTime, formatHM } from '../utils/time';

const store = useScheduleStore();

const today = formatDate(new Date());
const dateStr = ref(today);
const timeStr = ref(formatHM(new Date(Date.now() + 5 * 60_000)));
const title = ref('');

function add() {
  const t = title.value.trim() || '定时提醒';
  const [y, m, d] = dateStr.value.split('-').map(Number);
  const [hh, mm] = timeStr.value.split(':').map(Number);
  const at = new Date(y, m - 1, d, hh, mm, 0, 0).getTime();
  if (at <= Date.now()) return;
  store.add(t, at);
  title.value = '';
}

const upcoming = computed(() => store.items.filter(x => !x.fired).sort((a, b) => a.at - b.at));
const past = computed(() => store.items.filter(x => x.fired).sort((a, b) => b.at - a.at).slice(0, 20));

function countdownTo(ts: number): string {
  const diff = ts - Date.now();
  if (diff <= 0) return '到点';
  const s = Math.floor(diff / 1000);
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const sec = s % 60;
  if (h) return `${h}时${m}分${sec}秒后`;
  if (m) return `${m}分${sec}秒后`;
  return `${sec}秒后`;
}
</script>

<template>
  <section class="page">
    <div class="form">
      <input type="text" v-model="title" placeholder="提醒内容（如：开会）" class="input title">
      <div class="row2">
        <input type="date" v-model="dateStr" class="input" :min="today">
        <input type="time" v-model="timeStr" class="input">
      </div>
      <FButton tone="primary" block size="md" @click="add()">➕ 添加定时任务</FButton>
    </div>

    <h3 class="h">待触发 · {{ upcoming.length }}</h3>
    <div v-if="upcoming.length" class="list">
      <div class="item" v-for="it in upcoming" :key="it.id">
        <div class="main">
          <div class="t">{{ it.title }}</div>
          <div class="sub">{{ formatDateTime(new Date(it.at)) }}</div>
        </div>
        <div class="right">
          <span class="countdown">{{ countdownTo(it.at) }}</span>
          <button class="x" title="删除" @click="store.remove(it.id)">✕</button>
        </div>
      </div>
    </div>
    <div v-else class="empty">暂无定时任务</div>

    <div v-if="past.length" class="past-wrap">
      <div class="past-header">
        <h3 class="h" style="margin:0">已完成 · {{ past.length }}</h3>
        <button class="clear" @click="store.clearFired()">🗑 清空</button>
      </div>
      <div class="list muted">
        <div class="item" v-for="it in past" :key="it.id">
          <div class="main">
            <div class="t done">{{ it.title }}</div>
            <div class="sub">{{ formatDateTime(new Date(it.at)) }}</div>
          </div>
          <button class="x" title="删除" @click="store.remove(it.id)">✕</button>
        </div>
      </div>
    </div>
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
  height: 36px;
  padding: 0 10px;
  border-radius: 8px;
  border: 1px solid var(--ft-border);
  background: var(--ft-surface-1);
  color: var(--ft-text-1);
  font-size: 13px;
}
.input:focus { outline: 2px solid var(--ft-accent); outline-offset: 0; border-color: var(--ft-accent); }
.title::placeholder { color: var(--ft-text-3); }
.row2 { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
.h { margin: 2px 2px 0; font-size: 12px; color: var(--ft-text-2); font-weight: 600; letter-spacing: .3px; }

.list { display: flex; flex-direction: column; gap: 6px; }
.item {
  display: flex; align-items: center; justify-content: space-between;
  padding: 10px 12px;
  background: var(--ft-surface-2);
  border-radius: 12px;
}
.item .t { font-size: 13.5px; font-weight: 600; color: var(--ft-text-1); }
.item .t.done { color: var(--ft-text-3); text-decoration: line-through; }
.item .sub { font-size: 11.5px; color: var(--ft-text-3); margin-top: 2px; }
.right { display: flex; align-items: center; gap: 10px; }
.countdown { font-size: 12px; color: var(--ft-accent); font-weight: 600; font-variant-numeric: tabular-nums; }
.x {
  width: 24px; height: 24px;
  border: 0; background: transparent; border-radius: 6px;
  color: var(--ft-text-3); cursor: pointer;
}
.x:hover { background: var(--ft-surface-3); color: #d13438; }

.empty {
  padding: 20px; text-align: center; color: var(--ft-text-3); font-size: 12.5px;
  background: var(--ft-surface-2); border-radius: 12px;
}
.past-wrap { border-top: 1px solid var(--ft-border-soft); padding-top: 10px; }
.past-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px; padding: 0 2px; }
.clear { font-size: 12px; border: 0; background: transparent; color: var(--ft-text-3); cursor: pointer; }
.clear:hover { color: #d13438; }
.list.muted .item { opacity: 0.75; }
</style>
