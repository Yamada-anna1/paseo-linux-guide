# Linux · Codex · CC-Switch · Paseo 分类手册

中文安装、SSH 远程连接、手机二维码配对、服务商配置与模型排障手册。每个代码块独立复制，并标明操作位置。

这是第三方整理的**使用文档仓库**，不是 Codex、CC-Switch 或 Paseo 的官方软件仓库；克隆本仓库不会安装这三个工具。

## 从哪里开始

- **第一次配置**：[首次搭建路线](docs/01-introduction/quickstart.md)
- **只想安装工具**：直接看下面的“三个工具安装命令”
- **已经配置好**：[日常命令速查](docs/06-maintenance/daily.md)
- **模型缺少 / 刷新不出来**：[四条诊断命令](docs/05-models/models-missing.md)
- **Windows 远程连接**：[SSH 密钥](docs/03-remote/ssh-key.md) → [SSH Agent](docs/03-remote/ssh-agent.md) → [连接测试](docs/03-remote/ssh-test.md) → [Paseo 连接](docs/03-remote/desktop-ssh.md)
- **手机连接**：[二维码与 Relay](docs/04-projects-mobile/mobile-pair.md)
- **喜欢左侧目录的版式**：[下载单文件 HTML 手册](https://github.com/Yamada-anna1/paseo-linux-guide/raw/refs/heads/main/index.html)，用浏览器打开。

HTML 已内嵌内容、样式和脚本，不依赖服务器或 CDN。GitHub 的文件页面只显示源码，下载后用 Edge / Chrome 打开；不要改成 `.txt`。

## 工具分类

| 工具 | 用途 | 在哪里安装 |
| --- | --- | --- |
| Codex CLI（`codex`） | 实际执行 AI 编程任务 | Linux 服务器 |
| CC-Switch CLI（`cc-switch`） | 管理、切换服务商配置；可选 | 与 Codex 相同的 Linux 用户 |
| Paseo CLI（`paseo`） | 管理 daemon、Agent 和远程连接 | 与 Codex 相同的 Linux 用户 |
| Paseo 桌面 / 手机客户端 | 连接并操作 Linux 上的服务 | 本地电脑 / 手机，按 [Paseo 官网](https://paseo.sh) 下载 |

## 三个工具安装命令

以下在 **Linux 服务器的 Bash 终端**执行，不是在 Windows PowerShell 里执行。

先确保 `curl`、Node.js 和 `npm` 可用。Paseo 的 npm 安装需要 Node.js/npm；Codex 的独立安装脚本不依赖 npm。详细依赖检查见 [Linux 基础依赖](docs/02-installation/linux-prerequisites.md)。若全局 npm 安装报权限问题，先确认 Node.js 的安装方式与用户，不要直接切换为 root 后混用两套配置。

运行 `curl … | sh/bash` 会执行上游安装脚本。仅在信任对应来源时使用；需要审查时先下载阅读。这里只列出命令，本仓库不会自动安装软件或修改 SSH。

### 1. Codex CLI

安装（官方独立安装脚本）：

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

验证：

```bash
codex --version
```

官方账号的无桌面服务器可使用设备码登录；已使用第三方接口时，先看 [认证与测试说明](docs/02-installation/codex-login.md)，不要盲目覆盖现有配置：

```bash
codex login --device-auth
```

来源：[OpenAI Codex CLI 文档](https://learn.chatgpt.com/docs/codex/cli)。更多安装选项：[安装 Codex CLI](docs/02-installation/codex-install.md)。

### 2. CC-Switch CLI（可选）

安装（你指定的 `SaladDay/cc-switch-cli` 项目）：

```bash
curl -fsSL https://github.com/SaladDay/cc-switch-cli/releases/latest/download/install.sh | bash
```

让当前终端找到默认安装目录：

```bash
export PATH="$HOME/.local/bin:$PATH"
```

验证：

```bash
cc-switch --version
```

打开交互界面：

```bash
cc-switch
```

来源：[CC-Switch CLI 项目](https://github.com/SaladDay/cc-switch-cli)。长期保存 PATH：[命令目录与 PATH](docs/02-installation/path.md)。

### 3. Paseo CLI

安装（需先有 Node.js/npm）：

```bash
npm install -g @getpaseo/cli
```

验证：

```bash
paseo --version
```

启动 daemon：

```bash
paseo daemon start
```

查看状态：

```bash
paseo daemon status
```

需要手机配对时，再生成二维码：

```bash
paseo daemon pair
```

跨网络 Relay 配对、二维码保密等说明见 [手机二维码与 Relay](docs/04-projects-mobile/mobile-pair.md)。

来源：[Paseo 安装文档](https://paseo.sh/docs) · [Paseo CLI 文档](https://paseo.sh/docs/cli)。

## 分类目录

__CATEGORY_TABLE__

## 常见问题快捷入口

| 问题 | 文档 |
| --- | --- |
| 安装成功却提示 `command not found` | [PATH](docs/02-installation/path.md) |
| `PubkeyAuthentication no` | [开启公钥认证](docs/03-remote/sshd-pubkey.md) |
| 不知道填写哪个 Linux 路径 | [项目路径怎么看](docs/04-projects-mobile/project-paths.md) |
| `Choose a project` | [添加 Linux 项目](docs/04-projects-mobile/project-add.md) |
| 切换接口后 Paseo 没变化 | [服务商配置](docs/05-models/provider-switch.md) |
| 模型少、刷新无效 | [模型排障](docs/05-models/models-missing.md) |
| 修改 PATH 后 daemon 仍找不到 Codex | [启停与环境刷新](docs/06-maintenance/daemon-control.md) |

## 保存到自己的电脑

以下只下载本手册，不安装工具：

```bash
git clone https://github.com/Yamada-anna1/paseo-linux-guide.git
```

下载后直接用浏览器打开仓库内 `index.html`。也可以在 GitHub 上点击 **Code → Download ZIP**，解压后打开。

## 安全与占位符

- `YOUR_SERVER_IP`、`YOUR_PROVIDER_ID`、`YOUR_MODEL_ID`、`YOUR_REPOSITORY_URL` 必须先替换成自己的值。
- 示例中的 `root` 与 `/root` 不是要求。优先用专用普通用户，并保持 Codex、Paseo、CC-Switch 使用同一用户环境。
- 不要为照抄示例而开启 root 密码登录、关闭主机指纹检查，或把 daemon 端口直接暴露到公网。
- 不上传密码、API Key、SSH 私钥、`auth.json`、配对链接和二维码。求助日志也要先脱敏。
- 修改 SSH 前保留当前连接，备份配置，语法验证通过后才重载；不要把替代方案当成连续步骤执行。
- 手动添加模型不会开通权限；看到模型菜单项不等于接口调用已成功。

## 文档维护

本公开版整理于 **2026-10-20**。安装入口已按上游文档核对；没有在任何用户的 Linux 服务器上执行安装或声称完成配置。具体 CLI 选项、界面和模型权限以所用版本及账号为准。

目录结构：

```text
paseo-linux-guide/
├── README.md                 # 首页、分类入口、安装命令
├── index.html                # 带侧栏、搜索和复制按钮的离线手册
├── docs/                     # 6 大分类、26 篇 Markdown 教程
├── src/guide-content.json    # 教程内容唯一来源（仅脱敏内容）
├── src/guide-shell.html      # HTML 外壳
├── src/readme-template.md    # 首页模板
└── scripts/                  # 构建与检查，不执行工具安装
```

修改 `src/guide-content.json` / `src/readme-template.md` 后，分别执行（需要 Node.js，无第三方构建依赖）：

```bash
npm run build
```

```bash
npm run check
```

检查包括文档数量、内部链接、生成内容一致性、脚本语法和常见凭据模式，不代替人工安全审查。具体资料见 [参考资料](docs/06-maintenance/references.md)。
