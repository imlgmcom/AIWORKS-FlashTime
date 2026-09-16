<script setup lang="ts">
/**
 * 倒计时：可自定义 时/分/秒，支持预设，到点 Windows 通知 + 提示音。
 */
import { computed, ref } from 'vue';
import FButton from '../components/FButton.vue';
import TimeDisplay from '../components/TimeDisplay.vue';
import { useCountdownStore } from '../stores/countdown';

const cd = useCountdownStore();

// 自定义时分秒输入
const hh = ref(0);
const mm = ref(10);
const ss = ref(0);

function presetLabel(ms: number): string {
  const total = Math.floor(ms / 1000);
  const h = Math.floor(total / 3600);
  const m = Math.floor((total % 3600) / 60);
  const s = total % 60;
  if (h) return `${h}时${m ? m + '分' : ''}`;
  if (m) return `${m}分${s ? s + '秒' : ''}`;
  return `${s}秒`;
}

function applyPreset(ms: number) {
  cd.setTotal(ms);
  cd.stop();
  cd.reset();
  const s = Math.floor(ms / 1000);
  hh.value = Math.floor(s / 3600);
  mm.value = Math.floor((s % 3600) / 60);
  ss.value = s % 60;
}

function applyCustom() {
  const ms = ((hh.value * 3600) + (mm.value * 60) + ss.value) * 1000;
  if (ms <= 0) return;
  cd.setTotal(ms);
  cd.stop();
  cd.reset();
  cd.addPreset(ms);
}

const progressPct = computed(() => Math.round(cd.progress * 100));
</script>

<template>
  <section class="page">
    <div class="watch">
      <TimeDisplay :value="cd.remainMs" show-ms size="xl" />
      <div class="progress">
        <div class="bar" :style="{ width: progressPct + '%' }"></div>
      </div>
      <div class="sub">{{ progressPct }}% · 总时长 {{ presetLabel(cd.totalMs) }}</div>
    </div>

    <!-- 预设 -->
    <div class="presets">
      <button
        v-for="p in cd.presetMs" :key="p"
        class="chip"
        :class="{ active: p === cd.totalMs }"
        @click="applyPreset(p)"
      >
        {{ presetLabel(p) }}
      </button>
    </div>

    <!-- 自定义 -->
    <div class="custom">
      <div class="hms">
        <label>
          <span>时</span>
          <input type="number" min="0" max="99" v-model.number="hh">
        </label>
        <span class="sep">:</span>
        <label>
          <span>分</span>
          <input type="number" min="0" max="59" v-model.number="mm">
        </label>
        <span class="sep">:</span>
        <label>
          <span>秒</span>
          <input type="number" min="0" max="59" v-model.number="ss">
        </label>
      </div>
      <FButton size="sm" tone="subtle" @click="applyCustom()">应用</FButton>
    </div>

    <div class="row">
      <FButton
        v-if="!cd.running || cd.paused"
        tone="primary" size="lg" block
        @click="cd.start()"
      >
        ▶ {{ cd.paused ? '继续' : '开始' }}
      </FButton>
      <FButton
        v-else
        tone="danger" size="lg" block
        @click="cd.pauseAction()"
      >
        ⏸ 暂停
      </FButton>
      <FButton tone="subtle" size="lg" block @click="cd.reset()">⟲ 重置</FButton>
    </div>
  </section>
</template>

<style scoped>
.page { padding: 4px 16px 16px; display: flex; flex-direction: column; gap: 14px; }
.watch {
  margin-top: 12px;
  padding: 16px 0 14px;
  text-align: center;
  border-radius: 16px;
  background: linear-gradient(180deg, var(--ft-surface-2) 0%, transparent 100%);
}
.progress {
  margin: 14px 16px 6px;
  height: 6px;
  background: var(--ft-surface-3);
  border-radius: 6px;
  overflow: hidden;
}
.bar { height: 100%; background: var(--ft-accent); transition: width .2s linear; }
.sub { color: var(--ft-text-3); font-size: 12px; }
.presets { display: flex; flex-wrap: wrap; gap: 6px; }
.chip {
  border: 1px solid var(--ft-border-soft);
  background: var(--ft-surface-2);
  padding: 6px 12px;
  border-radius: 999px;
  font-size: 12px;
  color: var(--ft-text-2);
  cursor: pointer;
  transition: all .15s ease;
}
.chip:hover { color: var(--ft-text-1); border-color: var(--ft-border); }
.chip.active { color: #fff; background: var(--ft-accent); border-color: var(--ft-accent); }

.custom {
  display: flex; align-items: center; gap: 10px;
  padding: 10px 12px;
  background: var(--ft-surface-2);
  border-radius: 12px;
}
.hms { display: flex; align-items: flex-end; gap: 4px; flex: 1; }
.hms label {
  display: flex; flex-direction: column; gap: 3px;
  font-size: 11px; color: var(--ft-text-3);
}
.hms input {
  width: 48px; height: 32px;
  text-align: center;
  border: 1px solid var(--ft-border);
  border-radius: 8px;
  background: var(--ft-surface-1);
  color: var(--ft-text-1);
  font-size: 14px;
  font-variant-numeric: tabular-nums;
}
.hms input:focus { outline: 2px solid var(--ft-accent); outline-offset: 0; border-color: var(--ft-accent); }
.sep { color: var(--ft-text-2); padding-bottom: 4px; }

.row { display: grid; grid-template-columns: 1.3fr 1fr; gap: 8px; }
</style>
