<script setup lang="ts">
/**
 * 大字号时间显示组件：接受 ms，显示 HH:MM:SS[.mmm]。
 */
import { computed } from 'vue';
import { formatHMS, formatHMSMs } from '../utils/time';

const props = withDefaults(defineProps<{
  /** 总毫秒数 */
  value: number;
  /** 是否显示毫秒（3 位） */
  showMs?: boolean;
  /** 尺寸变体 */
  size?: 'xl' | 'lg' | 'md';
}>(), {
  showMs: false,
  size: 'lg',
});

const text = computed(() =>
  props.showMs ? formatHMSMs(props.value) : formatHMS(props.value)
);
const body = computed(() => {
  if (!props.showMs) return text.value;
  const i = text.value.lastIndexOf('.');
  return i < 0 ? text.value : text.value.slice(0, i);
});
const ms = computed(() => {
  if (!props.showMs) return '';
  const i = text.value.lastIndexOf('.');
  return i < 0 ? '' : text.value.slice(i);
});
</script>

<template>
  <div class="time-display" :class="`size-${size}`">
    <span class="main">{{ body }}</span>
    <span v-if="ms" class="ms">{{ ms }}</span>
  </div>
</template>

<style scoped>
.time-display {
  font-variant-numeric: tabular-nums;
  font-weight: 500;
  color: var(--ft-text-1);
  letter-spacing: 0.5px;
  display: inline-flex;
  align-items: baseline;
  justify-content: center;
}
.size-xl { font-size: 56px; line-height: 1.05; }
.size-lg { font-size: 44px; line-height: 1.1; }
.size-md { font-size: 28px; line-height: 1.2; }
.size-xl .ms { font-size: 30px; color: var(--ft-text-2); margin-left: 2px; }
.size-lg .ms { font-size: 22px; color: var(--ft-text-2); margin-left: 2px; }
.size-md .ms { font-size: 16px; color: var(--ft-text-2); margin-left: 2px; }
.main { font-family: "Segoe UI Variable", "Segoe UI", system-ui, sans-serif; }
</style>
