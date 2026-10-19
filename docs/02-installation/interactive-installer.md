# 交互式菜单安装

[返回首页](../../README.md) · [本分类目录](README.md)

只运行一条命令，按数字选择；自动补依赖、安装并验证。

执行位置：**Linux · 交互式 SSH 终端** · 分类：安装部署

## 唯一的入口命令

在已登录 Linux 服务器的 Bash 终端执行。需要已经有 curl 和 Bash。菜单从终端读取按键，不会把脚本下载内容当成输入。

**Linux · 打开中文安装菜单**

```bash
curl -fsSL https://raw.githubusercontent.com/Yamada-anna1/paseo-linux-guide/main/install.sh | bash
```

## 按数字选择

| 选项 | 功能 |
| --- | --- |
| 1 | 安装 Codex、CC-Switch、Paseo、GitHub CLI，自动补齐依赖 |
| 2 | 只安装 Codex |
| 3 | 只安装 CC-Switch |
| 4 | 只安装 Paseo，自动补 Node.js/npm |
| 5 | 启动 Paseo 并查看状态 |
| 6 | 确认后启用 Relay 并显示手机配对二维码 |
| 7 | 只读检查版本、路径和服务状态 |
| 8 | 确认后进行 Codex 官方账号设备码登录 |
| 9 | 打开 CC-Switch 服务商配置界面 |
| 10 | 安装 GitHub CLI（gh） |
| 11 | 确认后使用浏览器设备码登录 GitHub |
| 12 | 只读检查 GitHub CLI 和登录状态 |
| 13 | 确认后停止再启动本机 Paseo，以刷新环境 |
| 0 | 退出菜单 |

## 已经安装 Codex 和 CC-Switch，但缺少 npm

选 4 即可。安装器会先处理不可用的 Node.js/npm，再安装 Paseo。完成后选 5 启动；需要手机连接再选 6。从零安装则选 1。可正常运行的已有工具会自动跳过，不需要重装。

## GitHub 克隆窗口提示找不到 gh

在运行 Paseo 的同一台 Linux、同一个用户下打开菜单，依次选 10 安装、11 浏览器授权、12 检查。仍报找不到 gh 时，先等正在执行的任务结束，再选 13 并确认；回到 Paseo 重开 Clone from GitHub。13 不会自动执行，也不处理 systemd / 容器的服务定义。

## 安装器会做什么

- 支持 Linux x86_64 与 ARM64；基础包自动安装处理 apt-get、dnf、yum。其他发行版的缺失依赖会提示，不强行安装。
- Node.js/npm 不可用或 Node.js 低于 22 时，通过 nvm 安装 Node.js 24 LTS；Alpine 的 musl Node.js 不纳入自动流程。
- Codex 调用 OpenAI 官方安装器；CC-Switch 调用 SaladDay 项目安装器；Paseo 通过 npm 安装到当前用户的 ~/.local。
- GitHub CLI 使用固定版本 2.102.0 官方二进制，校验固定 SHA-256 后安装到 ~/.local/bin/gh；不新增软件源，保留已有可用 gh。
- 在 Bash 配置末尾追加带标记的环境设置，避免重复追加，不覆盖原配置。
- 任一步骤失败就停止当前流程并返回菜单，不继续启动不存在的命令。
- 不会自动升级可用工具、修改 SSH 或防火墙，不自动登录账号，也不自动停止已有 daemon。

> **运行前确认来源**
>
> 此脚本会下载并运行对应上游软件；选择安装后，必要时会补装系统依赖。普通用户需要有相应 sudo 权限。建议使用已有专用 Linux 用户，不要交替用 root 与普通用户混装。源码：https://github.com/Yamada-anna1/paseo-linux-guide/blob/main/install.sh

## 安装后怎样使用

在菜单里可以立即继续启动、登录或生成二维码。退出安装器后，重新连接一次 SSH，使原终端加载新 PATH 和 Node.js 环境。子进程无法直接改写它所属的旧终端环境。

> **账号与配对安全**
>
> 官方账号登录、第三方服务商密钥仍由你本人配置。安装器不会代填凭据。启用 Relay 会再确认；二维码和配对链接不要发到公开截图或仓库。

## 测试与问题反馈

脚本包含离线模拟测试，以及 GitHub 托管 Ubuntu 临时环境的真实安装测试。测试不连接个人服务器，不登录账号、不请求模型，也不生成配对二维码。运行结果：https://github.com/Yamada-anna1/paseo-linux-guide/actions

如果失败，保留菜单选项编号和错误文字，先遮盖凭据再反馈。网络、上游下载源或系统兼容性仍可能导致失败；不要在失败后重复执行手动启动命令。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：复制命令与使用约定](../01-introduction/copy-rules.md) · [下一篇：GitHub CLI 安装与登录](github-cli.md)
