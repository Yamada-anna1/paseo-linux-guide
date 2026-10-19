# GitHub CLI 安装与登录

[返回首页](../../README.md) · [本分类目录](README.md)

解决 Paseo 克隆窗口缺少 gh，并区分服务器授权与 daemon 环境。

执行位置：**Linux · 与 Paseo 相同的用户** · 分类：安装部署

## 先分清 git 与 gh

git 用于版本管理和普通仓库克隆；gh 是 GitHub CLI，负责 GitHub 账号认证和仓库相关操作。装了 git 并不等于装了 gh。Paseo 的 Clone from GitHub 报 GitHub CLI (gh) is not installed or not in PATH 时，先处理当前远端主机的 gh，不是重装 Codex 或 SSH。

## 一条命令打开菜单

**Linux · 原安装入口保持不变**

```bash
curl -fsSL https://raw.githubusercontent.com/Yamada-anna1/paseo-linux-guide/main/install.sh | bash
```

| 顺序 / 选项 | 操作 | 完成标志 |
| --- | --- | --- |
| 1 · 10 | 安装 GitHub CLI；已有可用版本则保留 | 显示 gh 版本，安装成功 |
| 2 · 11 | 确认登录；按终端提示在自己的电脑或手机浏览器授权 | 返回安装菜单且没有登录错误 |
| 3 · 12 | 检查当前 Linux 用户的 GitHub 登录 | 状态显示正确账号已登录 |
| 按需 · 13 | 旧 Paseo 仍找不到 gh 时，任务结束后确认停止再启动 | 服务状态正常，重开克隆窗口验证 |

全新搭建也可直接选 1，安装全部四个工具；仍需自行选 11 登录。只缺 gh 不必重装全部。菜单 10 使用经 SHA-256 校验的官方 2.102.0 Linux x86_64 / ARM64 二进制；不是自动跟随最新版的升级器。

## 浏览器授权怎么做

- 确保 SSH 登录用户就是运行 Paseo daemon 的用户；Windows 上已有的 GitHub 登录不会自动同步到 Linux。
- 选择 11 并确认后，按照终端显示的授权网址和一次性设备码，在自己的电脑或手机浏览器完成登录与权限确认。服务器无需安装桌面浏览器。
- 若询问是否让 Git 使用 GitHub 凭据，可按自身需要确认。此次新登录使用 github.com 与 HTTPS；已有有效登录直接保留，不切换账号。
- 等待终端完成授权，再选 12。不要把设备码、令牌或凭据配置内容发到聊天、截图或公开仓库。

> **凭据保存与环境变量**
>
> gh 优先使用可用的系统凭据库；没有可用凭据库时可能退回明文配置文件。安装器会事先提示，不强制使用不安全存储。检测到 GH_TOKEN / GITHUB_TOKEN 时，菜单 11 不覆盖它们；菜单 12 的成功也不代表旧 daemon 继承了同一环境。若需要改用持久化浏览器登录，请自行移除原终端中的临时变量再重开菜单，不要输出变量内容。

## 已安装但 Paseo 仍提示找不到

- 确认 Paseo 当前选中的是刚安装 gh 的那台 Linux 主机，且 daemon 与安装使用同一个用户。
- 选 7 或 12 确认当前终端能找到 gh；选 12 同时核对登录账号。
- 旧 daemon 不会自动继承新 PATH。等待任务结束，选 13 并确认停止后启动，再回到客户端重开克隆窗口。普通 daemon restart 不能保证刷新 supervisor 的环境。
- 若使用 systemd、容器或专门的 PASEO_HOME，检查真正的启动用户、PATH 和凭据环境；菜单 13 会明确显示目标目录，检测到 PASEO_HOST 会拒绝操作，不修改服务定义。
- 登录成功但私有仓库仍不出现：核对该账号的仓库权限、组织授权，以及终端与 daemon 是否使用相同配置目录。

## 只读手动检查（备选）

**Linux · gh 路径**

```bash
command -v gh
```

**Linux · gh 版本**

```bash
gh --version
```

**Linux · 检查 GitHub 登录，不显示令牌**

```bash
gh auth status --hostname github.com
```

官方资料：https://github.com/cli/cli/blob/trunk/docs/install_linux.md · https://cli.github.com/manual/gh_auth_login · https://cli.github.com/manual/gh_auth_status

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：交互式菜单安装](interactive-installer.md) · [下一篇：Linux 基础依赖](linux-prerequisites.md)
