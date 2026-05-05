# usque-CF-Zero-Trust

专为受限 Linux 环境设计的代理方案，通过 Cloudflare MASQUE + Shadowsocks 加密。

## 一键安装

```bash
curl -L https://raw.githubusercontent.com/zv201413/usque-CF-Zero-Trust/master/install.sh | bash
```

运行后输入 Zero Trust 令牌，脚本会自动：
1. 下载 usque 和 gost 二进制文件
2. 注册设备到 Cloudflare Zero Trust
3. 分配端口并启动服务
4. **显示代理节点链接**（直接复制使用）

## 工作原理

```
用户设备                    你的服务器                    Cloudflare
                                                          
  代理客户端 ──> gost (SS) ──> usque ──> MASQUE 隧道 ──> 出口
            (随机端口)      (随机端口)       (加密)
```

- **usque-bin**: Cloudflare MASQUE 隧道客户端
- **gost**: 将 Shadowsocks 流量转发到 usque

## 获取令牌 (Token)

1. 访问 `https://<团队名>.cloudflareaccess.com/warp` 完成验证
2. 在 Success 页面按 **F12** 打开开发者工具
3. 切换到 **Console** 标签
4. 执行:
```javascript
document.querySelector("meta[http-equiv='refresh']").content.split("=")[2]
```
5. 复制输出的 `eyJ...` 长字符串（整个命令的返回值）

## 安装后操作

### 1. 输入令牌

安装脚本会提示：
```
请输入 Zero Trust 令牌: 
粘贴刚才获取的 eyJ... 字符串
```

### 2. 复制节点链接

启动成功后，脚本会输出类似：
```
==================================================
✅ 代理服务启动成功！
--------------------------------------------------
节点链接: ss://YWVzLTI1Ni1nY206Zj(...省略...)@你的IP:35002#CN-MASQUE
--------------------------------------------------
密码: f28a4b3c-...
管理命令: cd usque-CFZT && ./manage.sh stop
==================================================
```

**直接复制这行链接**即可在代理客户端使用。

### 3. 使用的客户端

支持 Shadowsocks 的客户端都可用，例如：
- Windows: Shadowsocks-Windows, Clash Verge
- Android: Shadowsocks-android, Surfboard
- iOS: Shadowrocket, Quantumult X
- Linux: v2ray-agent, clash-meta

## 高级管理

```bash
cd usque-CFZT
```

| 命令 | 说明 |
|------|------|
| `./manage.sh start` | 交互式启动（输入内外端口） |
| `./manage.sh stop` | 停止服务 |
| `./manage.sh status` | 查看运行状态 |
| `./manage.sh new-pass` | 重置 Shadowsocks 密码 |

## 重复运行保护

install.sh 内置保护机制：
- 检测到已有服务运行时，弹出选项菜单
- 选 1 可清理旧进程并重新部署
- 选 2 可查看当前状态后退出
- 避免多次执行导致进程堆积

## 自动保活 (Cron)

```bash
crontab -e
# 添加以下行（每10分钟检查重启）
*/10 * * * * cd /home/$USER/usque-CFZT && ./manage.sh stop && ./manage.sh start << 'EOF'
35001
35002
EOF
```

## 常见问题

**Q: 无法连接？**
- 检查服务商后台是否开放了对应端口
- 常用命令: `devil port add tcp 35002`

**Q: 如何查看日志？**
```bash
cd usque-CFZT
cat usque.log   # usque 隧道日志
cat gost.log    # gost 出口日志
```

**Q: 想换端口？**
```bash
cd usque-CFZT
./manage.sh stop
./manage.sh start
# 重新选择端口
```

**Q: 密码在哪里？**
```bash
cat usque-CFZT/.proxy_auth
```

**Q: 没有看到节点链接，如何手动生成？**
如果错过初始输出，可手动拼接。步骤：

```bash
cd usque-CFZT

# 1. 获取密码
PASS=$(cat .proxy_auth)

# 2. 获取服务器公网 IP
IP=$(curl -s https://ifconfig.me)

# 3. 获取 gost 端口（正在监听的端口）
PORT=$(ss -tlnp | grep gost | grep -oP ':[0-9]+' | tail -1 | tr -d ':')

# 4. 拼接节点链接
METHOD="aes-256-gcm"
AUTH_B64=$(echo -n "$METHOD:$PASS" | base64 | tr -d '\n\r')
LINK="ss://$AUTH_B64@$IP:$PORT#Manual-MASQUE"

echo "节点链接: $LINK"
echo "密码: $PASS"
echo "端口: $PORT"
```

或者直接查看 gost.log 的启动输出，里面也会记录端口。

## 声明

仅供技术研究，请遵守当地法律法规。