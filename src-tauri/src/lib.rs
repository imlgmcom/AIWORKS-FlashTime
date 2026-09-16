//! lib.rs：Tauri 应用入口
//!
//! 模块：tray（托盘）。
//! 系统能力：官方 Tauri 2 插件（autostart/global-shortcut/notification/store/opener/shell）。

#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod scheduler;
mod tray;

use tauri::{
    Emitter, LogicalPosition, LogicalSize, Manager, WebviewWindow,
};

#[tauri::command]
fn ping() -> &'static str {
    "pong"
}

/// 文件日志
fn log(msg: &str) {
    use std::io::Write;
    let exe = std::env::current_exe().unwrap_or_default();
    let dir = exe.parent().unwrap_or(std::path::Path::new("."));
    let path = dir.join("app.log");
    if let Ok(mut f) = std::fs::OpenOptions::new().create(true).append(true).open(&path) {
        let _ = writeln!(f, "{}", msg);
    }
    eprintln!("[lib] {}", msg);
}

/// 绿色软件：数据存 exe 同目录的 data/ 子目录，而非 %APPDATA%
#[tauri::command]
fn data_store_path() -> String {
    let exe = std::env::current_exe().unwrap_or_default();
    let dir = exe.parent().unwrap_or(std::path::Path::new("."));
    let data_dir = dir.join("data");
    let _ = std::fs::create_dir_all(&data_dir);
    data_dir
        .join("flashtime.store.json")
        .to_string_lossy()
        .to_string()
}

/// 到点提醒：弹出 Windows 原生消息框（屏幕正中心、置顶、带系统提示音）
/// 在独立线程中调用，避免阻塞 Tauri 主线程
#[tauri::command]
fn show_alarm(title: String, body: String) {
    log(&format!("show_alarm: title={}, body={}", title, body));
    #[cfg(windows)]
    {
        std::thread::spawn(move || {
            use windows::Win32::UI::WindowsAndMessaging::*;
            // MB_TOPMOST  = 0x40000  让弹窗置顶在所有窗口之上
            // MB_ICONINFORMATION = 0x40  系统信息提示音
            // MB_SETFOREGROUND = 0x10000  抢占前台
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
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_store::Builder::new().build())
        .plugin(tauri_plugin_notification::init())
        .plugin(tauri_plugin_autostart::init(
            tauri_plugin_autostart::MacosLauncher::LaunchAgent,
            Some(vec!["--minimized"]),
        ))
        .plugin(tauri_plugin_shell::init())
        .invoke_handler(tauri::generate_handler![ping, data_store_path, show_alarm])
        .setup(|app| {
            let handle = app.handle().clone();

            // 1) 托盘
            log("setup: building tray");
            tray::build_tray(&handle).ok();

            // 2) 后台调度器（窗口隐藏时也能触发提醒/定时任务）
            log("setup: starting scheduler");
            scheduler::start_scheduler(handle.clone());

            // 3) 主窗口首次定位到右下角
            if let Some(w) = handle.get_webview_window("main") {
                position_at_bottom_right(&w);
            }

            Ok(())
        })
        // 关闭 -> 隐藏到托盘
        .on_window_event(|app, event| {
            use tauri::WindowEvent::*;
            if let CloseRequested { api, .. } = event {
                if let Some(win) = app.get_webview_window("main") {
                    let _ = win.hide();
                }
                api.prevent_close();
            }
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

fn position_at_bottom_right(win: &WebviewWindow) {
    let (sf, work_x, work_y, work_w, work_h) = match win.current_monitor() {
        Ok(Some(m)) => {
            let work = m.work_area();
            (m.scale_factor(), work.position.x, work.position.y, work.size.width, work.size.height)
        }
        _ => return,
    };
    let win_size = match win.outer_size() {
        Ok(s) => s.to_logical::<i32>(sf),
        Err(_) => LogicalSize { width: 380, height: 600 },
    };
    let x = work_x + (work_w as i32 - win_size.width - 12);
    let y = work_y + (work_h as i32 - win_size.height - 56);
    let _ = win.set_position(LogicalPosition { x, y });
}
