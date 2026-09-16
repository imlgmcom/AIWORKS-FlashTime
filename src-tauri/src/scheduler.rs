//! Rust 后端定时调度器
//!
//! 解决问题：窗口隐藏时浏览器节流 setInterval，导致前端 tick 不执行。
//! 方案：Rust 独立线程每秒读取 store JSON 文件，检查提醒/定时任务是否到期。
//! 到期时：弹出系统消息框 + 显示主窗口 + emit 事件给前端。

use serde_json::Value;
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Mutex;
use std::time::{Duration, SystemTime, UNIX_EPOCH};
use tauri::{AppHandle, Emitter, Manager};

/// 内存中记录已触发的 id → 触发时间戳，防止重复触发
static FIRED: Mutex<Option<HashMap<String, u64>>> = Mutex::new(None);

fn now_millis() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as u64
}

fn store_file_path() -> PathBuf {
    let exe = std::env::current_exe().unwrap_or_default();
    let dir = exe.parent().unwrap_or(std::path::Path::new("."));
    let data_dir = dir.join("data");
    let _ = std::fs::create_dir_all(&data_dir);
    data_dir.join("flashtime.store.json")
}

fn read_store() -> Value {
    let path = store_file_path();
    match std::fs::read_to_string(&path) {
        Ok(content) => {
            serde_json::from_str(&content).unwrap_or_else(|_| Value::Object(serde_json::Map::new()))
        }
        Err(_) => Value::Object(serde_json::Map::new()),
    }
}

/// 检查是否最近已触发过（5 分钟内）。如果没有，标记为已触发。
fn check_and_mark_fired(id: &str) -> bool {
    let mut guard = FIRED.lock().unwrap();
    if guard.is_none() {
        *guard = Some(HashMap::new());
    }
    let map = guard.as_mut().unwrap();
    let now = now_millis();

    // 清理超过 5 分钟的记录（重复提醒可以再次触发）
    map.retain(|_, ts| now - *ts < 300_000);

    if map.contains_key(id) {
        return false;
    }
    map.insert(id.to_string(), now);
    true
}

/// 弹出 Windows 原生消息框（独立线程，不阻塞调度器）
fn show_alarm_dialog(title: &str, body: &str) {
    let title = title.to_string();
    let body = body.to_string();
    #[cfg(windows)]
    {
        std::thread::spawn(move || {
            use windows::Win32::UI::WindowsAndMessaging::*;
            let flags = MB_TOPMOST | MB_SETFOREGROUND | MB_ICONINFORMATION | MB_OK;
            let text_w: Vec<u16> = body.encode_utf16().chain(std::iter::once(0)).collect();
            let title_w: Vec<u16> = title.encode_utf16().chain(std::iter::once(0)).collect();
            unsafe {
                MessageBoxW(
                    None,
                    windows::core::PCWSTR(text_w.as_ptr()),
                    windows::core::PCWSTR(title_w.as_ptr()),
                    flags,
                );
            }
        });
    }
    let _ = title;
    let _ = body;
}

/// 启动后台调度器线程
pub fn start_scheduler(app: AppHandle) {
    std::thread::spawn(move || {
        // 启动后等 3 秒，让前端 store 初始化完成
        std::thread::sleep(Duration::from_secs(3));

        loop {
            std::thread::sleep(Duration::from_secs(1));

            let store = read_store();
            let now = now_millis();
            let mut events: Vec<(&str, String, String)> = Vec::new();

            // 检查提醒
            if let Some(reminders) = store.get("reminder_items").and_then(|v| v.as_array()) {
                for r in reminders {
                    let id = r.get("id").and_then(|v| v.as_str()).unwrap_or("");
                    let title = r.get("title").and_then(|v| v.as_str()).unwrap_or("");
                    let enabled = r.get("enabled").and_then(|v| v.as_bool()).unwrap_or(false);
                    let next_at = r.get("nextAt").and_then(|v| v.as_f64()).unwrap_or(0.0) as u64;

                    if enabled && next_at > 0 && next_at <= now {
                        if check_and_mark_fired(id) {
                            events.push(("reminder", id.to_string(), title.to_string()));
                        }
                    }
                }
            }

            // 检查定时任务
            if let Some(schedules) = store.get("schedule_items").and_then(|v| v.as_array()) {
                for s in schedules {
                    let id = s.get("id").and_then(|v| v.as_str()).unwrap_or("");
                    let title = s.get("title").and_then(|v| v.as_str()).unwrap_or("");
                    let fired = s.get("fired").and_then(|v| v.as_bool()).unwrap_or(false);
                    let at = s.get("at").and_then(|v| v.as_f64()).unwrap_or(0.0) as u64;

                    if !fired && at <= now {
                        if check_and_mark_fired(id) {
                            events.push(("schedule", id.to_string(), title.to_string()));
                        }
                    }
                }
            }

            // 触发事件
            for (kind, id, title) in &events {
                let alarm_title = match *kind {
                    "reminder" => "闪时提醒",
                    "schedule" => "定时提醒",
                    _ => "提醒",
                };
                show_alarm_dialog(alarm_title, title);

                // 显示主窗口
                if let Some(w) = app.get_webview_window("main") {
                    let _ = w.show();
                    let _ = w.unminimize();
                    let _ = w.set_focus();
                }

                // emit 事件给前端（前端更新 store + 播放声音）
                let _ = app.emit(
                    "scheduler-fired",
                    serde_json::json!({
                        "type": kind,
                        "id": id,
                        "title": title,
                    }),
                );
            }
        }
    });
}
