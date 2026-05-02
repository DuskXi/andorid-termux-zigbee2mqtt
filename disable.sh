#!/bin/bash
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========== 正在安全清理后台环境 =========="

# 1. 强制杀死 Z2M 及其孵化的 Node 进程
echo "[...] 停止 Node.js (Z2M)..."
pkill -f "zigbee2mqtt" >/dev/null 2>&1 || true
pkill node >/dev/null 2>&1 || true

# 2. 杀掉中间件
echo "[...] 停止 Socat 与 Mosquitto..."
killall socat >/dev/null 2>&1 || true
killall mosquitto >/dev/null 2>&1 || true

# 3. 释放底层 PTY 和 USB
echo "[...] 释放底层 USB 硬件锁定..."
pkill ptyserial >/dev/null 2>&1 || true
pkill -f "sleep 86400" >/dev/null 2>&1 || true

# 4. 释放系统唤醒锁
echo "[...] 释放系统电池唤醒锁..."
termux-wake-unlock >/dev/null 2>&1 || true

echo "=============================================="
echo "🧹 清理完成！所有后台服务已全部下课，手机恢复省电。"
echo "=============================================="