<script setup lang="ts">
/**
 * 通用按钮：三种 size / 四种 tone / 可选 disabled。
 */
import { computed } from 'vue';
const props = withDefaults(defineProps<{
  tone?: 'primary' | 'ghost' | 'danger' | 'subtle';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  type?: 'button' | 'submit';
  block?: boolean;
}>(), {
  tone: 'ghost', size: 'md', disabled: false, type: 'button', block: false,
});
const cls = computed(() => [
  'ft-btn',
  `tone-${props.tone}`,
  `size-${props.size}`,
  { block: props.block, disabled: props.disabled },
]);
</script>

<template>
  <button :class="cls" :type="type" :disabled="disabled">
    <slot />
  </button>
</template>

<style scoped>
.ft-btn {
  border: 1px solid transparent;
  border-radius: 10px;
  cursor: pointer;
  transition: all .15s ease;
  display: inline-flex; align-items: center; justify-content: center;
  gap: 6px;
  font-weight: 500;
  color: var(--ft-text-1);
  background: var(--ft-surface-2);
}
.ft-btn.block { width: 100%; }
.ft-btn.disabled, .ft-btn:disabled { opacity: 0.45; cursor: not-allowed; pointer-events: none; }

.size-sm { height: 30px; padding: 0 10px; font-size: 12.5px; }
.size-md { height: 36px; padding: 0 14px; font-size: 13.5px; }
.size-lg { height: 42px; padding: 0 18px; font-size: 14.5px; }

.tone-primary {
  background: var(--ft-accent);
  color: #fff;
  border-color: var(--ft-accent);
}
.tone-primary:hover { filter: brightness(1.05); }

.tone-ghost:hover { background: var(--ft-surface-3); border-color: var(--ft-border); }
.tone-subtle {
  background: transparent; color: var(--ft-text-2);
  border-color: var(--ft-border-soft);
}
.tone-subtle:hover { color: var(--ft-text-1); border-color: var(--ft-border); }
.tone-danger {
  color: #d13438; border-color: #f3d1d1; background: #fef5f5;
}
.tone-danger:hover { background: #fde6e6; }
</style>
