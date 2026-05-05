# usque-CF-Zero-Trust

专为受限 Linux 环境设计的代理方案，通过 Cloudflare MASQUE + Shadowsocks 加密。

## 一键安装使用

```bash
curl -L https://raw.githubusercontent.com/zv201413/usque-CF-Zero-Trust/master/install.sh | bash
```

运行后只需输入 Zero Trust 令牌，其他全部自动完成。

## 工作原理

```
用户端                    你的服务器                    Cloudflare
                                                         
  客户端 ──┬──> gost (SS) ──> usque ──> MASQUE 隧道 ──> Cloudflare 网络
           (端口35002)      (端口35001)      (加密)
```

- **usque-bin**: Cloudflare MASQUE 隧道客户端
- **gost**: 将 Shadowsocks 流量转发到 usque

## 获取令牌

1. 访问 `https://<团队名>.cloudflareaccess.com/warp` 完成验证
2. 在 Success 页面按 F12 打开控制台
3. 执行: `console.log(document.querySelector("meta[http-equiv='refresh']").content.split("=")[2])`
4. 复制输出的 `eyJ...` 长字符串

## 高级管理

```bash
cd usque-CFZT
```

| 命令 | 说明 |
|------|------|
| `./manage.sh start` | 交互式启动 (选择端口) |
| `./manage.sh stop` | 停止服务 |
| `./manage.sh status` | 查看运行状态 |
| `./manage.sh new-pass` | 重置 Shadowsocks 密码 |

## 重复运行保护

install.sh 已内置保护机制：
- 检测到已有服务运行时，会询问是否清理
- 防止多次执行导致进程堆积
- 使用 `manage.sh stop` 可安全停止现有服务

## 自动保活

```bash
crontab -e
# 添加（每10分钟检查并重启）
*/10 * * * * cd /home/$USER/usque-CFZT && ./manage.sh stop && ./manage.sh start << 'EOF'
35001
35002
EOF
```

## 常见问题

**Q: 服务启动后无法连接？**
A: 检查服务商是否开放了相应端口（使用 `devil port add tcp 端口号`）

**Q: 如何查看日志？**
A: `cat usque-CFZT/usque.log` 或 `cat usque-CFZT/gost.log`

**Q: 想更换端口怎么办？**
A: `./manage.sh stop` 后再 `./manage.sh start`，可重新选择端口

## 声明

仅供技术研究，请遵守当地法律法规。