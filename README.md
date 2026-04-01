# usque-CF-Zero-Trust

专为受限 Linux 环境设计的代理方案，通过 Cloudflare MASQUE + Shadowsocks 加密。

## 一键部署

```bash
curl -L https://raw.githubusercontent.com/zv201413/usque-CF-Zero-Trust/main/setup.sh | bash
cd usque-CFZT
./run.sh
```

运行后会提示输入 Zero Trust 令牌，只需输入一次即可自动完成注册、启动。

## 获取令牌

1. 访问 `https://<团队名>.cloudflareaccess.com/warp` 完成验证
2. 在 Success 页面按 F12 打开控制台
3. 执行: `console.log(document.querySelector("meta[http-equiv='refresh']").content.split("=")[2])`
4. 复制输出的 `eyJ...` 字符串（有效期 1 分钟）

## 高级功能

使用 `./manage.sh` 进行高级管理：
- `./manage.sh register <TOKEN>` - 注册设备
- `./manage.sh start` - 交互式启动
- `./manage.sh stop` - 停止服务
- `./manage.sh status` - 查看状态
- `./manage.sh new-pass` - 重置密码

## 自动保活

```bash
crontab -e
# 添加（每10分钟检查）
*/10 * * * * cd /home/zvtdcomi/usque-CFZT && ./manage.sh start << 'EOF'
35001
35002
EOF
```

## 声明

仅供技术研究，请遵守当地法律法规。
