#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

BINARY="./usque-bin"
GOST="./gost"
CONFIG="config.json"
AUTH=".proxy_auth"
PID_U="usque.pid"
PID_G="gost.pid"
LOG_U="usque.log"
LOG_G="gost.log"

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

get_pass() {
    if [ -f "$AUTH" ] && [ -s "$AUTH" ]; then
        cat "$AUTH"
    else
        local p=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || date +%s%N | md5sum | head -c 32)
        echo "$p" > "$AUTH"
        echo "$p"
    fi
}

check_port() {
    local port=$1
    timeout 2s "$GOST" -L ":$port" > .check.log 2>&1 &
    local pid=$!
    sleep 1
    if grep -qiE "address already in use|bind" .check.log; then
        kill $pid 2>/dev/null
        return 1
    fi
    kill $pid 2>/dev/null
    return 0
}

get_port() {
    local base=$(shuf -i 35001-35999 -n 1)
    while ! check_port $base; do
        base=$(shuf -i 35001-35999 -n 1)
    done
    echo $base
}

if [ ! -f "$BINARY" ] || [ ! -f "$GOST" ]; then
    log "首次运行，正在下载必要组件..."
    ./setup.sh
fi

echo "=================================================="
echo "  usque-CF-Zero-Trust 交互式启动工具"
echo "=================================================="
echo ""
read -p "请输入 Zero Trust 令牌 (eyJ...): " TOKEN

if [[ ! "$TOKEN" =~ ^eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*$ ]]; then
    error "令牌格式无效！"
    exit 1
fi

if [ ! -f "$CONFIG" ] || [ -z "$(grep -o '"account_tag":"[^"]*' "$CONFIG" 2>/dev/null)" ]; then
    log "正在注册设备..."
    chmod +x "$BINARY"
    "$BINARY" register --jwt "$TOKEN" --accept-tos || {
        error "注册失败！令牌可能已过期"
        exit 1
    }
    log "✓ 注册成功"
else
    log "✓ 设备已注册"
fi

PUB_PORT=$(get_port)
INT_PORT=$(get_port)
while [ "$PUB_PORT" = "$INT_PORT" ]; do
    INT_PORT=$(get_port)
done

log "自动分配端口: 外部=$PUB_PORT, 内部=$INT_PORT"

if command -v devil &>/dev/null; then
    log "正在申请开放端口 $PUB_PORT..."
    devil port add tcp "$PUB_PORT" &>/dev/null && log "✓ 端口已开放" || warn "可能已开放或超出限制"
fi

log "正在启动 usque..."
nohup "$BINARY" socks --port "$INT_PORT" --bind 127.0.0.1 --config "$CONFIG" > "$LOG_U" 2>&1 &
echo $! > "$PID_U"
sleep 3

if grep -qi "handshake failure" "$LOG_U"; then
    error "TLS 握手失败！请重新获取令牌"
    exit 1
fi

if ! ps -p $(cat "$PID_U") > /dev/null 2>&1; then
    error "usque 启动失败，查看 $LOG_U"
    exit 1
fi
log "✓ usque 运行正常"

PASS=$(get_pass)
log "正在启动 GOST 加密代理..."
nohup "$GOST" -L "ss://aes-256-gcm:$PASS@:$PUB_PORT" -F "socks5://127.0.0.1:$INT_PORT" > "$LOG_G" 2>&1 &
echo $! > "$PID_G"
sleep 2

if ! ps -p $(cat "$PID_G") > /dev/null 2>&1; then
    error "GOST 启动失败，查看 $LOG_G"
    exit 1
fi

IP=$(curl -s -m 5 https://ifconfig.me || echo "你的IP")
LOC=$(curl -s -m 3 "http://ip-api.com/line?fields=country" | tr -d '\n\r' || echo "Unknown")
AUTH_B64=$(echo -n "aes-256-gcm:$PASS" | base64 | tr -d '\n\r')
LINK="ss://$AUTH_B64@$IP:$PUB_PORT#${LOC}-MASQUE"

echo ""
echo "=================================================="
echo -e "${GREEN}✅ 代理启动成功！${NC}"
echo "--------------------------------------------------"
echo "节点链接:"
echo -e "\033[32m$LINK\033[0m"
echo "--------------------------------------------------"
echo "密码: $PASS"
echo "状态: ./manage.sh status"
echo "停止: ./manage.sh stop"
echo "=================================================="
rm -f .check.log
