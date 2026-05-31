# TRAE-Ollama-Bridge

<picture>
    <img src="img/Traellama-Hero.png" alt="Traellama-Hero">
</picture>

[![简体中文](https://img.shields.io/badge/文档-简体中文-yellow)](README.md) [![English](https://img.shields.io/badge/docs-English-purple)](docs/README.en.md)

<span style="font-size:1.3em;">将本地 Ollama 模型包装为 OpenAI 兼容接口，绕过 TRAE 等 IDE 的固定服务商限制。</span>

---

## 📋 目录

- [📋 目录](#-目录)
- [🛠 项目简介](#-项目简介)
- [✨ 核心特性](#-核心特性)
- [⚙️ 环境准备](#️-环境准备)
- [🚀 快速开始](#-快速开始)
  - [方式 A：Start-Bridge.bat（推荐）](#方式-astart-bridgebat推荐)
  - [方式 B：TRAE-Bridge.cmd 菜单程序](#方式-btrae-bridgecmd-菜单程序)
- [🌐 WebUI 管理界面](#-webui-管理界面)
  - [聊天测试](#聊天测试)
  - [模型映射](#模型映射)
  - [特权桥接服务（透明拦截）](#特权桥接服务透明拦截)
- [🔧 配置 TRAE IDE](#-配置-trae-ide)
- [📖 两种使用模式](#-两种使用模式)
  - [模式 1：显式桥接](#模式-1显式桥接)
  - [模式 2：透明拦截](#模式-2透明拦截)
- [📁 配置文件详解](#-配置文件详解)
- [🔄 API 接口说明](#-api-接口说明)
- [❓ 常见问题](#-常见问题)
  - [端口冲突](#端口冲突)
  - [透明拦截不生效](#透明拦截不生效)
  - [SSL 证书问题](#ssl-证书问题)
  - [模型返回错误 / 400 Bad Request](#模型返回错误--400-bad-request)
  - [TRAE IDE 添加模型失败](#trae-ide-添加模型失败)
  - [<think> 标签过滤](#think-标签过滤)
  - [浏览器无法打开 WebUI](#浏览器无法打开-webui)
- [📂 文件结构](#-文件结构)
- [🧪 运行测试](#-运行测试)
- [📜 许可证](#-许可证)

---

## 🛠 项目简介

**解决的问题**：TRAE、Cursor 等 IDE 强制使用 OpenAI 等固定模型服务商，用户无法修改 Base URL，也无法使用本地部署的 Ollama 模型。本项目在本地建立一个代理服务，将 Ollama API 包装成 OpenAI 兼容格式，让 IDE 可以无缝调用本地模型。

**技术原理**：
1. 在本地启动一个 Express 服务，实现 OpenAI `/v1/chat/completions`、`/v1/models` 等接口
2. 请求到达桥接后，将 OpenAI 格式的请求转换为 Ollama API 格式
3. Ollama 的响应再转换回 OpenAI 格式返回给 IDE
4. 可选地，通过系统级 hosts + 端口转发 + CA 证书，透明拦截 `https://api.openai.com` 的请求

---

## ✨ 核心特性

- ✅ **OpenAI 完全兼容** — 实现 `/v1/models`、`/v1/chat/completions`（含流式 SSE），即插即用
- ✅ **双模式支持** — 「显式桥接」无需管理员权限；「透明拦截」劫持 `api.openai.com` 域名
- ✅ **WebUI 管理界面** — 浏览器可视化操作，一键测试、管理模型映射
- ✅ **模型映射** — 将任意 Ollama 模型映射为自定义 ID（如 `OpenAI-qwen2.5-coder:14b`）
- ✅ **API Key 校验** — 支持可选的身份验证（宽松模式 / 严格模式）
- ✅ **内容格式自适应** — 自动处理 OpenAI 数组格式的 `content`（兼容 TRAE IDE 请求）
- ✅ **流式与非流式** — 真实模拟 OpenAI Chat Completions 流式 SSE 响应
- ✅ **服务端代理测试** — WebUI 通过服务端中转测试透明拦截，避免浏览器证书报错
- ✅ **模型推理标签过滤** — `STRIP_THINK_TAGS=true` 自动移除 `<think>` 标签
- ✅ **本地优先** — 所有请求不出本机，数据安全可控

---

## ⚙️ 环境准备

### 1. Node.js (v18+)

下载安装 [Node.js LTS](https://nodejs.org/)，验证安装：

```bash
node --version    # v18.x.x 或更高
npm --version     # 10.x.x 或更高
```

### 2. Ollama

1. 从 [ollama.com](https://ollama.com/) 下载安装 Ollama
2. 拉取需要的模型：
   ```bash
   ollama pull qwen2.5-coder:14b
   ollama pull deepseek-coder:latest
   ```
3. 确认 Ollama 后台运行（系统托盘有图标）

### 3. 下载本项目

```bash
git clone https://github.com/Noyze-AI/TRAE-Ollama-Bridge.git
cd TRAE-Ollama-Bridge
```

或者直接下载 ZIP 压缩包解压。

---

## 🚀 快速开始

### 方式 A：Start-Bridge.bat（推荐）

双击项目根目录的 **`Start-Bridge.bat`**，自动完成：

1. 从 `.env.example` 复制生成 `.env`（首次）
2. 安装 `npm install`（首次）
3. 启动桥接服务
4. 在浏览器打开 WebUI

### 方式 B：TRAE-Bridge.cmd 菜单程序

双击 **`TRAE-Bridge.cmd`**，显示交互菜单：

```
===========================================
   TRAE-Ollama-Bridge 管理程序
===========================================
  1. 启动桥接服务（前台运行）
  2. 启动桥接服务（后台运行）
  3. 停止桥接服务
  4. 查看服务状态
  5. 打开 WebUI 管理界面
  6. 安装依赖
  7. 运行自动测试
  8. 查看环境配置
  0. 退出
===========================================
```

### 启动后的访问地址

| 服务 | 地址 |
|:----|:-----|
| 🌐 **WebUI 管理界面** (HTTP) | **http://localhost:5001/** |
| 🔗 API 端点 (HTTPS) | **https://localhost:3001/v1** |
| 🔒 透明拦截入口 | **https://api.openai.com** (通过 hosts + 端口转发) |

> 端口说明：`PORT=3001`（API），WebUI = `PORT+2000=5001`

---

## 🌐 WebUI 管理界面

浏览器打开 **http://localhost:5001/**，界面分为以下几个区域：

### 聊天测试

用于快速验证桥接服务是否正常工作：

1. **映射 ID** — 选择要测试的模型
2. **是否流式** — 建议开启"流式"获得实时回复
3. **测试模式**：
   - **显式桥接** — 直接调用本地 `/v1` 接口（无需管理员权限）
   - **透明拦截** — 测试 `https://api.openai.com` 拦截链路（需先配置拦截策略）
4. **API 密钥** — 如需校验密钥则填写
5. 输入聊天内容，点击 **发送**

> 透明拦截模式下，WebUI 使用服务端代理方式（`/bridge/proxy/chat/completions`），可避免浏览器 SSL 证书不信任的问题。

### 模型映射

将本地 Ollama 模型名称映射为 OpenAI 风格的 ID，供 IDE 使用：

| 本地模型名 | 映射 ID |
|:----------|:--------|
| `qwen2.5-coder:14b` | `OpenAI-qwen2.5-coder:14b` |
| `deepseek-coder:latest` | `OpenAI-deepseek-coder` |

操作步骤：
1. 点击 **刷新列表** 查看当前 Ollama 本地模型
2. 点击 **+ 新增映射**
3. 输入**本地模型名称**和**映射 ID**
4. 点击 **保存**

### 特权桥接服务（透明拦截）

管理系统级拦截策略：

| 按钮 | 功能 | 所需权限 |
|:----|:-----|:---------|
| **注册并启动服务** | 安装 Windows 服务，用于系统级操作 | 管理员 (UAC) |
| **应用拦截策略** | 安装 CA 证书、写入 hosts、配置 443 端口转发 | 管理员 (UAC) |
| **撤销拦截策略** | 清理 hosts 和端口转发 | 管理员 (UAC) |
| **卸载服务** | 移除 Windows 服务 | 管理员 (UAC) |
| **系统状态** | 查看当前 HTTPS 和 hosts 状态 | 无 |

---

## 🔧 配置 TRAE IDE

### 前提条件

1. 桥接服务已启动并正常运行
2. 在 WebUI「聊天测试」中验证模型可正常回复

### 配置步骤

1. 打开 TRAE IDE 并登录
2. 点击 AI 对话框的 **设置图标（齿轮）→ 模型 → 添加模型**
3. 填写配置：
   - **服务商**：选择 `OpenAI`
   - **模型**：选择 `自定义模型`
   - **模型 ID**：填写映射 ID（如 `OpenAI-qwen2.5-coder:14b`）
   - **API 密钥**：可输入任意字符（默认宽松模式）
4. 点击 **添加模型**
5. 在 AI 聊天框顶部下拉选择刚添加的模型即可使用

### 如果添加失败

TRAE IDE 添加模型失败通常有以下原因：

1. **TRAE IDE 未重启** — 完全关闭 TRAE IDE（含任务管理器中的进程），重新打开
2. **透明拦截未生效** — 参见下方「透明拦截不生效」排查步骤
3. **TRAE IDE 证书缓存** — Electron 应用启动时缓存证书列表，必须彻底重启才能识别新安装的 CA

---

## 📖 两种使用模式

### 模式 1：显式桥接

**适用场景**：IDE 支持自定义 Base URL（如 Cursor、OpenAI-compatible 客户端）

**配置方法**：在 IDE 的 Base URL 中填写：
```
http://localhost:3001/v1
```

**优点**：
- ✅ 无需管理员权限，即开即用
- ✅ 配置简单，不涉及系统级修改

**缺点**：
- ❌ TRAE IDE 不支持自定义 Base URL，此模式不适用于 TRAE

---

### 模式 2：透明拦截

**适用场景**：IDE 强制使用 `https://api.openai.com` 且不可修改地址（如 TRAE IDE）

**原理**：通过系统级 hosts 劫持 + 443 端口转发 + CA 证书，将对 `api.openai.com` 的请求透明地转发到本地桥接服务。

**完整配置步骤**：

#### 步骤 1：启动桥接服务
```bash
# 方法一：双击 Start-Bridge.bat
# 方法二：在项目目录执行
npm install    # 首次需要
node server.js
```

#### 步骤 2：在 WebUI 中配置透明拦截

打开 http://localhost:5001/ → **特权桥接服务** 区域：

1. 点击 **注册并启动服务**（首次会弹出 UAC 管理员确认）
2. 点击 **应用拦截策略**（自动完成以下操作）：
   - 生成本地 CA 根证书和 `api.openai.com` 域证书
   - 安装 CA 到 Windows「受信任的根证书颁发机构」
   - 写入 hosts：`127.0.0.1 api.openai.com`
   - 配置 netsh portproxy：`0.0.0.0:443 → 127.0.0.1:3001`
   - 开放 Windows 防火墙 443 端口
3. 点击 **系统状态** 确认显示：
   ```
   HTTPS：已启用 · hosts：已写入
   ```

#### 步骤 3：验证透明拦截

在 WebUI「聊天测试」中选择**透明拦截**模式，发送消息确认正常回复。

#### 步骤 4：重启 TRAE IDE 并添加模型

完全关闭 TRAE IDE（**必须从任务管理器结束所有 Trae CN 进程**），重新打开后添加模型。

#### 步骤 5：撤销透明拦截（如需）

在 WebUI 中点击 **撤销拦截策略** → **卸载服务**，即可清理所有系统修改。

**优点**：
- ✅ TRAE IDE 无需任何额外配置，直接添加模型即可
- ✅ 对所有固定访问 `api.openai.com` 的客户端生效

**缺点**：
- ❌ 需要管理员权限
- ❌ 配置步骤较多

---

## 📁 配置文件详解

项目根目录的 `.env` 文件控制所有行为（从 `.env.example` 复制）：

| 变量 | 默认值 | 说明 |
|:-----|:-------|:-----|
| `PORT` | `3001` | API 服务端口（HTTPS）；WebUI 在 `PORT+2000` |
| `BIND_ADDRESS` | `127.0.0.1` | 监听地址（`127.0.0.1` 仅本地，`0.0.0.0` 开放网络） |
| `HTTPS_ENABLED` | `true` | 启用 HTTPS（透明拦截必须开启） |
| `SSL_CERT_FILE` | `certs/api.openai.com.pem` | SSL 证书文件路径 |
| `SSL_KEY_FILE` | `certs/api.openai.com-key.pem` | SSL 私钥文件路径 |
| `OLLAMA_BASE_URL` | `http://127.0.0.1:11434` | Ollama 服务地址 |
| `ACCEPT_ANY_API_KEY` | `true` | `true` = 接受任意密钥；`false` = 强制校验 |
| `EXPECTED_API_KEY` | 空 | 固定密钥值（`ACCEPT_ANY_API_KEY=false` 时生效） |
| `STRIP_THINK_TAGS` | `false` | `true` = 自动移除 `<think>` 推理标签 |
| `ELEVATOR_PORT` | `55055` | 高权限助手进程端口 |

### 配置示例

```env
# 基础配置
PORT=3001
BIND_ADDRESS=127.0.0.1

# HTTPS（透明拦截必须）
HTTPS_ENABLED=true
SSL_CERT_FILE=certs/api.openai.com.pem
SSL_KEY_FILE=certs/api.openai.com-key.pem

# Ollama
OLLAMA_BASE_URL=http://127.0.0.1:11434

# 认证（宽松模式：接受任意密钥）
EXPECTED_API_KEY=
ACCEPT_ANY_API_KEY=true

# 过滤 <think> 标签
STRIP_THINK_TAGS=false
```

---

## 🔄 API 接口说明

### OpenAI 兼容接口

| 方法 | 路径 | 说明 |
|:----|:-----|:-----|
| `GET` | `/v1/models` | 列出所有模型映射 |
| `GET` | `/v1/models/:model` | 获取单个模型详情 |
| `POST` | `/v1/chat/completions` | 聊天补全（支持流式 SSE） |

> 同时提供无 `/v1` 前缀的别名路径：`/models`、`/models/:model`、`/chat/completions`

### 管理接口

| 方法 | 路径 | 说明 |
|:----|:-----|:-----|
| `GET` | `/health` | 健康检查 |
| `GET` | `/bridge/models` | 获取模型映射列表 |
| `POST` | `/bridge/models` | 新增映射 |
| `DELETE` | `/bridge/models/:id` | 删除映射 |
| `GET` | `/bridge/ollama/models` | 列出 Ollama 本地模型 |
| `POST` | `/bridge/proxy/chat/completions` | 服务端代理（用于 WebUI 透明拦截测试） |

### 系统管理接口

| 方法 | 路径 | 说明 |
|:----|:-----|:-----|
| `POST` | `/bridge/setup/https-hosts` | 生成证书 + 配置 hosts + 端口转发 |
| `POST` | `/bridge/setup/revoke` | 撤销拦截策略 |
| `GET` | `/bridge/setup/status` | 查询 HTTPS 与 hosts 状态 |
| `POST` | `/bridge/setup/install-elevated-service` | 安装零交互助手服务 |
| `POST` | `/bridge/setup/uninstall-elevated-service` | 卸载助手服务 |
| `GET` | `/bridge/setup/elevated-service-status` | 查询助手服务状态 |

---

## ❓ 常见问题

### 端口冲突

**问题**：`EADDRINUSE` 错误，端口被占用。

**排查**：
```powershell
# 查看 3001 端口占用
netstat -ano | findstr ":3001 "
# 查看 443 端口占用
netstat -ano | findstr ":443 "
```

**解决**：
1. 修改 `.env` 中的 `PORT` 为其他值（如 `3002`）
2. 或结束占用端口的进程：`Stop-Process -Id <PID> -Force`

### 透明拦截不生效

**问题**：IDE 添加模型失败，或 WebUI 透明拦截测试失败。

**排查步骤**：

```powershell
# 1. 检查 hosts
Select-String "api.openai.com" "C:\Windows\System32\drivers\etc\hosts"
# 应输出: 127.0.0.1 api.openai.com

# 2. 检查端口转发
netsh interface portproxy show v4tov4
# 应输出: 0.0.0.0:443 -> 127.0.0.1:3001

# 3. 检查 CA 证书
certutil -store Root | Select-String "TRAE Bridge"
# 应输出 CA 证书信息

# 4. 检查桥接服务是否运行
netstat -ano | findstr ":3001 " | findstr "LISTENING"
```

**解决**：
1. 重启桥接服务
2. 重新点击 WebUI 的「应用拦截策略」
3. 在 WebUI 点击「系统状态」确认 `HTTPS: 已启用 · hosts: 已写入`

### SSL 证书问题

**问题**：浏览器报 `ERR_CERT_INVALID` 或 `ERR_CERT_AUTHORITY_INVALID`。

**原因**：浏览器启动时缓存了证书列表，新安装的 CA 需要重启浏览器才能识别。

**解决**：
1. 完全退出浏览器（含任务管理器中的所有进程），重新打开
2. 或在地址栏输入 `chrome://restart` 让 Chrome 自动重启
3. 如果问题持续，尝试重新安装 CA：
   ```powershell
   # 以管理员身份运行
   certutil -delstore Root <旧证书哈希>
   certutil -addstore -f "Root" certs\local-ca.pem
   ```

### 模型返回错误 / 400 Bad Request

**问题**：`[Ollama 错误 400] json: cannot unmarshal array into Go struct...`

**原因**：TRAE IDE 发送的 `content` 是数组格式 `[{type:"text",text:"你好"}]`，而 Ollama 只接受字符串 `"你好"`。

**解决**：此问题已在桥接服务中修复。如果仍出现，请确认使用的是最新代码或重启服务。

### TRAE IDE 添加模型失败

**问题**：TRAE IDE 提示「添加模型失败」、「请求服务失败」或「网络异常」。

**根本原因**：TRAE IDE 使用透明拦截 `https://api.openai.com` 连接，需要系统级拦截完整就绪。

**完整排查清单**：

```
□ 桥接服务运行中（端口 3001 监听中）
□ hosts 文件包含 127.0.0.1 api.openai.com
□ netsh portproxy 已配置 0.0.0.0:443 → 127.0.0.1:3001
□ CA 证书已安装到「受信任的根证书颁发机构」
□ TRAE IDE 已完全重启（任务管理器确认无 Trae CN 进程残留）
□ 在 WebUI 中用「透明拦截」模式测试聊天正常
```

如果仍不成功，请运行以下命令提供诊断信息：

```powershell
node -e "const https=require('https'); https.get('https://api.openai.com/v1/models',{rejectUnauthorized:false},r=>{let d='';r.on('data',c=>d+=c);r.on('end',()=>console.log('状态:'+r.statusCode+' 模型:'+JSON.parse(d).data.length))}).on('error',e=>console.log('错误:'+e.message))"
```

预期输出：`状态:200 模型:5`

### <think> 标签过滤

**问题**：模型返回内容包含 `<think>...</think>` 推理过程标签。

**解决**：修改 `.env`：
```env
STRIP_THINK_TAGS=true
```
重启服务生效。

### 浏览器无法打开 WebUI

**问题**：访问 `http://localhost:5001/` 显示连接失败或白屏。

**检查**：
1. 确认桥接服务正在运行：`Get-Process -Name "node"`
2. 确认端口未被占用：`netstat -ano | findstr ":5001 "`
3. 注意是 HTTP（不是 HTTPS），地址正确

---

## 📂 文件结构

```
TRAE-Ollama-Bridge/
├── server.js                    # 桥接核心服务
├── elevated-service.js          # 高权限助手（系统操作）
├── forwarder.js                 # TCP 443 端口转发器
├── package.json                 # 项目依赖配置
├── .env                         # 运行配置（需自行创建）
├── .env.example                 # 配置模板
│
├── web/
│   └── index.html               # WebUI 管理界面（单页面应用）
│
├── certs/                       # SSL 证书目录（运行时生成）
│   ├── local-ca.pem             # CA 根证书
│   ├── local-ca-key.pem         # CA 私钥
│   ├── api.openai.com.pem       # 域证书
│   └── api.openai.com-key.pem   # 域私钥
│
├── data/
│   └── models.json              # 模型映射数据
│
├── scripts/
│   ├── install-elevated-service.js   # 安装 Windows 服务
│   └── uninstall-elevated-service.js # 卸载 Windows 服务
│
├── scripts/ (管理脚本)
│   ├── Start-Bridge.bat         # 一键启动脚本
│   ├── TRAE-Bridge.cmd          # 菜单管理程序
│   ├── setup-intercept.ps1      # 配置拦截策略
│   ├── setup-intercept.bat      # 配置拦截策略（批处理入口）
│   ├── fix-ca.ps1               # 修复 CA 证书
│   ├── reinstall-ca.ps1         # 重装 CA 证书
│   ├── install-ca-user.ps1      # 安装 CA 到当前用户
│   ├── start-forwarder.bat      # 启动 443 转发器
│   ├── test.js                  # 自动化测试
│   └── 使用说明.md               # 中文使用说明
│
├── img/                         # 图片资源
├── docs/                        # 多语言文档
├── README.md                    # 本文件
└── LICENSE                      # MIT 许可证
```

---

## 🧪 运行测试

项目内置自动化测试，验证核心功能：

```bash
npm test
```

测试内容包括：
- ✅ HTTP 健康检查
- ✅ 模型映射 CRUD（增删改查）
- ✅ `/v1/models` 列表接口
- ✅ 404 错误处理
- ✅ 数据文件隔离（测试后恢复原数据）

---

## 📜 许可证

MIT License — 详见根目录 [LICENSE](LICENSE) 文件。

---

## ⭐ 支持项目

如果你觉得本项目有帮助，请在 GitHub 点个 Star ⭐，让更多开发者看到！

[👉 前往 GitHub 给 TRAE-Ollama-Bridge 点星](https://github.com/Noyze-AI/TRAE-Ollama-Bridge)
