# usque + GOST Cloudflare Zero Trust 代理项目 (自动化版)

本项目专为 sv66 等受限 Linux 环境优化，支持自动获取 IP、随机 UUID 密码生成以及交互式自检逻辑。

## 1. 核心改进 (Build v3.0)
- **动态 IP 识别**: 脚本启动时会自动探测主机的公网 IP，并生成完整的节点链接。
- **随机安全密码**: 弃用硬编码密码，首次运行自动生成 UUID 随机密码并保存至 `.proxy_auth`。
- **交互式自检**: 实时监控 `usque` 的 TLS 握手状态，若私钥不匹配（TLS 0x128 错误）会立即拦截。
- **一键切换**: 运行 `./manage.sh new-pass` 可随时重置随机密码。

## 2. 节点信息
**Shadowsocks 链接**:
启动成功后，脚本会直接输出以 `ss://` 开头的彩色链接。

- **协议**: Shadowsocks (SS)
- **加密方式**: `aes-256-gcm`
- **认证**: UUID 随机生成 (持久化)

---

## 3. 配置文件 (config.json) 与风险说明

### 关于 ping0.cc 的“风险值”
Cloudflare WARP 的出口 IP 属于公共数据中心，且被大量用户共享，因此常被风控系统标记为 “VPN/Proxy” 类型（高风险）。这并不影响正常上网使用，仅代表 IP 属于非家庭宽带。

### 手动配置建议
如果你有一套从其它地方获取的“可用配置”，请确保 **整套替换** 以下字段：
- `private_key` (必须是 DER 格式)
- `id` (设备 ID)
- `access_token` (认证 Token)
- `ipv6` (对应的隧道内部地址)
**仅修改私钥会导致握手失败。**

---

## 4. 快速部署步骤
1. **上传文件**: 确保 `usque-bin` 已在当前目录。
2. **初始化**: `chmod +x *.sh usque-bin gost`（若无 gost 运行 `./install_gost.sh`）。
3. **注册**: `./manage.sh register <TOKEN>`（自动生成配套配置）。
4. **启动**: `./manage.sh start`。
   - 脚本会显示当前探测到的 IP。
   - 输入你选择的两个端口。
   - 复制生成的 `ss://` 链接即可使用。

---

## 5. 自动维护 (Crontab)
建议添加计划任务，脚本会自动跳过已运行的进程：
```bash
*/10 * * * * cd /home/zvtdcomi/ && ./manage.sh start << 'EOF'
35801
35998
EOF
```
