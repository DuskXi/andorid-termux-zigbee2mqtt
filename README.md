# 📱 基于 Termux 的 Zigbee2MQTT Zigbee 设备移动调试工具脚本集 (Termux Zigbee2MQTT Pocket Toolkit)
## —— 安卓免 Root 极客智能家居网关工具集

👉 [English Version / 英文文档](README_EN.md)

本项目提供了一套全自动化脚本，能让你在没有任何 Root 权限的正常使用的安卓手机上，完美运行完整的 Zigbee2MQTT (Z2M) 环境。

### 🎯 项目初衷与用途
本方案的核心价值在于：**便携与应急测试**。
在没有携带笨重的 Home Assistant (HA) 主机系统、或在新房/施工现场调试时，你只需利用这台 **不想 Root 的日常手机 + 一个 USB Zigbee 协调器模块**，即可随时随地搭建起临时的 Zigbee2MQTT 网关，在外快速测试、配对并验证任何 Zigbee 设备（如温湿度传感器、开关、插座等）。

---

## 📋 测试环境与版本参考

为了保证环境搭建的成功率，以下为开发者实际测试并完美运行的软硬件组合：
- **测试手机**：Android 正常使用的主力机（未进行 Root）。
- **Zigbee 模块**：基于 TI CC2652 系列芯片的协调器，配合国产 **CH9102** 串口芯片（USB VID: `0x1a86`, PID: `0x55d4`）。
- **适配协议**：`zstack` (Z-Stack 3.x.0 固件)。
- **SerialPipe 串口工具**：Releases **v0.0.3**，源码提交 Hash 为 `5102b429335f48b0a1bb0ffd32917f28b53ac2e4`。

---

## 🛠️ 初次安装与运行手把手教程 (Getting Started)

如果你是第一次使用本项目，请严格按照以下步骤操作，确保每一步都执行成功：

### 1. 软件环境配置
在开始前，请在你的 Android 手机上安装以下三个软件：
- **Termux**：测试环境选择了从Google Play商店下载的版本，确保其签名与 Termux:API 保持一致。
- **Termux:API**：测试环境选择了从 Google Play 商店下载的版本，确保其签名与 Termux 保持一致。提供访问 Android 系统功能的 API 接口。或使用pkg install termux-api安装，注意版本兼容性。
- **SerialPipe**：前往 `wh201906/SerialPipe` 下载并安装，推荐使用 Release **v0.0.3**。用于释放 Android 系统对 USB 驱动的底层独占。

### 2. 物理连接
使用 OTG 转接线将你的 Zigbee 协调器模块（如：基于 CC2652 + CH9102 的网关）插入手机。

### 3. 获取套件与编辑配置
打开 Termux，运行以下命令克隆仓库：
```bash
git clone https://github.com/DuskXi/andorid-termux-zigbee2mqtt.git
cd andorid-termux-zigbee2mqtt
chmod +x *.sh
```
若你的芯片 VID 和 PID 不是默认的 `0x1a86` 和 `0x55d4` (CH9102)，请使用文本编辑器进行修改：
```bash
# 使用 nano 修改，也可以使用 vi 或 vim
nano setup.sh
```
在文件顶部修改 `CUSTOM_VID` 和 `CUSTOM_PID` 后保存退出。

### 4. 一键安装部署
运行安装脚本：
```bash
./setup.sh
```
> **💡 注意**：此过程会安装全局 `pnpm` 并编译大量 C++ 底层库，耗时约 5-10 分钟。在此期间请保持手机屏幕常亮，请勿切出 Termux 或中断进程。

### 5. 启动网关服务（核心玄学：拔河战术）
初次运行以及后续每次重新拔插 USB 模块后，请执行以下命令：
```bash
./enable.sh
```
此时，脚本会自动唤起 `SerialPipe` App，请严格按照以下步骤操作：

#### **🔄 SerialPipe “拔河战术” 操作指南：**
1. **连接 (Claim)**：在 App 顶部波特率确认为 `115200`，点击“连接”或“启动服务”。
2. **释放 (Release)**：等待 1-2 秒，点击“断开”或“停止服务”，然后**彻底切回 Termux**。
3. **继续**：在 Termux 终端界面中，按下 **Enter (回车) 键** 继续。

#### **❓ 为什么需要这一步操作？（原理解析）**
- **痛点**：当你插入 USB 串口网关时，Android 内核自带的驱动（如 `ch341.ko`）会瞬间识别并死死占满、独占这个硬件。由于没有 Root 权限，Termux 中的驱动无法强行从系统内核手中抢夺控制权，直接运行会导致 `Device or resource busy (Error 9)`。
- **破局**：Android 系统提供了官方的 `UsbManager` API，允许普通 App 通过用户手动点击弹窗授权来接管硬件。
- **拔河逻辑**：我们借助 `SerialPipe` App 向系统发起连接。当你点击“连接”时，系统认为“既然用户手动允许了这个 App，那我就把内核驱动挤掉，把硬件控制权交给该 App”。紧接着，我们手动断开连接。此时，App 释放了硬件，但内核驱动不会立刻返回，USB 接口正处于短暂的 **“无主状态”**。
- **结果**：趁此空档，Termux 的 C++ 守护进程瞬间趁虚而入，通过 FD 文件描述符合法接管硬件，实现了对 USB 硬件的原生读写，完美避开独占限制。

---

## ✨ 特性
- **免 Root 直通硬件**：利用 Termux 官方包裹器生成原生 PTY 虚拟串口。
- **自定义芯片白名单**：自动向 C++ 底层驱动注入你的国产/非标 Zigbee 芯片 PID（如 `CH9102`）。
- **自动穿透锁机制**：使用 `socat` TCP 桥接，完美避开 Node.js 的 `/var/lock` 权限拒绝问题。
- **工作区隔离**：所有配置和源码均放置于独立 `work` 目录，不污染 Termux 宿主环境。
- **一键启停巡检**：配备极简的起飞 (`enable.sh`)、降落 (`disable.sh`) 与大屏监控 (`status.sh`) 脚本。

---

## 🛠️ 准备工作

### 1. 硬件准备
- 一台闲置的安卓手机。
- 一根 OTG 转接线。
- 一个 USB Zigbee 协调器模块。

### 2. 软件准备
- 安装GooglePlay/F-Droid 版本的 **Termux** 和 **Termux:API**。
- 安装 **SerialPipe** App。

---

## 🚀 快速开始

### 1. 获取套件
```bash
git clone https://github.com/DuskXi/andorid-termux-zigbee2mqtt.git
cd andorid-termux-zigbee2mqtt
chmod +x *.sh
```

### 2. 自定义你的芯片 (可选)
使用 `nano`、`vi` 或 `vim` 打开安装脚本，在顶部修改你的芯片 VID 和 PID。
```bash
vi setup.sh
```

### 3. 一键装机
```bash
./setup.sh
```

---

## 🎮 使用说明

日常使用时，你只需要用到以下三个脚本：

### 🟢 起飞：`./enable.sh`
插入 OTG 网关后运行此脚本，并通过 `SerialPipe` 完成“开启连接 -> 断开连接”的拔河操作。脚本会自动将服务挂起在后台静默运行，并智能轮询日志文件，直到服务初始化握手完成，彻底防范误判。

### 🔵 巡检：`./status.sh`
查看当前 USB 挂载情况、硬件守护进程、Socat 转发状态、MQTT 消息队列以及 Z2M 后台状态。排错必备。

### 🔴 降落：`./disable.sh`
安全停机，杀死所有后台关联服务，释放所有 CPU 唤醒锁，清理后台内存，让手机恢复正常的省电休眠模式。

### 💥 销毁：`./uninstall.sh`
彻底抹除 `work` 目录及相关配置，恢复到安装前的洁净状态。

---

## 🔧 高级修改与自定义指南

为了适配更多不同的 USB 芯片 and Zigbee2MQTT 配置，你可以通过以下方式进行二次魔改：

### 1. 如何增加其他国产/非标芯片支持？
由于本项目底层基于 C++ 编译，所有的 USB 芯片 PID 白名单都硬编码在驱动源码中。如果你使用的是其他非标准的芯片：
1. 用文本编辑器打开 `setup.sh`。
2. 找到文件顶部的 `CUSTOM_VID` 和 `CUSTOM_PID`。
3. 将其修改为你芯片的真实 ID。脚本中包含的魔改逻辑会自动将这行 ID 注入到 `Termux-serial-tty/src/ch34x.cpp` 源码文件的 `table[]` 初始化列表中并重新编译生成 `.so` 文件。

### 2. 如何修改 Z2M 配置文件以适配不同设备？
默认配置适配的是基于 TI CC2652 系列芯片（使用 Z-Stack 固件）的网关。如果你使用的是其他协议的芯片（例如基于 Silicon Labs 的 `ezsp` / `ember` 固件网关）：
1. 用编辑器打开 `work/zigbee2mqtt/data/configuration.yaml`：
   ```bash
   nano work/zigbee2mqtt/data/configuration.yaml
   ```
2. 找到 `serial` 段落，根据你的硬件进行修改：
   - 适配器协议更改：修改 `adapter: zstack` 为 `adapter: ezsp` 或 `adapter: ember`。
   - 波特率更改：如果硬件需要，在 `serial` 下加入 `baudrate: 115200`（或其他特定波特率）。

---

## ⚠️ 避坑指南 (Troubleshooting) 

### Zigbee2MQTT 运行几分钟后突然崩溃（Timeout）？
- **原因**：安卓系统的电池 Doze 模式冻结了 Termux 的后台网络。
- **解决**：前往手机的 **设置 -> 应用管理 -> Termux -> 电池/耗电管理**，将其设置为 **“无限制”** 或允许后台高耗电运行。本套件的 `enable.sh` 已默认调用 `termux-wake-lock` 防休眠。

### `setup.sh` 编译 `ptyserial` 时报 `Error 6`？
- **原因**：你的 Zigbee 模块 PID 没有在源码白名单中。
- **解决**：确认并修改 `setup.sh` 顶部的 `CUSTOM_VID` 和 `CUSTOM_PID` 后重新运行。

---

## 🤝 致谢
- `MarkWllms/Termux-serial-tty` 提供底层硬件桥接思路。
- `Koenkk/zigbee2mqtt` 强大的开源网关生态。
- `wh201906/SerialPipe` 提供关键的 USB 串口工具。本项目利用该软件 Releases **v0.0.3**（Hash: `5102b429335f48b0a1bb0ffd32917f28b53ac2e4`）作为“踢走”系统底层占用的破局工具，非常规经典用法。
