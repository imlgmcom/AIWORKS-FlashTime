---
AIGC:
  ContentProducer: '001191110102MAD55U9H0F10002'
  ContentPropagator: '001191110102MAD55U9H0F10002'
  Label: '1'
  ProduceID: '548c76d3-ef49-4b48-95a6-d684f4c892fe'
  PropagateID: '548c76d3-ef49-4b48-95a6-d684f4c892fe'
  ReservedCode1: '9ed3089f-c146-4ca2-90b1-619cd35fa0fd'
  ReservedCode2: '9ed3089f-c146-4ca2-90b1-619cd35fa0fd'
---

# 闪时工具箱 FlashTime

系统托盘常驻的桌面效率工具箱，集成正计时、倒计时、定时任务、提醒计划和待办管理。Windows 绿色便携，数据存 exe 同目录，零依赖、双击即用。

## 功能

- **正计时** — 从零开始记录经过时间，支持暂停/继续/重置
- **倒计时** — 设定倒计时长，到点自动弹窗 + 提示音 + 系统消息框
- **定时** — 指定时刻到点提醒，支持多个定时任务
- **提醒** — 设置提醒计划，到点触发通知
- **待办** — 轻量 TODO 管理，勾选完成

## 特性

- **托盘常驻** — 关闭窗口不退出，最小化到系统托盘，点击图标唤出
- **后台调度** — Rust 独立线程定时调度，窗口隐藏时仍准时触发提醒
- **原生弹窗** — 到点弹出 Windows 原生消息框（屏幕居中、置顶、系统提示音）
- **开机自启** — 支持注册开机自启动，静默托盘启动
- **绿色便携** — 数据存 exe 同目录 `data/` 文件夹，不写注册表、不污染 AppData
- **自动日期版本号** — 每次构建自动设为 `YY.M.D` 格式

## 截图

<div align="center">
  <table>
    <tr>
      <td align="center"><b>倒计时</b></td>
      <td align="center"><b>正计时</b></td>
      <td align="center"><b>待办</b></td>
    </tr>
    <tr>
      <td><img src="截图/计时.png" alt="正计时" width="260"></td>
      <td><img src="截图/提醒.png" alt="提醒" width="260"></td>
      <td><img src="截图/待办.png" alt="待办" width="260"></td>
    </tr>
  </table>
</div>

## 技术栈

| 层 | 技术 |
|---|---|
| 框架 | Tauri 2 |
| 前端 | Vue 3 + TypeScript + Vite + Pinia |
| 后端 | Rust |
| 存储 | 本地 JSON 文件（Tauri Store 插件） |
| 插件 | autostart / notification / store / shell / opener |

## 项目结构

```
FlashTime/
├── src/                  # 前端源码
│   ├── views/            # 五大功能视图
│   ├── components/       # 公共组件
│   ├── composables/      # 组合式函数
│   └── stores/          # Pinia 状态管理
├── src-tauri/            # Rust 后端
│   └── src/
│       ├── lib.rs        # 应用入口
│       ├── tray.rs      # 系统托盘
│       └── scheduler.rs  # 后台定时调度器
├── 截图/                  # 应用截图
└── release/              # 便携包输出目录
```

## 构建

> 构建前需安装 [Rust](https://rustup.rs) 和 [Node.js](https://nodejs.org)

双击 `build-portable.bat` 即可全流程构建，脚本自动完成：

1. 自动将版本号设为当天日期（`YY.M.D`）
2. 检查 Rust / Node.js 工具链
3. `npm install`（首次）
4. `tauri build` 编译 Rust + 打包前端
5. 生成便携 zip 到 `release/` 目录（含 exe + data/）

便携包为单 exe，数据存 exe 同目录 `data/flashtime.store.json`。

## License

MIT

> AI生成