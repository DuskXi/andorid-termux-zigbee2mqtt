# 📱 Termux Zigbee2MQTT Pocket Toolkit
## —— An Android No-Root Geek Smart Home Gateway & Debugging Toolset

This project provides a suite of fully automated scripts that allow you to seamlessly run a complete Zigbee2MQTT (Z2M) environment on a normal, non-rooted Android phone.

### 🎯 Intent & Use Case
The core value of this project lies in: **Portability and Emergency Testing**.
When you don't carry a heavy Home Assistant (HA) host system, or when debugging on a new property or construction site, you only need this **non-rooted daily-use phone + a USB Zigbee coordinator module**. This allows you to quickly set up a temporary Zigbee2MQTT gateway anywhere, anytime, to test, pair, and verify any Zigbee devices (such as temperature/humidity sensors, switches, plugs, etc.) in the field.

---

## 📋 Test Environment & Versions Reference

To ensure the highest success rate when setting up the environment, the following hardware and software combinations have been tested and verified to work flawlessly by developers:
- **Test Phone**: Android phone used as a daily driver (No Root).
- **Zigbee Module**: TI CC2652 series coordinator paired with a domestic **CH9102** serial chip (USB VID: `0x1a86`, PID: `0x55d4`).
- **Adapter Protocol**: `zstack` (Z-Stack 3.x.0 firmware).
- **SerialPipe Tool**: Releases **v0.0.3**, source commit Hash: `5102b429335f48b0a1bb0ffd32917f28b53ac2e4`.

---

## 🛠️ First-Time Installation & Setup Guide

If this is your first time using this project, please follow the steps below carefully to ensure everything works smoothly:

### 1. App Environment Configuration
Before you begin, install the following three apps on your Android phone:
- **Termux**: The test environment selected the version downloaded from the Google Play Store, ensuring its signature is consistent with Termux:API.
- **Termux:API**: The test environment selected the version downloaded from the Google Play Store, ensuring its signature is consistent with Termux. Provides the API interface to access Android system features. Alternatively, install using `pkg install termux-api`, paying attention to version compatibility.
- **SerialPipe**: Go to `wh201906/SerialPipe` on GitHub, download, and install it. We recommend using Release **v0.0.3**. This app is used to release the Android system's low-level exclusive lock on the USB driver.

### 2. Physical Connection
Connect your Zigbee coordinator module (e.g., CC2652 + CH9102 gateway) to your phone using a USB OTG cable.

### 3. Fetching the Scripts & Editing Configuration
Open Termux and run the following commands to clone the repository and navigate to the English setup directory:
```bash
git clone https://github.com/DuskXi/andorid-termux-zigbee2mqtt.git
cd andorid-termux-zigbee2mqtt
chmod +x ./en/*.sh
```
If your chip's VID and PID are not the default `0x1a86` and `0x55d4` (CH9102), use a text editor to modify them:
```bash
# Open with nano, or you can use vi / vim
nano ./en/setup.sh
``` 
Change `CUSTOM_VID` and `CUSTOM_PID` at the top of the file, then save and exit.

### 4. One-Key Installation & Deployment
Run the installation script:
```bash
./en/setup.sh
```
> **💡 Note**: This step will install `pnpm` globally and compile a large amount of low-level C++ libraries. It takes about 5 to 10 minutes. During this process, please keep the screen awake and do not exit Termux or interrupt the process.

### 5. Launching the Gateway (Core Magic: Tug-of-War Strategy)
On your first run, and every time you re-plug the USB module, run the following command:
```bash
./en/enable.sh
```
The script will automatically bring up the `SerialPipe` app. Please follow these exact steps:

#### **🔄 SerialPipe "Tug-of-War" Action Guide:**
1. **Connect**: In the app, make sure the baud rate at the top is set to `115200`, then tap "Connect" or "Start Server".
2. **Release**: Wait for 1–2 seconds, tap "Disconnect" or "Stop Server", and then **switch back to Termux**.
3. **Continue**: In the Termux terminal interface, press the **Enter** key to continue.

#### **❓ Why is this step necessary? (How it works)**
- **The Problem**: When you plug in a USB serial gateway, Android's built-in kernel driver (such as `ch341.ko`) instantly recognizes and exclusively locks down the hardware. Without Root privileges, the driver inside Termux cannot forcibly snatch control from the kernel, and executing directly will result in a `Device or resource busy (Error 9)`.
- **The Workaround**: Android provides the official `UsbManager` API, which allows regular apps to claim hardware once the user manually grants permission via a pop-up prompt.
- **The Tug-of-War Logic**: We use the `SerialPipe` app to initiate a connection. When you tap "Connect", the system thinks: "Since the user explicitly allowed this app, I will kick the kernel driver out and hand hardware control over to this app." Then, we immediately disconnect. At this point, the app releases the hardware, but the kernel driver doesn't reclaim it instantly. The USB interface temporarily enters a **"no-man's-land state"**.
- **The Result**: Taking advantage of this momentary gap, our C++ daemon process in Termux steps in immediately. It legally takes over the hardware through the FD (file descriptor), allowing us to read and write to the USB device directly without root permissions.

---

## ✨ Features
- **No-Root Direct Hardware Access**: Leverages the official Termux wrapper to create native PTY virtual serial ports.
- **Custom Chip Whitelisting**: Automatically injects your domestic or non-standard Zigbee chip PID (e.g., `CH9102`) into the low-level C++ driver.
- **Automatic Lock Bypassing**: Bridges the terminal with a `socat` TCP listener to seamlessly avoid Node.js `/var/lock` permission errors.
- **Workspace Isolation**: All configs and source files are safely confined to an independent `work` directory without polluting the host Termux environment.
- **One-Key Liftoff, Monitoring & Cleanup**: Comes with simple scripts for taking off (`en/enable.sh`), landing (`disable.sh`), and tracking (`en/status.sh`).

---

## 🛠️ Prerequisites

### 1. Hardware
- An unused or daily-use Android phone.
- A USB OTG cable.
- A USB Zigbee coordinator module.

### 2. Software
- F-Droid version of **Termux** and **Termux:API**.
- The **SerialPipe** App.

---

## 🚀 Quick Start

### 1. Clone the repository
```bash
git clone https://github.com/DuskXi/andorid-termux-zigbee2mqtt.git
cd andorid-termux-zigbee2mqtt
cd en
chmod +x en/*.sh
```

### 2. Customize your chip IDs (Optional)
Use `nano`, `vi`, or `vim` to open the setup script, and modify the VID and PID at the very top.
```bash
vi en/setup.sh
```

### 3. One-key Installation
```bash
./en/setup.sh
```

---

## 🎮 Usage Guide

During daily use, you only need to interact with the following three scripts:

### 🟢 Start up: `./enable.sh`
Run this script after connecting your OTG gateway. Complete the "Connect -> Disconnect" tug-of-war maneuver in `SerialPipe`. The script will automatically background all services. It smartly polls the logs until initialization and handshaking are complete, preventing false failure reports.

### 🔵 Status Check: `./en/status.sh`
Review the status of the USB mount, hardware daemon, Socat forwarding, MQTT broker, and Z2M background process. Crucial for troubleshooting.

### 🔴 Stop down: `./disable.sh`
Safe shutdown. Safely kills all background services, releases all CPU wake locks, and clears memory to allow your phone to enter standard, battery-saving sleep modes.

### 💥 Uninstall: `./en/uninstall.sh`
Completely wipes the `work` directory and all linked configs to return to the original clean state.

---

## 🔧 Advanced Tweaks & Customization

To adapt the tools to different USB chips and custom Zigbee2MQTT configs, you can tweak the following:

### 1. Adding support for other domestic/non-standard chips
Since our backend relies on compiled C++, the USB chip PID whitelist is hard-coded into the driver source code. If you are using a different non-standard chip:
1. Open `en/setup.sh` in your text editor.
2. Find `CUSTOM_VID` and `CUSTOM_PID` at the top of the file.
3. Change them to your chip's actual IDs. The injection logic in our script will insert these new IDs directly into the initialization `table[]` inside the `Termux-serial-tty/src/ch34x.cpp` source file and automatically compile a fresh `.so` file.

### 2. Modifying Z2M configurations for different hardware
By default, the script creates a configuration for TI CC2652 series chips (running Z-Stack firmware). If you are using a coordinator with a different protocol (such as Silicon Labs' `ezsp` / `ember` firmware):
1. Open `work/zigbee2mqtt/data/configuration.yaml` with an editor:
   ```bash
   nano work/zigbee2mqtt/data/configuration.yaml
   ```
2. Find the `serial` section and adapt it to your hardware:
    - Protocol adapter change: Change `adapter: zstack` to `adapter: ezsp` or `adapter: ember`.
    - Baud rate change: If your hardware requires it, add `baudrate: 115200` (or your device's specific baud rate) under `serial`.

---

## ⚠️ Troubleshooting 

### Zigbee2MQTT crashes after a few minutes (Timeout)?
- **Cause**: Android's battery Doze mode froze Termux's background network.
- **Solution**: Navigate to your phone's **Settings -> App Management -> Termux -> Battery Management**, and change it to **"Unrestricted"** or allow background power usage. Our `en/enable.sh` calls `termux-wake-lock` automatically to prevent sleep issues.

### `en/setup.sh` reports `Error 6` while compiling `ptyserial`?
- **Cause**: Your Zigbee module's PID is not included in the source code whitelist.
- **Solution**: Verify your chip IDs, change `CUSTOM_VID` and `CUSTOM_PID` at the top of `en/setup.sh`, and run it again.

---

## 🤝 Acknowledgments
- `MarkWllms/Termux-serial-tty` for the core low-level hardware bridging concept.
- `Koenkk/zigbee2mqtt` for the powerful open-source Zigbee ecosystem.
- `wh201906/SerialPipe` for the vital USB serial utility. This project adopts its Releases **v0.0.3** (Commit Hash: `5102b429335f48b0a1bb0ffd32917f28b53ac2e4`) as a key tool to cleanly pry open system driver permissions.
