import { defineStore } from 'pinia';
import { ref, onMounted } from 'vue';
import { getJson, setJson, removeKey } from '../utils/storage';
import { uid } from '../utils/time';

export interface TodoItem {
  id: string;
  title: string;
  done: boolean;
  createdAt: number;
  dueAt?: number;   // 可选截止时间戳
}

/**
 * TODO 待办：增删改查 + 本地持久化 + 完成状态。
 */
export const useTodoStore = defineStore('todo', () => {
  const items = ref<TodoItem[]>([]);
  const filter = ref<'all' | 'active' | 'done'>('all');

  async function load() {
    items.value = await getJson<TodoItem[]>('todo_items', []);
  }

  async function save() {
    await setJson('todo_items', items.value);
  }

  function add(title: string, dueAt?: number) {
    const t = title.trim();
    if (!t) return;
    items.value.unshift({
      id: uid(),
      title: t,
      done: false,
      createdAt: Date.now(),
      dueAt,
    });
    save();
  }

  function toggle(id: string) {
    const it = items.value.find(x => x.id === id);
    if (!it) return;
    it.done = !it.done;
    save();
  }

  function remove(id: string) {
    const i = items.value.findIndex(x => x.id === id);
    if (i >= 0) {
      items.value.splice(i, 1);
      save();
    }
  }

  function clearDone() {
    items.value = items.value.filter(x => !x.done);
    save();
  }

  function updateTitle(id: string, title: string) {
    const it = items.value.find(x => x.id === id);
    if (!it) return;
    it.title = title.trim();
    save();
  }

  function clearAll() {
    items.value = [];
    removeKey('todo_items');
  }

  onMounted(load);

  return { items, filter, load, add, toggle, remove, clearDone, updateTitle, clearAll };
});
