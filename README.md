# Linux · Codex · CC-Switch · Paseo 分类手册

一条命令打开中文安装菜单，按数字安装 Codex、CC-Switch、Paseo，并自动补齐依赖。另附 SSH 连接、手机配对与模型排障分类手册。

这是第三方整理的**交互式安装器与使用文档仓库**，不是三个工具的官方发行包。克隆仓库不会安装软件；主动运行下方命令并选择安装选项后，才会调用上游安装器。

## 一条命令，按菜单安装

在 **Linux 服务器的交互式 SSH 终端**复制这一条即可（需要已有 `curl` 和 Bash）：

```bash
curl -fsSL https://raw.githubusercontent.com/Yamada-anna1/paseo-linux-guide/main/install.sh | bash
```

运行远程脚本前请确认信任来源；可以先审阅 [install.sh](install.sh)。脚本会从 OpenAI、CC-Switch 项目、nvm 项目和 npm 下载所选软件。缺少系统依赖时会用 apt-get / dnf / yum 补装；普通用户需要具备相应 sudo 权限。

```text
1) 一键安装全部：Codex + CC-Switch + Paseo（自动补依赖）
2) 只安装 Codex
3) 只安装 CC-Switch
4) 只安装 Paseo（自动补 Node.js / npm）
5) 启动 Paseo 并查看状态
6) 启用 Relay 并显示手机配对二维码
7) 检查版本、命令路径和服务状态（只读）
8) Codex 官方账号登录
9) 打开 CC-Switch 服务商配置
0) 退出
```

**你已经装好 Codex 和 CC-Switch，却遇到 `npm: command not found`：选 `4` 即可。** 完成后选 `5` 启动，需手机连接时选 `6`。从零搭建可以选 `1`；可正常运行的已有工具会跳过，不会自动升级或覆盖。

- 缺少或无法运行的 Node.js/npm，或 Node.js 低于 22：通过 nvm 安装 Node.js 24 LTS，并保存 Bash 环境。
- 任一步骤失败会停止当前流程、显示报错并返回菜单，不会继续调用没有安装好的工具。
- 安装器的菜单直接从终端读取输入，支持上面的 `curl … | bash` 方式。
- 不自动登录账号，不修改 SSH、防火墙、API Key，不自动停止已有 daemon。
- 登录和 Relay 启用会再确认；二维码与配对链接不可公开。
- 菜单内可立即继续启动或配对。退出后，**重新连接一次 SSH**，让原终端加载新 PATH / Node.js 环境。

详细说明：[交互式菜单安装](docs/02-installation/interactive-installer.md)。

## 从哪里开始

- **第一次配置**：[首次搭建路线](docs/01-introduction/quickstart.md)
- **只想安装工具**：使用上方“一条命令，按菜单安装”；下方手动命令仅作备选
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

## 手动安装命令（备选，不需要与菜单方式重复执行）

以下在 **Linux 服务器的 Bash 终端**执行，不是在 Windows PowerShell 里执行。

先确保 `curl`、Node.js 和 `npm` 可用。Paseo 的 npm 安装需要 Node.js/npm；Codex 的独立安装脚本不依赖 npm。详细依赖检查见 [Linux 基础依赖](docs/02-installation/linux-prerequisites.md)。若全局 npm 安装报权限问题，先确认 Node.js 的安装方式与用户，不要直接切换为 root 后混用两套配置。

运行 `curl … | sh/bash` 会执行上游安装脚本。仅在信任对应来源时使用；需要审查时先下载阅读。下方是手动方式，与上面的菜单安装器二选一，不必重复安装。

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

| 分类 | 篇数 | 内容 |
| --- | --- | --- |
| [简介](docs/01-introduction/README.md) | 3 | 工具关系、首次搭建路线、复制约定 |
| [安装部署](docs/02-installation/README.md) | 7 | 交互式一键安装、Linux 依赖、PATH、三个工具的手动安装 |
| [远程连接](docs/03-remote/README.md) | 5 | Windows 密钥、SSH Agent、公钥认证、Paseo SSH |
| [项目与手机](docs/04-projects-mobile/README.md) | 3 | Linux 路径、添加项目、二维码与 Relay |
| [模型与服务商](docs/05-models/README.md) | 4 | 服务商切换、模型缺少、手动添加、模型配置 |
| [维护与排障](docs/06-maintenance/README.md) | 5 | 软件更新、daemon 启停、日常速查、错误与资料 |

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

本公开版更新于 **2026-10-20**。安装入口与非交互安装参数已按上游文档及安装脚本核对。测试分为离线模拟测试和 GitHub 托管 Ubuntu 临时环境中的真实安装测试；结果见 [Actions](https://github.com/Yamada-anna1/paseo-linux-guide/actions)。没有连接或修改任何用户的服务器，测试不会登录账号、请求模型或生成配对二维码。

目录结构：

```text
paseo-linux-guide/
├── README.md                 # 首页、分类入口、安装命令
├── index.html                # 带侧栏、搜索和复制按钮的离线手册
├── install.sh                # 中文交互式安装菜单
├── docs/                     # 6 大分类、27 篇 Markdown 教程
├── src/guide-content.json    # 教程内容唯一来源（仅脱敏内容）
├── src/guide-shell.html      # HTML 外壳
├── src/readme-template.md    # 首页模板
├── scripts/                  # 文档构建、检查与安装器测试
└── .github/workflows/        # Ubuntu 自动测试
```

修改 `src/guide-content.json` / `src/readme-template.md` 后，分别执行（需要 Node.js，无第三方构建依赖）：

```bash
npm run build
```

```bash
npm run check
```

离线安装器测试（需要 Bash；不联网、不安装软件、不改动真实用户主目录）：

```bash
bash scripts/test-installer.sh
```

`scripts/smoke-installer-ci.sh` 仅允许在临时的 GitHub 托管 runner 中执行真实安装；请勿作为个人服务器的安装入口。

检查包括文档数量、内部链接、生成内容一致性、脚本语法和常见凭据模式，不代替人工安全审查。具体资料见 [参考资料](docs/06-maintenance/references.md)。
