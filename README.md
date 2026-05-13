# usque-CF-Zero-Trust

专为受限 Linux 环境设计的代理方案，通过 Cloudflare MASQUE + Shadowsocks 加密。

## 一键安装

```bash
curl -L https://raw.githubusercontent.com/zv201413/usque-CF-Zero-Trust/master/install.sh | bash
```

运行后输入 Zero Trust 令牌，脚本会自动：
1. 下载 usque 和 gost 二进制文件
2. 注册设备到 Cloudflare Zero Trust
3. **提示输入端口**并启动服务
4. **显示代理节点链接**（直接复制使用）

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

### 2. 配置端口

注册成功后，脚本会提示输入端口：
```
===== 端口配置 =====
请输入内部通信端口 (建议 35001-35999): 
请输入外部加密端口 (建议 35001-35999): 
```

- **内部端口**：usque 与 gost 之间的本地通信端口
- **外部端口**：Shadowsocks 对外服务的加密端口（需在服务商面板放行）
- 两个端口不能相同

### 3. 复制节点链接

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

### 4. 使用的客户端

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
| `./manage.sh start` | 交互式启动（手动输入内外端口） |
| `./manage.sh start --config <路径>` | 使用指定配置文件启动 |
| `./manage.sh stop` | 停止服务 |
| `./manage.sh restart` (或 `rep`) | 重启（停掉旧进程后重新启动） |
| `./manage.sh status` | 查看运行状态 |
| `./manage.sh link` | 生成节点链接（随时可用） |
| `./manage.sh new-pass` | 重置 Shadowsocks 密码 |
| `./manage.sh uninstall` (或 `clean`) | 卸载并删除所有相关文件（二进制、日志、配置等） |

### 使用保存的配置文件 (--config)

每次注册设备后，`config.json` 会保存 Cloudflare 的认证凭据。你可以备份这个文件，下次部署时直接复用：

```bash
# 备份
cp config.json ~/backup-config.json

# 重新部署后直接使用备份的配置（跳过注册步骤）
./manage.sh start --config ~/backup-config.json

# 也支持环境变量方式
CONFIG_FILE=~/backup-config.json ./manage.sh start
```

只要配置文件中有有效的 `account_tag` 字段，脚本会自动跳过注册步骤。

### 端口改为手动输入（v2 变更）

从 v2 版本开始，所有脚本（`install.sh`、`run.sh`、`manage.sh`）不再自动随机分配端口，改为**手动输入**。原因：

- 自动分配依赖 `gost` 临时监听来探测端口，每次探测都会 spawn 一个 gost 进程
- 多次运行后会导致**大量残留 gost 进程**堆积
- 手动输入结合 `ss` 检查（不产生额外进程），更可控也更干净

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

**Q: 没有看到节点链接，如何生成？**
运行以下命令即可：
```bash
cd usque-CFZT
./manage.sh link
```
这会显示当前的节点链接（IPv6 地址会自动添加方括号）、密码、端口和 IP。

**Q: 为什么运行好多个 gost 进程？**
旧版本使用 `gost` 做端口探测，每次探测 spawn 一个进程。如果多次运行脚本，残留进程会堆积。v2 修复：
- 端口探测改为 `ss` 命令（只读查询，不产生进程）
- 停止服务时增加 `pkill` 兜底清理
- 端口改用手动输入，不循环随机探测
> 如果已有残留进程，手动执行 `pkill gost` 清理一次即可。

## 声明

仅供技术研究，请遵守当地法律法规。
