<script setup lang="ts">
/**
 * 顶部 Tab 导航：五大功能模块。
 */
export type TabKey = 'timer' | 'countdown' | 'schedule' | 'reminder' | 'todo';
defineProps<{ modelValue: TabKey }>();
const emit = defineEmits<{ 'update:modelValue': [v: TabKey] }>();

const tabs: { key: TabKey; label: string; icon: string }[] = [
  { key: 'timer',     label: '正计时', icon: '⏱' },
  { key: 'countdown', label: '倒计时', icon: '⏳' },
  { key: 'schedule',  label: '定时',   icon: '📌' },
  { key: 'reminder',  label: '提醒',   icon: '🔔' },
  { key: 'todo',      label: '待办',   icon: '✅' },
];
</script>

<template>
  <nav class="tabnav">
    <button
      v-for="t in tabs"
      :key="t.key"
      class="tab"
      :class="{ active: modelValue === t.key }"
      @click="emit('update:modelValue', t.key)"
    >
      <span class="i">{{ t.icon }}</span>
      <span class="l">{{ t.label }}</span>
      <span v-if="modelValue === t.key" class="dot"></span>
    </button>
  </nav>
</template>

<style scoped>
.tabnav {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 4px;
  padding: 6px 10px 10px;
  flex-shrink: 0;
}
.tab {
  appearance: none;
  border: 0;
  background: transparent;
  padding: 8px 2px;
  border-radius: 10px;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  color: var(--ft-text-2);
  font-size: 11.5px;
  position: relative;
  transition: all .2s ease;
}
.tab:hover { background: var(--ft-surface-2); color: var(--ft-text-1); }
.tab .i { font-size: 18px; line-height: 1; }
.tab.active { color: var(--ft-accent); background: var(--ft-surface-2); }
.tab.active .i { transform: translateY(-1px); }
.dot {
  position: absolute;
  bottom: 4px; left: 50%;
  transform: translateX(-50%);
  width: 3px; height: 3px; border-radius: 50%;
  background: var(--ft-accent);
}
</style>
