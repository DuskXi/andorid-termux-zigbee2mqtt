#!/bin/bash
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$BASE_DIR/work"

echo "📋 === Zigbee2MQTT Running Status Check ==="

# 1. 检查物理 USB
USB=$(termux-usb -l | grep -oE '/dev/bus/usb/[0-9]+/[0-9]+')
if [ -n "$USB" ]; then
    echo "✅ USB Hardware: Connected ($USB)"
else
    echo "❌ USB Hardware: Not found"
fi

# 2. 检查硬件守护进程（改为全命令匹配，防止漏报）
PID_PTY=$(pgrep -f "ptyserial|sleep 86400")
if [ -n "$PID_PTY" ]; then
    echo "✅ Hardware Daemon (ptyserial): Running"
else
    echo "❌ Hardware Daemon (ptyserial): Stopped"
fi

# 3. 检查 socat 转发
PID_SOCAT=$(pgrep -x socat || pgrep -f "socat")
if [ -n "$PID_SOCAT" ]; then
    echo "✅ Serial Passthrough (socat): Running"
else
    echo "❌ Serial Passthrough (socat): Stopped"
fi

# 4. 检查 MQTT
PID_MQTT=$(pgrep -x mosquitto || pgrep -f "mosquitto")
if [ -n "$PID_MQTT" ]; then
    echo "✅ Message Queue (mosquitto): Running"
else
    echo "❌ Message Queue (mosquitto): Stopped"
fi

# 5. 检查 Z2M 后台进程
PID_Z2M=$(pgrep -f "node index.js" || pgrep -f "zigbee2mqtt")
if [ -n "$PID_Z2M" ]; then
    echo "✅ Zigbee2MQTT Main Service: Running (PID $PID_Z2M)"
else
    echo "❌ Zigbee2MQTT Main Service: Stopped"
fi

# 6. 检查 Z2M 控制台 WebUI（抛弃 netstat，使用纯 Bash /dev/tcp 原生探测）
if timeout 1 bash -c 'cat < /dev/null > /dev/tcp/127.0.0.1/8080' >/dev/null 2>&1; then
    echo "✅ Control Panel (WebUI): http://127.0.0.1:8080 accessible"
else
    echo "❌ Control Panel (WebUI): Offline"
fi

# 7. 提取日志状态
PTY=$(grep -o '/dev/pts/[0-9]*' "$WORK_DIR/usb_pty.log" 2>/dev/null | tail -n 1)
echo "📍 Current virtual serial port: ${PTY:-unknown}"

echo -e "\n📝 === Z2M Last 5 lines of log summary ==="
if [ -f "$WORK_DIR/zigbee2mqtt.log" ]; then
    tail -n 5 "$WORK_DIR/zigbee2mqtt.log"
else
    echo "(No log file)"
fi
echo "========================================"
