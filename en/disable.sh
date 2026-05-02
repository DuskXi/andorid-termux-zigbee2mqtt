#!/bin/bash
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "========== Safely cleaning up background environment =========="

# 1. 强制杀死 Z2M 及其孵化的 Node 进程
echo "[...] Stopping Node.js (Zigbee2MQTT)..."
pkill -f "zigbee2mqtt" >/dev/null 2>&1 || true
pkill node >/dev/null 2>&1 || true

# 2. 杀掉中间件 (全面改用 pkill -f 精准匹配进程命令行)
echo "[...] Stopping Socat and Mosquitto..."
pkill -f "socat" >/dev/null 2>&1 || true
pkill -f "mosquitto" >/dev/null 2>&1 || true

# 3. 释放底层 PTY 和 USB
echo "[...] Releasing low-level USB hardware lock..."
pkill -f "ptyserial" >/dev/null 2>&1 || true
pkill -f "sleep 86400" >/dev/null 2>&1 || true

# 4. 释放系统唤醒锁
echo "[...] Releasing system wakelock..."
termux-wake-unlock >/dev/null 2>&1 || true

echo "=============================================="
echo "🧹 Cleanup complete! Port 5000 and background services have been fully released."
echo "=============================================="
