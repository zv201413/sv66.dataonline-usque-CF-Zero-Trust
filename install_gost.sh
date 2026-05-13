#!/bin/bash
set -e
PROJECT_DIR=$(pwd)
GOST_VER="3.0.0-rc10"
GOST_URL="https://github.com/go-gost/gost/releases/download/v${GOST_VER}/gost_${GOST_VER}_linux_amd64.tar.gz"

echo "目标目录: $PROJECT_DIR"
echo "[1/2] 正在下载 GOST..."
curl -L "$GOST_URL" -o "$PROJECT_DIR/gost.tar.gz"

echo "[2/2] 正在解压..."
tar -xzf "$PROJECT_DIR/gost.tar.gz" -C "$PROJECT_DIR" gost
rm "$PROJECT_DIR/gost.tar.gz"
chmod +x "$PROJECT_DIR/gost"

echo "---------------------------------------"
echo "成功！gost 已下载并赋予权限。"
