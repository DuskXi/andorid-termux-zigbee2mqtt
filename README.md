# 📱 Termux Zigbee2MQTT Pocket Edition
## —— 安卓免 Root 极客智能家居网关发行版

本项目提供了一套全自动化脚本，能让你在没有任何 Root 权限的废旧安卓手机上，完美运行完整的 Zigbee2MQTT (Z2M) 环境。通过底层的 C++ 源码魔改与本地 Socket 转发，彻底绕过安卓内核的 USB 独占锁与 Node.js 串口库的权限墙。

## ✨ 特性
- **免 Root 直通硬件**：利用 Termux 官方包裹器生成原生 PTY 虚拟串口。
- **自定义芯片白名单**：自动向 C++ 底层驱动注入你的国产/非标 Zigbee 芯片 PID（如 `CH9102`）。
- **自动穿透锁机制**：使用 `socat` TCP 桥接，完美避开 Node.js 的 `/var/lock` 权限拒绝问题。
- **工作区隔离**：所有配置和源码均放置于独立 `work` 目录，不污染 Termux 宿主环境。
- **一键启停巡检**：配备极简的起飞 (`enable.sh`)、降落 (`disable.sh`) 与大屏监控 (`status.sh`) 脚本。

## 🛠️ 准备工作
### 1. 硬件准备
- 一台闲置的安卓手机。
- 一根 OTG 转接线。
- 一个 USB Zigbee 协调器模块（如：基于 CC2652 + CH9102 的网关）。

### 2. 软件准备（⚠️ 极度重要）
- **安装真正的 Termux**：绝对不要从 Google Play 下载（已废弃）！请务必从 F-Droid 下载最新版。
- **安装 Termux:API**：同样需要从 F-Droid 下载，并确保与 Termux 是相同的签名。
- **安装 SerialPipe**：请前往 `wh201906/SerialPipe` 下载并安装此 App（用于后续的“拔河战术”释放内核占用）。

## 🚀 快速开始
### 1. 获取套件
在手机 Termux 中执行以下命令克隆本仓库：

``bash
git clone https://github.com/你的用户名/你的仓库名.git cd 你的仓库名
chmod +x *.sh
``

### 2. 自定义你的芯片 (可选)
使用 `nano setup.sh` 打开安装脚本，在顶部修改你的芯片 VID 和 PID。默认配置为 `0x1a86` 和 `0x55d4` (`CH9102`)。

### 3. 一键装机
``bash
./setup.sh
``
(注意：此过程会安装全局 `pnpm` 并编译大量 C++ 底层库，可能耗时 5-10 分钟，请确保手机屏幕常亮，绝对不要切到后台或中断进程！)

## 🎮 使用说明
日常使用时，你只需要用到以下三个脚本：

### 🟢 起飞：`./enable.sh`
插入 OTG 网关后运行此脚本。【核心玄学：拔河战术】
脚本运行中途会弹起 SerialPipe App。请在 App 中执行 “开启连接 -> 断开连接” 的操作。原理：借助安卓原生 API 合法抢走内核的 `ch341` 驱动占用，断开后 USB 接口变为无主状态，此时 Termux 原生 C++ 驱动即可瞬间接管硬件！

### 🔵 巡检：`./status.sh`
在新的 Termux 会话中运行。它会为你展示当前 USB 挂载情况、守护进程状态、Socat 转发状态以及 Z2M 前端 WebUI 状态。排错必备。

### 🔴 降落：`./disable.sh`
安全停机，释放所有 CPU 唤醒锁，清理僵尸进程，让手机恢复正常的省电休眠模式。

### 💥 销毁：`./uninstall.sh`
彻底抹除 `work` 目录及相关配置，恢复到安装前的洁净状态。

## ⚠️ 避坑指南 (Troubleshooting)
### 执行脚本报 `$'\r': command not found` 错误？
- **原因**：在 Windows 系统 (VS Code) 下编写/修改的脚本带有 CRLF 换行符，而 Linux 只认 LF。
- **解决**：在 Termux 中运行 `sed -i 's/\r$//' *.sh` 洗掉多余的回车符。未来开发请务必将 IDE 右下角的换行符切换为 LF。

### Zigbee2MQTT 运行几分钟后突然崩溃（Timeout）？
- **原因**：安卓系统的电池 Doze 模式冻结了 Termux 的后台网络。
- **解决**：前往手机的 **设置 -> 应用管理 -> Termux -> 电池/耗电管理**，将其设置为 “无限制” 或允许后台高耗电运行。本套件的 `enable.sh` 已默认调用 `termux-wake-lock` 防休眠。

### `setup.sh` 编译 `ptyserial` 时报 `Error 6`？
- **原因**：你的 Zigbee 模块 PID 没有在源码白名单中。
- **解决**：确认并修改 `setup.sh` 顶部的 `CUSTOM_VID` 和 `CUSTOM_PID` 后重新运行。

## 🤝 致谢
- `MarkWllms/Termux-serial-tty` 提供底层硬件桥接思路。
- `Koenkk/zigbee2mqtt` 强大的开源网关生态。
