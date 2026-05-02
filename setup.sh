#!/bin/bash
set -e

# ==========================================
# 用户自定义配置
# ==========================================
CUSTOM_VID="0x1a86"
CUSTOM_PID="0x55d4"
TTY_HASH="aebb5af8c2ac6a831ca3de08969b183f3cf86bf7"
Z2M_HASH="4639243cf933cdae692c83dbd10bdb8dbecb6a6c"
# ==========================================

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$BASE_DIR/work"

echo "=================================================="
echo "🚀 正在部署 Zigbee2MQTT 极客环境 (增强版)"
echo "=================================================="

# 1. 安装依赖
echo -e "\n[1/4] 📦 正在安装核心依赖与 pnpm..."
pkg update -y
pkg install clang libusb make pkg-config git termux-api nodejs mosquitto socat ncurses-utils -y
npm install -g pnpm
echo "[✓] 依赖安装完成"

# 2. 编译底层
echo -e "\n[2/4] 🛠️ 正在编译底层 USB 驱动..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
if [ ! -d "Termux-serial-tty" ]; then
    git clone https://github.com/MarkWllms/Termux-serial-tty.git
fi
cd Termux-serial-tty
git checkout $TTY_HASH
make clean >/dev/null 2>&1 || true

echo "[...] 正在魔改 C++ 源码并编译..."
PATCH_FILE="src/ch34x.cpp"
if ! grep -qi "devid32($CUSTOM_VID, $CUSTOM_PID)" "$PATCH_FILE"; then
    sed -i "/devid32(0x1a86, 0x7523),/a \            devid32(${CUSTOM_VID}, ${CUSTOM_PID})," "$PATCH_FILE"
fi
make all
cp bin/libusbuart.so $PREFIX/lib/
make ptyserial
echo "[✓] ptyserial 编译成功"

# 3. 部署 Z2M
echo -e "\n[3/4] 🏠 正在通过 pnpm 安装 Zigbee2MQTT..."
cd "$WORK_DIR"
if [ ! -d "zigbee2mqtt" ]; then
    git clone https://github.com/Koenkk/zigbee2mqtt.git
fi
cd zigbee2mqtt
git checkout $Z2M_HASH
pnpm install
echo "[✓] Z2M 部署完成"

# 4. 配置初始化
echo -e "\n[4/4] ⚙️ 初始化配置..."
mkdir -p data
[ -f data/configuration.yaml ] || cat << 'EOF' > data/configuration.yaml
homeassistant: false
permit_join: true
mqtt:
  base_topic: zigbee2mqtt
  server: mqtt://127.0.0.1
serial:
  port: tcp://127.0.0.1:5000
  adapter: zstack
frontend:
  port: 8080
EOF
echo -e "listener 1883\nallow_anonymous true" > "$WORK_DIR/mosquitto.conf"

echo "=================================================="
echo "🎉 Setup 完成！请运行 ./enable.sh 启动"
echo "=================================================="