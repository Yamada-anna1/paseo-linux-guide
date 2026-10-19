# Codex 登录与单独测试

[返回首页](../../README.md) · [本分类目录](README.md)

先确认 Codex 能独立使用，再接入 Paseo。

执行位置：**Linux** · 分类：安装部署

## 使用官方账号登录

没有图形界面的 Linux 服务器可先使用设备码登录。根据终端提示，在本地浏览器打开地址并输入一次性代码。账号或组织设置需要允许该登录方式。

**Linux · 设备码登录**

```bash
codex login --device-auth
```

如果设备码不可用，使用普通登录流程，并根据 CLI 提示处理浏览器和回调。下面是替代方式，无需在已成功登录后重复执行。

**Linux · 替代方式：普通登录**

```bash
codex login
```

**Linux · 查看登录状态**

```bash
codex login status
```

> **已配置第三方服务商时**
>
> 先明确使用官方账号还是第三方 API 配置。不要用重复登录来盲目覆盖已有配置；CC-Switch 管理的接口能否使用，以该配置下实际执行请求的结果为准。

## 在测试目录启动

**Linux · 创建测试目录**

```bash
mkdir -p /root/codex-test
```

**Linux · 进入测试目录**

```bash
cd /root/codex-test
```

**Linux · 启动 Codex**

```bash
codex
```

**在 Codex 对话中输入**

```text
只回复 OK，不读取或修改文件。
```

能启动界面只说明程序能运行；成功收到模型回复，才同时验证了当前认证、网络和模型调用。

---

[返回首页](../../README.md) · [本分类目录](README.md) · [上一篇：安装 Codex CLI](codex-install.md) · [下一篇：安装 CC-Switch CLI](cc-switch-install.md)
