# 技术归档：sv66.dataonline-usque-CF-Zero-Trust 项目总结

这份文档记录了在 sv66 (Serv00) 等极度受限的 Linux 共享主机环境下，从 0 到 1 搭建 MASQUE 加密代理的全过程。

---

## 一、 项目背景与架构

### 1.1 核心痛点
- **无 Root 权限**：无法创建虚拟网卡 (TUN/TAP)，无法修改系统内核。
- **资源高度受限**：内存小（通常 512MB 以下），CPU 并行线程数限制严重。
- **网络封锁**：常规 SOCKS5 代理明文传输，极易被运营商或主机商防火墙阻断。

### 1.2 最终方案架构
本项目支持两种运行模式：
1. **双重隧道模式 (加密入站)**: 
   - 架构：`Client --(Shadowsocks)--> Host --(MASQUE)--> Cloudflare`
   - 优势：安全性高，公网无法识别流量内容。
2. **直连模式 (SOCKS5入站)**:
   - 架构：`Client --(SOCKS5)--> Host --(MASQUE)--> Cloudflare`
   - 优势：部署极简，适合内网或临时调试。

---

## 二、 遇到的困难与解决方案 (Troubleshooting History)

### 2.1 编译阶段：nproc 限制导致的“资源不可用”
- **困难**: 在主机上运行 `go build` 报错 `resource temporarily unavailable`。
- **成因**: Go 默认利用所有 CPU 核心并行编译，产生的子进程超过了 sv66 对单用户的线程数限制。
- **解决**: 弃用在线编译。改为从本地 WSL 交叉编译上传，或直接在脚本中集成官方 Release 版本的自动下载，彻底消除对主机开发环境的依赖。

### 2.2 运行阶段：ASN.1 私钥解析语法错误
- **困难**: 手动修改 `config.json` 填入 WireGuard 私钥后，`usque` 报错 `ASN.1 syntax error: indefinite length found (not DER)`。
- **成因**: `usque` 内部使用 Go 的 `x509` 库解析 ECDSA 私钥。它不接受 32 字节的原始私钥（Base64 44位），而是要求 **SEC1 ASN.1 DER** 包装后的格式。
- **解决**: 使用 Python 的 `cryptography` 库将原始 D 值重新包装成 DER 编码的 Base64 字符串。本项目的 `config.json` 已预置此类格式。

### 2.3 认证阶段：401 Unauthorized 与 Token 时效
- **困难**: `register` 命令频繁报 401 错误，即使在网页端认证成功也无效。
- **解决**: 
    - **发现**: JWT 令牌有效期极短（约 1 分钟）。
    - **Hack**: 提供了“浏览器 Console 控制台提取法”。在 Success 页面通过 JS 注入直接从 meta 标签提取 Token。
    - **配置**: 指引用户必须在 Zero Trust 后台手动配置 `Device Enrollment Rules`（包含邮箱），否则请求会被判定为 Invalid。

### 2.4 部署阶段：sv66 端口冲突与探测自检
- **困难**: sv66 是数千人共享的系统，常用端口极大概率被占用。此外，外部防火墙默认封闭，即使进程运行也无法访问。
- **解决**: 
    - **交互逻辑**: 实现 `while true` 端口输入循环。
    - **gost 预探测**: 在正式启动前，利用 `gost -L :$PORT` 启动临时监听检查 Bind 状态。
    - **防火墙集成**: 尝试执行 `devil port add` 自动开启端口。
    - **状态自检**: 启动后通过 `netstat` 或 `ss` 验证监听状态，并在无法验证时给予用户明确的防火墙检查提示。

### 2.6 节点命名优化
- **改进**: 集成 `ip-api.com` 接口。脚本启动时动态抓取服务器所属国家名称（如 Germany, Vietnam 等），并将其拼接入 SS 链接的 Metadata 中（`#CountryName-MASQUE`），实现节点的自动分类。

### 2.5 脚本健壮性：工具链缺失与管理优化
- **困难**: sv66 镜像中没有 `uuidgen` 且没有 `unzip`；散乱的文件不便于多实例管理。
- **解决**: 
    - **解压**: 在 `setup.sh` 中改用 Python 3 的 `zipfile` 库解压二进制。
    - **UUID**: 实现阶梯式降级逻辑：`uuidgen` -> `random pool` -> `date | md5sum`。
    - **管理**: `setup.sh` 自动创建 `usque-CFZT` 专用文件夹并归集所有相关脚本与二进制，实现“拎包入住”式的管理。

---

## 三、 核心代码片段参考 (移植用)

### 3.1 跨平台端口探测 (Bash)
```bash
timeout 2s ./gost -L ":$port" > /tmp/probe.log 2>&1
if grep -qiE "address already in use|bind: permission denied" /tmp/probe.log; then
    return 1 # 端口不可用
fi
```

### 3.2 Shadowsocks 链接自动合成
```bash
local auth_b64=$(echo -n "$METHOD:$PASS" | base64 | tr -d '\n\r')
echo "ss://$auth_b64@$IP:$PORT#Name"
```

---

## 四、 移植与后期建议

1. **多用户移植**: 如需在相同主机部署给多个人用，只需复制整个文件夹，并确保 `INTERNAL_PORT` 和 `PUBLIC_PORT` 各不相同。
2. **性能优化**: 
   - sv66 内存极小，建议关闭 `usque` 或 `gost` 的调试日志。
   - 加密方式推荐 `aes-256-gcm`，它在支持 AES-NI 的 CPU 上性能最佳。
3. **保活建议**: 
   - 强烈建议使用 `crontab` 每 5 分钟探测一次进程。
   - 若系统重启，sv66 会杀掉所有进程，`manage.sh start` 在 crontab 中的配合是必须的。

---
**归档日期**: 2026/03/13  
**开发者**: Antigravity Assistant & zv201413  
**鸣谢**: @闹海金蛟 (YouTube 思路来源)
