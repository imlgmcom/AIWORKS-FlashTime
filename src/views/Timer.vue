<script setup lang="ts">
/**
 * 正计时：开始 / 暂停 / 重置 / 计次 Lap
 */
import FButton from '../components/FButton.vue';
import TimeDisplay from '../components/TimeDisplay.vue';
import { useTimerStore } from '../stores/timer';

const timer = useTimerStore();
</script>

<template>
  <section class="timer-page">
    <div class="watch">
      <TimeDisplay :value="timer.elapsedMs" show-ms size="xl" />
    </div>

    <div class="row">
      <FButton
        :tone="timer.running ? 'danger' : 'primary'"
        size="lg"
        block
        @click="timer.running ? timer.pause() : timer.start()"
      >
        {{ timer.running ? '⏸ 暂停' : '▶ 开始' }}
      </FButton>
      <FButton tone="ghost" size="lg" block @click="timer.lap()" :disabled="!timer.running && timer.elapsedMs === 0">
        ⏱ 计次
      </FButton>
      <FButton tone="subtle" size="lg" block @click="timer.reset()">
        ⟲ 重置
      </FButton>
    </div>

    <div class="laps" v-if="timer.laps.length">
      <header>
        <span>#</span><span>分段</span><span>总时长</span>
      </header>
      <div class="lap" v-for="l in timer.laps" :key="l.index">
        <span class="idx">{{ l.index }}</span>
        <span class="seg">{{ l.lap }}</span>
        <span class="tot">{{ l.total }}</span>
      </div>
    </div>
    <div v-else class="empty">
      点击「开始」启动正计时，运行中可记录分段。
    </div>
  </section>
</template>

<style scoped>
.timer-page { padding: 4px 16px 16px; display: flex; flex-direction: column; gap: 18px; }
.watch {
  margin-top: 12px;
  display: flex; justify-content: center;
  padding: 16px 0;
  border-radius: 16px;
  background: linear-gradient(180deg, var(--ft-surface-2) 0%, transparent 100%);
}
.row { display: grid; grid-template-columns: 1.3fr 1fr 1fr; gap: 8px; }
.laps {
  border-radius: 12px;
  background: var(--ft-surface-2);
  padding: 4px 10px;
  max-height: 260px;
  overflow-y: auto;
}
.laps header, .lap {
  display: grid;
  grid-template-columns: 44px 1fr 1fr;
  font-variant-numeric: tabular-nums;
  padding: 6px 8px;
  border-radius: 8px;
}
.laps header {
  position: sticky; top: 0; background: var(--ft-surface-2);
  color: var(--ft-text-2); font-size: 11px; text-transform: uppercase; letter-spacing: .5px;
  border-bottom: 1px solid var(--ft-border-soft);
}
.lap .idx { color: var(--ft-text-3); }
.lap:nth-child(even) { background: rgba(255,255,255,0.2); }
.seg { color: var(--ft-accent); font-weight: 600; }
.tot { color: var(--ft-text-2); }
.empty {
  padding: 24px 12px;
  border-radius: 12px;
  background: var(--ft-surface-2);
  color: var(--ft-text-3);
  text-align: center;
  font-size: 13px;
}
</style>
