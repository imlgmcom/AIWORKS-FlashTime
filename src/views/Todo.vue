<script setup lang="ts">
/**
 * TODO 待办：增删改、完成切换、筛选（全部/进行中/已完成）、批量清空。
 */
import { computed, ref } from 'vue';
import FButton from '../components/FButton.vue';
import { useTodoStore } from '../stores/todo';
import { formatDate } from '../utils/time';

const todo = useTodoStore();
const input = ref('');
const editingId = ref<string | null>(null);
const editingText = ref('');

function add() {
  if (!input.value.trim()) return;
  todo.add(input.value);
  input.value = '';
}

function startEdit(id: string, title: string) {
  editingId.value = id;
  editingText.value = title;
}
function commitEdit() {
  if (editingId.value && editingText.value.trim()) {
    todo.updateTitle(editingId.value, editingText.value);
  }
  editingId.value = null;
  editingText.value = '';
}
function cancelEdit() {
  editingId.value = null;
  editingText.value = '';
}

function dueLabel(ts?: number): string | null {
  if (!ts) return null;
  const diff = ts - Date.now();
  const d = new Date(ts);
  if (Math.abs(diff) < 86_400_000 && formatDate(d) === formatDate(new Date())) return '今天';
  return formatDate(d);
}

const shown = computed(() => {
  const all = todo.items;
  if (todo.filter === 'active') return all.filter(x => !x.done);
  if (todo.filter === 'done') return all.filter(x => x.done);
  return all;
});

const remainCount = computed(() => todo.items.filter(x => !x.done).length);
const doneCount = computed(() => todo.items.length - remainCount.value);
</script>

<template>
  <section class="page">
    <div class="adder">
      <input
        v-model="input"
        @keydown.enter="add()"
        placeholder="添加待办事项…（回车确认）"
        class="input"
      >
      <FButton tone="primary" size="md" @click="add()">添加</FButton>
    </div>

    <div class="filters">
      <button
        v-for="(f, i) in (['all','active','done'] as const)" :key="f"
        class="chip"
        :class="{ active: todo.filter === f }"
        @click="todo.filter = f"
      >
        {{ i === 0 ? '全部 ' + todo.items.length : i === 1 ? '进行中 ' + remainCount : '已完成 ' + doneCount }}
      </button>
    </div>

    <div class="list" v-if="shown.length">
      <label
        v-for="it in shown" :key="it.id"
        class="item"
        :class="{ done: it.done, editing: editingId === it.id }"
      >
        <input
          type="checkbox"
          :checked="it.done"
          @change="todo.toggle(it.id)"
          class="cb"
        >
        <div class="main" v-if="editingId !== it.id" @dblclick="startEdit(it.id, it.title)">
          <div class="t">{{ it.title }}</div>
          <div class="meta">
            <span>创建于 {{ formatDate(new Date(it.createdAt)) }}</span>
            <span v-if="dueLabel(it.dueAt)" class="due" :class="{ overdue: (it.dueAt ?? 0) < Date.now() && !it.done }">
              📅 {{ dueLabel(it.dueAt) }}
            </span>
          </div>
        </div>
        <div v-else class="editor">
          <input
            v-model="editingText"
            @keydown.enter="commitEdit()"
            @keydown.esc="cancelEdit()"
            @blur="commitEdit()"
            autofocus
          >
        </div>
        <button
          class="x" title="删除"
          @click.stop="todo.remove(it.id)"
        >❌</button>
      </label>
    </div>
    <div v-else class="empty">
      {{ todo.filter === 'done' ? '还没有完成的待办' : todo.filter === 'active' ? '没有进行中的待办' : '还没有待办，先添加一条吧' }}
    </div>

    <div class="foot" v-if="todo.items.length">
      <span class="stat">剩余 <b>{{ remainCount }}</b> · 已完成 <b>{{ doneCount }}</b></span>
      <button class="clear" v-if="doneCount" @click="todo.clearDone()">🗑 清空已完成</button>
    </div>
  </section>
</template>

<style scoped>
.page { padding: 4px 16px 16px; display: flex; flex-direction: column; gap: 12px; }
.adder { display: grid; grid-template-columns: 1fr 72px; gap: 8px; }
.input {
  height: 38px; padding: 0 12px;
  border-radius: 10px;
  border: 1px solid var(--ft-border);
  background: var(--ft-surface-1);
  color: var(--ft-text-1);
  font-size: 13.5px;
}
.input:focus { outline: 2px solid var(--ft-accent); outline-offset: 0; border-color: var(--ft-accent); }

.filters { display: flex; gap: 6px; }
.chip {
  border: 1px solid var(--ft-border-soft);
  background: var(--ft-surface-2);
  padding: 5px 12px; border-radius: 999px;
  font-size: 12px; color: var(--ft-text-2); cursor: pointer;
}
.chip:hover { color: var(--ft-text-1); }
.chip.active { background: var(--ft-accent); border-color: var(--ft-accent); color: #fff; }

.list { display: flex; flex-direction: column; gap: 6px; }
.item {
  display: flex; align-items: flex-start; gap: 10px;
  padding: 10px 12px;
  background: var(--ft-surface-2);
  border-radius: 12px;
}
.item.done .t { text-decoration: line-through; color: var(--ft-text-3); }
.cb { margin-top: 4px; accent-color: var(--ft-accent); width: 16px; height: 16px; }
.main { flex: 1; min-width: 0; }
.t { font-size: 13.5px; color: var(--ft-text-1); line-height: 1.4; word-break: break-all; }
.meta { margin-top: 4px; display: flex; gap: 8px; flex-wrap: wrap; font-size: 11px; color: var(--ft-text-3); }
.due { color: var(--ft-text-2); }
.due.overdue { color: #d13438; }
.editor { flex: 1; }
.editor input {
  width: 100%;
  height: 28px;
  padding: 0 8px;
  border-radius: 6px;
  border: 1px solid var(--ft-accent);
  background: var(--ft-surface-1);
  color: var(--ft-text-1);
  font-size: 13.5px;
}
.x {
  border: 0; background: transparent; cursor: pointer;
  font-size: 14px; padding: 2px 4px; border-radius: 6px; opacity: 0;
  transition: all .15s ease;
}
.item:hover .x { opacity: 1; }
.x:hover { background: var(--ft-surface-3); }

.empty {
  padding: 24px; text-align: center; color: var(--ft-text-3); font-size: 12.5px;
  background: var(--ft-surface-2); border-radius: 12px;
}
.foot {
  display: flex; align-items: center; justify-content: space-between;
  padding: 8px 4px;
  font-size: 12px; color: var(--ft-text-3);
}
.foot b { color: var(--ft-text-1); font-weight: 600; }
.clear {
  border: 0; background: transparent; cursor: pointer; color: var(--ft-text-3); font-size: 12px;
}
.clear:hover { color: #d13438; }
</style>
