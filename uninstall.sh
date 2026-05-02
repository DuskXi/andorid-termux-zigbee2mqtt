#!/bin/bash
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$BASE_DIR/work"

echo "========== ⚠️ 警告：环境销毁程序 =========="
read -p "这将会删除 $WORK_DIR 目录下的所有文件！确定继续吗？(y/N): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "操作已取消。"
    exit 0
fi

# 先执行一次安全停机
bash "$BASE_DIR/disable.sh" >/dev/null 2>&1

echo "[...] 正在抹除工作区..."
rm -rf "$WORK_DIR"

echo "💥 销毁完成！系统已恢复洁净状态。"