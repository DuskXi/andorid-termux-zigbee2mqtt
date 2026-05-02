#!/bin/bash
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$BASE_DIR/work"

echo "📋 === Zigbee2MQTT 运行状态巡检 ==="

# 1. 检查物理 USB
USB=$(termux-usb -l | grep -oE '/dev/bus/usb/[0-9]+/[0-9]+')
if [ -n "$USB" ]; then
    echo "✅ USB 硬件: 已连接 ($USB)"
else
    echo "❌ USB 硬件: 未找到"
fi

# 2. 检查硬件守护进程（改为全命令匹配，防止漏报）
PID_PTY=$(pgrep -f "ptyserial|sleep 86400")
if [ -n "$PID_PTY" ]; then
    echo "✅ 硬件守护 (ptyserial): 运行中"
else
    echo "❌ 硬件守护 (ptyserial): 停止"
fi

# 3. 检查 socat 转发
PID_SOCAT=$(pgrep -x socat || pgrep -f "socat")
if [ -n "$PID_SOCAT" ]; then
    echo "✅ 串口转发 (socat): 运行中"
else
    echo "❌ 串口转发 (socat): 停止"
fi

# 4. 检查 MQTT
PID_MQTT=$(pgrep -x mosquitto || pgrep -f "mosquitto")
if [ -n "$PID_MQTT" ]; then
    echo "✅ 消息队列 (mosquitto): 运行中"
else
    echo "❌ 消息队列 (mosquitto): 停止"
fi

# 5. 检查 Z2M 后台进程
PID_Z2M=$(pgrep -f "node index.js" || pgrep -f "zigbee2mqtt")
if [ -n "$PID_Z2M" ]; then
    echo "✅ Zigbee2MQTT 主服务: 运行中 (PID $PID_Z2M)"
else
    echo "❌ Zigbee2MQTT 主服务: 停止"
fi

# 6. 检查 Z2M 控制台 WebUI（抛弃 netstat，使用纯 Bash /dev/tcp 原生探测）
if timeout 1 bash -c 'cat < /dev/null > /dev/tcp/127.0.0.1/8080' >/dev/null 2>&1; then
    echo "✅ 控制面板 (WebUI): http://127.0.0.1:8080 可正常访问"
else
    echo "❌ 控制面板 (WebUI): 离线"
fi

# 7. 提取日志状态
PTY=$(grep -o '/dev/pts/[0-9]*' "$WORK_DIR/usb_pty.log" 2>/dev/null | tail -n 1)
echo "📍 当前使用的虚拟串口: ${PTY:-未知}"

echo -e "\n📝 === Z2M 最近 5 行日志摘要 ==="
if [ -f "$WORK_DIR/zigbee2mqtt.log" ]; then
    tail -n 5 "$WORK_DIR/zigbee2mqtt.log"
else
    echo "（暂无日志文件）"
fi
echo "========================================"