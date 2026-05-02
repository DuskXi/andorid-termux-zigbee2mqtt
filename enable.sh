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

# 5. 后台启动主程序 (pnpm) 并清空旧日志
echo "[🚀] 正在后台拉起 Zigbee2MQTT 主进程..."
cd "$WORK_DIR/zigbee2mqtt"
> "$WORK_DIR/zigbee2mqtt.log" # 抹除旧日志
nohup pnpm start > "$WORK_DIR/zigbee2mqtt.log" 2>&1 &

Z2M_PID=$!

# 🔄 6. 智能循环轮询，等待服务完全加载
echo -n "[...] 正在等待 Z2M 完成初始化与握手"
MAX_RETRIES=30
COUNT=0
SUCCESS=false

while [ $COUNT -lt $MAX_RETRIES ]; do
    # A. 检查 PID 状态：如果 Z2M 进程提前挂了，直接终止循环
    if ! kill -0 "$Z2M_PID" 2>/dev/null; then
        echo -e "\n❌ 糟糕：Zigbee2MQTT 进程在启动阶段异常崩溃！"
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
    echo "🎉 所有底层服务已成功挂起至后台静默运行！"
    echo "📊 你现在可以关闭这个终端，或运行 ./status.sh 查看状态"
    echo "📝 Z2M 运行日志保存在: work/zigbee2mqtt.log"
    echo "==============================================="
else
    echo "==============================================="
    echo "❌ Z2M 后台拉起失败或启动超时！"
    echo "👉 请查看最后 10 行日志寻找线索："
    echo "-----------------------------------------------"
    tail -n 10 "$WORK_DIR/zigbee2mqtt.log"
    echo "==============================================="
fi
