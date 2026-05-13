# usque-CF-Zero-Trust

专为受限 Linux 环境设计的代理方案，通过 Cloudflare MASQUE + Shadowsocks 加密。

## 一键安装

```bash
curl -L https://raw.githubusercontent.com/zv201413/usque-CF-Zero-Trust/master/install.sh | bash
```

运行后依次：输入令牌 → 输入端口 → 复制节点链接使用。

## 获取令牌

1. 访问 `https://<团队名>.cloudflareaccess.com/warp` 完成验证
2. 在 Success 页面按 **F12** → **Console**
3. 执行:
```javascript
document.querySelector("meta[http-equiv='refresh']").content.split("=")[2]
```
4. 复制输出的 `eyJ...` 字符串

## 管理命令

```bash
cd usque-CFZT
```

| 命令 | 说明 |
|------|------|
| `./manage.sh start` | 交互式启动（手动输入端口） |
| `./manage.sh start --config <路径>` | 使用指定配置文件启动 |
| `./manage.sh stop` | 停止服务 |
| `./manage.sh restart` (或 `rep`) | 重启 |
| `./manage.sh status` | 查看运行状态 |
| `./manage.sh link` | 生成节点链接 |
| `./manage.sh new-pass` | 重置 Shadowsocks 密码 |
| `./manage.sh uninstall` (或 `clean`) | 卸载并删除所有文件 |

## 使用备份配置

注册后保存 `config.json`，下次直接复用：

```bash
./manage.sh start --config ~/backup-config.json
```

## 自动保活

```bash
crontab -e
*/10 * * * * cd /home/$USER/usque-CFZT && ./manage.sh stop && ./manage.sh start << 'EOF'
35001
35002
EOF
```

## 声明

仅供技术研究，请遵守当地法律法规。
