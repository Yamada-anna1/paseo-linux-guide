# 复制命令与使用约定

[返回首页](../../README.md) · [本分类目录](README.md)

看清执行位置，每次只复制一条命令。

执行位置：**阅读说明** · 分类：简介

| 标记 | 在哪里执行 |
| --- | --- |
| Linux | 已登录服务器的 SSH 终端 |
| Windows PowerShell | 本地 Windows 的普通 PowerShell |
| 管理员 PowerShell | 以管理员身份打开的本地 PowerShell |
| Paseo 界面 | 在 Paseo Desktop 或手机应用里点击操作 |
| 填写内容 / 预期输出 | 用于填写或对照，不是执行命令 |

- 每个命令框只放一个步骤。复制按钮只复制框内内容，不复制说明。
- 不要复制终端提示符，例如 root@主机:~# 或 PS C:\Users\WINDOWS_USER>。
- 命令中的网络地址使用纯 URL，不带 Markdown 的 `[链接](链接)` 格式。
- YOUR_SERVER_IP、YOUR_PROVIDER_ID、YOUR_MODEL_ID、YOUR_REPOSITORY_URL 等占位符必须先替换。没有给出真实模型 ID，是为了避免把过时或无权限的模型当成通用选项。
- 需要输入密码或密钥口令时，终端通常不显示字符，这是正常行为。
- 首次 SSH 连接要核对服务器指纹；确认提示处不能输入密码。
- 遇到错误先看对应说明，不要继续执行依赖它的修改或重启步骤。
- 软件已正常工作时，跳过对应的安装、生成密钥和修复步骤。

> **本手册中的用户身份**
>
> 示例以 root 和 /root 展示路径，不要求使用 root。Codex、CC-Switch 与 Paseo 应使用同一个专用 Linux 用户；改用普通用户时，同步替换用户名、主目录以及需要管理员权限的命令。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：首次搭建路线](quickstart.md) · [下一篇：Linux 基础依赖](../02-installation/linux-prerequisites.md)
