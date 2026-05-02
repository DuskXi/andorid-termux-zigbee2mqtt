#!/bin/bash
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$BASE_DIR/work"

echo "========== Zigbee2MQTT One-click Start =========="

# 1. 环境准备与彻底清场
termux-wake-lock
pkill node >/dev/null 2>&1 || true
pkill ptyserial >/dev/null 2>&1 || true
pkill -f "sleep 86400" >/dev/null 2>&1 || true
killall socat >/dev/null 2>&1 || true
killall mosquitto >/dev/null 2>&1 || true

# 2. 唤起 App
echo "[!] Attempting to wake up SerialPipe..."
if ! am start --user 0 -n io.github.wh201906.serialpipe/.MainActivity >/dev/null 2>&1; then
    echo "=================================================="
    echo "❌ Startup failed! SerialPipe not found."
    echo "👉 Please install and grant USB permissions, then run this script again!"
    echo "=================================================="
    exit 1
fi

echo "[!] Please perform 'open and close' in the App to release kernel occupation!"
read -p ">> Press Enter to continue after completion..."

# 3. 硬件挂载
USB_PATH=$(termux-usb -l | grep -oE '/dev/bus/usb/[0-9]+/[0-9]+' | head -n 1)
if [ -z "$USB_PATH" ]; then echo "❌ USB not found, please check OTG connection!"; exit 1; fi

LOG_FILE="$WORK_DIR/usb_pty.log"
termux-usb -r -e "$WORK_DIR/Termux-serial-tty/ptyserial sleep 86400" $USB_PATH > "$LOG_FILE" 2>&1 &
sleep 2

PTY_PATH=$(grep -o '/dev/pts/[0-9]*' "$LOG_FILE" | head -n 1)
if [ -z "$PTY_PATH" ]; then
    echo "❌ PTY creation failed, please check the log:"
    cat "$LOG_FILE"
    exit 1
fi
echo "[✓] Native serial passthrough: $PTY_PATH"

# 4. 启动后端服务
socat TCP-LISTEN:5000,fork,reuseaddr $PTY_PATH,raw,echo=0 &
mosquitto -c "$WORK_DIR/mosquitto.conf" >/dev/null 2>&1 &
echo "[✓] Socat and Mosquitto are ready"

# 5. 后台启动主程序 (pnpm) 并清空旧日志
echo "[🚀] Starting Zigbee2MQTT main process in background..."
cd "$WORK_DIR/zigbee2mqtt"
> "$WORK_DIR/zigbee2mqtt.log" # 抹除旧日志
nohup pnpm start > "$WORK_DIR/zigbee2mqtt.log" 2>&1 &

Z2M_PID=$!

# 🔄 6. 智能循环轮询，等待服务完全加载
echo -n "[...] Waiting for Z2M to initialize and handshake"
MAX_RETRIES=30
COUNT=0
SUCCESS=false

while [ $COUNT -lt $MAX_RETRIES ]; do
    # A. 检查 PID 状态：如果 Z2M 进程提前挂了，直接终止循环
    if ! kill -0 "$Z2M_PID" 2>/dev/null; then
        echo -e "\n❌ Oops: Zigbee2MQTT process crashed during startup!"
        break
    fi

    # B. 检查日志：看是否打印出了成功上线的字样
    if grep -q "Zigbee2MQTT started!" "$WORK_DIR/zigbee2mqtt.log"; then
        SUCCESS=true
        break
    fi

    # C. 打印进度点
    echo -n "."
    sleep 1
    COUNT=$((COUNT + 1))
done

echo "" # 换行

# 7. 最终判决
if [ "$SUCCESS" = true ]; then
    echo "==============================================="
    echo "🎉 All underlying services successfully started in the background!"
    echo "📊 You can now close this terminal, or run ./status.sh to view status"
    echo "📝 Z2M logs are saved in: work/zigbee2mqtt.log"
    echo "==============================================="
else
    echo "==============================================="
    echo "❌ Failed to start Z2M in the background or startup timed out!"
    echo "👉 Please check the last 10 lines of the log for clues:"
    echo "-----------------------------------------------"
    tail -n 10 "$WORK_DIR/zigbee2mqtt.log"
    echo "==============================================="
fi
