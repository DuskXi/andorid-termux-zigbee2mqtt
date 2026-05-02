#!/bin/bash
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$BASE_DIR/work"

echo "========== Zigbee2MQTT 后台一键起飞 =========="

# 1. 环境准备与彻底清场
termux-wake-lock
pkill node >/dev/null 2>&1 || true
pkill ptyserial >/dev/null 2>&1 || true
pkill -f "sleep 86400" >/dev/null 2>&1 || true
killall socat >/dev/null 2>&1 || true
killall mosquitto >/dev/null 2>&1 || true

# 2. 唤起 App
echo "[!] 正在尝试唤起 SerialPipe..."
if ! am start --user 0 -n io.github.wh201906.serialpipe/.MainActivity >/dev/null 2>&1; then
    echo "=================================================="
    echo "❌ 启动失败！未能找到 SerialPipe。"
    echo "👉 请先安装并授予 USB 权限后，再重新运行此脚本！"
    echo "=================================================="
    exit 1
fi

echo "[!] 请在 App 中执行『开启再关闭』的拔河操作，释放内核占用！"
read -p ">> 拔河完成后按回车继续..."

# 3. 硬件挂载
USB_PATH=$(termux-usb -l | grep -oE '/dev/bus/usb/[0-9]+/[0-9]+' | head -n 1)
if [ -z "$USB_PATH" ]; then echo "❌ 找不到 USB，请检查 OTG！"; exit 1; fi

LOG_FILE="$WORK_DIR/usb_pty.log"
termux-usb -r -e "$WORK_DIR/Termux-serial-tty/ptyserial sleep 86400" $USB_PATH > "$LOG_FILE" 2>&1 &
sleep 2

PTY_PATH=$(grep -o '/dev/pts/[0-9]*' "$LOG_FILE" | head -n 1)
if [ -z "$PTY_PATH" ]; then 
    echo "❌ PTY 创建失败，请查看日志："
    cat "$LOG_FILE"
    exit 1
fi
echo "[✓] 原生串口直通: $PTY_PATH"

# 4. 启动后端服务
socat TCP-LISTEN:5000,fork,reuseaddr $PTY_PATH,raw,echo=0 &
mosquitto -c "$WORK_DIR/mosquitto.conf" >/dev/null 2>&1 &
echo "[✓] Socat 与 Mosquitto 已就绪"

# 5. 后台启动主程序 (pnpm)
echo "[🚀] 正在后台拉起 Zigbee2MQTT 主进程..."
cd "$WORK_DIR/zigbee2mqtt"
nohup pnpm start > "$WORK_DIR/zigbee2mqtt.log" 2>&1 &

# 稍等 2 秒让它建立起进程，以便确认是否启动成功
sleep 2
if pgrep -f "zigbee2mqtt" >/dev/null || pgrep -f "node index.js" >/dev/null; then
    echo "==============================================="
    echo "🎉 所有底层服务已成功挂起至后台静默运行！"
    echo "📊 你现在可以关闭这个终端，或运行 ./status.sh 查看状态"
    echo "📝 Z2M 运行日志保存在: work/zigbee2mqtt.log"
    echo "==============================================="
else
    echo "❌ Z2M 后台拉起失败，请检查 work/zigbee2mqtt.log 里的报错信息。"
fi