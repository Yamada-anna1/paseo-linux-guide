# 安装 Paseo 与启动 daemon

[返回首页](../../README.md) · [本分类目录](README.md)

在 Linux 上运行服务，让桌面端或手机连接。

执行位置：**Linux** · 分类：安装部署

## 1. 检查和安装

**Linux · 检查 Paseo**

```bash
paseo --version
```

命令不存在时再执行安装；Node.js 和 npm 需要已经可用。

**Linux · 安装 Paseo CLI**

```bash
npm install -g @getpaseo/cli
```

**Linux · 验证版本**

```bash
paseo --version
```

**Linux · 查看 Paseo 路径**

```bash
command -v paseo
```

## 2. 启动与检查

**Linux · 启动 daemon**

```bash
paseo daemon start
```

**Linux · 检查运行状态**

```bash
paseo daemon status
```

**Linux · 检查 Paseo 实际调用的 Codex**

```bash
paseo provider diagnostic codex
```

Paseo 默认 daemon 端口为 6767。使用 SSH 转发访问远程回环地址即可，不需要把 6767 直接开放到公网；以 status 的实际监听信息为准。

> **同一个 Linux 用户**
>
> 用哪个用户启动 daemon，就要让该用户能找到 Codex 并读取其配置。root 的 Codex 登录和配置不会自动出现在另一个普通用户下。

只有打算使用手机配对时，才继续“手机二维码与 Relay”。Windows Desktop 使用 SSH 的流程见“Paseo Desktop 连接”。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：安装 CC-Switch CLI](cc-switch-install.md) · [下一篇：SSH 排查与配置指引](../03-remote/ssh-troubleshooting.md)
