# usque Cloudflare Zero Trust Proxy

这是一个利用 `usque` 项目在受限 Linux 环境下通过 MASQUE 协议接入 Cloudflare Zero Trust (Teams) 的项目模板。

## 目录结构
- `setup.sh`: 自动安装环境并编译 `usque`。
- `manage.sh`: 注册与启动管理脚本。
- `config.json`: 存储配置信息（运行后自动生成）。

## 快速开始

### 1. 获取 Zero Trust 令牌 (JWT)

你可以通过以下两种方式之一获取令牌：

#### 方法 A：通过 Zero Trust 控制台（推荐）
1. 访问 [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)。
2. 进入 **Settings** -> **WARP Client**（或 **Devices** -> **Enrollment**）。
3. 找到 **Bulk Enrollment**，点击 **Generate Token**。
4. 复制生成的以 `eyJ` 开头的长字符串。

#### 方法 B：通过浏览器控制台（手动方式）
1. 在浏览器访问：`https://<你的团队域名>.cloudflareaccess.com/warp`。
2. 完成身份验证。
3. 在认证成功的“Success”页面，按下 `F12` 打开开发者工具，点击 **Console**（控制台）。
4. 输入并执行以下命令：
   ```javascript
   console.log(document.querySelector("meta[http-equiv='refresh']").content.split("=")[2])
   ```
5. 复制输出的令牌字符串。

### 2. 环境准备与编译
运行以下命令安装 Go 语言环境并编译项目：
```bash
chmod +x setup.sh manage.sh
./setup.sh
```

### 3. 注册设备 (仅需一次)
将你获取的令牌填入：
```bash
./manage.sh register <你的JWT令牌>
```

### 4. 启动代理
启动 SOCKS5 代理（默认端口 1080）：
```bash
./manage.sh start
```

## 代理信息
- **类型**: SOCKS5
- **地址**: `127.0.0.1`
- **端口**: `1080`
- **协议**: MASQUE (HTTP/3)

## 进阶配置
你可以修改 `manage.sh` 中的启动参数，例如：
- `-p 8080`: 更改监听端口。
- `--dns 1.1.1.1`: 设置自定义 DNS。
- `http-proxy`: 改为启动 HTTP 代理。
