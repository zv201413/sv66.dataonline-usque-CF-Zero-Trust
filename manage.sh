#!/bin/bash
BINARY="./usque-bin"
GOST="./gost"
PID_USQUE="usque.pid"
PID_GOST="gost.pid"
CONFIG_FILE="config.json"
AUTH_FILE=".proxy_auth"

# 基础安全配置
SS_METHOD="aes-256-gcm"

# 获取或生成持久化的随机密码
get_or_create_password() {
    if [ -f "$AUTH_FILE" ]; then
        cat "$AUTH_FILE"
    else
        local pass=$(uuidgen)
        echo "$pass" > "$AUTH_FILE"
        echo "$pass"
    fi
}

# 获取公网 IP
get_public_ip() {
    local ip=$(curl -s -m 5 https://ifconfig.me || curl -s -m 5 https://api.ipify.org || echo "你的IP")
    echo "$ip"
}

is_running() {
    [ -f "$1" ] && ps -p $(cat "$1") > /dev/null 2>&1
}

stop_services() {
    [ -f $PID_USQUE ] && kill $(cat $PID_USQUE) 2>/dev/null && rm -f $PID_USQUE
    [ -f $PID_GOST ] && kill $(cat $PID_GOST) 2>/dev/null && rm -f $PID_GOST
}

start_interactive() {
    local SS_PASS=$(get_or_create_password)
    local PUB_IP=$(get_public_ip)

    while true; do
        echo "==============================================="
        echo "           sv66 自动化 & 交互式启动器           "
        echo "-----------------------------------------------"
        echo "当前外网 IP: $PUB_IP"
        echo "提示: 建议使用 35001-35999 之间的端口"
        read -p "请输入内部通信端口 (建议 35801): " INT_PORT
        read -p "请输入外部加密端口 (建议 35998): " PUB_PORT
        
        if [ "$INT_PORT" == "$PUB_PORT" ]; then
            echo "❌ 错误: 端口不能相同！"
            continue
        fi

        echo "正在初始化环境..."
        stop_services
        chmod +x "$BINARY" "$GOST" 2>/dev/null
        
        # 1. 尝试启动 usque
        echo "尝试启动 usque (后端隧道)..."
        nohup $BINARY socks --port $INT_PORT --bind 127.0.0.1 --config "$CONFIG_FILE" > usque.log 2>&1 &
        echo $! > $PID_USQUE
        
        echo "等待 usque 建立 TLS 隧道 (5秒)..."
        sleep 5
        if grep -qi "handshake failure" usque.log; then
            echo "❌ 严重错误: TLS 握手失败 (CRYPTO_ERROR 0x128)！"
            echo "提示: 这通常是因为 config.json 中的 私钥/ID/Token 不配套。"
            stop_services && exit 1
        fi
        
        if ! is_running $PID_USQUE; then
            echo "❌ 失败: usque 无法启动，请查看 usque.log。"
            stop_services && continue
        fi
        echo "✅ usque 隧道连接成功！"

        # 2. 尝试启动 GOST
        echo "尝试启动 GOST (Shadowsocks 加密入口)..."
        nohup $GOST -L "ss://$SS_METHOD:$SS_PASS@:$PUB_PORT" -F "socks5://127.0.0.1:$INT_PORT" > gost.log 2>&1 &
        echo $! > $PID_GOST
        
        sleep 2
        if ! is_running $PID_GOST; then
            echo "❌ 失败: GOST 启动失败，可能端口 $PUB_PORT 无权限或被占用。"
            stop_services && continue
        fi

        # 生成节点链接
        local auth_b64=$(echo -n "$SS_METHOD:$SS_PASS" | base64)
        local ss_link="ss://$auth_b64@$PUB_IP:$PUB_PORT#Vietnam-MASQUE"

        echo "-----------------------------------------------"
        echo "🎉 代理节点已上线！"
        echo "端口: $PUB_PORT"
        echo "密码: $SS_PASS"
        echo "节点链接 (直接复制到软件):"
        echo -e "\033[32m$ss_link\033[0m"
        echo "-----------------------------------------------"
        break
    done
}

case "$1" in
    register)
        chmod +x "$BINARY" 2>/dev/null
        $BINARY register --jwt "$2" --accept-tos ;;
    start)
        start_interactive ;;
    stop)
        stop_services && echo "已停止。" ;;
    status)
        is_running $PID_USQUE && echo "usque: 运行中" || echo "usque: 已停止"
        is_running $PID_GOST && echo "gost: 运行中" || echo "gost: 已停止" ;;
    new-pass)
        rm -f "$AUTH_FILE"
        echo "旧密码已清除，下次启动将生成新密码。" ;;
    *)
        echo "用法: ./manage.sh {register|start|stop|status|new-pass}" ;;
esac
