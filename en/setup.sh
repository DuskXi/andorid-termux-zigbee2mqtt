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

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$BASE_DIR/work"

echo "=================================================="
echo "🚀 Deploying Zigbee2MQTT Geek Environment (Enhanced Version)"
echo "=================================================="

# 1. 安装依赖
echo -e "\n[1/4] 📦 Installing core dependencies and pnpm..."
pkg update -y
pkg install clang libusb make pkg-config git termux-api nodejs mosquitto socat ncurses-utils -y
npm install -g pnpm
echo "[✓] Dependencies installed"

# 2. 编译底层
echo -e "\n[2/4] 🛠️ Compiling low-level USB driver..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
if [ ! -d "Termux-serial-tty" ]; then
    git clone https://github.com/MarkWllms/Termux-serial-tty.git
fi
cd Termux-serial-tty
git checkout $TTY_HASH
make clean >/dev/null 2>&1 || true

echo "[...] Patching C++ source and compiling..."
PATCH_FILE="src/ch34x.cpp"
if ! grep -qi "devid32($CUSTOM_VID, $CUSTOM_PID)" "$PATCH_FILE"; then
    sed -i "/devid32(0x1a86, 0x7523),/a \            devid32(${CUSTOM_VID}, ${CUSTOM_PID})," "$PATCH_FILE"
fi
make all
cp bin/libusbuart.so $PREFIX/lib/
make ptyserial
echo "[✓] ptyserial compiled successfully"

# 3. 部署 Z2M
echo -e "\n[3/4] 🏠 Installing Zigbee2MQTT via pnpm..."
cd "$WORK_DIR"
if [ ! -d "zigbee2mqtt" ]; then
    git clone https://github.com/Koenkk/zigbee2mqtt.git
fi
cd zigbee2mqtt
git checkout $Z2M_HASH
pnpm install
echo "[✓] Z2M deployment complete"

# 4. 配置初始化
echo -e "\n[4/4] ⚙️ Initializing configuration..."
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
echo "🎉 Setup complete! Please run ./enable.sh to start"
echo "=================================================="
