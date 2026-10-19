# 三个工具与整体关系

[返回首页](../../README.md) · [本分类目录](README.md)

先分清 Codex、Paseo 和 CC-Switch 各自负责什么。

执行位置：**阅读说明** · 分类：简介

这份手册对应的使用方式是：在 Windows 上打开 Paseo Desktop，通过 SSH 连接 Linux 服务器上的 Paseo daemon，由 daemon 启动和管理服务器上的 Codex。代码、工作目录和实际执行的命令都位于 Linux 服务器。

| 工具 | 执行命令 | 作用 | 是否需要 |
| --- | --- | --- | --- |
| Codex CLI | codex | 阅读代码、修改文件、运行命令并执行 AI 编程任务 | 使用 Codex 时需要 |
| Paseo CLI / daemon | paseo | 在服务器上管理 Agent、项目和客户端连接 | 远程 Paseo 需要 |
| CC-Switch CLI | cc-switch | 管理和切换 Codex、Claude 等工具的服务商配置 | 可选 |

## 它们怎样配合

- Windows Paseo Desktop → SSH → Linux Paseo daemon → Linux Codex CLI。
- 手机 Paseo → 配对连接 / Relay → Linux Paseo daemon。
- CC-Switch 修改 Codex 的服务商配置；它不是上述连接链条中必须常驻的中转进程。
- 安装 cc-switch 并不会同时安装 codex 或 paseo，三个命令要分别检查。

## 公开示例与占位符

| 字段 | 示例值 / 说明 |
| --- | --- |
| 服务器地址 | YOUR_SERVER_IP：替换为你自己的 IP 或域名 |
| SSH 用户 | root 仅作示例；优先使用已有的专用普通用户 |
| SSH 端口 | 示例为 22，以实际配置为准 |
| Linux 主机名 | LINUX_HOSTNAME |
| Windows 用户目录 | C:\Users\WINDOWS_USER |
| 公开版整理日期 | 2026-10-20 |

> **安全与适用范围**
>
> 本仓库是第三方整理的中文使用手册，不是三个工具的官方发行包。未包含真实服务器地址、密码、私钥、API Key 或配对二维码。示例中的 root 和 /root 仅用于说明；改用普通用户时，请同步替换用户名和主目录。不要为了照抄示例而开启 root 密码登录或开放公网 daemon 端口。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [下一篇：首次搭建路线](quickstart.md)
