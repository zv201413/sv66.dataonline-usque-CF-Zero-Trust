#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=================================================="
echo " usque-CF-Zero-Trust 一键安装启动器"
echo "=================================================="
echo ""

TARGET_DIR="usque-CFZT"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# === 新增: 检查并清理旧进程 ===
cleanup_old_processes() {
    echo -e "${YELLOW}[检查] 检测现有进程...${NC}"
    
    # 清理残留的 gost 进程 (端口检测)
    for pid_file in usque.pid gost.pid; do
        if [ -f "$pid_file" ]; then
            old_pid=$(cat "$pid_file" 2>/dev/null)
            if [ -n "$old_pid" ] && ps -p "$old_pid" > /dev/null 2>&1; then
                echo -e "${YELLOW}[清理] 停止旧进程 PID=$old_pid${NC}"
                kill "$old_pid" 2>/dev/null
                sleep 1
            fi
            rm -f "$pid_file"
        fi
    done
    
    # 清理可能残留的 gost 端口进程 (同一目录下的)
    pkill -f "\./gost -L" 2>/dev/null || true
    pkill -f "./usque-bin" 2>/dev/null || true
    sleep 1
}

# 检查是否已有服务运行
check_existing() {
    if [ -f "usque.pid" ] && ps -p $(cat usque.pid) > /dev/null 2>&1; then
        return 0  # 运行中
    fi
    if pgrep -f "./usque-bin" > /dev/null 2>&1; then
        return 0  # 运行中
    fi
    return 1  # 未运行
}

# 如果已有服务运行，询问用户
if check_existing; then
    echo -e "${YELLOW}[警告] 检测到已有服务运行中${NC}"
    echo "当前进程:"
    ps aux | grep -E "(gost|usque-bin)" | grep -v grep || echo "  (无)"
    echo ""
    echo "选项:"
    echo "  1. 停止旧进程并重新部署 (推荐)"
    echo "  2. 查看当前状态"
    echo "  3. 退出"
    read -p "请选择 [1-3]: " choice
    
    case "$choice" in
        1)
            cleanup_old_processes
            echo -e "${GREEN}[OK] 已清理旧进程${NC}"
            ;;
        2)
            echo "查看日志: cat usque.log / cat gost.log"
            echo "管理命令: ./manage.sh status"
            exit 0
            ;;
        *)
            echo "退出"
            exit 0
            ;;
    esac
fi

# 下载组件
echo "正在下载必要组件..."
if [ ! -f "gost" ]; then
    echo "[1/2] 下载 GOST..."
    curl -L "https://github.com/go-gost/gost/releases/download/v3.0.0-rc10/gost_3.0.0-rc10_linux_amd64.tar.gz" -o gost.tar.gz
    tar -xzf gost.tar.gz gost && rm gost.tar.gz
    chmod +x gost
fi

if [ ! -f "usque-bin" ]; then
    echo "[2/2] 下载 usque..."
    curl -L "https://github.com/Diniboy1123/usque/releases/download/v1.4.2/usque_1.4.2_linux_amd64.zip" -o usque.zip
    python3 -c "import zipfile; zipfile.ZipFile('usque.zip').extract('usque', '.')"
    mv usque usque-bin && rm usque.zip
    chmod +x usque-bin
fi

# 复制必要文件
if [ ! -f "config.json" ]; then
    curl -L "https://raw.githubusercontent.com/zv201413/usque-CF-Zero-Trust/main/config.json" -o config.json
fi

if [ ! -f "manage.sh" ]; then
    curl -L "https://raw.githubusercontent.com/zv201413/usque-CF-Zero-Trust/main/manage.sh" -o manage.sh
    chmod +x manage.sh
fi

# 交互式输入令牌（支持管道执行）
echo ""
echo "获取 Zero Trust 令牌的步骤:"
echo "1. 访问 https://<团队名>.cloudflareaccess.com/warp"
echo "2. 完成邮箱验证"
echo "3. 在 Success 页面按 F12 打开控制台"
echo "4. 执行: console.log(document.querySelector(\"meta[http-equiv='refresh']\").content.split(\"=\")[2])"
echo "5. 复制输出的 eyJ... 长字符串"
echo ""

# 从终端读取输入（兼容管道模式）
if [ -t 0 ]; then
    read -p "请输入 Zero Trust 令牌: " TOKEN
else
    echo -e "${YELLOW}[提示]正在读取令牌...${NC}"
    read -p "请输入 Zero Trust 令牌: " TOKEN < /dev/tty
fi

if [[ ! "$TOKEN" =~ ^eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*$ ]]; then
    echo -e "${RED}令牌格式无效！${NC}"
    exit 1
fi

# 注册设备
CONFIG_FILE="config.json"
if [ ! -f "$CONFIG_FILE" ] || [ -z "$(grep -o '"account_tag":"[^"]*' "$CONFIG_FILE" 2>/dev/null)" ]; then
    echo "正在注册设备..."
    chmod +x usque-bin
    if ! ./usque-bin register --jwt "$TOKEN" --accept-tos; then
        echo -e "${RED}注册失败！令牌可能已过期${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ 注册成功${NC}"
else
    echo -e "${GREEN}✓ 设备已注册${NC}"
fi

# 手动选择端口
echo ""
echo "===== 端口配置 ====="
while true; do
    read -p "请输入内部通信端口 (建议 35001-35999): " INT_PORT
    read -p "请输入外部加密端口 (建议 35001-35999): " PUB_PORT

    [ "$INT_PORT" == "$PUB_PORT" ] && { echo -e "${RED}错误: 端口不能相同！${NC}"; continue; }

    # 用 ss 检查端口是否已被占用（不 spawn 额外 gost 进程）
    if command -v ss &> /dev/null; then
        if ss -tuln 2>/dev/null | grep -q ":$INT_PORT "; then
            echo -e "${RED}内部端口 $INT_PORT 已被占用${NC}"
            continue
        fi
        if ss -tuln 2>/dev/null | grep -q ":$PUB_PORT "; then
            echo -e "${RED}外部端口 $PUB_PORT 已被占用${NC}"
            continue
        fi
    fi
    break
done

# 开放端口
if command -v devil &>/dev/null; then
    echo "正在申请开放端口 $PUB_PORT..."
    devil port add tcp "$PUB_PORT" &>/dev/null
fi

# 生成密码
AUTH=".proxy_auth"
if [ -f "$AUTH" ] && [ -s "$AUTH" ]; then
    PASS=$(cat "$AUTH")
else
    PASS=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || date +%s%N | md5sum | head -c 32)
    echo "$PASS" > "$AUTH"
fi

# 启动服务
echo "正在启动代理服务..."
nohup ./usque-bin socks --port "$INT_PORT" --bind 127.0.0.1 --config "$CONFIG_FILE" > "usque.log" 2>&1 &
echo $! > usque.pid
sleep 3

nohup ./gost -L "ss://aes-256-gcm:$PASS@:$PUB_PORT" -F "socks5://127.0.0.1:$INT_PORT" > "gost.log" 2>&1 &
echo $! > gost.pid
sleep 2

# 生成链接
IP=$(curl -s -m 5 https://ifconfig.me || echo "你的IP")
LOC=$(curl -s -m 3 "http://ip-api.com/line?fields=country" | tr -d '\n\r' || echo "Unknown")
AUTH_B64=$(echo -n "aes-256-gcm:$PASS" | base64 | tr -d '\n\r')
LINK="ss://$AUTH_B64@$IP:$PUB_PORT#${LOC}-MASQUE"

echo ""
echo "=================================================="
echo -e "${GREEN}✅ 代理服务启动成功！${NC}"
echo "--------------------------------------------------"
echo -e "节点链接: \033[32m$LINK\033[0m"
echo "--------------------------------------------------"
echo "密码: $PASS"
echo ""
echo "管理命令:"
echo "  cd $TARGET_DIR && ./manage.sh stop"
echo "  cd $TARGET_DIR && ./manage.sh status"
echo "=================================================="
