cat << 'EOF' > install_gost.sh
#!/bin/bash
set -e
PROJECT_DIR=$(pwd)
GOST_VER="3.0.0-rc10"
GOST_URL="https://github.com/go-gost/gost/releases/download/v${GOST_VER}/gost_${GOST_VER}_linux_amd64.tar.gz"
echo "[1/2] 下载 GOST..."
curl -L "$GOST_URL" -o "$PROJECT_DIR/gost.tar.gz"
echo "[2/2] 解压..."
tar -xzf "$PROJECT_DIR/gost.tar.gz" -C "$PROJECT_DIR" gost
rm "$PROJECT_DIR/gost.tar.gz"
chmod +x "$PROJECT_DIR/gost"
echo "GOST 安装成功。"
EOF

cat << 'EOF' > manage.sh
#!/bin/bash
BINARY="./usque-bin"
GOST="./gost"
PID_USQUE="usque.pid"
PID_GOST="gost.pid"

# --- 安全配置 (建议修改) ---
SS_METHOD="aes-256-gcm"
SS_PASS="SecurePass123"
PUBLIC_PORT="2080"
# -------------------------

case "$1" in
    register)
        $BINARY register --jwt "$2" --accept-tos
        ;;
    start)
        echo "启动后端隧道..."
        nohup $BINARY socks --port 1080 --bind 127.0.0.1 > usque.log 2>&1 &
        echo $! > $PID_USQUE
        echo "启动加密入口 (端口 $PUBLIC_PORT)..."
        nohup $GOST -L "ss://$SS_METHOD:$SS_PASS@:$PUBLIC_PORT" -F "socks5://127.0.0.1:1080" > gost.log 2>&1 &
        echo $! > $PID_GOST
        echo "服务已成功启动！"
        echo "请在客户端使用 Shadowsocks 协议连接: $PUBLIC_PORT"
        ;;
    stop)
        kill $(cat $PID_USQUE) $(cat $PID_GOST) 2>/dev/null
        rm -f $PID_USQUE $PID_GOST
        echo "服务已停止。"
        ;;
    status)
        ps -p $(cat $PID_USQUE 2>/dev/null) >/dev/null && echo "usque: 运行中" || echo "usque: 已停止"
        ps -p $(cat $PID_GOST 2>/dev/null) >/dev/null && echo "gost: 运行中" || echo "gost: 已停止"
        ;;
    *)
        echo "用法: ./manage.sh {register|start|stop|status}"
        ;;
esac
EOF

chmod +x install_gost.sh manage.sh
echo "脚本修复完成。"
