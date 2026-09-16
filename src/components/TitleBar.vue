<script setup lang="ts">
/**
 * 自定义标题栏：
 *  - 左：产品名（鼠标左键按下可拖动窗口）
 *  - 右：最小化、关闭（关闭 = 隐藏到托盘）
 */
import { useWindowControl } from '../composables/useWindowControl';
import { useAutoStart } from '../composables/useAutoStart';

const { startDrag, minimize, close } = useWindowControl();
const { enabled: autoEnabled, loading: autoLoading, available: autoAvailable, toggle: autoToggle } = useAutoStart();
</script>

<template>
  <header class="titlebar" @mousedown="startDrag">
    <div class="brand">
      <span class="logo">⏱</span>
      <span class="name">闪时工具箱</span>
    </div>
    <div class="opts" @mousedown.stop>
      <label class="autostart" :title="autoAvailable ? '开机自启' : '仅在桌面应用中可用'">
        <input type="checkbox" :checked="autoEnabled" :disabled="autoLoading || !autoAvailable" @change="autoToggle()">
        <span>自启{{ autoAvailable ? '' : '(Web)' }}</span>
      </label>
      <button class="btn ghost" @click="minimize()" title="最小化">—</button>
      <button class="btn danger ghost" @click="close()" title="隐藏到托盘">✕</button>
    </div>
  </header>
</template>

<style scoped>
.titlebar {
  height: 38px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 10px 0 14px;
  user-select: none;
  -webkit-user-select: none;
  flex-shrink: 0;
}
.brand { display: flex; align-items: center; gap: 8px; font-weight: 600; color: var(--ft-text-1); }
.logo { font-size: 16px; }
.name { font-size: 13px; letter-spacing: 0.2px; }
.opts { display: flex; align-items: center; gap: 6px; }
.btn {
  border: 0;
  width: 28px; height: 28px;
  border-radius: 6px;
  background: transparent;
  color: var(--ft-text-2);
  font-size: 14px;
  cursor: pointer;
  display: inline-flex; align-items: center; justify-content: center;
  transition: background .15s ease, color .15s ease;
}
.btn:hover { background: var(--ft-surface-2); color: var(--ft-text-1); }
.btn.danger:hover { background: #e81123; color: #fff; }
.autostart {
  display: inline-flex; align-items: center; gap: 5px;
  font-size: 12px; color: var(--ft-text-2);
  cursor: pointer; padding: 2px 6px;
  border-radius: 6px;
}
.autostart:hover { background: var(--ft-surface-2); }
.autostart input { cursor: pointer; accent-color: var(--ft-accent); }
.autostart:has(input:disabled) { opacity: 0.6; }
</style>
