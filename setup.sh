#!/bin/bash
set -e

echo "正在初始化项目..."
mkdir -p "usque-CFZT" && cd "usque-CFZT"

echo "[1/2] 下载 GOST..."
curl -L "https://github.com/go-gost/gost/releases/download/v3.0.0-rc10/gost_3.0.0-rc10_linux_amd64.tar.gz" -o gost.tar.gz
tar -xzf gost.tar.gz gost && rm gost.tar.gz
chmod +x gost

echo "[2/2] 下载 usque..."
curl -L "https://github.com/Diniboy1123/usque/releases/download/v1.4.2/usque_1.4.2_linux_amd64.zip" -o usque.zip
python3 -c "import zipfile; zipfile.ZipFile('usque.zip').extract('usque', '.')"
mv usque usque-bin && rm usque.zip
chmod +x usque-bin

echo "✅ 初始化完成"
echo "启动代理: ./run.sh"
echo "高级管理: ./manage.sh"
