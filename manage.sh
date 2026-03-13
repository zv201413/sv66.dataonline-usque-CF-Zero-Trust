#!/bin/bash
BINARY="./usque-bin"
GOST="./gost"
PID_USQUE="usque.pid"
PID_GOST="gost.pid"
CONFIG_FILE="config.json"

# 基础安全配置
SS_METHOD="aes-256-gcm"
SS_PASS="SecurePass123"

is_running() {
    [ -f "$1" ] && ps -p $(cat "$1") > /dev/null 2>&1
}

stop_services() {
    [ -f $PID_USQUE ] && kill $(cat $PID_USQUE) 2>/dev/null && rm -f $PID_USQUE
    [ -f $PID_GOST ] && kill $(cat $PID_GOST) 2>/dev/null && rm -f $PID_GOST
}

start_interactive() {
    while true; do
        echo "==============================================="
        echo "           sv66 交互式端口自检启动器           "
        echo "-----------------------------------------------"
        echo "提示: 建议使用 35001-35999 之间的端口"
        read -p "请输入 usque 后端端口: " INT_PORT
        read -p "请输入 GOST 出口端口: " PUB_PORT
        
        if [ "$INT_PORT" == "$PUB_PORT" ]; then
            echo "❌ 错误: 内部端口和外部端口不能相同！"
            continue
        fi

        echo "正在初始化环境..."
        stop_services
        chmod +x "$BINARY" "$GOST" 2>/dev/null
        
        # 1. 尝试启动 usque
        echo "尝试启动 usque (后端)..."
        nohup $BINARY socks --port $INT_PORT --bind 127.0.0.1 --config "$CONFIG_FILE" > usque.log 2>&1 &
        echo $! > $PID_USQUE
        
        # 实时自检
        sleep 2
        if grep -qi "address already in use" usque.log; then
            echo "❌ 失败: 端口 $INT_PORT 已被占用，请尝试其他端口。"
            stop_services
            continue
        fi
        
        if ! is_running $PID_USQUE; then
            echo "❌ 失败: usque 无法启动。日志最后两行："
            tail -n 2 usque.log
            stop_services
            continue
        fi
        echo "✅ usque 启动成功！"

        # 2. 尝试启动 GOST
        echo "尝试启动 GOST (加密入口)..."
        nohup $GOST -L "ss://$SS_METHOD:$SS_PASS@:$PUB_PORT" -F "socks5://127.0.0.1:$INT_PORT" > gost.log 2>&1 &
        echo $! > $PID_GOST
        
        sleep 2
        if grep -qiE "address already in use|bind: permission denied" gost.log; then
            echo "❌ 失败: 外部端口 $PUB_PORT 不可用（被占用或无权限）。"
            stop_services
            continue
        fi

        if ! is_running $PID_GOST; then
            echo "❌ 失败: GOST 启动失败。日志最后两行："
            tail -n 2 gost.log
            stop_services
            continue
        fi

        echo "-----------------------------------------------"
        echo "🎉 恭喜！所有服务已成功绑定并运行。"
        echo "SS 节点: ss://$(echo -n "$SS_METHOD:$SS_PASS" | base64)@你的IP:$PUB_PORT"
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
    *)
        echo "用法: ./manage.sh {register|start|stop|status}" ;;
esac
