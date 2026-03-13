# usque + GOST Cloudflare Zero Trust 代理项目 (增强探测版)

本项目专为 sv66 等受限 Linux 环境设计，集成了基于 `gost` 的端口预探测功能。

## 1. 核心改进：智能探测
- **端口预检**: 在正式启动前，脚本会利用 `gost` 尝试开启临时监听。如果由于端口占用或无权限导致监听失败，脚本会立刻拦截并引导你重新输入。
- **防火墙联动**: 探测成功后，脚本会自动尝试调用 `devil port add` 命令，尽可能在系统层面打通访问权限。
- **两阶段验证**: 只有后端 (usque) 和前端 (gost) 都通过自检，脚本才会宣布成功。

## 2. 节点信息
**Shadowsocks 链接**:
`ss://YWVzLTI1Ni1nY206U2VjdXJlUGFzczEyMw==@<你的IP>:<端口>#Vietnam-CF`

- **协议**: Shadowsocks (SS)
- **可用端口范围**: `35001 - 35999`
- **加密**: `aes-256-gcm`
- **密码**: `SecurePass123`

---

## 3. 配置文件 (config.json)
已预置 DER 格式私钥。如需手动更换账号，请确保 `private_key` 是经过转换的长字符串。

---

## 4. 快速部署步骤
1. **环境**: 确保 `usque-bin` 已上传，运行 `./install_gost.sh`。
2. **初始化**: `chmod +x *.sh usque-bin gost`。
3. **注册**: `./manage.sh register <TOKEN>`。
4. **启动**: `./manage.sh start`。
   - 输入你想要使用的内部和外部端口。
   - 观察脚本的“探测”反馈。
   - 成功后，根据生成的链接进行连接。
