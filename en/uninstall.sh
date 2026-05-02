#!/bin/bash
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$BASE_DIR/work"

echo "========== ⚠️ WARNING: Environment Destruction Program =========="
read -p "This will delete all files under $WORK_DIR! Are you sure you want to continue? (y/N): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Operation cancelled."
    exit 0
fi

# 先执行一次安全停机
bash "$BASE_DIR/en/disable.sh" >/dev/null 2>&1

echo "[...] Erasing workspace..."
rm -rf "$WORK_DIR"

echo "💥 Destruction complete! System restored to a clean state."
