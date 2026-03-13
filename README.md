# usque + GOST Cloudflare Zero Trust 代理项目 (增强交互版)

本项目专为 sv66 等受限 Linux 环境设计，通过交互式脚本解决端口冲突并提供安全的 Shadowsocks 加密入口。

## 1. 核心改进
- **交互式自检**: 运行 `./manage.sh start` 后，脚本会引导你输入端口。
- **智能诊断**: 脚本会自动等待并读取 `usque.log` 和 `gost.log`。如果检测到 `Address already in use`，会立刻提示并让你重新输入，无需手动检查。
- **自动联动**: 后端启动成功后才会开启前端转发，确保通路逻辑严密。

## 2. 节点信息
**Shadowsocks 链接**:
`ss://YWVzLTI1Ni1nY206U2VjdXJlUGFzczEyMw==@<越南主机IP>:<你选的端口>#Vietnam`

- **协议**: Shadowsocks (SS)
- **可用端口范围**: `35001 - 35999`
- **加密**: `aes-256-gcm`
- **密码**: `SecurePass123`

---

## 3. 配置文件 (config.json)
已预置修正后的 DER 格式私钥和 IPv6 地址。
- **手动更新**: 如果以后更换了 CF 账号，请使用 `register` 命令自动生成，或使用 Python 将 32 字节私钥转为 DER 格式填入。

---

## 4. 快速部署步骤
1. **环境**: 确保 `usque-bin` 已上传，运行 `./install_gost.sh`。
2. **权限**: `chmod +x *.sh usque-bin gost`。
3. **注册**: `./manage.sh register <TOKEN>`。
4. **启动**: `./manage.sh start` 并按照提示寻找可用端口。
