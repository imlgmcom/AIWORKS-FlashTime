//! 系统托盘：图标 + 右键菜单（显示/隐藏主窗口、显示/隐藏遮罩、退出）
//!
//! 使用 Tauri 2 自带的 `tray-icon` feature（Cargo.toml 里已启用）。

use tauri::{
    menu::{Menu, MenuEvent, MenuItem},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    AppHandle, Manager,
};

const TRAY_ID: &str = "flashtime-main";

pub fn build_tray(app: &AppHandle) -> tauri::Result<()> {
    let show_item =
        MenuItem::with_id(app, "show", "显示主窗口", true, None::<&str>)?;
    let hide_item =
        MenuItem::with_id(app, "hide", "隐藏到托盘", true, None::<&str>)?;
    let quit_item =
        MenuItem::with_id(app, "quit", "退出 闪时工具箱", true, None::<&str>)?;

    let menu = Menu::with_items(app, &[&show_item, &hide_item, &quit_item])?;

    let tray = TrayIconBuilder::with_id(TRAY_ID)
        .icon(app.default_window_icon().cloned().unwrap())
        .tooltip("闪时工具箱 FlashTime")
        .menu(&menu)
        .show_menu_on_left_click(false)
        .on_menu_event(|app, event: MenuEvent| match event.id.as_ref() {
            "show" => show_window(app),
            "hide" => hide_window(app),
            "quit" => app.exit(0),
            _ => {}
        })
        .on_tray_icon_event(|tray, event: TrayIconEvent| {
            if let TrayIconEvent::Click {
                button: MouseButton::Left,
                button_state: MouseButtonState::Up,
                ..
            } = event
            {
                let app = tray.app_handle();
                // 单击托盘图标：切换主窗口显示/隐藏
                if let Some(win) = app.get_webview_window("main") {
                    if win.is_visible().unwrap_or(false) {
                        hide_window(app);
                    } else {
                        show_window(app);
                    }
                } else {
                    show_window(app);
                }
            }
        })
        .build(app)?;
    let _ = tray;
    Ok(())
}

fn show_window(app: &AppHandle) {
    if let Some(win) = app.get_webview_window("main") {
        let _ = win.show();
        let _ = win.unminimize();
        let _ = win.set_focus();
    }
}

fn hide_window(app: &AppHandle) {
    if let Some(win) = app.get_webview_window("main") {
        let _ = win.hide();
    }
}
