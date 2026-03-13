#!/bin/bash
set -e

PROJECT_DIR=$(pwd)

# 1. 下载 GOST
GOST_VER="3.0.0-rc10"
GOST_URL="https://github.com/go-gost/gost/releases/download/v${GOST_VER}/gost_${GOST_VER}_linux_amd64.tar.gz"

echo "[1/2] 正在安装 GOST..."
curl -L "$GOST_URL" -o "$PROJECT_DIR/gost.tar.gz"
tar -xzf "$PROJECT_DIR/gost.tar.gz" -C "$PROJECT_DIR" gost
rm "$PROJECT_DIR/gost.tar.gz"
chmod +x "$PROJECT_DIR/gost"

# 2. 下载 usque
USQUE_VER="1.4.2"
USQUE_URL="https://github.com/Diniboy1123/usque/releases/download/v${USQUE_VER}/usque_${USQUE_VER}_linux_amd64.zip"

echo "[2/2] 正在下载 usque v${USQUE_VER}..."
curl -L "$USQUE_URL" -o "$PROJECT_DIR/usque.zip"
# 使用 python 进行解压，避免环境中没有 unzip 命令
python3 -c "import zipfile; zipfile.ZipFile('usque.zip').extract('usque', '$PROJECT_DIR')"
mv "$PROJECT_DIR/usque" "$PROJECT_DIR/usque-bin"
rm "$PROJECT_DIR/usque.zip"
chmod +x "$PROJECT_DIR/usque-bin"

echo "---------------------------------------"
echo "环境准备完成！"
echo "1. 请获取 JWT Token (参考 README.md)"
echo "2. 运行 ./manage.sh register <TOKEN> 进行注册"
echo "3. 运行 ./manage.sh start 启动服务"
